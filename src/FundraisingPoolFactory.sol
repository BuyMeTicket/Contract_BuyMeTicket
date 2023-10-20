// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {FundraisingPool} from "./FundraisingPool.sol";
import {IFundraisingPoolFactory} from "./interfaces/IFundraisingPoolFactory.sol";
import {IGlobals} from "./interfaces/IGlobals.sol";

contract FundraisingPoolFactory is IFundraisingPoolFactory {
    //** Modifier */

    modifier onlyEventHolder() {
        require(globals.isValidEventHolder(msg.sender), "TicketFactory: only valid event holder");
        _;
    }

    modifier onlyGovernor() {
        require(msg.sender == globals.governor(), "TicketFactory: only governor");
        _;
    }

    //** Storage */
    IGlobals public globals;
    FundraisingPool[] public fundraisingPools;

    constructor(address _globals) {
        globals = IGlobals(_globals);
    }

    //** Normal Functions */

    function createPool(address _fundAsset, uint256 _startTimestamp, uint256 _endTimestamp, uint256 _targetAmount)
        public
        override
        onlyEventHolder
        returns (address _poolAddress, uint256 _poolId)
    {
        require(_fundAsset != address(0), "FundraisingPoolFactory: fund asset is zero address");
        require(_startTimestamp > block.timestamp, "FundraisingPoolFactory: start timestamp must be in the future");
        require(_endTimestamp > _startTimestamp, "FundraisingPoolFactory: end timestamp must be after start timestamp");
        require(_targetAmount > 0, "FundraisingPoolFactory: target amount must be greater than zero");

        FundraisingPool pool =
            new FundraisingPool(_fundAsset, msg.sender, _startTimestamp, _endTimestamp, _targetAmount);
        fundraisingPools.push(pool);
        emit FundraisingPoolCreated(msg.sender, address(pool), fundraisingPools.length - 1);
        return (address(pool), fundraisingPools.length - 1);
    }
}
