// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";
import "../public/interfaces/IOpenRepo.sol";
import "../interfaces/IERC1155RolesTracker.sol";
import "../interfaces/IProtocolEntity.sol";
import "../interfaces/IGameUp.sol";
import "../interfaces/IHub.sol";
import "../interfaces/ISoul.sol";

/**
 * @title GameExtension
 */
abstract contract GameExtension is Context {

    //--- Storage
    
    //--- Functions 

    /// Use Self (Main Game)
    function game() internal view returns (IGame) {
        return IGame(address(this));
    }

    /// Use Game Role Interface on Self 
    function gameRoles() internal view returns (IERC1155RolesTracker) {
        return IERC1155RolesTracker(address(this));
    }

    /// Get Data Repo Address (From Hub)
    function repoAddr() public view returns (address) {
        return IProtocolEntity(address(this)).repoAddr();
    }

    /// Get Assoc Repo
    function repo() internal view returns (IOpenRepo) {
        return IOpenRepo(repoAddr());
    }

    /// Hub Address
    function hubAddress() internal view returns (address) {
        return IProtocolEntity(address(this)).getHub();
    }
      
    /// Get Hub
    function hub() internal view returns (IHub) {
        return IHub(hubAddress());
    }  

    /// Get Soul Contract Address
    function getSoulAddr() internal view returns (address) {
        return repo().addressGetOf(hubAddress(), "SBT");
    }

    /// Get Soul Contract
    function soul() internal view returns (ISoul) {
        return ISoul(getSoulAddr());
    }  
    
}
