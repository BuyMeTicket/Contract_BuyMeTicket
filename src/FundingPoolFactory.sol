// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {FundingPool} from "./FundingPool.sol";
import {IFundingPoolFactory} from "./interfaces/IFundingPoolFactory.sol";
import {IGlobals} from "./interfaces/IGlobals.sol";

contract FundingPoolFactory is IFundingPoolFactory {
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
    FundingPool[] public fundingPools;

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
        require(_fundAsset != address(0), "FundingPoolFactory: fund asset is zero address");
        require(_startTimestamp > block.timestamp, "FundingPoolFactory: start timestamp must be in the future");
        require(_endTimestamp > _startTimestamp, "FundingPoolFactory: end timestamp must be after start timestamp");
        require(_targetAmount > 0, "FundingPoolFactory: target amount must be greater than zero");

        FundingPool pool = new FundingPool(_fundAsset, msg.sender, _startTimestamp, _endTimestamp, _targetAmount);
        fundingPools.push(pool);
        emit FundingPoolCreated(msg.sender, address(pool), fundingPools.length - 1);
        return (address(pool), fundingPools.length - 1);
    }
}
