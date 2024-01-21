// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/ContinuousToken.sol";
import "./mocks/ERC20Mock.sol";

/// @title ContinuousTokenTest
/// @notice Test suite for the ContinuousToken smart contract
contract ContinuousTokenTest is Test {
    ContinuousToken continuousToken;
    ERC20Mock mockReserveToken;

    address alice = address(0x1);
    address bob = address(0x2);
    address attacker = address(0x3);
    uint256 public initialBalance = 1000 ether;

    /// @notice Set up the test environment by deploying ContinuousToken and ERC20Mock as the ReserveToken
    function setUp() public {
        mockReserveToken = new ERC20Mock("Reserve Token", "RSRV");
        continuousToken = new ContinuousToken(
            address(mockReserveToken),
            "Continuous Token",
            "CNTU"
        );

        mockReserveToken.mint(alice, initialBalance);
        mockReserveToken.mint(bob, initialBalance);
        mockReserveToken.mint(attacker, initialBalance);

        vm.prank(alice);
        mockReserveToken.approve(address(continuousToken), type(uint256).max);

        vm.prank(bob);
        mockReserveToken.approve(address(continuousToken), type(uint256).max);

        vm.prank(attacker);
        mockReserveToken.approve(address(continuousToken), type(uint256).max);
    }

    /// @notice Tests the minting functionality of the ContinuousToken contract
    /// @dev Checks if the minted amount matches the expected amount and if the reserve balance updates correctly
    function testMintingFunctionality() public {
        uint256 depositAmount = 100 ether;

        vm.startPrank(alice);
        uint256 initialReserveBalance = continuousToken.reserveBalance();
        uint256 expectedMintAmount = continuousToken.getContinuousMintAmount(depositAmount);
        uint256 mintAmount = continuousToken.mint(depositAmount);
        vm.stopPrank();

        assertEq(mintAmount, expectedMintAmount, "Minted amount does not match expected amount");
        assertEq(
            continuousToken.reserveBalance(),
            initialReserveBalance + depositAmount,
            "Reserve balance did not update correctly"
        );
    }

    /// @notice Tests that burning tokens before the cooldown period ends results in a revert
    /// @dev Ensures that the contract enforces the cooldown period for token burning
    function testBurningRevertsForCooldown() public {
        uint256 depositAmount = 100 ether;

        vm.startPrank(alice);
        uint256 mintAmount = continuousToken.mint(depositAmount);
        uint256 burnAmount = mintAmount;
        vm.expectRevert("Cooldown period not yet elapsed");
        continuousToken.burn(burnAmount);
    }

    /// @notice Tests the accuracy of the getContinuousBurnAmount function
    /// @dev Verifies that the amount returned by getContinuousBurnAmount matches the actual return amount from burning
    function testGetContinuousBurnAmountAccuracy() public {
        uint256 depositAmount = 100 ether;

        vm.startPrank(alice);
        uint256 mintAmount = continuousToken.mint(depositAmount);
        uint256 burnAmount = mintAmount;
        initialBalance = continuousToken.balanceOf(alice);
        uint256 expectedReturnAmount = continuousToken.getContinuousBurnAmount(burnAmount);

        vm.warp(block.timestamp + 15 minutes); // Fast forward time to pass cooldown
        uint256 returnAmount = continuousToken.burn(burnAmount);
        vm.stopPrank();

        assertEq(continuousToken.balanceOf(alice), initialBalance - burnAmount, "Token balance after burn incorrect");
        assertEq(expectedReturnAmount, returnAmount, "Return amount from burn incorrect");
    }

    /// @notice Tests the return amount accuracy when burning tokens
    /// @dev Checks if the actual return amount matches the expected return amount calculated by the contract
    function testGetContinuousBurnReturnAccuracy() public {
        uint256 depositAmount = 100 ether;

        vm.startPrank(alice);
        uint256 mintAmount = continuousToken.mint(depositAmount);
        uint256 burnAmount = mintAmount;
        initialBalance = continuousToken.balanceOf(alice);
        uint256 expectedReturnAmount = continuousToken.getContinuousBurnAmount(burnAmount);

        vm.warp(block.timestamp + 15 minutes); // Fast forward time to pass cooldown
        uint256 returnAmount = continuousToken.burn(burnAmount);
        vm.stopPrank();

        assertEq(expectedReturnAmount, returnAmount, "Return amount from burn incorrect");
    }

    /// @notice Tests burning an amount of tokens greater than the total supply results in a revert
    /// @dev Ensures that the contract does not allow burning more tokens than the user's balance
    function testBurningBeyondSupply() public {
        uint256 depositAmount = 100 ether;

        vm.startPrank(alice);
        uint256 mintAmount = continuousToken.mint(depositAmount);
        uint256 burnAmount = mintAmount + 1;

        vm.warp(block.timestamp + 30 minutes); // Fast forward time to pass cooldown
        vm.expectRevert("Balance must be greater than or equal to burn amount.");
        continuousToken.burn(burnAmount);
    }

    /// @notice Tests that burning zero amount of tokens results in a revert
    /// @dev Ensures that the burn function requires a non-zero amount
    function testBurningRevertsForZeroAmount() public {
        vm.prank(alice);
        vm.expectRevert("Burn amount must be non-zero.");
        continuousToken.burn(0);
    }

    /// @notice Tests the vulnerability of the contract to a sandwich attack
    /// @dev Simulates a scenario where an attacker attempts to exploit the order of transactions to profit from minting and burning
    function testStopSandwichAttack() public {
        // alice and bob plan to buy tokens
        // Attacker front-runs the transaction
        vm.startPrank(attacker);
        uint256 attackerMinted = continuousToken.mint(10 ether);
        vm.stopPrank();

        // User transactions
        vm.startPrank(alice);
        continuousToken.mint(10 ether);
        vm.stopPrank();

        vm.startPrank(bob);
        continuousToken.mint(10 ether);
        vm.stopPrank();

        // Attacker tries to sell the tokens
        // Expecting a revert due to cooldown restrictions
        vm.startPrank(attacker);
        vm.expectRevert("Cooldown period not yet elapsed");
        continuousToken.burn(attackerMinted);
    }

    // TODO: Add test for confirming a reserve ratio of 50% is truly linear between CT price and supply
    // function testLinearPriceIncrease() public {
    //     ...
    // }
}
