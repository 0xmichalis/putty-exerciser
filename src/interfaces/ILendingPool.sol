//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ILendingPool {
    function flashLoanSimple(
        address receiverAddress,
        address asset,
        uint256 amount,
        bytes calldata params,
        uint16 referralCode
    ) external;
}
