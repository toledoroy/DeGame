//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

// import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
// import "@openzeppelin/contracts/utils/Context.sol";
// import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "../interfaces/IEscrow.sol";

/**
 * @title Basic Escrow & Splits Functionality for Contracts 
 * @dev Inherit this to add basic reception and sending functionality
 * Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/finance/PaymentSplitter.sol
 */
abstract contract Escrow is IEscrow {

    //--- Events

    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    //--- Storage

    //--- Functions

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        // emit PaymentReceived(_msgSender(), msg.value);   //Sometimes this is inherited by an upgradable contract and sometimes a regular contract
        emit PaymentReceived(msg.sender, msg.value);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function _release(address payable account, uint256 payment) internal {
        require(payment > 0, "ESCROW:NOTHING_TO_RELEASE");
        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function _releaseToken(address token, address account, uint256 payment) internal {
        require(payment > 0, "ESCROW:NOTHING_TO_RELEASE");
        SafeERC20.safeTransfer(IERC20(token), account, payment);
        emit ERC20PaymentReleased(IERC20(token), account, payment);
    }

    //-- Views
   
    /// Get the balance of this contract by Token address. Use 0 address for native tokens
    function contractBalance(address token) public view returns (uint256) {
        if(address(0) == token){
            return address(this).balance;
        }else{
            return IERC20(token).balanceOf(address(this));
        }
    }

}
