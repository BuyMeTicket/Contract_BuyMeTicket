// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./BaseTest.t.sol";
import {ITicketFactoryEvent} from "../src/interfaces/ITicketFactoryEvent.sol";
import {ITicketEvent} from "../src/interfaces/ITicketEvent.sol";
import {Ticket} from "../src/Ticket.sol";

contract TicketFactoryTest is BaseTest, ITicketFactoryEvent, ITicketEvent {
    function setUp() public override {
        super.setUp();
    }

    function test_creatEvent() public {
        (address eventAddress, uint256 eventId) = _setUpEvent();
        // assertions
        assertEq(eventId, 0);
    }

    function test_mintEventTicket() public {
        (address eventAddress, uint256 eventId) = _setUpEvent();
        Ticket ticket = Ticket(eventAddress);

        // mint ticket
        vm.startPrank(EVENT_PARTICIPANT);
        usdt.approve(eventAddress, 600e18);
        vm.expectEmit(true, true, true, true);
        emit ERC1155Minted(EVENT_PARTICIPANT, eventAddress, 3);
        ticketFactory.mintEventTicket(eventId, 1, 3); // mint 3 testB tickets for event 0
        vm.stopPrank();

        // assertions
        assertEq(address(ticket), eventAddress);
        assertEq(ticket.owner(), address(ticketFactory));
        assertEq(ticket.balanceOf(EVENT_PARTICIPANT, 1), 3);
        assertEq(ticket.balanceOf(EVENT_PARTICIPANT, 0), 0);
        assertEq(usdt.allowance(EVENT_PARTICIPANT, address(ticket)), 0);
        assertEq(usdt.balanceOf(address(ticket)), 600e18);
        assertEq(usdt.balanceOf(EVENT_PARTICIPANT), 1_000_000e18 - 600e18);
    }

    function test_refundEventTicket() public {
        (address eventAddress, uint256 eventId) = _setUpEvent();
        Ticket ticket = Ticket(eventAddress);

        // mint ticket
        vm.startPrank(EVENT_PARTICIPANT);
        usdt.approve(eventAddress, 600e18);
        ticketFactory.mintEventTicket(eventId, 1, 3); // mint 3 testB tickets for event 0

        // refund ticket
        vm.expectEmit(true, true, true, true);
        emit ERC1155Refunded(EVENT_PARTICIPANT, eventAddress, 3);
        // assume 5 days passed
        vm.warp(block.timestamp + 5 days);

        uint256 refundAmount = ticketFactory.refundEventTicket(eventId, 1, 3); // refund 3 testB tickets for event 0
        vm.stopPrank();

        // assertions
        assertEq(ticket.balanceOf(EVENT_PARTICIPANT, 1), 0);
        assertEq(ticket.balanceOf(EVENT_PARTICIPANT, 0), 0);
        assertEq(usdt.balanceOf(address(ticket)), 600e18 - refundAmount);
        assertEq(usdt.balanceOf(EVENT_PARTICIPANT), 1_000_000e18 - 600e18 + refundAmount);
    }

    function testFuzz_refundEventTicket(uint256 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount < 60);
        (address eventAddress, uint256 eventId) = _setUpEvent();
        Ticket ticket = Ticket(eventAddress);

        // mint ticket
        vm.startPrank(EVENT_PARTICIPANT);
        usdt.approve(eventAddress, 600e18);
        ticketFactory.mintEventTicket(eventId, 1, 3); // mint 3 testB tickets for event 0

        // refund ticket
        vm.expectEmit(true, true, true, true);
        emit ERC1155Refunded(EVENT_PARTICIPANT, eventAddress, 3);
        vm.warp(block.timestamp + amount * 1 days);
        uint256 refundAmount = ticketFactory.refundEventTicket(eventId, 1, 3); // refund 3 testB tickets for event 0
        vm.stopPrank();

        // assertions
        assertEq(ticket.balanceOf(EVENT_PARTICIPANT, 1), 0);
        assertEq(ticket.balanceOf(EVENT_PARTICIPANT, 0), 0);
        assertEq(usdt.balanceOf(address(ticket)), 600e18 - refundAmount);
        assertEq(usdt.balanceOf(EVENT_PARTICIPANT), 1_000_000e18 - 600e18 + refundAmount);
    }

    function test_withdraw() public {
        (address eventAddress, uint256 eventId) = _setUpEvent();
        Ticket ticket = Ticket(eventAddress);

        // mint ticket
        vm.startPrank(EVENT_PARTICIPANT);
        usdt.approve(eventAddress, 600e18);
        ticketFactory.mintEventTicket(eventId, 1, 3); // mint 3 testB tickets for event 0

        // withdraw
        changePrank(EVENT_HOLDER);

        vm.expectEmit(true, true, true, true);
        emit Withdrawn(EVENT_HOLDER, 600e18);

        ticket.withdraw();
        vm.stopPrank();

        // assertions
        assertEq(usdt.balanceOf(address(ticket)), 0);
        assertEq(usdt.balanceOf(EVENT_HOLDER), 1_000_000e18 + 600e18);
    }

    function _max(UD60x18 _a, UD60x18 _b) internal pure returns (UD60x18 _maximum) {
        _maximum = _a.gt(_b) ? _a : _b;
    }

    //** Helper Functions */
    function _setUpEvent() internal returns (address _eventAddress, uint256 _eventId) {
        vm.prank(EVENT_HOLDER);
        // create event
        (_eventAddress, _eventId) = ticketFactory.createEvent(
            msg.sender,
            address(usdt),
            "test",
            "testURI",
            10,
            block.timestamp,
            block.timestamp + 60 days,
            _dynamicMintPrices(),
            _dynamicMaxSupply(),
            _dynamicString(),
            _dynamicIds()
        );
    }

    // below are helper functions to create dynamic arrays for testing
    function _dynamicMintPrices() internal pure returns (uint256[] memory uint256s) {
        uint256s = new uint256[](3);
        uint256s[0] = 300e18;
        uint256s[1] = 200e18;
        uint256s[2] = 100e18;
    }

    function _dynamicMaxSupply() internal pure returns (uint256[] memory uint256s) {
        uint256s = new uint256[](3);
        uint256s[0] = 100;
        uint256s[1] = 200;
        uint256s[2] = 300;
    }

    function _dynamicIds() internal pure returns (uint256[] memory ids) {
        ids = new uint256[](3);
        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 2;
    }

    function _dynamicString() internal pure returns (string[] memory names) {
        names = new string[](3);
        names[0] = "testA";
        names[1] = "testB";
        names[2] = "testC";
    }
}
