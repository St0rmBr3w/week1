// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";

// Solidity contract 2: Token with god mode.
// A special address is able to transfer tokens between addresses at will.
contract GodMode is ERC20, Ownable2Step {
    address public activeGod;

    /// @notice Event emitted when the god address is changed.
    event GodChanged(address indexed previousGod, address indexed newGod);

    /// @param name The name of the token.
    /// @param symbol The symbol of the token.
    constructor(string memory name, string memory symbol) ERC20(name, symbol) Ownable(msg.sender) {}

    /// @notice Allows the owner to mint new tokens.
    /// @param to The address that will receive the minted tokens.
    /// @param amount The amount of tokens to mint.
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /// @notice Sets the 'god' address.
    /// @param _newGod The address to be set as 'god'.
    /// @dev Only the contract owner can set or change the god address.
    function setGod(address _newGod) external onlyOwner {
        emit GodChanged(activeGod, _newGod);
        activeGod = _newGod;
    }

    /// @notice Allows the god address to transfer tokens between any two addresses.
    /// @param from The address from which tokens are transferred.
    /// @param to The address to which tokens are transferred.
    /// @param amount The amount of tokens to transfer.
    /// @dev This function can only be called by the god address.
    function godTransfer(address from, address to, uint256 amount) external {
        require(msg.sender == activeGod, "Caller is not the current god");
        _transfer(from, to, amount);
    }
}
