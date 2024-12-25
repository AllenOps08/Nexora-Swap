// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.26;

// ░▒█▄░▒█░▒█▀▀▀░▀▄░▄▀░▒█▀▀▀█░▒█▀▀▄░█▀▀▄░░░▒█▀▀▀█░▒█░░▒█░█▀▀▄░▒█▀▀█
// ░▒█▒█▒█░▒█▀▀▀░░▒█░░░▒█░░▒█░▒█▄▄▀▒█▄▄█░░░░▀▀▀▄▄░▒█▒█▒█▒█▄▄█░▒█▄▄█
// ░▒█░░▀█░▒█▄▄▄░▄▀▒▀▄░▒█▄▄▄█░▒█░▒█▒█░▒█░░░▒█▄▄▄█░▒▀▄▀▄▀▒█░▒█░▒█░░░

/**
 * @title IGetters
 * @author AllenOps08
 * @notice Interface for the Getter functions
 */
interface IGetters {
    function getCurrentPoolPrice() external view returns (uint256);
    function getCurrentImbalanceFee() external view returns (uint256);
    function getAmplificationCoefficientValue() external view returns (uint256);

    function getTotalLiquidity() external view returns (uint256);
    function getCurrentTokenSupply() external view returns (uint256);
    function getCurrentTokenPrice() external view returns (uint256);

    function getOutputTokenAmount(uint256 inputTokenAmount, uint256 inputTokenIndex, uint256 minAmountOut)
        external
        view
        returns (uint256);
    function getInputTokenAmount(uint256 outputTokenAmount, uint256 outputTokenIndex, uint256 maxAmountIn)
        external
        view
        returns (uint256);

    function getCurrentSwapFee() external view returns (uint256);
}
