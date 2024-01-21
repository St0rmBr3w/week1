// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {SanctionedToken} from "../src/SanctionedToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title SanctionedTokenTest
/// @notice This is a suite of unit tests for the SanctionedToken contract,
/// ensuring that the token minting, transferring, and banning functionalities
/// work as expected.
contract SanctionedTokenTest is Test {
    SanctionedToken token;

    address public sender = payable(address(0x1));
    address public receiver = payable(address(0x2));

    /// @notice Set up the test environment by deploying the token contract and minting tokens.
    function setUp() public {
        token = new SanctionedToken("SanctionedToken", "STK");
        token.mint(address(sender), 10 ether);
        token.mint(address(receiver), 10 ether);
    }

    /// @notice Tests that a transfer of tokens between two non-banned addresses is successful.
    function testTransfer() public {
        vm.prank(sender);
        uint256 amountToSend = 1 ether;
        token.transfer(address(receiver), amountToSend);
        assertTrue(token.balanceOf(sender) == 9 ether);
        assertTrue(token.balanceOf(receiver) == 11 ether);
    }

    /// @notice Tests that an address can be successfully banned.
    function testBanAddress() public {
        token.banAddress(sender);
        assertTrue(token.isBanned(sender));
    }

    /// @notice Tests that a previously banned address can be successfully unbanned.
    function testUnbanAddress() public {
        token.banAddress(sender);
        token.unbanAddress(sender);
        assertFalse(token.isBanned(sender));
    }

    /// @notice Tests that a transfer from a banned address is reverted.
    function test_transfer_Banned() public {
        token.banAddress(sender);
        vm.expectRevert();
        token.transfer(sender, 1 ether);
    }

    /// @notice Tests that a transferFrom initiated by a banned sender is reverted.
    function test_transferFrom_Banned_Sender() public {
        token.banAddress(sender);
        vm.prank(sender);
        vm.expectRevert();
        token.transferFrom(sender, receiver, 1 ether);
    }

    /// @notice Tests that a transferFrom to a banned receiver is reverted.
    function test_TransferFrom_Banned_Receiver() public {
        token.banAddress(receiver);
        vm.prank(sender);
        vm.expectRevert();
        token.transferFrom(sender, receiver, 1 ether);
    }
}
