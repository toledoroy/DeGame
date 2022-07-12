// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IVotesRepoTracker {

    //--- Events

    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChangedToken(uint256 indexed delegator, uint256 indexed fromDelegate, uint256 indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
     */
    event DelegateVotesChangedToken(uint256 indexed delegate, uint256 previousBalance, uint256 newBalance);


    //--- Functions
    
    /// Expose Voting Power Transfer Method
    function transferVotingUnits(uint256 from, uint256 to, uint256 amount) external;

    /// Expose Target Contract
    function getTargetContract() external returns (address);


    function delegatesToken(uint256 accountToken) external view returns (uint256);

    function getVotesForToken(uint256 account) external view returns (uint256);

    function getPastVotesForToken(uint256 account, uint256 blockNumber) external view returns (uint256);

}
