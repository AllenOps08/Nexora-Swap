// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.26;

// ░▒█▄░▒█░▒█▀▀▀░▀▄░▄▀░▒█▀▀▀█░▒█▀▀▄░█▀▀▄░░░▒█▀▀▀█░▒█░░▒█░█▀▀▄░▒█▀▀█
// ░▒█▒█▒█░▒█▀▀▀░░▒█░░░▒█░░▒█░▒█▄▄▀▒█▄▄█░░░░▀▀▀▄▄░▒█▒█▒█▒█▄▄█░▒█▄▄█
// ░▒█░░▀█░▒█▄▄▄░▄▀▒▀▄░▒█▄▄▄█░▒█░▒█▒█░▒█░░░▒█▄▄▄█░▒▀▄▀▄▀▒█░▒█░▒█░░░

import {INexoraPool} from "../Interfaces/INexoraPool.sol";
import {ISetters} from "../Interfaces/ISetters.sol";
import {IGetters} from "../Interfaces/IGetters.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {NexoraToken} from "./NexoraToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {PriceOracle} from "src/core/PriceOracle.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

contract NexoraPool is INexoraPool, OwnableUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable, IGetters {
    using SafeERC20 for IERC20;

    NexoraToken public immutable token;

    IERC20[3] public coins;
    uint256[3] public balances;
    PriceOracle[3] public priceOracles;

    uint256 public immutable amplificationCoefficient;
    uint256 public immutable swapFee;
    uint256 public immutable adminFee;
    uint256 public imbalanceFee;
    uint256 public amplificationTimeline = 24 hours;
    uint256 public amplificationPrecision = 100;
    uint256 public fee;
    uint256 constant PRECISION = 1e18;

    uint256 FEE_DENOMINATOR = 10 ** 10;

    uint256[50] private __gaps;

    // Price Oracle
    PriceOracle public oracle;

    //State variables for ramping up amplification coefficient
    uint256 public initialAmplificationCoefficient;
    uint256 public futureAmplificationCoefficient;
    uint256 public initialAmplificationPeriod;
    uint256 public futureAmplificationPeriod;

    constructor(
        address[3] memory _coins,
        address[3] memory _priceOracles,
        uint256 _amplificationCoefficient,
        uint256 _swapFee,
        uint256 _adminFee
    ) {
        __Ownable_init(msg.sender);
        require(_amplificationCoefficient > 0, "Invalid amplification coefficient");
        require(_swapFee <= FEE_DENOMINATOR / 100, "Fee too high");
        require(_adminFee <= FEE_DENOMINATOR, "Admin fee too high");

        for (uint256 i = 0; i < coins.length; i++) {
            require(_coins[i] != address(0), "Invalid coin");
            require(priceOracles[i] != address(0), "Stale price");
            coins[i] = IERC20(_coins[i]);
            priceOracles[i] = PriceOracle(_priceOracles[i]);
        }

        amplificationCoefficient = _amplificationCoefficient;
        swapFee = _swapFee;
        adminFee = _adminFee;

        initialAmplificationCoefficient = _amplificationCoefficient;
        futureAmplificationCoefficient = _amplificationCoefficient;
        initialAmplificationPeriod = block.timestamp;
        futureAmplificationPeriod = block.timestamp;
    }

    event NotImplemented();

    function swap(
        uint256 tokenIndexFrom,
        uint256 tokenIndexTo,
        uint256 inputAmount,
        uint256 minOutputAmount,
        uint256 deadline
    ) external override nonReentrant returns (uint256) {
        require(deadline >= block.timestamp, "Deadline expired");
        require(tokenIndexFrom != tokenIndexTo, "Same token index");
        require(tokenIndexFrom < coins.length && tokenIndexTo < coins.length, "Invalid token index");

        uint256 outputAmount = calculateSwap(tokenIndexFrom, tokenIndexTo, inputAmount);
        require(outputAmount >= minOutputAmount, "Insufficient output available");

        // Calculate and validate price
        uint256 expectedPrice = (inputAmount * PRECISION) / outputAmount;
        bool isPriceValid = validatePrice(address(coins[tokenIndexFrom]), address(coins[tokenIndexTo]), expectedPrice);

        require(isPriceValid, "Price validation failed");

        //Swapping
        coins[tokenIndexFrom].safeTransferFrom(msg.sender, address(this), inputAmount);
        balances[tokenIndexFrom] += inputAmount;
        balances[tokenIndexTo] -= outputAmount;

        coins[tokenIndexTo].safeTransfer(msg.sender, outputAmount);

        emit TokenSwap(msg.sender, tokenIndexFrom, tokenIndexTo);
        return outputAmount;
    }

    function validatePrice(address tokenIn, address tokenOut, uint256 expectedPrice)
        public
        view
        override
        returns (bool)
    {
        uint256 tokenInIndex = getTokenIndex(tokenIn);
        uint256 tokenOutIndex = getTokenIndex(tokenOut);

        // Get EMA prices from oracles
        uint256 tokenInPrice = priceOracles[tokenInIndex].calculateEMAPrice();
        uint256 tokenOutPrice = priceOracles[tokenOutIndex].calculateEMAPrice();

        // Calculate the actual price ratio
        uint256 actualPrice = (tokenInPrice * PRECISION) / tokenOutPrice;

        //Get last verified prices and validate
        uint256 tokenInLastVerified = priceOracles[tokenInIndex];
        uint256 tokenOutLastVerified = priceOracles[tokenOutIndex];

        // Check if both prices are within deviation limits
        bool isTokenInValid = priceOracles[tokenInIndex].isPriceWithinDeviation(tokenInPrice, tokenInLastVerified);

        bool isTokenOutValid = priceOracles[tokenOutIndex].isPriceWithinDeviation(tokenOutPrice, tokenOutLastVerified);

        uint256 maxDeviation = priceOracles[tokenInIndex].maxPriceDeviation();
        uint256 upperBound = expectedPrice + ((expectedPrice * maxDeviation) / 100);
        uint256 lowerBound = expectedPrice - ((expectedPrice * maxDeviation) / 100);

        return isTokenInValid && isTokenOutValid && actualPrice >= lowerBound && actualPrice <= upperBound;
    }

    function calculateSwap(uint256 tokenIndexFrom, uint256 tokenIndexTo, uint256 inputAmount)
        external
        view
        override
        returns (uint256)
    {
        require(tokenIndexFrom != tokenIndexTo, "Same token");
        require(tokenIndexFrom < coins.length && tokenIndexTo < coins.length);

        uint256 xy = balances[tokenIndexFrom] * balances[tokenIndexTo];
        uint256 k = xy * amplificationCoefficient;

        //New balances
        uint256 newBalanceFrom = balances[tokenIndexFrom] + inputAmount;
        uint256 newBalanceTo = k / (newBalanceFrom * amplificationCoefficient);

        //Calculating Output Amount
        uint256 outputAmount = balances[tokenIndexTo] - newBalanceTo;

        // Apply fees
        uint256 feeAmount = (outputAmount * swapFee) / FEE_DENOMINATOR;
        outputAmount -= feeAmount;

        return outputAmount;
    }

    function addLiquidity(uint256[] calldata amounts, uint256 minMintAmount)
        external
        override
        nonReentrant
        returns (uint256)
    {
        require(amounts.length == coins.length, "Invalid amount");

        uint256 D0 = 0;
        uint256[] memory oldBalances = new uint256[](coins.length);

        for (uint256 i = 0; i < coins.length; i++) {
            oldBalances[i] = balances[i];
            D0 += balances[i];
        }

        uint256 totalSupply = token.totalSupply();
        uint256 D1 = D0;

        for (uint256 i = 0; i < coins.length; i++) {
            if (amounts[i] > 0) {
                coins[i].safeTransferFrom(msg.sender, address(this), amounts[i]);
                balances[i] += amounts[i];
                D1 += amounts[i];
            }
        }

        uint256 mintAmount;
        if (totalSupply == 0) {
            mintAmount = D1;
        } else {
            mintAmount = (D1 * totalSupply) / D0;
        }

        require(mintAmount >= minMintAmount, "Insufficient Nexora Tokens");
        token.mint(msg.sender, mintAmount);

        emit AddLiquidity(msg.sender, amounts, mintAmount);
        return mintAmount;
    }

    function removeLiquidity(uint256 tokenAmount, uint256 minAmounts, uint256 deadline)
        external
        override
        returns (uint256[] memory)
    {
        emit NotImplemented();
    }

    function removeLiquidityOneToken(uint256 tokenIndex, uint256 tokenAmount, uint256 minAmount, uint256 deadline)
        external
        override
        returns (uint256)
    {
        emit NotImplemented();
    }

    function stopRampA() external override onlyOwner {
        emit NotImplemented();
    }

    function rampA(uint256 futureA) external view override onlyOwner returns (uint256) {
        uint256 currentTimestamp = block.timestamp;

        if (currentTimestamp < amplificationTimeline) {
            uint256 A0 = amplificationCoefficient;
            uint256 t0 = currentTimestamp;

            if (futureA > A0) {
                return A0 + ((futureA - A0) * (currentTimestamp - t0)) / (amplificationTimeline - t0);
            } else {
                return A0 - ((A0 - futureA) * (currentTimestamp - t0)) / (amplificationTimeline - t0);
            }
        } else {
            return futureA;
        }
    }

    function calculateWithdrawOneCoin(uint256 tokenAmount, uint256 index)
        external
        view
        override
        returns (uint256, uint256)
    {
        emit NotImplemented();
    }

    function validatePrice(address tokenIn, address tokenOut, uint256 price) external view override returns (bool) {
        emit NotImplemented();
    }

    function calculateImbalanceFee() external view override returns (uint256) {
        emit NotImplemented();
    }

    function withdrawAdminFees() external override {
        emit NotImplemented();
    }

    function calculateAdminFee() external view override returns (uint256) {
        emit NotImplemented();
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override {
        emit NotImplemented();
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    function getTokenIndex(address _token) internal view returns (uint256) {
        for (uint256 i = 0; i < coins.length; i++) {
            if (address(coins[i]) == _token) {
                return i;
            }
        }

        revert("Token not found");
    }
}
