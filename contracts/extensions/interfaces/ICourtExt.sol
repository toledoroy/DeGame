// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../../libraries/DataTypes.sol";

interface ICourtExt {
    
    //--- Events

    //--- Functions
    
    /// Make a new Reaction
    /// @dev a wrapper function for creation, adding rules, assigning roles & posting
    function reactionMake(
        string calldata name_, 
        string calldata uri_, 
        DataTypes.RuleRef[] calldata rules, 
        DataTypes.InputRoleToken[] calldata assignRoles, 
        DataTypes.PostInput[] calldata posts
    ) external returns (address);

    /// Make a new Reaction & File it
    /// @dev a wrapper function for creation, adding rules, assigning roles, posting & filing a reaction
    function reactionMakeOpen(
        string calldata name_, 
        string calldata uri_, 
        DataTypes.RuleRef[] calldata rules, 
        DataTypes.InputRoleToken[] calldata assignRoles, 
        DataTypes.PostInput[] calldata posts
    ) external returns (address);

    /// Make a new Reaction, File it & Close it
    /// @dev a wrapper function for creation, adding rules, assigning roles, posting & filing a reaction
    function reactionMakeClosed(
        string calldata name_, 
        string calldata uri_, 
        DataTypes.RuleRef[] calldata rules, 
        DataTypes.InputRoleToken[] calldata assignRoles, 
        DataTypes.PostInput[] calldata posts,
        string calldata decisionURI_
    ) external returns (address);

}