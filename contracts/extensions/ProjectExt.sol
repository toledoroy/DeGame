// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "hardhat/console.sol";

// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// import "./interfaces/IProjectExt.sol";
import "../abstract/GameExtension.sol";
import "../interfaces/ICTXEntityUpgradable.sol";
import "../interfaces/ITask.sol";

/**
 * @title Game Extension: Project Functionality
 */
contract ProjectExt is GameExtension {

    /// Make a new Task
    /// @dev a wrapper function for creation, adding rules, assigning roles & posting
    function taskMake(
        string calldata type_, 
        string calldata name_, 
        string calldata uri_
    ) public payable returns (address) {
        //Validate Caller Permissions (Member of Game)
        require(gameRoles().roleHas(_msgSender(), "member"), "Members Only");
        //Create new Claim
        address newContract = hub().taskMake(type_, name_, uri_);
        //Register New Contract
        _registerNewClaim(newContract);
        //Create Custom Roles
        ICTXEntityUpgradable(newContract).roleCreate("applicant");    //Applicants (Can Deliver Results)
        //Fund Task
        if(msg.value > 0){
            // console.log("Moving ETH to New Contract", msg.value);
            // payable(newContract).transfer(msg.value);
            // bool sent = payable(newContract).send(msg.value);
            (bool sent, ) = payable(newContract).call{value: msg.value}("");
            require(sent, "Failed to forward Ether to new contract");
        }
        //Open by default
        ITask(newContract).stageOpen();
        //Return new Contract Address
        return newContract;
    }

    /// Register New Claim Contract
    function _registerNewClaim(address claimContract) private {
        //Register Child Contract
        repo().addressAdd("claim", claimContract);
    }

}