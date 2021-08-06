// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./ERC20/ERC20.sol";

contract GertsCoin is ERC20 {
    constructor() ERC20("GertsCoin", "GRC") {
        _mint(msg.sender, 100000000000000000000000);
    }
}