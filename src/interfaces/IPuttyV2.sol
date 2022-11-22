//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Order} from '../lib/Order.sol';

interface IPuttyV2 {
    function exercise(Order memory order, uint256[] calldata floorAssetTokenIds) external payable;
}
