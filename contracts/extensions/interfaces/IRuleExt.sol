// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../../libraries/DataTypes.sol";

interface IRuleExt {
    
    /// Get Rule
    function ruleGet(uint256 id) external view returns (DataTypes.Rule memory);

    /// Get Rule's Effects
    function effectsGet(uint256 id) external view returns (DataTypes.Effect[] memory);

    /// Get Rule's Confirmation Method
    function confirmationGet(uint256 id) external view returns (DataTypes.Confirmation memory);

    //-- Setters

    /// Create New Rule
    function ruleAdd(
        DataTypes.Rule memory rule, 
        DataTypes.Confirmation memory confirmation, 
        DataTypes.Effect[] memory effects
    ) external returns (uint256);

    /// Update Rule
    function ruleUpdate(
        uint256 id, 
        DataTypes.Rule memory rule, 
        DataTypes.Effect[] memory effects
    ) external;

    /// Set Disable Status for Rule
    function ruleDisable(uint256 id, bool disabled) external;

    /// Update Rule's Confirmation Data
    function ruleConfirmationUpdate(uint256 id, DataTypes.Confirmation memory confirmation) external;

}