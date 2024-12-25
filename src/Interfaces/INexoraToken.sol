// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// ░▒█▄░▒█░▒█▀▀▀░▀▄░▄▀░▒█▀▀▀█░▒█▀▀▄░█▀▀▄░░░▒█▀▀▀█░▒█░░▒█░█▀▀▄░▒█▀▀█
// ░▒█▒█▒█░▒█▀▀▀░░▒█░░░▒█░░▒█░▒█▄▄▀▒█▄▄█░░░░▀▀▀▄▄░▒█▒█▒█▒█▄▄█░▒█▄▄█
// ░▒█░░▀█░▒█▄▄▄░▄▀▒▀▄░▒█▄▄▄█░▒█░▒█▒█░▒█░░░▒█▄▄▄█░▒▀▄▀▄▀▒█░▒█░▒█░░░

/**
 * @title INexoraToken
 * @author AllenOps08
 * @notice Interface for the Nexora Token
 */
interface INexoraToken is IERC20 {
    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external;
    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}
