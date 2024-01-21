// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {UntrustedEscrow} from "../src/UntrustedEscrow.sol";
import {ERC20Mock} from "./mocks/ERC20Mock.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC777Mock} from "./mocks/ERC777Mock.sol";

contract UntrustedEscrowTest is Test {
    UntrustedEscrow escrow;
    ERC20Mock tokenERC20;
    // ERC777Mock tokenERC777;

    address creator = address(0x1);
    address beneficiary = address(0x2);
    address attacker = address(0x3);
    uint256 amount = 100 ether;

    function setUp() public {
        tokenERC20 = new ERC20Mock("Test ERC20", "TST");
        escrow = new UntrustedEscrow();

        tokenERC20.mint(creator, amount);
        vm.prank(creator);
        tokenERC20.approve(address(escrow), amount);

        // TODO: Mock ERC777 deployment
        // tokenERC777 = new ERC777Mock("Test ERC777", "TSTS", new address[](0), 1000 ether, creator);

        // tokenERC777.mint(creator, amount, "0x", "0x");
        // vm.prank(creator);
        // tokenERC777.approve(address(escrow), amount);
    }

    function testCreateTokenEscrow() public {
        vm.startPrank(creator);
        vm.expectEmit(true, true, true, true);
        emit UntrustedEscrow.EscrowCreated(0, address(tokenERC20), creator, beneficiary, amount);
        uint256 escrowId = escrow.createTokenEscrow(address(tokenERC20), beneficiary, amount);
        vm.stopPrank();

        UntrustedEscrow.TokenEscrow memory createdEscrow = escrow.getEscrowDetails(escrowId);
        assertEq(createdEscrow.escrowedToken, address(tokenERC20));
        assertEq(createdEscrow.escrowCreator, creator);
        assertEq(createdEscrow.escrowBeneficiary, beneficiary);
        assertEq(createdEscrow.escrowedAmount, amount);
        assertEq(createdEscrow.releaseTime, block.timestamp + 3 days);
    }

    // TODO: Test ERC777 interaction when mock is working
    // function testCreateTokenEscrowWithERC777() public {
    //     vm.startPrank(creator);
    //     vm.expectEmit(true, true, true, true);
    //     emit UntrustedEscrow.EscrowCreated(0, address(tokenERC777), creator, beneficiary, amount);
    //     uint256 escrowId = escrow.createTokenEscrow(address(tokenERC777), beneficiary, amount);
    //     vm.stopPrank();

    //     UntrustedEscrow.TokenEscrow memory createdEscrow = escrow.getEscrowDetails(escrowId);
    //     assertEq(createdEscrow.escrowedToken, address(tokenERC777));
    //     assertEq(createdEscrow.escrowCreator, creator);
    //     assertEq(createdEscrow.escrowBeneficiary, beneficiary);
    //     assertEq(createdEscrow.escrowedAmount, amount);
    //     assertEq(createdEscrow.releaseTime, block.timestamp + 3 days);
    // }

    function testSuccessfulReleaseTokenEscrow() public {
        uint256 initialBalance = IERC20(tokenERC20).balanceOf(beneficiary);

        vm.startPrank(creator);
        uint256 escrowId = escrow.createTokenEscrow(address(tokenERC20), beneficiary, amount);
        vm.stopPrank();

        vm.warp(block.timestamp + 3 days); // Fast forward time past the lock period
        vm.startPrank(beneficiary);
        vm.expectEmit(true, true, true, true);
        emit UntrustedEscrow.EscrowReleased(escrowId, beneficiary);
        escrow.releaseTokenEscrow(escrowId);
        assertEq(IERC20(tokenERC20).balanceOf(beneficiary), initialBalance + 100 ether);
    }

    function testEarlyReleaseTokenEscrow() public {
        vm.startPrank(creator);
        uint256 escrowId = escrow.createTokenEscrow(address(tokenERC20), beneficiary, amount);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days); // Fast forward time, but not enough
        vm.prank(beneficiary);
        vm.expectRevert("Escrow is still locked");
        escrow.releaseTokenEscrow(escrowId);
    }

    function testUnauthorizedReleaseTokenEscrow() public {
        vm.startPrank(creator);
        uint256 escrowId = escrow.createTokenEscrow(address(tokenERC20), beneficiary, amount);
        vm.stopPrank();

        vm.warp(block.timestamp + 3 days); // Fast forward time
        vm.prank(attacker);
        vm.expectRevert("Only beneficiary can release");
        escrow.releaseTokenEscrow(escrowId);
    }
}
