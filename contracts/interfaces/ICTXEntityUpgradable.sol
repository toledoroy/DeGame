// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface ICTXEntityUpgradable {

    //--- Functions

    /// Request to Join
    function nominate(uint256 soulToken, string memory uri) external;


    /// Create a new Role
    function roleCreate(string calldata role) external;

    /// Assign Someone to a Role
    function roleAssign(address account, string calldata role) external;

    /// Assign Tethered Token to a Role
    function roleAssignToToken(uint256 toToken, string memory role) external;

    /// Remove Someone Else from a Role
    function roleRemove(address account, string calldata role) external;

    /// Remove Tethered Token from a Role
    function roleRemoveFromToken(uint256 ownerToken, string memory role) external;

    /// Change Role Wrapper (Add & Remove)
    function roleChange(address account, string memory roleOld, string memory roleNew) external;


    //--- Events


    /// Nominate
    event Nominate(address account, uint256 indexed id, string uri);


}
