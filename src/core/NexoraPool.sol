// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.26;

import {INexoraPool} from "../Interfaces/INexoraPool.sol";
import {ISetters} from "../Interfaces/ISetters.sol";
import {IGetters} from "../Interfaces/IGetters.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {NexoraToken} from "./NexoraToken.sol";

contract NexoraPool is INexoraPool, Ownable {
    NexoraToken public immutable token;

    uint256 public immutable amplificationCoefficient;
    uint256 public immutable swapFee;
    uint256 public immutable adminFee;
    uint256 public imbalanceFee;
    uint256 public amplificationTimeline = 24 hours;
    uint256 public amplificationPrecision = 100;

    constructor() Ownable(msg.sender) {}

    function swap(uint256 tokenIndexFrom, uint256 tokenIndexTo, uint256 dx, uint256 minDy, uint256 deadline)
        external
        override
    {}

    function calculateSwap(uint256 tokenIndexFrom, uint256 tokenIndexTo, uint256 dx)
        external
        view
        override
        returns (uint256)
    {}

    function addLiquidity(uint256[] calldata amount, uint256 minMintAmount) external override returns (uint256) {}

    function removeLiquidity(uint256 tokenAmount, uint256 minAmounts, uint256 deadline)
        external
        override
        returns (uint256[] memory)
    {}

    function removeLiquidityOneToken(uint256 tokenIndex, uint256 tokenAmount, uint256 minAmount, uint256 deadline)
        external
        override
        returns (uint256)
    {}

    function stopRampA() external override onlyOwner {}

    function rampA(uint256 futureA) external view override onlyOwner returns (uint256) {
        uint256 currentTimestamp = block.timestamp;

        if (currentTimestamp < amplificationTimeline) {
            uint256 A0 = amplificationCoefficient;
            uint256 t0 = currentTimestamp;

            if (futureA > A0) {
                return A0 + (futureA - A0) * (currentTimestamp - t0) / (amplificationTimeline - t0);
            } else {
                return A0 - (A0 - futureA) * (currentTimestamp - t0) / (amplificationTimeline - t0);
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
    {}

    function validatePrice(address tokenIn, address tokenOut, uint256 price) external view override returns (bool) {}

    function calculateImbalanceFee() external view override returns (uint256) {}

    function withdrawAdminFees() external override {}

    function calculateAdminFee() external view override returns (uint256) {}
}
