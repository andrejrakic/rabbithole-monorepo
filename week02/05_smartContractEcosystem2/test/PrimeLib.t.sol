// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";
import {PrimeLib} from "../src/PrimeLib.sol";
import {Strings} from "../src/vendor/@openzeppelin/contracts/v5.0.0/utils/Strings.sol";
import {BytesLib} from "../src/vendor/solidity-bytes-utils/v0.8.0/BytesLib.sol";

contract PrimeLibTest is Test {
    using PrimeLib for uint256;

    function setUp() public {}

    function isPrimeRust(uint256 number) public returns (bool) {
        string[] memory cmds = new string[](4);
        cmds[0] = "cargo";
        cmds[1] = "run";
        cmds[2] = "--";
        cmds[3] = Strings.toString(number);
        bytes memory output = vm.ffi(cmds);

        uint8 result = (BytesLib.toUint8(output, 0));

        // 48 is ASCII code for 0 (false)
        // 49 is ASCII code for 1 (true)
        if (result == 48) return false;
        if (result == 49) return true;
        assert(result == 48 || result == 49);
    }

    function test_isPrime(uint256 number) external {
        number = bound(number, 1, 100_000_000);

        assertEq(number.isPrime(), isPrimeRust(number));
    }
}
