// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface ICTXEntityUpgradable {

    //--- Functions

    /// Request to Join
    function nominate(uint256 soulToken, string memory uri) external;


    //--- Events


    /// Nominate
    event Nominate(address account, uint256 indexed id, string uri);


}
