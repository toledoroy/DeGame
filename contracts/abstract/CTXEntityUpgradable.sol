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

    //--- Modifiers

    /// Permissions Modifier
    modifier AdminOnly() virtual {
       //Validate Permissions
        require(roleHas(tx.origin, "admin")    //Admin Role
            || roleHas(_msgSender(), "admin")    //Admin Role
            , "INVALID_PERMISSIONS");
        _;
    }

    /// Permissions Modifier
    modifier AdminOrOwner() virtual {
       //Validate Permissions
        require(owner() == _msgSender()      //Owner
            || roleHas(tx.origin, "admin")    //Admin Role
            || roleHas(_msgSender(), "admin")    //Admin Role
            , "INVALID_PERMISSIONS");
        _;
    }

    //-- Functions

    /// Check if current account is Admin or Owner
    function _isAdminOrOwner() internal view returns (bool) {
        return (owner() == _msgSender()      //Owner
            || roleHas(tx.origin, "admin")    //Admin Role
            || roleHas(_msgSender(), "admin")    //Admin Role
        );
    }

    /// ERC165 - Supported Interfaces
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(ICTXEntityUpgradable).interfaceId 
            || super.supportsInterface(interfaceId);
    }

    /// Request to Join
    function nominate(uint256 soulToken, string memory uri_) public override {
        emit Nominate(_msgSender(), soulToken, uri_);
    }

    //** Generic Config
    
    /// Generic Config Get Function
    function confGet(string memory key) public view override returns (string memory) {
        return repo().stringGet(key);
    }
    
    /// Generic Config Set Function
    function confSet(string memory key, string memory value) public override AdminOrOwner {
        _confSet(key, value);
    }

    //** Role Management
    
    /// Create a new Role
    function roleCreate(string memory role) external virtual override AdminOrOwner {
        _roleCreate(role);
    }

    /// Override Assign Tethered Token to a Role
    function _roleAssign(address account, string memory role, uint256 amount) internal override {
        uint256 sbt = _getExtTokenId(account);
        if(sbt == 0){
            //Auto-mint token for Account
            if(sbt == 0) _HUB.mintForAccount(account, "");
        }
        _roleAssignToToken(sbt, role, amount);
    }

    /// Assign Someone Else to a Role
    function roleAssign(address account, string memory role) public virtual override roleExists(role) AdminOrOwner {
        _roleAssign(account, role, 1);
    }

    /// Assign Tethered Token to a Role
    function roleAssignToToken(uint256 sbt, string memory role) public virtual override roleExists(role) AdminOrOwner {
        _roleAssignToToken(sbt, role, 1);
    }

    /// Remove Someone Else from a Role
    function roleRemove(address account, string memory role) public virtual override roleExists(role) AdminOrOwner {
        _roleRemove(account, role, 1);
    }

    /// Remove Tethered Token from a Role
    function roleRemoveFromToken(uint256 sbt, string memory role) public virtual override roleExists(role) AdminOrOwner {
        _roleRemoveFromToken(sbt, role, 1);
    }

    /// Change Role Wrapper (Add & Remove)
    function roleChange(address account, string memory roleOld, string memory roleNew) external virtual override {
        roleAssign(account, roleNew);
        roleRemove(account, roleOld);
    }
    
    /// Get Token URI by Token ID
    function uri(uint256 token_id) public view override returns (string memory) {
        return _tokenURIs[token_id];
    }

    /// Set Metadata URI For Role
    function setRoleURI(string memory role, string memory _tokenURI) external override AdminOrOwner {
        _setRoleURI(role, _tokenURI);
    }
   
    /// Set Contract URI
    function setContractURI(string calldata contract_uri) external override AdminOrOwner {
        _setContractURI(contract_uri);
    }
    

}