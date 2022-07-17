// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

// import "hardhat/console.sol";

import "./interfaces/ICourtExt.sol";
import "../abstract/GameExtension.sol";
import "../libraries/DataTypes.sol";
import "../interfaces/IClaim.sol";

/**
 * @title Game Extension: Court of Law 
 */
contract CourtExt is ICourtExt, GameExtension {

    /// Make a new Case
    /// @dev a wrapper function for creation, adding rules, assigning roles & posting
    function caseMake(
        string calldata name_, 
        string calldata uri_, 
        DataTypes.RuleRef[] calldata rules, 
        DataTypes.InputRoleToken[] calldata assignRoles, 
        DataTypes.PostInput[] calldata posts
    ) public override returns (address) {
        //Validate Caller Permissions (Member of Game)
        require(gameRoles().roleHas(_msgSender(), "member"), "Members Only");
        //Create new Claim
        address claimContract = hub().claimMake(name_, uri_, rules, assignRoles);
        //Register New Contract
        _registerNewClaim(claimContract);
        //Posts
        for (uint256 i = 0; i < posts.length; ++i) {
            IClaim(claimContract).post(posts[i].entRole, posts[i].tokenId, posts[i].uri);
        }
        //Return new Contract Address
        return claimContract;
    }

    /// Make a new Case & File it
    /// @dev a wrapper function for creation, adding rules, assigning roles, posting & filing a claim
    function caseMakeOpen(
        string calldata name_, 
        string calldata uri_, 
        DataTypes.RuleRef[] calldata rules, 
        DataTypes.InputRoleToken[] calldata assignRoles, 
        DataTypes.PostInput[] calldata posts
    ) public override returns (address) {
        //Validate Caller Permissions (Member of Game)
        require(gameRoles().roleHas(_msgSender(), "member"), "Members Only");
        //Create new Claim
        address claimContract = caseMake(name_, uri_, rules, assignRoles, posts);
        //File Claim
        IClaim(claimContract).stageFile();
        //Return new Contract Address
        return claimContract;
    }

    /// Make a new Case, File it & Close it
    /// @dev a wrapper function for creation, adding rules, assigning roles, posting & filing a claim
    function caseMakeClosed(
        string calldata name_, 
        string calldata uri_, 
        DataTypes.RuleRef[] calldata rules, 
        DataTypes.InputRoleToken[] calldata assignRoles, 
        DataTypes.PostInput[] calldata posts,
        string calldata decisionURI_
    ) public override returns (address) {
        //Validate Role
        require(gameRoles().roleHas(_msgSender(), "authority") , "ROLE:AUTHORITY_ONLY");
        //Generate A Decision -- Yes to All
        DataTypes.InputDecision[] memory verdict = new DataTypes.InputDecision[](rules.length);
        for (uint256 i = 0; i < rules.length; ++i) {
            verdict[i].ruleId = i+1;
            verdict[i].decision = true;
        }
        //Create new Claim
        // address claimContract = caseMake(name_, uri_, rules, assignRoles, posts);
        //Make Claim & Open
        address claimContract = caseMakeOpen(name_, uri_, rules, assignRoles, posts);
        //File Claim
        // IClaim(claimContract).stageFile();
        //Push Forward
        IClaim(claimContract).stageWaitForVerdict();
        //Close Claim
        IClaim(claimContract).stageVerdict(verdict, decisionURI_);
        //Return
        return claimContract;
    }

    /// Register New Claim Contract
    function _registerNewClaim(address claimContract) private {
        //Register Child Contract
        repo().addressAdd("claim", claimContract);
        //New Claim Created Event
        // emit ClaimCreated(claimId, claimContract);  //CANCELLED
    }
}
