// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract InfoToken is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    event Mint(address indexed account, uint256 amount, string info);
    event Burn(address indexed account, uint256 amount, string info);

    constructor() ERC20("Token", "$TOKEN") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(BURNER_ROLE, msg.sender);
    }

    function mint(address account, uint256 amount, string calldata info) public {
        require(hasRole(MINTER_ROLE, msg.sender), "Only minters can mint");
        _mint(account, amount);
        emit Mint(account, amount, info);
    }

    function burn(address account, uint256 amount, string calldata info) public {
        require(hasRole(BURNER_ROLE, msg.sender), "Only burners can burn");
        _burn(account, amount);
        emit Burn(account, amount, info);
    }
}