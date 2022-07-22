// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../libraries/DataTypes.sol";

interface IProcedure {

    //-- Functions


    //--- Events

    /// Claim Stage Change
    event Stage(DataTypes.ClaimStage stage);

    /// Post Verdict
    event Verdict(string uri, address account);

    /// Claim Cancelation Data
    event Executed(address account);

    /// Claim Cancelation Data
    event Cancelled(string uri, address account);

}