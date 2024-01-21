// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BancorFormula} from "./curves/BancorFormula.sol";
import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";

/// @title Continuous Token Contract
/// @notice Implements a token using a continuous pricing model based on the Bancor Formula.
/// @dev Inherits BancorFormula for pricing, ERC20 for token functionality, and Ownable2Step for ownership management.
contract ContinuousToken is BancorFormula, ERC20, Ownable2Step {
    using SafeERC20 for IERC20;

    uint256 public scale = 10 ** 18;
    uint256 public reserveBalance = 10 * scale;

    /// @notice Reserve Ratio, represented in parts per million, determines the bonding curve.
    /// @dev 50% RR = Linear Bonding Curve, 10% RR = Exponential Bonding Curve.
    uint256 public reserveRatio = 500000;

    /// @notice Address of the reserve token used for exchange.
    address public reserveTokenAddress;

    /// @dev Mapping to store the timestamp of the most recent mint for each minter.
    mapping(address => uint256) private mintTimestamp;

    /// @notice Emitted when Continuous Tokens are burned for Reserve Tokens.
    /// @param _address Address of the user performing the burn.
    /// @param continuousTokenAmount Amount of Continuous Tokens burned.
    /// @param reserveTokenAmount Amount of Reserve Tokens obtained.
    event ContinuousBurn(address _address, uint256 indexed continuousTokenAmount, uint256 indexed reserveTokenAmount);

    /// @notice Emitted when Reserve Tokens are minted into Continuous Tokens.
    /// @param _address Address of the user performing the mint.
    /// @param reserveTokenAmount Amount of Reserve Tokens used for minting.
    /// @param continuousTokenAmount Amount of Continuous Tokens minted.
    event ContinuousMint(address _address, uint256 indexed reserveTokenAmount, uint256 indexed continuousTokenAmount);

    /// @notice Constructs the ContinuousToken contract.
    /// @dev Sets the ERC20 reserve token for the bonding curve, and mints initial supply to the contract deployer.
    /// @param _reserveTokenAddress Address of the reserve token (e.g., DAI, Ether).
    /// @param _continuousTokenName Name of the continuous token.
    /// @param _continuousTokenSymbol Symbol of the continuous token.
    constructor(address _reserveTokenAddress, string memory _continuousTokenName, string memory _continuousTokenSymbol)
        ERC20(_continuousTokenName, _continuousTokenSymbol)
        Ownable2Step()
        Ownable(msg.sender)
    {
        reserveTokenAddress = _reserveTokenAddress;
        _mint(msg.sender, 1 ether);
    }

    /// @notice Mints continuous tokens in exchange for reserve tokens.
    /// @dev Transfers reserve tokens from caller to contract and mints continuous tokens to the caller.
    /// @param _amount Amount of reserve tokens to be used for minting.
    /// @return Amount of continuous tokens minted.
    function mint(uint256 _amount) public returns (uint256) {
        uint256 allowance = IERC20(reserveTokenAddress).allowance(msg.sender, address(this));
        require(_amount < allowance, "Must approve enough reserve tokens.");

        bool success = IERC20(reserveTokenAddress).transferFrom(msg.sender, address(this), _amount);
        require(success, "Failed to transfer reserve tokens");

        mintTimestamp[msg.sender] = block.timestamp;
        return _continuousMint(_amount);
    }

    /// @notice Burns continuous tokens and returns an equivalent amount of reserve tokens.
    /// @dev Transfers reserve tokens from contract to the caller in exchange for burning continuous tokens.
    /// @param _amount Amount of continuous tokens to burn.
    /// @return Amount of reserve tokens returned.
    function burn(uint256 _amount) public returns (uint256) {
        uint256 returnAmount = _continuousBurn(_amount);
        IERC20(reserveTokenAddress).transfer(msg.sender, returnAmount);
        return returnAmount;
    }

    /// @notice Calculates the amount of continuous tokens that can be minted with a specified amount of reserve tokens.
    /// @param _amount Amount of reserve tokens.
    /// @return continuousAmount The calculated amount of continuous tokens that can be minted.
    function getContinuousMintAmount(uint256 _amount) public view returns (uint256 continuousAmount) {
        return purchaseTargetAmount(totalSupply(), reserveBalance, uint32(reserveRatio), _amount);
    }

    /// @notice Calculates the amount of reserve tokens that can be received for a specified amount of continuous tokens.
    /// @param _amount Amount of continuous tokens to burn.
    /// @return burnAmount The calculated amount of reserve tokens that can be received.
    function getContinuousBurnAmount(uint256 _amount) public view returns (uint256 burnAmount) {
        return saleTargetAmount(totalSupply(), reserveBalance, uint32(reserveRatio), _amount);
    }

    /// @dev Internal function to handle the minting process of continuous tokens.
    /// @param _deposit The amount of reserve tokens to be deposited in the contract.
    /// @return The amount of continuous tokens minted.
    /// @notice Mints continuous tokens based on the bonding curve's rate for reserve tokens.
    function _continuousMint(uint256 _deposit) internal returns (uint256) {
        require(_deposit > 0, "Deposit must be non-zero.");

        uint256 amount = getContinuousMintAmount(_deposit);
        _mint(msg.sender, amount);
        reserveBalance += _deposit;
        emit ContinuousMint(msg.sender, _deposit, amount);
        return amount;
    }

    /// @dev Internal function to handle the burning process of continuous tokens.
    /// @param _amount The amount of continuous tokens to be burned.
    /// @return The amount of reserve tokens reimbursed.
    /// @notice Burns continuous tokens and updates the reserve balance accordingly.
    /// This function also checks for the cooldown period compliance.
    function _continuousBurn(uint256 _amount) internal returns (uint256) {
        require(_amount > 0, "Burn amount must be non-zero.");
        require(balanceOf(msg.sender) >= _amount, "Balance must be greater than or equal to burn amount.");
        require(block.timestamp >= mintTimestamp[msg.sender] + 15 minutes, "Cooldown period not yet elapsed");

        uint256 reimburseAmount = getContinuousBurnAmount(_amount);
        _burn(msg.sender, _amount);
        reserveBalance -= reimburseAmount;
        emit ContinuousBurn(msg.sender, _amount, reimburseAmount);
        return reimburseAmount;
    }
}
