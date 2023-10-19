// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./BaseTest.t.sol";

contract FundraisingPoolFactoryTest is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    function test_CreatePool() external {
        changePrank(EVENT_HOLDER);
        (address poolAddress, uint256 poolId) = fundraisingPoolFactory.createPool(
            address(usdt), block.timestamp + 1 days, block.timestamp + 31 days, 100_000e18
        );
        assertEq(poolAddress, address(fundraisingPoolFactory.fundraisingPools(0)));
        assertEq(poolId, 0);
    }
}
