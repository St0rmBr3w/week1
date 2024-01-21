// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ERC777PresetFixedSupply} from "erc777-contracts/token/ERC777/presets/ERC777PresetFixedSupply.sol";

contract ERC777Mock is ERC777PresetFixedSupply {
    constructor(
        string memory name,
        string memory symbol,
        address[] memory defaultOperators,
        uint256 initialSupply,
        address owner
    ) ERC777PresetFixedSupply(name, symbol, defaultOperators, initialSupply, owner) {}

    function mint(address to, uint256 amount, bytes memory userData, bytes memory operatorData) public {
        _mint(to, amount, userData, operatorData);
    }
}
