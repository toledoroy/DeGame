// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../libraries/DataTypes.sol";

interface IGame {
    
    //--- Functions

    /// Initialize
    function initialize(string calldata gameType_, string calldata name_, string calldata uri_) external;

    /// Symbol As Arbitrary contract designation signature
    function symbol() external view returns (string memory);

    /// Add Post 
    function post(string calldata entRole, uint256 tokenId, string calldata uri) external;

    /// Disable Claim
    function claimDisable(address claimContract) external;

    /// Check if Claim is Owned by This Contract (& Active)
    function claimHas(address claimContract) external view returns (bool);

    /// Join game as member
    function join() external returns (uint256);

    /// Leave member role in current game
    function leave() external returns (uint256);

    /// Request to Join
    // function nominate(uint256 soulToken, string memory uri) external;

    /* MOVED UP
    /// Assign Someone to a Role
    function roleAssign(address account, string calldata role) external;

    /// Assign Tethered Token to a Role
    function roleAssignToToken(uint256 toToken, string memory role) external;

    /// Remove Someone Else from a Role
    function roleRemove(address account, string calldata role) external;

    /// Remove Tethered Token from a Role
    function roleRemoveFromToken(uint256 ownerToken, string memory role) external;

    /// Change Role Wrapper (Add & Remove)
    function roleChange(address account, string memory roleOld, string memory roleNew) external;

    /// Create a new Role
    // function roleCreate(address account, string calldata role) external;
    */
    
    /// Set Metadata URI For Role
    // function setRoleURI(string memory role, string memory _tokenURI) external;

    /// Set Contract URI
    // function setContractURI(string calldata contract_uri) external;

    /// Add Reputation (Positive or Negative)
    // function repAdd(address contractAddr, uint256 tokenId, string calldata domain, bool rating, uint8 amount) external;

    /// Execute Rule's Effects (By Claim Contreact)
    function effectsExecute(uint256 ruleId, address targetContract, uint256 targetTokenId) external;

    /// Register an Incident (happening of a valued action)
    function reportEvent(uint256 ruleId, address account, string calldata detailsURI_) external;


    /* MOVED TO IRules
    //-- Rule Func.

    /// Create New Rule
    function ruleAdd(DataTypes.Rule memory rule, DataTypes.Confirmation memory confirmation, DataTypes.Effect[] memory effects) external returns (uint256);

    /// Update Rule
    function ruleUpdate(uint256 id, DataTypes.Rule memory rule, DataTypes.Effect[] memory effects) external;
    
    /// Update Rule's Confirmation Data
    function ruleConfirmationUpdate(uint256 id, DataTypes.Confirmation memory confirmation) external;

    */

    //--- Events

    /// New Claim Created
    // event ClaimCreated(uint256 indexed id, address contractAddress);    

    /// Nominate
    // event Nominate(address account, uint256 indexed id, string uri);

    /// Effect
    event EffectsExecuted(uint256 indexed targetTokenId, uint256 indexed ruleId, bytes data);

}