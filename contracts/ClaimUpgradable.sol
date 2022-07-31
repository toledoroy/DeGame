//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./libraries/DataTypes.sol";
import "./interfaces/IClaim.sol";
import "./interfaces/IRules.sol";
import "./interfaces/ISoul.sol";
import "./interfaces/IERC1155RolesTracker.sol";
import "./interfaces/IGameUp.sol";
import "./abstract/CTXEntityUpgradable.sol";
import "./abstract/ERC1155RolesTrackerUp.sol";
import "./abstract/Procedure.sol";

/**
 * @title Upgradable Claim Contract
 * @dev Version 2.2.0
 */
contract ClaimUpgradable is IClaim
    , Procedure
    {

    //--- Storage
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter internal _ruleIds;  //Track Last Rule ID

    // // Contract name
    // string public name;
    // // Contract symbol
    // string public symbol;

    //Rules Reference
    mapping(uint256 => DataTypes.RuleRef) internal _rules;      // Mapping for Claim Rules
    mapping(uint256 => bool) public decision;                   // Mapping for Rule Decisions
    
    //--- Functions
    
    /// ERC165 - Supported Interfaces
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IClaim).interfaceId 
            || interfaceId == type(IRules).interfaceId 
            || super.supportsInterface(interfaceId);
    }

    /// Initializer
    function initialize (
        address container,
        string calldata type_,
        string memory name_, 
        string calldata uri_
    ) public virtual override initializer {
        super.initialize(container, type_, name_, uri_);
        symbol = "CLAIM";
    }

    //--- Rule Reference 

    /// Check if Reference ID exists
    function ruleRefExist(uint256 ruleRefId) internal view returns (bool) {
        return (_rules[ruleRefId].game != address(0) && _rules[ruleRefId].ruleId != 0);
    }

    /// Fetch Rule By Reference ID
    function ruleGet(uint256 ruleRefId) public view returns (DataTypes.Rule memory) {
        //Validate
        require (ruleRefExist(ruleRefId), "INEXISTENT_RULE_REF_ID");
        return IRules(_rules[ruleRefId].game).ruleGet(_rules[ruleRefId].ruleId);
    }

    /// Get Rule's Confirmation Data
    function ruleGetConfirmation(uint256 ruleRefId) public view returns (DataTypes.Confirmation memory) {
        //Validate
        require (ruleRefExist(ruleRefId), "INEXISTENT_RULE_REF_ID");
        return IRules(_rules[ruleRefId].game).confirmationGet(_rules[ruleRefId].ruleId);
    }

    /// Get Rule's Effects
    function ruleGetEffects(uint256 ruleRefId) public view returns (DataTypes.Effect[] memory) {
        //Validate
        require (ruleRefExist(ruleRefId), "INEXISTENT_RULE_REF_ID");
        return IRules(_rules[ruleRefId].game).effectsGet(_rules[ruleRefId].ruleId);
    }

    /// Add Rule Reference
    function ruleRefAdd(address game_, uint256 ruleId_) external override AdminOrOwnerOrCTX {
        //Validate Jurisdiciton implements IRules (ERC165)
        require(IERC165(game_).supportsInterface(type(IRules).interfaceId), "Implmementation Does Not Support Rules Interface");  //Might Cause Problems on Interface Update. Keep disabled for now.
        _ruleRefAdd(game_, ruleId_);
    }

    /// Add Relevant Rule Reference 
    function _ruleRefAdd(address game_, uint256 ruleId_) internal {
        //Assign Rule Reference ID
        _ruleIds.increment(); //Start with 1
        uint256 ruleId = _ruleIds.current();
        //New Rule
        _rules[ruleId].game = game_;
        _rules[ruleId].ruleId = ruleId_;
        //Get Rule, Get Affected & Add as new Role if Doesn't Exist
        DataTypes.Rule memory rule = ruleGet(ruleId);
        //Validate Rule Active
        require(rule.disabled == false, "Selected rule is disabled");
        if(!roleExist(rule.affected)) {
            //Create Affected Role if Missing
            _roleCreate(rule.affected);
        }
        //Event: Rule Reference Added 
        emit RuleAdded(game_, ruleId_);
    }
    
    //--- State Changers
    
    /// File the Claim (Validate & Open Discussion)  --> Open
    function stageFile() public override {
        //Validate Caller
        require(roleHas(tx.origin, "creator") || roleHas(_msgSender(), "admin") , "ROLE:CREATOR_OR_ADMIN");
        //Validate Lifecycle Stage
        require(stage == DataTypes.ClaimStage.Draft, "STAGE:DRAFT_ONLY");
        //Validate - Has Subject
        require(uniqueRoleMembersCount("subject") > 0 , "ROLE:MISSING_SUBJECT");
        //Validate - Prevent Self Report? (subject != affected)

        //Validate Witnesses
        for (uint256 ruleId = 1; ruleId <= _ruleIds.current(); ++ruleId) {
            // DataTypes.Rule memory rule = ruleGet(ruleId);
            DataTypes.Confirmation memory confirmation = ruleGetConfirmation(ruleId);
            //Get Current Witness Headcount (Unique)
            uint256 witnesses = uniqueRoleMembersCount("witness");
            //Validate Min Witness Requirements
            require(witnesses >= confirmation.witness, "INSUFFICIENT_WITNESSES");
        }
        //Claim is now Open
        _setStage(DataTypes.ClaimStage.Open);
    }

    /// Claim Wait For Verdict  --> Pending
    function stageWaitForDecision() public override {
        //Validate Stage
        require(stage == DataTypes.ClaimStage.Open, "STAGE:OPEN_ONLY");
        //Validate Caller
        require(_msgSender() == getContainerAddr() 
            || roleHas(_msgSender(), "authority") 
            || roleHas(_msgSender(), "admin") , "ROLE:AUTHORITY_OR_ADMIN");
        //Claim is now Waiting for Verdict
        _setStage(DataTypes.ClaimStage.Decision);
    }   

    /// Stage: Place Verdict  --> Closed
    function stageDecision(DataTypes.InputDecision[] calldata verdict, string calldata uri_) public override {
        require(_msgSender() == getContainerAddr()  //Parent Contract
            || roleHas(_msgSender(), "authority")   //Authority
            , "ROLE:AUTHORITY_ONLY");
        require(stage == DataTypes.ClaimStage.Decision, "STAGE:DECISION_ONLY");
        //Process Decision
        for (uint256 i = 0; i < verdict.length; ++i) {
            decision[verdict[i].ruleId] = verdict[i].decision;
            if(verdict[i].decision) {
                //Fetch Claim's Subject(s)
                uint256[] memory subjects = uniqueRoleMembers("subject");
                //Each Subject
                for (uint256 s = 0; s < subjects.length; ++s) {
                    //Get Subject's SBT ID 
                    uint256 tokenId = subjects[s];
                    uint256 parentRuleId = _rules[verdict[i].ruleId].ruleId;
                    //Execute Rule
                    IGame(getContainerAddr()).effectsExecute(parentRuleId, getSoulAddr(), tokenId);
                }
                //Rule Confirmed Event
                emit RuleConfirmed(verdict[i].ruleId);
            }
        }
        //Claim is now Closed
        _setStage(DataTypes.ClaimStage.Closed);
        //Emit Verdict Event
        emit Verdict(uri_, tx.origin);
    }

    /// Stage: Reject Claim --> Cancelled
    function stageCancel(string calldata uri_) public override {
        require(stage <= DataTypes.ClaimStage.Decision, "STAGE:TOO_FAR_ALONG");
        // require(roleHas(_msgSender(), "authority") , "ROLE:AUTHORITY_ONLY");
        require(_msgSender() == getContainerAddr() 
            || roleHas(_msgSender(), "authority") 
            || roleHas(_msgSender(), "admin") , "ROLE:AUTHORITY_OR_ADMIN");
        _stageCancel(uri_);
    }


}