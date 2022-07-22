// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "hardhat/console.sol";

// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// import "./interfaces/IProjectExt.sol";
import "../abstract/GameExtension.sol";
import "../interfaces/ICTXEntityUpgradable.sol";
import "../interfaces/IClaim.sol";

/**
 * @title Game Extension: Project Functionality
 */
contract ProjectExt is GameExtension {

    /// Make a new Task
    /// @dev a wrapper function for creation, adding rules, assigning roles & posting
    function taskMake(
        string calldata name_, 
        string calldata uri_
    ) public payable returns (address) {
        //Validate Caller Permissions (Member of Game)
        require(gameRoles().roleHas(_msgSender(), "member"), "Members Only");
        //Create new Claim
        address claimContract = hub().taskMake(name_, uri_);
        //Register New Contract
        _registerNewClaim(claimContract);

        //Create Custom Roles
        ICTXEntityUpgradable(claimContract).roleCreate("applicant");    //Applicants (Can Deliver Results)
        //Fund Task
        if(msg.value > 0){
            // console.log("Moving ETH to New Contract", msg.value);
            // payable(claimContract).transfer(msg.value);
            // bool sent = payable(claimContract).send(msg.value);
            (bool sent, ) = payable(claimContract).call{value: msg.value}("");
            require(sent, "Failed to forward Ether to new contract");
        }

        /*
        //Assign Roles
        for (uint256 i = 0; i < assignRoles.length; ++i) {
            ICTXEntityUpgradable(claimContract).roleAssignToToken(assignRoles[i].tokenId, assignRoles[i].role);
        }
        //Add Rules
        for (uint256 i = 0; i < rules.length; ++i) {
            IClaim(claimContract).ruleRefAdd(rules[i].game, rules[i].ruleId);
        }
        //Post Posts
        for (uint256 i = 0; i < posts.length; ++i) {
            IClaim(claimContract).post(posts[i].entRole, posts[i].tokenId, posts[i].uri);
        }
        */
        //Return new Contract Address
        return claimContract;
    }

    
    /// Register New Claim Contract
    function _registerNewClaim(address claimContract) private {
        //Register Child Contract
        repo().addressAdd("claim", claimContract);
    }

}