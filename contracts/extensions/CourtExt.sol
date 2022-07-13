// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "hardhat/console.sol";

// import "../public/interfaces/IOpenRepo.sol";
import "./interfaces/ICourtExt.sol";
import "../abstract/GameExtension.sol";
import "../libraries/DataTypes.sol";
import "../interfaces/IReaction.sol";


/**
 * @title Game Extension: Court of Law 
 */
contract CourtExt is ICourtExt, GameExtension {

    //--- Storage

    
    //--- Functions 

    // constructor() { }


    //** Reaction Functions

    /// Make a new Reaction
    /// @dev a wrapper function for creation, adding rules, assigning roles & posting
    function reactionMake(
        string calldata name_, 
        string calldata uri_, 
        DataTypes.RuleRef[] calldata rules, 
        DataTypes.InputRoleToken[] calldata assignRoles, 
        DataTypes.PostInput[] calldata posts
    ) public override returns (address) {
        //Validate Caller Permissions (Member of Game)
        require(gameRoles().roleHas(_msgSender(), "member"), "Members Only");

        // console.log("[DEBUG] CourtExt.reactionMake() Running");
        // console.log("[DEBUG] CourtExt.reactionMake() isMember", gameRoles().roleHas(_msgSender(), "member"));

        //Create new Reaction
        address reactionContract = hub().reactionMake(name_, uri_, rules, assignRoles);
        //Register New Contract
        _registerNewReaction(reactionContract);
        //Posts
        for (uint256 i = 0; i < posts.length; ++i) {
            IReaction(reactionContract).post(posts[i].entRole, posts[i].tokenId, posts[i].uri);
        }
        
        console.log("[DEBUG] CourtExt.reactionMake() Done");

        //Return new Contract Address
        return reactionContract;
    }
    

    /// Make a new Reaction & File it
    /// @dev a wrapper function for creation, adding rules, assigning roles, posting & filing a reaction
    function reactionMakeOpen(
        string calldata name_, 
        string calldata uri_, 
        DataTypes.RuleRef[] calldata rules, 
        DataTypes.InputRoleToken[] calldata assignRoles, 
        DataTypes.PostInput[] calldata posts
    ) public override returns (address) {
        //Validate Caller Permissions (Member of Game)
        require(gameRoles().roleHas(_msgSender(), "member"), "Members Only");

        console.log("[DEBUG] CourtExt.reactionMakeOpen() Running");

        //Create new Reaction
        address reactionContract = reactionMake(name_, uri_, rules, assignRoles, posts);
        //File Reaction
        IReaction(reactionContract).stageFile();

        console.log("[DEBUG] CourtExt.reactionMakeOpen() Done");

        //Return new Contract Address
        return reactionContract;
    }

    /// Make a new Reaction, File it & Close it
    /// @dev a wrapper function for creation, adding rules, assigning roles, posting & filing a reaction
    function reactionMakeClosed(
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
        //Create new Reaction
        // address reactionContract = reactionMake(name_, uri_, rules, assignRoles, posts);
        //Make Reaction & Open
        address reactionContract = reactionMakeOpen(name_, uri_, rules, assignRoles, posts);
        //File Reaction
        // IReaction(reactionContract).stageFile();
        //Push Forward
        IReaction(reactionContract).stageWaitForVerdict();
        //Close Reaction
        IReaction(reactionContract).stageVerdict(verdict, decisionURI_);
        //Return
        return reactionContract;
    }

    /// Register New Reaction Contract
    function _registerNewReaction(address reactionContract) private {

        //Register Child Contract
        repo().addressAdd("reaction", reactionContract);

        //New Reaction Created Event
        // emit ReactionCreated(reactionId, reactionContract);  //CANCELLED
    }
}
