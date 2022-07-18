//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";

import "./ClaimUpgradable.sol";
import "./abstract/ProtocolEntityUpgradable.sol";
import "./abstract/ERC1155RolesTrackerUp.sol";
import "./abstract/Posts.sol";
import "./interfaces/ITask.sol";


/**
 * @title Task / Request for Product (RFP) Entity
 * @dev 
 */
contract TaskUpgradable is 
    ITask,
    ClaimUpgradable
    // Posts, 
    // ProtocolEntityUpgradable, 
    // ERC1155RolesTrackerUp 
    {

    //-- Storage
    
    // string public constant override symbol = "TASK";


    //-- Functions



/* COPY

    //-- Storage

    //Contract Admin Address
    address admin;
    //Escrow in account
    uint256 public funds;

    // Contract name
    string public name;
    // Contract symbol
    string public constant override symbol = "PROJECT";

    //Lifecycle
    enum CaseStage {
        Draft,
        Open,
        Accepted,
        Delivered, 
        Approved,
        Cancelled
    }

    //-- Functions



    /// Initializer
    function initialize (address hub, string calldata name_, string calldata uri_) public payable override initializer {
        //Initializers
        // __common_init(hub);
        // __UUPSUpgradeable_init();

        //Initializers
        __ProtocolEntity_init(hub);
        __setTargetContract(getSoulAddr());
        //Set Parent Container
        _setParentCTX(container);

        //Set Contract URI
        _setContractURI(uri_);
        //Identifiers
        name = name_;
        //Track Funds
        if(msg.value > 0){
            funds += msg.value;
        }
    }
    
    /// Upgrade
    function _authorizeUpgrade(address newImplementation) internal onlyOwner override {}
*/

 

}