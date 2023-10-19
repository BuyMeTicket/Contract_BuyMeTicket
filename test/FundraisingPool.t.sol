// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./BaseTest.t.sol";
import {FundraisingPool} from "../src/FundraisingPool.sol";

contract FundraisingPoolTest is BaseTest {
    FundraisingPool public fundraisingPool;

    function setUp() public override {
        super.setUp();

        changePrank(EVENT_HOLDER);
        (address poolAddress, uint256 poolId) = fundraisingPoolFactory.createPool(
            address(usdt), block.timestamp + 1 days, block.timestamp + 31 days, 100_000e18
        );
        fundraisingPool = FundraisingPool(poolAddress);

        // let donater as the default msg.sender
        changePrank(DONATER);
        usdt.approve(address(fundraisingPool), type(uint256).max);
    }

    function test_IsPoolOpen() external {
        assertEq(fundraisingPool.isPoolOpen(), false);

        vm.warp(block.timestamp + 1 days);
        assertEq(fundraisingPool.isPoolOpen(), true);
    }

    function test_Deposit_RevertWhen_PoolNotOpen() external {
        vm.expectRevert(bytes("FundraisingPool: pool not open"));
        fundraisingPool.deposit(100e18);

        vm.warp(block.timestamp + 31 days + 1);
        vm.expectRevert(bytes("FundraisingPool: pool not open"));
        fundraisingPool.deposit(100e18);
    }

    function test_Deposit() external {
        vm.warp(block.timestamp + 1 days);
        fundraisingPool.deposit(100e18);
        assertEq(usdt.balanceOf(address(fundraisingPool)), 100e18);
        assertEq(usdt.balanceOf(DONATER), 999_900e18);

        assertEq(fundraisingPool.userDepositInfo(DONATER), 100e18);
    }

    function test_Withdraw_RevertWhen_NotAdmin() external {
        vm.expectRevert(bytes("FundraisingPool: only admin"));
        fundraisingPool.withdraw();
    }

    function test_Withdraw_RevertWhen_PoolNotClosed() external {
        vm.warp(block.timestamp + 1 days);
        fundraisingPool.deposit(100_000e18);
        changePrank(EVENT_HOLDER);
        vm.expectRevert(bytes("FundraisingPool: pool not closed"));
        fundraisingPool.withdraw();
    }

    function test_Withdraw_RevertWhen_TargetNotReached() external {
        vm.warp(block.timestamp + 31 days + 1);
        changePrank(EVENT_HOLDER);
        vm.expectRevert(bytes("FundraisingPool: target not reached"));
        fundraisingPool.withdraw();
    }

    function test_Withdraw() external {
        vm.warp(block.timestamp + 1 days);
        fundraisingPool.deposit(500_000e18);

        vm.warp(block.timestamp + 30 days + 1);
        changePrank(EVENT_HOLDER);
        fundraisingPool.withdraw();

        assertEq(usdt.balanceOf(address(fundraisingPool)), 0);
        assertEq(usdt.balanceOf(EVENT_HOLDER), 1_000_000e18 + 500_000e18);
    }
}
