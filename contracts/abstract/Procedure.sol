//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

// import "hardhat/console.sol";

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "../interfaces/IProcedure.sol";
import "../libraries/DataTypes.sol";
import "../abstract/CTXEntityUpgradable.sol";


/**
 * @title Procedure Basic Logic for Contracts 
 */
abstract contract Procedure is 
    IProcedure
    , CTXEntityUpgradable
    {

    //-- Storage

    //Stage (Claim Lifecycle)
    DataTypes.ClaimStage public stage;


    //-- Functions

    /// Request to Join
    // function nominate(uint256 soulToken, string memory uri_) public override {
    //     emit Nominate(_msgSender(), soulToken, uri_);
    // }

    /// Change Claim Stage
    function _setStage(DataTypes.ClaimStage stage_) internal {
        //Set Stage
        stage = stage_;
        //Stage Change Event
        emit Stage(stage);
    }


}
    