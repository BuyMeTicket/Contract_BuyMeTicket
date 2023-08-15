// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface ITicketEvent {
    event Withdrawn(address indexed _eventHolder, uint256 indexed _weiAmount);
}
