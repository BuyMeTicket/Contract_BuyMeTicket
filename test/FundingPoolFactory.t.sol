// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./BaseTest.t.sol";

contract FundingPoolFactoryTest is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    function test_CreatePool() external {
        changePrank(EVENT_HOLDER);
        (address poolAddress, uint256 poolId) = fundingPoolFactory.createPool(
            address(usdt), block.timestamp + 1 days, block.timestamp + 31 days, 100_000e18
        );
    }
}
