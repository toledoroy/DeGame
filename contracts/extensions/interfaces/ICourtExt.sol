// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../../libraries/DataTypes.sol";

interface ICourtExt {
    
    //--- Events

    //--- Functions
    
    /// Make a new Claim
    /// @dev a wrapper function for creation, adding rules, assigning roles & posting
    function caseMake(
        string calldata name_, 
        string calldata uri_, 
        DataTypes.RuleRef[] calldata rules, 
        DataTypes.InputRoleToken[] calldata assignRoles, 
        DataTypes.PostInput[] calldata posts
    ) external returns (address);

    /// Make a new Claim & File it
    /// @dev a wrapper function for creation, adding rules, assigning roles, posting & filing a claim
    function caseMakeOpen(
        string calldata name_, 
        string calldata uri_, 
        DataTypes.RuleRef[] calldata rules, 
        DataTypes.InputRoleToken[] calldata assignRoles, 
        DataTypes.PostInput[] calldata posts
    ) external returns (address);

    /// Make a new Claim, File it & Close it
    /// @dev a wrapper function for creation, adding rules, assigning roles, posting & filing & closing a claim
    function caseMakeClosed(
        string calldata name_, 
        string calldata uri_, 
        DataTypes.RuleRef[] calldata rules, 
        DataTypes.InputRoleToken[] calldata assignRoles, 
        DataTypes.PostInput[] calldata posts,
        string calldata decisionURI_
    ) external returns (address);

}