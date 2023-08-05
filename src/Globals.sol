// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {IGlobals} from "./interfaces/IGlobals.sol";

contract Globals is IGlobals {
    //** Storage Functions - for storing data */
    mapping(address => bool) public isEventHolders;

    //** allow list function */
    function setValidEventHolder(address _eventHolder, bool _isValid) external override {
        require(_eventHolder != address(0), "Globals: _eventHolder is zero address");
        isEventHolders[_eventHolder] = _isValid;
        emit ValidEventHolderSet(_eventHolder, _isValid);
    }

    //** view function */
    function isValidEventHolder(address _eventHolder) external view override returns (bool) {
        return isEventHolders[_eventHolder];
    }
}
