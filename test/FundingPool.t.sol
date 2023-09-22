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

        // let donater as the default msg.sender
        changePrank(DONATER);
        usdt.approve(address(fundingPool), type(uint256).max);
    }

    function test_IsPoolOpen() external {
        assertEq(fundingPool.isPoolOpen(), false);

        vm.warp(block.timestamp + 1 days);
        assertEq(fundingPool.isPoolOpen(), true);
    }

    function test_Deposit_RevertWhen_PoolNotOpen() external {
        vm.expectRevert(bytes("FundingPool: pool not open"));
        fundingPool.deposit(100e18);

        vm.warp(block.timestamp + 31 days + 1);
        vm.expectRevert(bytes("FundingPool: pool not open"));
        fundingPool.deposit(100e18);
    }

    function test_Deposit() external {
        vm.warp(block.timestamp + 1 days);
        fundingPool.deposit(100e18);
        assertEq(usdt.balanceOf(address(fundingPool)), 100e18);
        assertEq(usdt.balanceOf(DONATER), 999_900e18);

        assertEq(fundingPool.userDepositInfo(DONATER), 100e18);
    }

    function test_Withdraw_RevertWhen_NotAdmin() external {
        vm.expectRevert(bytes("FundingPool: only admin"));
        fundingPool.withdraw();
    }

    function test_Withdraw_RevertWhen_PoolNotClosed() external {
        vm.warp(block.timestamp + 1 days);
        fundingPool.deposit(100_000e18);
        changePrank(EVENT_HOLDER);
        vm.expectRevert(bytes("FundingPool: pool not closed"));
        fundingPool.withdraw();
    }

    function test_Withdraw_RevertWhen_TargetNotReached() external {
        vm.warp(block.timestamp + 31 days + 1);
        changePrank(EVENT_HOLDER);
        vm.expectRevert(bytes("FundingPool: target not reached"));
        fundingPool.withdraw();
    }

    function test_Withdraw() external {
        vm.warp(block.timestamp + 1 days);
        fundingPool.deposit(500_000e18);

        vm.warp(block.timestamp + 30 days + 1);
        changePrank(EVENT_HOLDER);
        fundingPool.withdraw();

        assertEq(usdt.balanceOf(address(fundingPool)), 0);
        assertEq(usdt.balanceOf(EVENT_HOLDER), 1_000_000e18 + 500_000e18);
    }
}
