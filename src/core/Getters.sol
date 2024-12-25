// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {IGetters} from "../Interfaces/IGetters.sol";
import {NexoraPool} from "./NexoraPool.sol";

contract Getters is IGetters, NexoraPool {
    function getCurrentPoolPrice() external view override returns (uint256) {}

    function getCurrentImbalanceFee() external view override returns (uint256) {
        return imbalanceFee;
    }

    function getAmplificationCoefficientValue() external view override returns (uint256) {
        return amplificationCoefficient/amplificationPrecision;
    }

    function getTotalLiquidity() external view override returns (uint256) {}

    function getCurrentTokenSupply() external view override returns (uint256) {
        return token.totalSupply();
    }

    function getCurrentTokenPrice() external view override returns (uint256) {}

    function getOutputTokenAmount(uint256 inputTokenAmount, uint256 inputTokenIndex, uint256 minAmountOut)
        external
        view
        override
        returns (uint256)
    {}

    function getInputTokenAmount(uint256 outputTokenAmount, uint256 outputTokenIndex, uint256 maxAmountIn)
        external
        view
        override
        returns (uint256)
    {}

    function getCurrentSwapFee() external view override returns (uint256) {}
}
