// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RBKToken is ERC20, Ownable {
    constructor() ERC20("RBKToken", "RBK") {
        _mint(msg.sender, 20000000 * 1E18);
    }
}
