// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface ITask {

    //** Already Supported

    /// Initialize
    // function initialize(address hub, string calldata name_, string calldata uri_) external payable;

    /// Arbitrary contract symbol
    // function symbol() external view returns (string memory);


    /// Apply (Nominte Self)
    function application(string memory uri_) external;

    /// Accept Application (Assign Role)
    function acceptApplicant(uint256 sbtId) external;

    /// Deliver (Just use the Post function directly)

    /// Approve Delivery (Close Case w/Positive Verdict)
    function deliveryApprove(uint256 sbtId) external;

    /// Reject Application (Ignore / dApp Function)
    
    /// Reject Delivery
    function deliveryReject(uint256 sbtId, string calldata uri_) external;
    
    /// Withdraw -- Disburse all funds to participants
    function disburse(address[] memory tokens) external;

    /// Cancel Task
    function cancel(string calldata uri_, address[] memory tokens) external;

    /// Refund -- Send Tokens back to Task Creator
    function refund(address[] memory tokens) external;

    /// Deposit (Anyone can send funds at any point)

    //--- Events

    /// Delivery from sbtId was Rejected by Account
    event DeliveryRejected(address admin, uint256 sbtId, string uri);

}