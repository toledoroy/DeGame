//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

// import "hardhat/console.sol";

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "../interfaces/IProcedure.sol";
import "../interfaces/IGameUp.sol";
import "../libraries/DataTypes.sol";
import "../abstract/CTXEntityUpgradable.sol";
import "../abstract/Posts.sol";


/**
 * @title Procedure Basic Logic for Contracts 
 */
abstract contract Procedure is IProcedure
    , CTXEntityUpgradable
    , Posts
    {

    //-- Storage

    //Stage (Claim Lifecycle)
    DataTypes.ClaimStage public stage;


    //--- Modifiers

    /// Permissions Modifier
    modifier AdminOrOwner() override {
       //Validate Permissions
        require(owner() == _msgSender()      //Owner
            || roleHas(_msgSender(), "admin")    //Admin Role
            , "INVALID_PERMISSIONS");
        _;
    }

    /// Permissions Modifier
    modifier AdminOrOwnerOrCTX() {
       //Validate Permissions
        require(owner() == _msgSender()      //Owner
            || roleHas(_msgSender(), "admin")    //Admin Role
            || msg.sender == getContainerAddr()
            , "INVALID_PERMISSIONS");

        _;
    }

    //-- Functions

    /* Maybe, When used more than once

    // function nextStage(string calldata uri) public {
        // if (sha3(myEnum) == sha3("Bar")) return MyEnum.Bar;
    // }

    /// Set Association
    function _assocSet(string memory key, address contractAddr) internal {
        repo().addressSet(key, contractAddr);
    }

    /// Get Contract Association
    function assocGet(string memory key) public view override returns (address) {
        //Return address from the Repo
        return repo().addressGet(key);
    }
    */

    /// Change Claim Stage
    function _setStage(DataTypes.ClaimStage stage_) internal {
        //Set Stage
        stage = stage_;
        //Stage Change Event
        emit Stage(stage);
    }

    /// Claim Stage: Reject Claim --> Cancelled
    function _stageCancel(string calldata uri_) internal {
        //Claim is now Closed
        _setStage(DataTypes.ClaimStage.Cancelled);
        //Cancellation Event
        emit Cancelled(uri_, _msgSender());
    }

    /// Set Parent Container
    function _setParentCTX(address container) internal {
        //Validate
        require(container != address(0), "Invalid Container Address");
        require(IERC165(container).supportsInterface(type(IGame).interfaceId), "Implmementation Does Not Support Game Interface");  //Might Cause Problems on Interface Update. Keep disabled for now.
        //Set to OpenRepo
        repo().addressSet("container", container);
        // _assocSet("container", container);
    }
    
    /// Get Container Address
    function getContainerAddr() internal view returns (address) {
        // return _game;
        return repo().addressGet("container");
    }

    //** Role Management
    
    /// Create a new Role
    function roleCreate(string memory role) external override AdminOrOwnerOrCTX {
        _roleCreate(role);
    }

    /// Assign to a Role
    function roleAssign(address account, string memory role) public override roleExists(role) {
        //Special Validations for Special Roles 
        if (Utils.stringMatch(role, "admin") || Utils.stringMatch(role, "authority")) {
            require(getContainerAddr() != address(0), "Unknown Parent Container");
            //Validate: Must Hold same role in Containing Game
            require(IERC1155RolesTracker(getContainerAddr()).roleHas(account, role), "User Required to hold same role in the Game context");
        }
        else{
            //Validate Permissions
            require(
                owner() == _msgSender()      //Owner
                || roleHas(_msgSender(), "admin")    //Admin Role
                || msg.sender == address(_HUB)   //Through the Hub
                , "INVALID_PERMISSIONS");
        }
        //Add
        _roleAssign(account, role, 1);
    }
    
    /// Assign Tethered Token to a Role
    function roleAssignToToken(uint256 ownerToken, string memory role) public override roleExists(role) AdminOrOwnerOrCTX {
        _roleAssignToToken(ownerToken, role, 1);
    }

    /* Identical to parent
    /// Remove Tethered Token from a Role
    function roleRemoveFromToken(uint256 ownerToken, string memory role) public override roleExists(role) AdminOrOwner {
        _roleRemoveFromToken(ownerToken, role, 1);
    }
    */

    // function post(string entRole, string uri) 
    // - Post by account + role (in the claim, since an account may have multiple roles)

    // function post(uint256 token_id, string entRole, string uri) 
    //- Post by Entity (Token ID or a token identifier struct)
 
    /// Add Post 
    /// @param entRole  posting as entitiy in role (posting entity must be assigned to role)
    /// @param tokenId  Acting SBT Token ID
    /// @param uri_     post URI
    function post(string calldata entRole, uint256 tokenId, string calldata uri_) public override {
        //Validate that User Controls The Token
        require(ISoul(getSoulAddr()).hasTokenControlAccount(tokenId, _msgSender())
            || ISoul(getSoulAddr()).hasTokenControlAccount(tokenId, tx.origin)
            , "POST:SOUL_NOT_YOURS"); //Supports Contract Permissions
        //Validate: Soul Assigned to the Role 
        // require(roleHas(tx.origin, entRole), "POST:ROLE_NOT_ASSIGNED");    //Validate the Calling Account
        require(roleHasByToken(tokenId, entRole), "POST:ROLE_NOT_ASSIGNED");    //Validate the Calling Account
        //Validate Stage
        require(stage < DataTypes.ClaimStage.Closed, "STAGE:CLOSED");
        //Post Event
        _post(tx.origin, tokenId, entRole, uri_);
    }
}
    