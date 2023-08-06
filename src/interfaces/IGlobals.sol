// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface IGlobals {
    //** events */
    event ValidEventHolderSet(address indexed eventHolder, bool indexed isValid);

    event GovernorTransferred(address _previousGovernor, address _newGovernor);

    event CreateEventFeeSet(uint256 _fee);

    //** allow list function */

    function setValidEventHolder(address _eventHolder, bool _isValid) external;

    //** Setter Functions */
    function setCreateEventFee(uint256 _fee) external;

    //** view function */
    function governor() external view returns (address);

    function createEventFee() external view returns (uint256);

    function isValidEventHolder(address _eventHolder) external view returns (bool);

    //** Governor Transfer Functions */

    function transferGovernor(address _newGovernor) external;
}
