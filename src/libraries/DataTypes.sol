// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

interface DataTypes {
    //  Core Structs

    /**
     * @notice Struct to store the band information
     */
    struct BandInfo {
        uint256 startingBandPrice;
        uint256 endPrice;
        uint256 currentBandPrice;
        bool isActive;
    }

    /**
     * @notice Struct to store the user position in the pool
     */
    struct UserPosition {
        int256 startingBand; //Lower Band
        int256 endBand; //Upper Band
        uint256[] shares; //Shares of the user in the pool
    }

    /**
     * @notice Struct to store the trade details
     */
    struct TradeDetails {
        uint256 inputAmount; //Input amount of tokens
        uint256 outputAmount; //Output amount of tokens
        int256 startingBand; //Lower Band
        int256 endBand; //Upper Band
        uint256 executionBand; //Last Band at which the trade was executed
        uint256[] affectedBands; //Array of bands that were touched during the trade
        uint256 feeAmount; //Fee collected from the trade
    }

    /**
     * @notice Struct to store the price information
     */
    struct PriceInfo {
        uint256 oraclePrice; //Current oracle price
        uint256 currentBandPrice; //Price withing current band
        uint256 lastUpdateTime; //Last Price Update
        uint256 deviation; //Deviation from oracle
    }

    /**
     * @notice Struct to store the trade parameters
     */
    struct TradeParams {
        uint256 amountIn; //Input Amount
        uint256 minAmountOut; //Minimum output Amount
        int256 startBand; //Starting band for the trade
        int256 endBand; //Ending band for the trade
        uint256 minShares; //Minimum shares to be received
    }

    /**
     * @notice Struct to store the rate information
     */
    struct RateInfo {
        uint256 interestRate; //Current interest rate
        uint256 rateMultiplier; //Accumulated rate multiplier
        uint256 lastUpdateTime; //Last rate update time
        uint256 targetUtilization; //Target band utilization
    }

    // Enums

    enum TradeDirection {
        STABLE_TO_COLLATERAL,
        COLLATERAL_TO_STABLE
    }
    enum BandStatus {
        EMPTY,
        ACTIVE,
        DEPRECATED
    }
    enum ErrorCodes {
        NO_ERROR,
        INSUFFICIENT_LIQUIDITY,
        PRICE_DEVIATION_TOO_HIGH,
        SLIPPAGE_EXCEEDED,
        INVALID_BAND_RANGE,
        INSUFFICIENT_SHARES
    }

    // Events
    event Trade(
        address indexed trader,
        TradeDirection direction,
        uint256 amountIn,
        uint256 amountOut,
        uint256 fee,
        int256 bandRange
    );

    event LiquidityAdded(
        address indexed provided,
        uint256 stableAmount,
        uint256 collateralAmount,
        int256 startBand,
        int256 endBand,
        uint256 shares
    );

    event LiquidityRemoved(int256 indexed bandIndex, uint256 price, uint256 timestamp);

    event RateUpdated(uint256 newRate, uint256 multiplier, uint256 timestamp, uint256 utilization);

    // Errors
    error InvalidBandRange(int256 lower, int256 upper);
    error InsufficientLiquidity(uint256 required, uint256 available);
    error PriceDeviationTooHigh(uint256 deviation);
    error SlippageExceeded(uint256 expected, uint256 received);
    error InvalidShares(uint256 shares, uint256 minRequired);
    error StaleOracle(uint256 lastUpdate, uint256 threshold);
    error UnauthorizedCallback(address caller);
    error InvalidFeeConfiguration(uint256 tradingFee, uint256 protocolFee);
}
