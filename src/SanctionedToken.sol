// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

/// @title SanctionedToken
/// @notice A fungible token that allows an admin (the owner) to ban and unban addresses from sending and receiving tokens.
/// @dev Extends ERC20 standard token from OpenZeppelin with sanctioning capabilities.
contract SanctionedToken is ERC20, Ownable2Step {

    /// @notice Tracks whether an address is banned or not.
    mapping(address => bool) private bannedAddresses;

    /// @notice Ensures that neither the sender nor the recipient is banned.
    /// @param _recipient The receiving address to be checked for a ban.
    modifier onlyUnbanned(address _recipient) {
        require(!bannedAddresses[msg.sender], "Sender address is banned");
        require(!bannedAddresses[tx.origin], "Origin address is banned");
        require(!bannedAddresses[_recipient], "Recipient address is banned");
        _;
    }

    /// @notice Contract constructor that sets token details.
    /// @param name The name of the token.
    /// @param symbol The symbol of the token.
    constructor(string memory name, string memory symbol) ERC20(name, symbol) Ownable2Step() Ownable(msg.sender) {}

    /// @notice Allows the owner to mint new tokens.
    /// @param to The address that will receive the minted tokens.
    /// @param amount The amount of tokens to mint.
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /// @notice Transfer tokens from one address to another with sanction checks.
    /// @param from The address from which tokens are transferred.
    /// @param to The recipient address.
    /// @param value The amount of tokens to transfer.
    /// @return A boolean value indicating whether the operation succeeded.
    function transferFrom(address from, address to, uint256 value) public override onlyUnbanned(to) returns (bool) {
        return super.transferFrom(from, to, value);
    }

    /// @notice Transfer tokens with sanction checks.
    /// @param to The recipient address.
    /// @param value The amount of tokens to transfer.
    /// @return A boolean value indicating whether the operation succeeded.
    function transfer(address to, uint256 value) public override onlyUnbanned(to) returns (bool) {
        return super.transfer(to, value);
    }

    /// @notice Allows the owner to ban an address.
    /// @param _address The address to be banned.
    function banAddress(address _address) external onlyOwner {
        require(_address != owner(), "Cannot ban the owner");
        bannedAddresses[_address] = true;
    }

    /// @notice Allows the owner to unban an address.
    /// @param _address The address to be unbanned.
    function unbanAddress(address _address) external onlyOwner {
        bannedAddresses[_address] = false;
    }

    /// @notice Checks if an address is banned.
    /// @param _address The address to check.
    /// @return A boolean indicating if the address is banned.
    function isBanned(address _address) external view returns (bool) {
        return bannedAddresses[_address];
    }
}
