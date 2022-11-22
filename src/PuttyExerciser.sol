// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import './interfaces/IFlashLoanSimpleReceiver.sol';
import './interfaces/ILendingPool.sol';
import './interfaces/ILendingPoolAddressesProvider.sol';
import './interfaces/ILSSVMPair.sol';
import './interfaces/IPuttyV2.sol';
import './interfaces/IWETH.sol';
import {Order} from './lib/Order.sol';

/// @notice PuttyExerciser automates exercising Putty call
/// options without the need to have any capital available
/// to pay the option premium.
contract PuttyExerciser is IFlashLoanSimpleReceiver {
    // ----------------------------------------
    //                STORAGE
    // ----------------------------------------

    /// @notice Lending pool that supports flashloans
    ILendingPool public immutable lendingPool;
    /// @notice Putty contract to exercise options
    IPuttyV2 public immutable putty;
    IWETH public immutable weth;

    // ----------------------------------------
    //              CONSTRUCTOR
    // ----------------------------------------

    constructor(address _provider, address _putty, address _weth) payable {
        require(_provider != address(0), '!_provider');
        require(_putty != address(0), '!_putty');
        require(_weth != address(0), '!_weth');

        lendingPool = ILendingPool(ILendingPoolAddressesProvider(_provider).getLendingPool());
        putty = IPuttyV2(_putty);
        weth = IWETH(_weth);
        IWETH(_weth).approve(_putty, type(uint256).max);
    }

    // ----------------------------------------
    //                 LOGIC
    // ----------------------------------------

    /**
     * @notice Exercise a Putty option via a flashloan
     * @param order Putty order to exercise
     * @param sudoPool Sudo pool to swap assets
     */
    function exercise(Order calldata order, address sudoPool) external {
        lendingPool.flashLoanSimple(
            address(this), // receiving address
            order.baseAsset,
            order.strike,
            abi.encode(order, sudoPool), // params
            0 // referal code
        );
    }

    /**
     * @notice This function is called after our contract has received the flash loaned amount
     * @param amount The amount of the flash-borrowed asset
     * @param premium The fee of the flash-borrowed asset
     * @param initiator The address of the flashloan initiator
     * @param params The byte-encoded params passed when initiating the flashloan
     */
    function executeOperation(
        address, /* asset */
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        // Decode parameters provided by the lending pool
        (Order memory order, address sudoPool) = abi.decode(params, (Order, address));

        // Exercise option in Putty
        putty.exercise(order, new uint[](0));

        // Prepare NFT ids to swap
        uint256 nftCount = order.erc721Assets.length;
        uint256[] memory nftIds = new uint[](nftCount);
        for (uint256 i = 0; i < nftCount; i++) {
            nftIds[i] = order.erc721Assets[i].tokenId;
        }

        // At the end of our logic, we owe the flashloaned amount + premium.
        // Therefore we need to ensure we have enough to repay this amount.
        uint256 amountOwing = amount + premium;

        // Swap received NFT in Sudo - assuming there is a single
        // NFT asset per option so we just use a single pool.
        ILSSVMPair(sudoPool).swapNFTsForToken(nftIds, amountOwing, payable(initiator), false, address(0));

        return true;
    }
}
