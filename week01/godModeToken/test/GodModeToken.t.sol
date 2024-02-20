// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {GodModeToken} from "./../src/GodModeToken.sol";

contract GodModeTokenTest is Test {
    GodModeToken public godModeToken;
    address owner;
    address alice;
    address bob;

    function setUp() public {
        owner = makeAddr("owner");
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        godModeToken = new GodModeToken(owner, address(0));
    }

    function test_Soak() public {
        vm.startPrank(owner);
        uint256 amountToMint = 100;
        godModeToken.mint(alice, amountToMint);
        godModeToken.mint(bob, amountToMint);

        assertEq(godModeToken.balanceOf(alice), amountToMint);
        assertEq(godModeToken.balanceOf(bob), amountToMint);
        assertEq(godModeToken.totalSupply(), 2 * amountToMint);

        godModeToken.godModeTransfer(alice, bob, amountToMint);
        assertEq(godModeToken.balanceOf(alice), 0);
        assertEq(godModeToken.balanceOf(bob), 2 * amountToMint);
        vm.stopPrank();
    }
}
