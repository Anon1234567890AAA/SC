// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LPToken is ERC20, Ownable {
    constructor() ERC20("LPToken", "LPtest") {
        _mint(0x3b38f8c88e968e4bE2a4C58dCc16321662F4cba4, 100 * 1E18);
        _mint(0xC4aD948943e4513A3d3949c0F5Bad380A336289F, 200 * 1E18);
        _mint(0x0Fbae0Bd913be7cF373583EFe2420a112d635538, 300 * 1E18);
        _mint(0xb10F86746004e61A5c4d386091b08e270F6cCF02, 400 * 1E18);
        _mint(0xbd55259Cf5ac3e8AA0c55d7c541b004c350995A2, 500 * 1E18);
        _mint(0x48969b2d1D180E4D2fe85A82909D196287d6c359, 600 * 1E18);
        _mint(0xd7F0Ee73BD664E4eF8Cb044D5F7052e6e489f9aa, 700 * 1E18);
        _mint(0xa2CF74bECf51011D0c64202Ef50252A7b3405316, 800 * 1E18);
        _mint(0x70759Da952D398752391fa5615E8A735150c7BD1, 900 * 1E18);
    }
}
