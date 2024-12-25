// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {INexoraToken} from "../Interfaces/INexoraToken.sol";

// ░▒█▄░▒█░▒█▀▀▀░▀▄░▄▀░▒█▀▀▀█░▒█▀▀▄░█▀▀▄░░░▒█▀▀▀█░▒█░░▒█░█▀▀▄░▒█▀▀█
// ░▒█▒█▒█░▒█▀▀▀░░▒█░░░▒█░░▒█░▒█▄▄▀▒█▄▄█░░░░▀▀▀▄▄░▒█▒█▒█▒█▄▄█░▒█▄▄█
// ░▒█░░▀█░▒█▄▄▄░▄▀▒▀▄░▒█▄▄▄█░▒█░▒█▒█░▒█░░░▒█▄▄▄█░▒▀▄▀▄▀▒█░▒█░▒█░░░

/**
 * @title INexoraToken
 * @author AllenOps08
 * @notice The official NexoraToken
 */
abstract contract NexoraToken is INexoraToken {
    mapping(address => uint256) private _balances;
    uint256 private _totalSupply;
    uint8 private _decimals = 18;

    function mint(address to, uint256 amount) external override {
        require(to != address(0), "Cannot transfer to a zero address");
        require(amount > 0, "Cannot mint 0 tokens");
        _totalSupply += amount;
        _balances[to] += amount;
    }

    function burn(uint256 amount) external override {
        _totalSupply -= amount;
        _balances[msg.sender] -= amount;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(sender != address(0), "Invalid sender address");
        require(recipient != address(0), "Invalid recipient address");
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        return true;
    }
}
