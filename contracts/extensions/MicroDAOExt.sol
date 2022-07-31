// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "hardhat/console.sol";

// import "./interfaces/IMDAO.sol";
import "../abstract/GameExtension.sol";
import "../interfaces/IClaim.sol";
import "../interfaces/ITask.sol";

/**
 * @title Game Extension: MicroDAO
 */
contract MicroDAOExt is GameExtension {

    /// Apply to a Task (Nominte Self)
    function applyToTask(address taskAddr, string memory uri) external AdminOnly {
        ITask(taskAddr).application(uri);
    }

    /// Deliver a Task (Just use the Post function directly)
    function deliverTask(address taskAddr, string memory uri) external AdminOnly {
        //Self's SBT TokenId
        uint256 sbtToken = soul().tokenByAddress(address(this));

        // console.log("MicroDAOExt: Post as Game", sbtToken, address(this));
        // console.log("MicroDAOExt: Has Control?", soul().hasTokenControl(sbtToken));

        //Post as Applicant
        IGame(taskAddr).post("applicant", sbtToken, uri);
        // IClaim(taskAddr).post("applicant", sbtToken, uri);
    }

}