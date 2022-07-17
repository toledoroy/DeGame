//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
// import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
// import "@openzeppelin/contracts/governance/utils/Votes.sol";
// import "./abstract/Votes.sol";
// import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/draft-ERC721VotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/utils/VotesUpgradeable.sol"; //Adds 3.486Kb
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "./interfaces/IGameUp.sol";
// import "./interfaces/IRulesRepo.sol";
import "./interfaces/IRules.sol";
import "./interfaces/IReaction.sol";
import "./interfaces/IActionRepo.sol";
import "./public/interfaces/IVotesRepoTracker.sol";
import "./abstract/ERC1155RolesTrackerUp.sol";
import "./abstract/ProtocolEntityUpgradable.sol";
import "./abstract/Opinions.sol";
import "./abstract/Posts.sol";
// import "./abstract/Rules.sol";
// import "./abstract/Recursion.sol";
// import "./public/interfaces/IOpenRepo.sol";
import "./abstract/ProxyMulti.sol";  //Adds 1.529Kb
// import "./libraries/DataTypes.sol";


/**
 * @title Game Contract
 * @dev Retains Group Members in Roles
 * @dev Version 3.1
 * V1: Using Role NFTs
 * - Mints Member NFTs
 * - One for each
 * - All members are the same
 * - Rules
 * - Creates new Reactions
 * - Contract URI
 * - Token URIs for Roles
 * - Owner account must have an Avatar NFT
 * V2: Trackers
 * - NFT Trackers - Assign Avatars instead of Accounts & Track the owner of the Avatar NFT
 * V3:
 * - Multi-Proxy Pattern
 * V4:
 * - [TODO] DAO Votes
 * - [TODO] Unique Rule IDs (GUID)
 */
contract GameUpgradable is 
        IGame, 
        // IRules,
        ProtocolEntityUpgradable, 
        Opinions, 
        Posts,
        ProxyMulti,
        // VotesUpgradeable,
        ERC1155RolesTrackerUp {

    //--- Storage
    string public constant override symbol = "GAME";
    using Strings for uint256;

    using CountersUpgradeable for CountersUpgradeable.Counter;
    // CountersUpgradeable.Counter internal _tokenIds; //Track Last Token ID
    CountersUpgradeable.Counter internal _reactionIds;  //Track Last Reaction ID
    
    // Contract name
    string public name;
    // Mapping for Reaction Contracts
    mapping(address => bool) internal _active;

    //--- Modifiers

    /// Check if GUID Exists
    modifier AdminOrOwner() {
       //Validate Permissions
        require(owner() == _msgSender()      //Owner
            || roleHas(_msgSender(), "admin")    //Admin Role
            , "INVALID_PERMISSIONS");
        _;
    }

    //--- Functions


    /** For VotesUpgradeable
     * @dev Returns the balance of `account`.
     * /
    function _getVotingUnits(address account) internal view virtual override returns (uint256) {
        return balanceOf(account, _roleToId("member"));
    }
    */


    //Get Rules Repo
    function _ruleRepo() internal view returns (IRules) {
        address ruleRepoAddr = repo().addressGetOf(address(_HUB), "RULE_REPO");
        return IRules(ruleRepoAddr);
    }

    /// ERC165 - Supported Interfaces
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IGame).interfaceId 
            || interfaceId == type(IRules).interfaceId 
            || super.supportsInterface(interfaceId);
    }

    /// Initializer
    function initialize (
        address hub, 
        string calldata name_, 
        string calldata uri_
    ) public override initializer {
        //Initializers
        __ProtocolEntity_init(hub);
        __setTargetContract(repo().addressGetOf(address(_HUB), "SBT"));
        //Set Contract URI
        _setContractURI(uri_);
        //Identifiers
        name = name_;
        //Assign Creator as Admin & Member
        _roleAssign(tx.origin, "admin", 1);
        _roleAssign(tx.origin, "member", 1);
        //Init Default Game Roles
        // _roleCreate("admin"); 
        // _roleCreate("member");
        _roleCreate("authority");
        //Default Token URIs
        // _setRoleURI("admin", "");
        // _setRoleURI("member", "");
        // _setRoleURI("authority", "");
    }

    //** Reaction Functions

    /// Register an Incident (happening of a valued action)
    function reportEvent(
        uint256 ruleId, 
        address account,
        string calldata detailsURI_
    ) external override {
        //Validate Role
        require(roleHas(_msgSender(), "authority") , "ROLE:AUTHORITY_ONLY");
        //Fetch SBT Token
        uint256 sbToken = _getExtTokenId(account);
        //Mint SBT for that Account if doesn't exist
        if(sbToken == 0) _HUB.mintForAccount(account, "");

        //Execute Effects on that SBT
        _effectsExecute(ruleId, getSoulAddr(), sbToken);

        //TODO: Event: Rule Confirmed / Action Executed

    }

    /// Execute Rule's Effects (By Reaction Contreact)
    function effectsExecute(uint256 ruleId, address targetContract, uint256 targetTokenId) external override {
        //Validate - Called by Child Reaction
        require(reactionHas(msg.sender), "NOT A VALID INCIDENT");
        _effectsExecute(ruleId, targetContract, targetTokenId);
    }

    /// Execute Rule's Effects
    function _effectsExecute(uint256 ruleId, address targetContract, uint256 targetTokenId) internal {
        //Fetch Rule's Effects
        DataTypes.Effect[] memory effects = effectsGet(ruleId);
        //Run Each Effect
        for (uint256 j = 0; j < effects.length; ++j) {
            DataTypes.Effect memory effect = effects[j];
            //Register Rep in Game      //{name:'professional', value:5, direction:false}
            _repAdd(targetContract, targetTokenId, effect.name, effect.direction, effect.value);
            //Update Hub
            _HUB.repAdd(targetContract, targetTokenId, effect.name, effect.direction, effect.value);
        }
        //
        emit EffectsExecuted(targetTokenId, ruleId, "");
    }

    /// Disable (Disown) Reaction
    function reactionDisable(address reactionContract) public override onlyOwner {
        //Validate
        require(reactionHas(reactionContract), "Reaction Not Active");
        repo().addressRemove("reaction", reactionContract);
    }

    /// Check if Reaction is Owned by This Contract (& Active)
    function reactionHas(address reactionContract) public view override returns (bool) {
        return repo().addressHas("reaction", reactionContract);
    }

    /// Add Post 
    /// @param entRole  posting as entitiy in role (posting entity must be assigned to role)
    /// @param tokenId  Acting SBT Token ID
    /// @param uri_     post URI
    function post(string calldata entRole, uint256 tokenId, string calldata uri_) external override {
        //Validate that User Controls The Token
        require(ISoul( repo().addressGetOf(address(_HUB), "SBT") ).hasTokenControl(tokenId), "POST:SOUL_NOT_YOURS");
        //Validate: Soul Assigned to the Role 
        require(roleHasByToken(tokenId, entRole), "POST:ROLE_NOT_ASSIGNED");    //Validate the Calling Account
        // require(roleHasByToken(tokenId, entRole), string(abi.encodePacked("TOKEN: ", tokenId, " NOT_ASSIGNED_AS: ", entRole)) );    //Validate the Calling Account
        //Post Event
        _post(tx.origin, tokenId, entRole, uri_);
    }

    /// Get Token URI by Token ID
    // function tokenURI(uint256 token_id) public view returns (string memory) {
    function uri(uint256 token_id) public view returns (string memory) {
        // require(exists(token_id), "NONEXISTENT_TOKEN");
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

    //** Generic Config
    
    /// Generic Config Get Function
    function confGet(string memory key) public view override returns (string memory) {
        return repo().stringGet(key);
    }
    
    /// Generic Config Set Function
    function confSet(string memory key, string memory value) public override AdminOrOwner {
        _confSet(key, value);
    }

    //** Multi Proxy

    /// Proxy Fallback Implementations
    function _implementations() internal view virtual override returns (address[] memory) {
        address[] memory implementationAddresses;
        string memory gameType = confGet("type");
        
        // console.log("[DEBUG] Find Implementations For", gameType);

        if(Utils.stringMatch(gameType, "")) return implementationAddresses;
        // require (!Utils.stringMatch(gameType, ""), "NO_GAME_TYPE");
        //UID
        string memory gameTypeFull = string(abi.encodePacked("GAME_", gameType));
        //Fetch Implementations
        implementationAddresses = repo().addressGetAllOf(address(_HUB), gameTypeFull); //Specific
        require(implementationAddresses.length > 0, "NO_FALLBACK_CONTRACTS");

        // console.log("[DEBUG] Has Implementations For: ", gameTypeFull);

        return implementationAddresses;
    }

    /* Support for Global Extension
    /// Proxy Fallback Implementations
    function _implementations() internal view virtual override returns (address[] memory) {
        //UID
        string memory gameType = string(abi.encodePacked("GAME_", confGet("type")));
        //Fetch Implementations
        address[] memory implementationAddresses = repo().addressGetAllOf(address(_HUB), gameType); //Specific
        address[] memory implementationAddressesAll = repo().addressGetAllOf(address(_HUB), "GAME_ALL"); //General
        return arrayConcat(implementationAddressesAll, implementationAddresses);
    }
    
    /// Concatenate Arrays (A Suboptimal Solution -- ~800Bytes)      //TODO: Maybe move to an external library?
    function arrayConcat(address[] memory Accounts, address[] memory Accounts2) private pure returns (address[] memory) {
        //Create a new container array
        address[] memory returnArr = new address[](Accounts.length + Accounts2.length);
        uint i=0;
        if(Accounts.length > 0) {
            for (; i < Accounts.length; i++) {
                returnArr[i] = Accounts[i];
            }
        }
        uint j=0;
        if(Accounts2.length > 0) {
            while (j < Accounts.length) {
                returnArr[i++] = Accounts2[j++];
            }
        }
        return returnArr;
    } 
    */

    //** Role Management

    /// Join a game (as a regular 'member')
    function join() external override returns (uint256) {
        require (!Utils.stringMatch(confGet("isClosed"), "true"), "CLOSED_SPACE");
        //Mint Member Token to Self
        return _GUIDAssign(_msgSender(), _stringToBytes32("member"), 1);
    }

    /// Leave 'member' Role in game
    function leave() external override returns (uint256) {
        return _GUIDRemove(_msgSender(), _stringToBytes32("member"), 1);
    }

    /// Request to Join
    function nominate(uint256 soulToken, string memory uri_) external override {
        emit Nominate(_msgSender(), soulToken, uri_);
    }

    /// Assign Someone Else to a Role
    function roleAssign(address account, string memory role) public override roleExists(role) AdminOrOwner {
        _roleAssign(account, role, 1);
    }

    /// Assign Tethered Token to a Role
    function roleAssignToToken(uint256 ownerToken, string memory role) public override roleExists(role) AdminOrOwner {
        _roleAssignToToken(ownerToken, role, 1);
    }

    /// Remove Someone Else from a Role
    function roleRemove(address account, string memory role) public override roleExists(role) AdminOrOwner {
        _roleRemove(account, role, 1);
    }

    /// Remove Tethered Token from a Role
    function roleRemoveFromToken(uint256 ownerToken, string memory role) public override roleExists(role) AdminOrOwner {
        _roleRemoveFromToken(ownerToken, role, 1);
    }

    /// Change Role Wrapper (Add & Remove)
    function roleChange(address account, string memory roleOld, string memory roleNew) external override {
        roleAssign(account, roleNew);
        roleRemove(account, roleOld);
    }

    /** TODO: DEPRECATE - Allow Uneven Role Distribution 
    * @dev Hook that is called before any token transfer. This includes minting and burning, as well as batched variants.
    *  - Max of Single Token for each account
    */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        // if (to != address(0) && to != _targetContract) { //Not Burn
        if (_isOwnerAddress(to)) { //Not Burn
            for (uint256 i = 0; i < ids.length; ++i) {
                //Validate - Max of 1 Per Account
                uint256 id = ids[i];
                require(balanceOf(to, id) == 0, "ALREADY_ASSIGNED_TO_ROLE");
                uint256 amount = amounts[i];
                require(amount == 1, "ONE_TOKEN_MAX");
            }
        }
    }
    
    /// Hook:Track Voting Power    //UNTESTED
    function _afterTokenTransferTracker(
        address operator,
        uint256 fromToken,
        uint256 toToken,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._afterTokenTransferTracker(operator, fromToken, toToken, ids, amounts, data);
        //-- Track Voting Power by SBT
        address votesRepoAddr = repo().addressGetOf(address(_HUB), "VOTES_REPO");
        // console.log("Votes Repo: ", votesRepoAddr);
        if(votesRepoAddr != address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                //Only "member" tokens give voting rights
                if(_roleToId("member") == ids[i]) {
                    // uint256 id = ids[i];
                    uint256 amount = amounts[i];
                    //Votes Changes
                    IVotesRepoTracker(votesRepoAddr).transferVotingUnits(fromToken, toToken, amount);
                }
            }
        }
        // else{ console.log("No Votes Repo Configured", votesRepoAddr); }
    }

    //** Rule Management    //Maybe Offload to a GameExtension
    
    //-- Getters

    /// Get Rule
    function ruleGet(uint256 id) public view returns (DataTypes.Rule memory) {
        return _ruleRepo().ruleGet(id);
    }

    /// Get Rule's Effects
    function effectsGet(uint256 id) public view returns (DataTypes.Effect[] memory) {
        return _ruleRepo().effectsGet(id);
    }

    /// Get Rule's Confirmation Method
    function confirmationGet(uint256 id) public view returns (DataTypes.Confirmation memory) {
        return _ruleRepo().confirmationGet(id);
    }

    //-- Setters

    /// Create New Rule
    function ruleAdd(
        DataTypes.Rule memory rule, 
        DataTypes.Confirmation memory confirmation, 
        DataTypes.Effect[] memory effects
    ) public returns (uint256) {
        return _ruleRepo().ruleAdd(rule, confirmation, effects);
    }

    /// Update Rule
    function ruleUpdate(
        uint256 id, 
        DataTypes.Rule memory rule, 
        DataTypes.Effect[] memory effects
    ) external {
        _ruleRepo().ruleUpdate(id, rule, effects);
    }

    /// Set Disable Status for Rule
    function ruleDisable(uint256 id, bool disabled) external {
        _ruleRepo().ruleDisable(id, disabled);
    }

    /// Update Rule's Confirmation Data
    function ruleConfirmationUpdate(uint256 id, DataTypes.Confirmation memory confirmation) external {
        _ruleRepo().ruleConfirmationUpdate(id, confirmation);
    }

    
}