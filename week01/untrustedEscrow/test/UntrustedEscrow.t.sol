// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {UntrustedEscrow} from "../src/UntrustedEscrow.sol";
import {ERC20} from "../src/vendor/openzeppelin/contracts/v5.0.0/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    constructor() ERC20("MyToken", "MTK") {}

    function mint(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }
}

contract UntrustedEscrowTest is Test {
    UntrustedEscrow public untrustedEscrow;
    MockToken public mockToken;
    address owner;
    address alice;
    address bob;

    uint256 internal constant HUNDRED_PERCENT_BPS = 10_000;
    uint256 internal constant UNFREEZE_PERIOD = 3 days;

    function setUp() public {
        owner = makeAddr("owner");
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        untrustedEscrow = new UntrustedEscrow(owner, address(0));

        mockToken = new MockToken();
    }

    function test_Soak(uint256 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount < type(uint256).max / HUNDRED_PERCENT_BPS);
        mockToken.mint(alice, amount);

        vm.startPrank(alice);
        mockToken.approve(address(untrustedEscrow), amount);
        bytes32 escrowId = untrustedEscrow.deposit(bob, address(mockToken), amount);

        assertTrue(escrowId != bytes32(""));

        // console2.logBytes32(escrowId);

        assertEq(mockToken.balanceOf(alice), 0);
        assertEq(mockToken.balanceOf(address(untrustedEscrow)), amount);
        vm.stopPrank();

        // vm.startPrank(owner);
        // vm.expectRevert(
        //     abi.encodeWithSelector(
        //         UntrustedEscrow.UnstructuredEscrow__InvalidCaller.selector,
        //         bob,
        //         owner
        //     )
        // );
        // vm.stopPrank();

        vm.startPrank(bob);
        vm.expectRevert(abi.encodeWithSelector(UntrustedEscrow.UnstructuredEscrow__TooEarlyToCall.selector));
        untrustedEscrow.withdraw(escrowId);

        vm.warp(block.timestamp + UNFREEZE_PERIOD);
        untrustedEscrow.withdraw(escrowId);
        assertEq(mockToken.balanceOf(bob), amount);
        assertEq(mockToken.balanceOf(address(untrustedEscrow)), 0);
        vm.stopPrank();
    }
}
