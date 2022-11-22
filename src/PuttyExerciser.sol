// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import './interfaces/IFlashLoanSimpleReceiver.sol';
import './interfaces/ILendingPool.sol';
import './interfaces/ILendingPoolAddressesProvider.sol';
import './interfaces/IPuttyV2.sol';
import './interfaces/IWETH.sol';

contract PuttyExerciser is IFlashLoanSimpleReceiver {
    /// @notice Lending pool that supports flashloans
    ILendingPool public immutable lendingPool;
    /// @notice Putty contract to exercise options
    IPuttyV2 public immutable putty;
    IWETH public immutable weth;

    error InsufficientBalance();
    error InvalidSender();

    modifier onlyLendingPool() {
        if (msg.sender != address(lendingPool)) {
            revert InvalidSender();
        }
        _;
    }

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
     * @notice Request a flashloan to be executed
     * @param asset Asset to borrow
     * @param amount Amount to borrow
     * @param sudoPool Sudo pool to swap assets
     */
    function exercise(address asset, uint256 amount, address sudoPool) external {
        lendingPool.flashLoanSimple(
            address(this), // receiving address
            asset,
            amount,
            abi.encode(sudoPool), // params
            0 // referal code
        );
    }

    /**
     * @notice This function is called after our contract has received the flash loaned amount
     * @param asset The address of the flash-borrowed asset
     * @param amount The amount of the flash-borrowed asset
     * @param premium The fee of the flash-borrowed asset
     * @param initiator The address of the flashloan initiator
     * @param params The byte-encoded params passed when initiating the flashloan
     */
    function executeOperation(address asset, uint256 amount, uint256 premium, address initiator, bytes calldata params)
        external
        override
        onlyLendingPool
        returns (bool)
    {
        // TODO: Probably can be removed
        if (initiator != address(this)) {
            revert InvalidSender();
        }

        // Decode parameters provided by the lending pool
        (address sudoPool) = abi.decode(params, (address));

        // TODO: Logic
        // 1. If the asset to be borrowed is WETH then
        // approve Putty + premium in WETH
        // 2.

        uint256 amountOut;

        // At the end of our logic above, we owe the flashloaned amounts + premiums.
        // Therefore we need to ensure we have enough to repay these amounts.
        uint256 amountOwing = amount + premium;
        // It is assumed here that the client that constructs the path is trusted
        // and has done the construction properly, otherwise we may get rekt.
        if (amountOwing > amountOut) {
            revert InsufficientBalance();
        }

        return true;
    }
}
