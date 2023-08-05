// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface IGlobals {
    //** events */
    event ValidEventHolderSet(address indexed eventHolder, bool indexed isValid);

    //** allow list function */

    function setValidEventHolder(address _eventHolder, bool _isValid) external;

    //** view function */

    // mapping(address => bool) public isEventHolders;
    function isValidEventHolder(address _eventHolder) external view returns (bool);
}
