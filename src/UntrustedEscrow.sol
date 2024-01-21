// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract UntrustedEscrow is ReentrancyGuard {
    using SafeERC20 for IERC20;
    
    uint256 constant LOCK_DURATION = 3 days;

    struct TokenEscrow {
        address escrowedToken;
        address escrowCreator;
        address escrowBeneficiary;
        uint256 escrowedAmount;
        uint256 releaseTime;
    }

    mapping(uint256 => TokenEscrow) private tokenEscrows;
    uint256 public nextEscrowId;

    event EscrowCreated(uint256 indexed escrowId, address escrowedToken, address indexed escrowCreator, address indexed escrowBeneficiary, uint256 escrowedAmount);
    event EscrowReleased(uint256 indexed escrowId, address indexed escrowBeneficiary);

    /// @notice Creates an escrow with a specific ERC20 token
    /// @param escrowedTokenAddress Address of the ERC20 token
    /// @param beneficiary Address of the escrow beneficiary (seller)
    /// @param amount Amount of tokens to be escrowed
    /// @return escrowId Id of the created escrow
    function createTokenEscrow(address escrowedTokenAddress, address beneficiary, uint256 amount) external returns (uint256 escrowId) {
        require(amount > 0, "Amount must be greater than 0");
        require(IERC20(escrowedTokenAddress).transferFrom(msg.sender, address(this), amount), "Transfer failed");

        escrowId = nextEscrowId++;
        TokenEscrow storage newEscrow = tokenEscrows[escrowId];
        newEscrow.escrowedToken = escrowedTokenAddress;
        newEscrow.escrowCreator = msg.sender;
        newEscrow.escrowBeneficiary = beneficiary;
        newEscrow.escrowedAmount = amount;
        newEscrow.releaseTime = block.timestamp + LOCK_DURATION;

        emit EscrowCreated(escrowId, escrowedTokenAddress, msg.sender, beneficiary, amount);
    }

    /// @notice Releases the escrowed tokens to the beneficiary
    /// @param escrowId Id of the escrow
    function releaseTokenEscrow(uint256 escrowId) external nonReentrant {
        TokenEscrow storage escrow = tokenEscrows[escrowId];
         require(block.timestamp >= escrow.releaseTime, "Escrow is still locked");
        require(msg.sender == escrow.escrowBeneficiary, "Only beneficiary can release");

        uint256 amountToRelease = escrow.escrowedAmount;
        escrow.escrowedAmount = 0;
        require(IERC20(escrow.escrowedToken).transfer(escrow.escrowBeneficiary, amountToRelease), "Transfer failed");

        emit EscrowReleased(escrowId, escrow.escrowBeneficiary);
    }

    /// @notice Retrieves details of a specific escrow
    /// @param escrowId The ID of the escrow
    /// @return The details of the specified escrow
    function getEscrowDetails(uint256 escrowId) public view returns (TokenEscrow memory) {
        return tokenEscrows[escrowId];
    }
}