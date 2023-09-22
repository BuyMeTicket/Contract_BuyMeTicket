// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./BaseTest.t.sol";
import {FundingPool} from "../src/FundingPool.sol";

contract FundingPoolTest is BaseTest {
    FundingPool public fundingPool;

    function setUp() public override {
        super.setUp();

        changePrank(EVENT_HOLDER);
        (address poolAddress, uint256 poolId) = fundingPoolFactory.createPool(
            address(usdt), block.timestamp + 1 days, block.timestamp + 31 days, 100_000e18
        );
        fundingPool = FundingPool(poolAddress);
    }

    function test_IsPoolOpen() external {
        assertEq(fundingPool.isPoolOpen(), false);

        vm.warp(block.timestamp + 1 days);
        assertEq(fundingPool.isPoolOpen(), true);
    }

}