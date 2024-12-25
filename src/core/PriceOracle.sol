// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import "@chainlink/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "@chainlink/v0.8/vrf/testhelpers/VRFConsumerV2.sol";
import "@chainlink/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {UD60x18, ud} from "@prb/math/UD60x18.sol";
import {exp} from "@prb/math/sd59x18/Math.sol";
import {SD59x18, sd} from "@prb/math/SD59x18.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title PriceOracle
 */
contract PriceOracle is VRFConsumerBaseV2, Ownable {
    // Chainlink Price Feed
    AggregatorV3Interface public priceFeed;

    bool public initialized;

    // Price Tracking
    uint256 public lastPrice;
    uint256 public lastTimestamp;
    uint256 public constant MIN_EMA_PERIOD = 30;
    uint256 public constant MAX_EMA_PERIOD = 365 * 86400;
    uint256 public immutable EMA_EXPTime;

    // Chainlink VRF Parameters
    VRFCoordinatorV2Interface public vrfCoordinator;
    bytes32 public keyHash;
    uint64 public subscriptionId;
    uint32 public callbackGasLimit = 100000;
    uint16 public constant REQUEST_CONFIRMATIONS = 3;

    //Price Validation
    uint256 public maxPriceDeviation = 10;
    uint256 public lastVerifiedPrice;
    uint256 public lastRequestId;

    // Events
    event PriceUpdated(uint256 newPrice, uint256 timestamp);
    event PriceValidationRequested(uint256 requestId);
    event PriceValidated(uint256 price, bool isValid);
    event CallbackGasLimitUpdated(uint32 newGasLimit);
    event MaxPriceDeviationUpdated(uint256 maxPriceDevivation);
    /**
     * Constructor for the PriceOracle contract
     * @param _emaExpTime The time period for the EMA decay
     * @param _priceFeed The address of the price feed
     * @param _vrfCoordinator The address of the VRF coordinator
     * @param _subId The subscription id
     * @param _keyHash The key hash
     */

    constructor(uint256 _emaExpTime, address _priceFeed, address _vrfCoordinator, uint64 _subId, bytes32 _keyHash)
        VRFConsumerBaseV2(_vrfCoordinator)
        Ownable(msg.sender)
    {
        require(!initialized, "Already initialized");
        require(_emaExpTime >= MIN_EMA_PERIOD && _emaExpTime <= MAX_EMA_PERIOD, "Invalid EMA Timestamp");
        priceFeed = AggregatorV3Interface(_priceFeed);
        keyHash = _keyHash;
        subscriptionId = _subId;
        EMA_EXPTime = _emaExpTime;

        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        lastTimestamp = block.timestamp;
        lastPrice = getLatestPrice();
        lastVerifiedPrice = lastPrice;
        initialized = true;
    }

    /**
     * @notice Get the latest price from the price feed
     * @return The latest price
     */
    function getLatestPrice() public view returns (uint256) {
        (, int256 price,,,) = priceFeed.latestRoundData();

        require(price > 0, "Invalid Price");
        return uint256(price);
    }

    /**
     * @notice Calculating the EMA price based on the chainlink price feed and the last price
     * @return The EMA price
     */
    function calculateEMAPrice() public view returns (uint256) {
        uint256 PRECISION = 1e18;
        uint256 currentPrice = getLatestPrice();
        uint256 timeDelta = block.timestamp - lastTimestamp;

        require(timeDelta > 0, "Time delta cannot be zero");
        uint256 alpha = calculateDecayFactor(timeDelta);
        return (currentPrice * (PRECISION - alpha) + lastPrice * alpha) / PRECISION;
    }

    /**
     * @notice Calculating the decay factor based on the time delta
     * @param timeDelta The time delta
     * @return The decay factor
     */
    function calculateDecayFactor(uint256 timeDelta) public view returns (uint256) {
        return _calculateDecayFactor(timeDelta);
    }

    function _calculateDecayFactor(uint256 timeDelta) internal view returns (uint256) {
        SD59x18 decayTime = sd(int256((timeDelta * 1e18) / EMA_EXPTime) * -1);
        return uint256(exp(decayTime).unwrap());
    }

    /**
     * @notice Requesting the price validation from the VRF service
     * @return requestId the request id
     */
    function requestPriceValidation() external returns (uint256 requestId) {
        requestId =
            vrfCoordinator.requestRandomWords(keyHash, subscriptionId, REQUEST_CONFIRMATIONS, callbackGasLimit, 1);

        lastRequestId = requestId;

        emit PriceValidationRequested(requestId);
    }

    /**
     * @param requestId RequestId fulfilling the requestId
     */
    function _fulfillRandomWords(uint256 requestId) external {
        fulfillRandomWords(requestId, new uint256[](0));
    }

    /**
     * @notice Handles the VRF callback, processing the random words returned by the Chainlink VRF service
     * @notice request Price Validation must be called before this function
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory) internal virtual override {
        require(requestId == lastRequestId, "Invalid request ID");
        uint256 currentPrice = getLatestPrice();
        bool isPriceValid = isPriceWithinDeviation(currentPrice, lastVerifiedPrice);

        if (isPriceValid) {
            lastVerifiedPrice = currentPrice;
        }

        emit PriceValidated(currentPrice, isPriceValid);
    }

    /**
     * @notice Checking the the new price deviation is within an acceptable deviation from the last verified price deviation
     * @param newPrice The new price
     * @param basePrice The base price
     */
    function isPriceWithinDeviation(uint256 newPrice, uint256 basePrice) public view returns (bool) {
        uint256 deviation = calculatePriceDeviation(newPrice, basePrice);
        return deviation <= maxPriceDeviation;
    }

    /**
     * @notice Calculating the percentage price deviation between the new price and the base price
     * @param newPrice The new price
     * @param basePrice The base price
     * @return The price deviation
     */
    function calculatePriceDeviation(uint256 newPrice, uint256 basePrice) public pure returns (uint256) {
        return ((newPrice > basePrice ? newPrice - basePrice : basePrice - newPrice) * 100) / basePrice;
    }

    /**
     * @notice Updating the callback gas limit
     * @param _gasLimit The new gas limit
     */
    function updateCallbackGasLimit(uint32 _gasLimit) external onlyOwner {
        callbackGasLimit = _gasLimit;
        emit CallbackGasLimitUpdated(callbackGasLimit);
    }

    /**
     * @notice Updating the max price deviation
     * @param _maxPriceDeviation The new maximum price deviation
     */
    function updateMaxPriceDeviation(uint256 _maxPriceDeviation) external onlyOwner {
        require(_maxPriceDeviation > 0, "Max price deviation cannot be zero");
        require(_maxPriceDeviation <= 10, "Max price deviation cannot be greater than 10");
        maxPriceDeviation = _maxPriceDeviation;
        emit MaxPriceDeviationUpdated(maxPriceDeviation);
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    function getLastPrice() external view returns (uint256) {
        return lastPrice;
    }
}
