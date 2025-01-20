// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.26;

// ░▒█▄░▒█░▒█▀▀▀░▀▄░▄▀░▒█▀▀▀█░▒█▀▀▄░█▀▀▄░░░▒█▀▀▀█░▒█░░▒█░█▀▀▄░▒█▀▀█
// ░▒█▒█▒█░▒█▀▀▀░░▒█░░░▒█░░▒█░▒█▄▄▀▒█▄▄█░░░░▀▀▀▄▄░▒█▒█▒█▒█▄▄█░▒█▄▄█
// ░▒█░░▀█░▒█▄▄▄░▄▀▒▀▄░▒█▄▄▄█░▒█░▒█▒█░▒█░░░▒█▄▄▄█░▒▀▄▀▄▀▒█░▒█░▒█░░░

/**
 * @title INexoraSwapPool
 * @author AllenOps08
 * @notice Interface for the NexoraSwapPool
 */
interface INexoraPool {
    // Events

    event TokenSwap(
        address indexed buyer, uint256 tokenIndexFrom, uint256 tokenIndexTo, uint256 tokensSold, uint256 tokensBought
    );

    event AddLiquidity(
        address indexed provider, uint256[] tokenAmounts, uint256[] fees, uint256 invariant, uint256 lpTokenSupply
    );

    event RemoveLiquidity(address indexed provider, uint256[] tokenAmounts, uint256 tokenAmount);

    event RampA(uint256 oldA, uint256 newA, uint256 initialTime, uint256 futureTime);

    event StopRampA(uint256 currentA, uint256 time);

    event Fees(uint256 swapFee, uint256 adminFee);

    // Errors

    error DeadlineExpired();
    error SlippageTooHigh();
    error PoolNotInitialized();
    error PoolUnbalanced();
    error InvalidTokenIndex();
    error InsufficientBalance();
    error InsufficientLiquidity();
    error InvalidParameter();
    error ZeroValueError();
    error ZeroAddressError();
    error RampAInProgress();
    error RampAAlreadyStopped();
    error InvalidRampA();

    // Structs

    struct PoolState {
        uint256 amplificationCoefficient;
        uint256[] balances;
        uint256 lpTotalSupply;
        uint256 adminFee;
        uint256 swapFee;
        uint256 rampCooldownDuration;
        uint256 rampStartTime;
        uint256 futureA;
    }

    // Functions

    function swap(uint256 tokenIndexFrom, uint256 tokenIndexTo, uint256 dx, uint256 minDy, uint256 deadline)
        external
        returns (uint256);
    function calculateSwap(uint256 tokenIndexFrom, uint256 tokenIndexTo, uint256 dx) external view returns (uint256);
    function addLiquidity(uint256[] calldata amount, uint256 minMintAmount) external returns (uint256);

    function removeLiquidity(uint256 lpAmount, uint256 minAmounts, uint256 deadline)
        external
        returns (uint256[] memory);
    function removeLiquidityOneToken(uint256 tokenIndex, uint256 lpAmount, uint256 minAmount, uint256 deadline)
        external
        returns (uint256);
    function stopRampA() external;
    function rampA(uint256 futureA) external returns (uint256);
    // Returns amount of coin to withdraw after fees, fee amount deducted , total amount of lp tokens.
    function calculateWithdrawOneCoin(uint256 tokenAmount, uint256 index) external view returns (uint256, uint256);

    function validatePrice(address tokenIn, address tokenOut, uint256 price) external view returns (bool);
    function calculateImbalanceFee() external view returns (uint256);

    function withdrawAdminFees() external;
    function calculateAdminFee() external view returns (uint256);
}
