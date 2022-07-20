// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../HubUpgradable.sol";

/**
 * @title HubMock
 */
contract HubMock is HubUpgradable {

    constructor(
        address openRepo,
        address gameContract, 
        address claimContract,
        address taskContract
        ) {
        initialize(
            openRepo,
            gameContract, 
            claimContract,
            taskContract
        );
    }

}
