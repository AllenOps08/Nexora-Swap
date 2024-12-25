// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.26;

// ░▒█▄░▒█░▒█▀▀▀░▀▄░▄▀░▒█▀▀▀█░▒█▀▀▄░█▀▀▄░░░▒█▀▀▀█░▒█░░▒█░█▀▀▄░▒█▀▀█
// ░▒█▒█▒█░▒█▀▀▀░░▒█░░░▒█░░▒█░▒█▄▄▀▒█▄▄█░░░░▀▀▀▄▄░▒█▒█▒█▒█▄▄█░▒█▄▄█
// ░▒█░░▀█░▒█▄▄▄░▄▀▒▀▄░▒█▄▄▄█░▒█░▒█▒█░▒█░░░▒█▄▄▄█░▒▀▄▀▄▀▒█░▒█░▒█░░░

interface ISetters {
    function setFee(uint256 fee) external;
    function setAmplificationCoefficient(uint256 amplificationCoefficient) external;
    function setSwapFee(uint256 swapFee) external;
    function setAdminFee(uint256 adminFee) external;
}
