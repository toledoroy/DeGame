//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";

// import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
// import "../interfaces/ISoul.sol";
// import "../interfaces/IERC1155RolesTracker.sol";

import "../interfaces/ICTXEntityUpgradable.sol";
import "../abstract/ProtocolEntityUpgradable.sol";
import "../abstract/ERC1155RolesTrackerUp.sol";
import "../libraries/DataTypes.sol";

/**
 * @title Base for CTX Entities
 * @dev Version 1.0.0
 */
abstract contract CTXEntityUpgradable is 
    ICTXEntityUpgradable,
    ProtocolEntityUpgradable,
    ERC1155RolesTrackerUp {


    //-- Functions

    /// Request to Join
    function nominate(uint256 soulToken, string memory uri_) public override {
        emit Nominate(_msgSender(), soulToken, uri_);
    }

}