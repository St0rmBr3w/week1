// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../src/UntrustedEscrow.sol";
import "./ERC20Mock.sol";

// Malicious contract attempting to re-enter UntrustedEscrow during token release
contract MaliciousReentrancy {
    UntrustedEscrow public escrow;
    uint256 public escrowId;

    constructor(UntrustedEscrow _escrow, uint256 _escrowId) {
        escrow = _escrow;
        escrowId = _escrowId;
    }

    // This function is called by the escrow contract when releasing tokens
    function receiveToken() external {
        // Attempt to call releaseTokenEscrow recursively
        escrow.releaseTokenEscrow(escrowId);
    }
}