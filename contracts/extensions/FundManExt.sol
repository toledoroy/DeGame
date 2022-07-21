// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

// import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/IFundManExt.sol";
import "../abstract/GameExtension.sol";
import "../abstract/Escrow.sol";

/**
 * @title Game Extension: Escrow Capabilities (Receive and Send funds)
 */
contract FundManExt is IFundManExt, GameExtension, Escrow {

    /// Disburse Token to SBT Holders
    function _disburse(address token, uint256 amount) internal {
        //Validate Amount
        require(amount > 0, "NOTHING_TO_DISBURSE");
        //Get Subject(s)
        uint256[] memory sbts = gameRoles().uniqueRoleMembers("subject");
        //Send Funds
        for (uint256 i = 0; i < sbts.length; i++) {
            if(token == address(0)){
                //Disburse Native Token
                _release(payable(IERC721(getSoulAddr()).ownerOf(sbts[i])), amount);
            }else{
                //Disburse ERC20 Token
                _releaseToken(token, IERC721(getSoulAddr()).ownerOf(sbts[i]), amount);
            }
        }
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
    // receive() external payable virtual {
        // emit PaymentReceived(_msgSender(), msg.value);   //Sometimes this is inherited by an upgradable contract and sometimes a regular contract
        // emit PaymentReceived(msg.sender, msg.value);
    // }

}