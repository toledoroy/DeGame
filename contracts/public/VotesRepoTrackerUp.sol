// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (governance/utils/Votes.sol)
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CheckpointsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/governance/utils/IVotesUpgradeable.sol";
import "./interfaces/IVotesRepoTracker.sol";
import "../abstract/TrackerUpgradable.sol";

/**
 * @dev Based on VotesUpgradeable  https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v4.7.0/contracts/governance/utils/VotesUpgradeable.sol
 * @title Votes Repository
 * @dev Retains Voting Power History for other Contracts
 * Version 1.0.0
 *
 * @dev This is a base abstract contract that tracks voting units, which are a measure of voting power that can be
 * transferred, and provides a system of vote delegation, where an account can delegate its voting units to a sort of
 * "representative" that will pool delegated voting units from different accounts and can then use it to vote in
 * decisions. In fact, voting units _must_ be delegated in order to count as actual votes, and an account has to
 * delegate those votes to itself if it wishes to participate in decisions and does not have a trusted representative.
 *
 * This contract is often combined with a token contract such that voting units correspond to token units. For an
 * example, see {ERC721Votes}.
 *
 * The full history of delegate votes is tracked on-chain so that governance protocols can consider votes as distributed
 * at a particular block number to protect against flash loans and double voting. The opt-in delegate system makes the
 * cost of this history tracking optional.
 *
 * When using this module the derived contract must implement {_getVotingUnits} (for example, make it return
 * {ERC721-balanceOf}), and can use {_transferVotingUnits} to track a change in the distribution of those units (in the
 * previous example, it would be included in {ERC721-_beforeTokenTransfer}).
 *
 * _Available since v4.5._
 */
// abstract contract VotesUpgradeable is Initializable, IVotesUpgradeable, ContextUpgradeable, EIP712Upgradeable {
contract VotesRepoUpgradable is 
        IVotesRepoTracker, 
        IVotesUpgradeable, 
        Initializable, 
        TrackerUpgradable,
        ContextUpgradeable, 
        EIP712Upgradeable {

            
    /// Expose Target Contract
    function getTargetContract() public view virtual override returns (address) {
        return _targetContract;
    }


    //** Implementation

    //Track Voting Units
    // mapping(address => mapping(address => uint256)) internal _votingUnits;
    mapping(address => mapping(uint256 => uint256)) internal _votingUnits;


    /// Expose Voting Power Transfer Method
    /// @dev Run this on the consumer contract. On _afterTokenTransfer() 
    // function transferVotingUnits(address from, address to, uint256 amount) external override {
    //     _transferVotingUnits(from, to, amount);
    // }
    function transferVotingUnits(uint256 from, uint256 to, uint256 amount) external override {
        _transferVotingUnits(from, to, amount);
    }

    /**
     * @dev Returns the balance of `account`.
     */
    // function _getVotingUnits(address account) internal view returns (uint256) {
        // return _votingUnits[msg.sender][account];
    // }
    function _getVotingUnits(uint256 account) internal view returns (uint256) {
        return _votingUnits[msg.sender][account];
    }


    //** Core

    using CheckpointsUpgradeable for CheckpointsUpgradeable.History;
    using CountersUpgradeable for CountersUpgradeable.Counter;


    bytes32 private constant _DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    // mapping(address => address) private _delegation;
    // mapping(address => mapping(address => address)) private _delegation;
    mapping(address => mapping(uint256 => uint256)) private _delegation;
    
    // mapping(address => CheckpointsUpgradeable.History) private _delegateCheckpoints;
    // mapping(address => mapping(address => CheckpointsUpgradeable.History)) private _delegateCheckpoints;
    mapping(address => mapping(uint256 => CheckpointsUpgradeable.History)) private _delegateCheckpoints;

    // CheckpointsUpgradeable.History private _totalCheckpoints;
    mapping(address => CheckpointsUpgradeable.History) private _totalCheckpoints;

    // mapping(address => CountersUpgradeable.Counter) private _nonces;
    // mapping(address => mapping(address => CountersUpgradeable.Counter)) private _nonces;
    mapping(address => mapping(uint256 => CountersUpgradeable.Counter)) private _nonces;


    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account) public view virtual override returns (uint256) {
        // return _delegateCheckpoints[msg.sender][account].latest();
        return getVotesForToken(getExtTokenId(account));
    }
    function getVotesForToken(uint256 account) public view virtual override returns (uint256) {
        return _delegateCheckpoints[msg.sender][account].latest();
    }

    /**
     * @dev Returns the amount of votes that `account` had at the end of a past block (`blockNumber`).
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastVotes(address account, uint256 blockNumber) public view virtual override returns (uint256) {
        // return _delegateCheckpoints[msg.sender][account].getAtBlock(blockNumber);
        return getPastVotesForToken(getExtTokenId(account), blockNumber);
    }
    function getPastVotesForToken(uint256 account, uint256 blockNumber) public view virtual override returns (uint256) {
        return _delegateCheckpoints[msg.sender][account].getAtBlock(blockNumber);
    }

    /**
     * @dev Returns the total supply of votes available at the end of a past block (`blockNumber`).
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastTotalSupply(uint256 blockNumber) public view virtual override returns (uint256) {
        require(blockNumber < block.number, "VotesRepo: block not yet mined");
        return _totalCheckpoints[msg.sender].getAtBlock(blockNumber);
    }

    /**
     * @dev Returns the current total supply of votes.
     */
    function _getTotalSupply() internal view virtual returns (uint256) {
        return _totalCheckpoints[msg.sender].latest();
    }

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address account) public view virtual override returns (address) {
        // return _delegation[msg.sender][account];
        return _getAccount( delegatesToken(getExtTokenId(account)) );
    }
    function delegatesToken(uint256 accountToken) public view virtual override returns (uint256) {
        return _delegation[msg.sender][accountToken];
    }

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) public virtual override {
        // address account = _msgSender();
        address account = tx.origin;
        _delegate(account, delegatee);
    }

    /**
     * @dev Delegates votes from signer to `delegatee`.
     */
    function delegateBySig(address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) public virtual override {
        require(block.timestamp <= expiry, "VotesRepo: signature expired");
        address signer = ECDSAUpgradeable.recover(
            _hashTypedDataV4(keccak256(abi.encode(_DELEGATION_TYPEHASH, delegatee, nonce, expiry))),
            v, r, s
        );
        require(nonce == _useNonce(getExtTokenId(signer)), "VotesRepo: invalid nonce");
        _delegate(signer, delegatee);
    }

    /**
     * @dev Delegate all of `account`'s voting units to `delegatee`.
     *
     * Emits events {DelegateChanged} and {DelegateVotesChanged}.
     */
    function _delegate(address account, address delegatee) internal virtual {
        return _delegateToken(getExtTokenId(account), getExtTokenId(delegatee));
    }
    function _delegateToken(uint256 account, uint256 delegatee) internal virtual {
        // address oldDelegate = delegates(account);
        uint256 oldDelegate = delegatesToken(account);
        _delegation[msg.sender][account] = delegatee;
        emit DelegateChanged(_getAccount(account), _getAccount(oldDelegate), _getAccount(delegatee));   //For Backward Compatibility (Should Not be Trusted)
        emit DelegateChangedToken(account, oldDelegate, delegatee);
        _moveDelegateVotes(oldDelegate, delegatee, _getVotingUnits(account));
    }

    /**
     * @dev Transfers, mints, or burns voting units. To register a mint, `from` should be zero. To register a burn, `to`
     * should be zero. Total supply of voting units will be adjusted with mints and burns.
     */
    // function _transferVotingUnits(address from, address to, uint256 amount) internal virtual {
    function _transferVotingUnits(uint256 from, uint256 to, uint256 amount) internal virtual {
        // if (from == address(0)) {
        if (from == 0) {
            _totalCheckpoints[msg.sender].push(_add, amount);
        }
        // if (to == address(0)) {
        if (to == 0) {
            _totalCheckpoints[msg.sender].push(_subtract, amount);
        }
        _moveDelegateVotes(delegatesToken(from), delegatesToken(to), amount);
    }

    /**
     * @dev Moves delegated votes from one delegate to another.
     */
    // function _moveDelegateVotes(address from, address to, uint256 amount) private {
    function _moveDelegateVotes(uint256 from, uint256 to, uint256 amount) private {
        if (from != to && amount > 0) {
            // if (from != address(0)) {
            if (from != 0) {
                (uint256 oldValue, uint256 newValue) = _delegateCheckpoints[msg.sender][from].push(_subtract, amount);
                // emit DelegateVotesChanged(from, oldValue, newValue);
                emit DelegateVotesChanged(_getAccount(from), oldValue, newValue);   //For Backward Compatibility (Should Not be Trusted)
                emit DelegateVotesChangedToken(from, oldValue, newValue);
            }
            // if (to != address(0)) {
            if (to != 0) {
                (uint256 oldValue, uint256 newValue) = _delegateCheckpoints[msg.sender][to].push(_add, amount);
                // emit DelegateVotesChanged(to, oldValue, newValue);
                emit DelegateVotesChanged(_getAccount(to), oldValue, newValue);   //For Backward Compatibility (Should Not be Trusted)
                emit DelegateVotesChangedToken(to, oldValue, newValue);
            }
        }
    }

    function _add(uint256 a, uint256 b) private pure returns (uint256) {
        return a + b;
    }

    function _subtract(uint256 a, uint256 b) private pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Consumes a nonce.
     *
     * Returns the current value and increments nonce.
     */
    function _useNonce(uint256 owner) internal virtual returns (uint256 current) {
        CountersUpgradeable.Counter storage nonce = _nonces[msg.sender][owner];
        current = nonce.current();
        nonce.increment();
    }

    /**
     * @dev Returns an address nonce.
     */
    function nonces(address owner) public view virtual returns (uint256) {
        // return _nonces[msg.sender][owner].current();
        return noncesForToken(getExtTokenId(owner));
    }
    function noncesForToken(uint256 owner) public view virtual returns (uint256) {
        return _nonces[msg.sender][owner].current();
    }

    /**
     * @dev Returns the contract's {EIP712} domain separator.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    /** MOVED
     * @dev Must return the voting units held by an account.
     * /
    function _getVotingUnits(address) internal view virtual returns (uint256);

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
}