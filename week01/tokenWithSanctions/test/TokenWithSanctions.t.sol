// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {TokenWithSanctions} from "./../src/TokenWithSanctions.sol";

contract TokenWithSanctionsTest is Test {
    TokenWithSanctions public tokenWithSanctions;
    address owner;
    address alice;
    address bob;

    uint256 constant TRUE = 1;
    uint256 constant FALSE = 0;

    function setUp() public {
        owner = makeAddr("owner");
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        tokenWithSanctions = new TokenWithSanctions(owner, address(0));
    }

    function test_smoke() public {
        vm.startPrank(owner);
        uint256 amountToMint = 100;
        tokenWithSanctions.mint(alice, amountToMint);
        tokenWithSanctions.mint(bob, amountToMint);

        assertEq(tokenWithSanctions.balanceOf(alice), amountToMint);
        assertEq(tokenWithSanctions.balanceOf(bob), amountToMint);
        assertEq(tokenWithSanctions.totalSupply(), 2 * amountToMint);
        vm.stopPrank();

        vm.startPrank(alice);
        uint256 amountToTransfer = 20;
        tokenWithSanctions.transfer(bob, amountToTransfer);
        assertEq(tokenWithSanctions.balanceOf(alice), amountToMint - amountToTransfer);
        assertEq(tokenWithSanctions.balanceOf(bob), amountToMint + amountToTransfer);
        vm.stopPrank();

        vm.startPrank(owner);
        tokenWithSanctions.ban(alice);
        assertEq(tokenWithSanctions.isBanned(alice), TRUE);
        vm.stopPrank();

        vm.startPrank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(TokenWithSanctions.TokenWithSanctions__BannedFromSending.selector, alice)
        );
        tokenWithSanctions.transfer(bob, amountToTransfer);
        vm.stopPrank();

        vm.startPrank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(TokenWithSanctions.TokenWithSanctions__BannedFromReceiving.selector, alice)
        );
        tokenWithSanctions.transfer(alice, amountToTransfer);
        vm.stopPrank();

        // sanity check
        assertEq(tokenWithSanctions.balanceOf(alice), amountToMint - amountToTransfer);
        assertEq(tokenWithSanctions.balanceOf(bob), amountToMint + amountToTransfer);
    }
}
