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
 */
abstract contract Escrow is IEscrow
    // , Context
    // , ContextUpgradeable 
    {

    //--- Events

    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    //--- Storage

    //--- Functions



    /**
     * Inspiration: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/finance/PaymentSplitter.sol
     * 

    event PayeeAdded(address account, uint256 shares);

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    mapping(IERC20 => uint256) private _erc20TotalReleased;
    mapping(IERC20 => mapping(address => uint256)) private _erc20Released;

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     * /
    constructor() payable {

    }
    
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

    /**
     * @dev Getter for the amount of shares held by an account.
     * /
    function shares(address account) public virtual pure returns (uint256) {
        // return _shares[account];
        return 1;
    }
    
    /**
     * @dev Getter for the total shares held by payees.
     * /
    function totalShares() public virtual view returns (uint256) {
        // return _totalShares;
    }

    
    /**
     * @dev Getter for the total amount of Ether already released.
     * /
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
     * contract.
     * /
    function totalReleased(IERC20 token) public view returns (uint256) {
        return _erc20TotalReleased[token];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     * /
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an
     * IERC20 contract.
     * /
    function released(IERC20 token, address account) public view returns (uint256) {
        return _erc20Released[token][account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     * /
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }
 
    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     * /
    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return (totalReceived * shares(account)) / totalShares() - alreadyReleased;
    }

    /**
     * @dev Getter for the amount of payee's releasable Ether.
     * /
    function releasable(address account) public view returns (uint256) {
        // uint256 totalReceived = address(this).balance + totalReleased();
        // return _pendingPayment(account, totalReceived, released(account));
        //Always Release Everything
        return _pendingPayment(account, contractBalance(address(0)), 0);
    }

    /**
     * @dev Getter for the amount of payee's releasable `token` tokens. `token` should be the address of an
     * IERC20 contract.
     * /
    function releasable(address token, address account) public view returns (uint256) {
        // uint256 totalReceived = token.balanceOf(address(this)) + totalReleased(token);
        // return _pendingPayment(account, totalReceived, released(token, account));
        //Always Release Everything
        // uint256 totalReceived = token.balanceOf(address(this));
        return _pendingPayment(account, contractBalance(token), 0);
    }


    /* END OF COPIED FUNC */

}
