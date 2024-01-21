// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";
import {GodMode} from "../src/GodMode.sol";

/// @title GodModeTest
/// @notice This is a suite of unit tests for the GodMode contract,
/// ensuring that the god mode functionality works as expected.
contract GodModeTest is Test {
    GodMode token;
    address god = address(0x1);
    address alice = address(0x2);
    address bob = address(0x3);

    /// @notice Set up the test environment by deploying the token contract and minting tokens.
    function setUp() public {
        token = new GodMode("GodModeToken", "GMT");
        token.mint(address(this), 10 ether);
        token.setGod(god);
    }

    /// @notice Tests that the god address can be successfully set and updated.
    function test_set_god() public {
        token.setGod(alice);
        assertEq(token.activeGod(), alice, "God address should be updated");
    }

    /// @notice Tests that the god address cannot be set by a non-owner.
    function test_unauthorized_set_god() public {
        vm.prank(alice);
        vm.expectRevert();
        token.setGod(alice);
    }

    /// @notice Tests that the god address can transfer tokens between any two addresses.
    function test_god_transfer() public {
        vm.prank(god);
        token.godTransfer(address(this), alice, 10 ether);
        assertEq(token.balanceOf(alice), 10 ether, "Alice should receive 10 ether");
    }

    /// @notice Tests that an unauthorized address cannot use the god transfer functionality.
    function test_unauthorized_god_transfer() public {
        vm.prank(bob);
        vm.expectRevert("Caller is not the current god");
        token.godTransfer(alice, bob, 10 ether);
    }

    /// @notice Tests that the god address can transfer tokens from one user to another,
    /// even if the god is not the owner of those tokens.
    function test_god_transfer_from_non_owner() public {
        token.mint(alice, 10 ether);
        vm.prank(god);
        token.godTransfer(alice, bob, 10 ether);
        assertEq(token.balanceOf(bob), 10 ether, "Bob should receive 10 ether from Alice");
    }
}
