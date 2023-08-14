// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Globals} from "../src/Globals.sol";
import {TicketFactory} from "../src/TicketFactory.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {PRBTest} from "@prb-test/PRBTest.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {console} from "forge-std/console.sol";

abstract contract BaseTest is PRBTest, StdCheats {
    ERC20 internal usdt;

    Globals public globals;
    TicketFactory public ticketFactory;

    address payable GOVERNOR;
    address payable EVENT_HOLDER;
    address payable EVENT_PARTICIPANT;

    function setUp() public virtual {
        usdt = new ERC20("USDT Stablecoin", "USDT");

        // create all the users
        GOVERNOR = createUser("GOVERNOR");
        EVENT_HOLDER = createUser("EVENT_HOLDER");
        EVENT_PARTICIPANT = createUser("EVENT_PARTICIPANT");

        // deploy globals and set the governor
        globals = new Globals(GOVERNOR);
        vm.prank(GOVERNOR);
        globals.setValidEventHolder(EVENT_HOLDER, true);

        // deploy the ticket factory and set the globals address
        ticketFactory = new TicketFactory(address(globals));

        // label the base test contract
        vm.label(address(usdt), "USDT");
        vm.label(address(globals), "Globals");
        vm.label(address(ticketFactory), "TicketFactory");
    }

    function test_setUpState() public {
        assertEq(globals.governor(), GOVERNOR);
        assertEq(usdt.balanceOf(GOVERNOR), 1_000_000e18);
        assertEq(usdt.balanceOf(EVENT_HOLDER), 1_000_000e18);
        assertEq(usdt.balanceOf(EVENT_PARTICIPANT), 1_000_000e18);
        assertTrue(globals.isValidEventHolder(EVENT_HOLDER));
    }

    /// @dev Generates a user, labels its address, and funds it with test assets.
    function createUser(string memory name) internal returns (address payable) {
        address payable user = payable(makeAddr(name));
        vm.deal({account: user, newBalance: 100 ether});
        deal({token: address(usdt), to: user, give: 1_000_000e18});
        return user;
    }
}
