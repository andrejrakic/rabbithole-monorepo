// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {MyToken} from "../src/MyToken.sol";
import {TokenSale} from "../src/TokenSale.sol";

contract TokenSaleTest is Test {
    MyToken public myToken;
    TokenSale public tokenSale;
    address alice;
    address bob;
    uint256 userStartingBalance = 100 ether;
    uint256 slope = 1 ether;

    function setUp() public {
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        vm.deal(alice, userStartingBalance);
        vm.deal(bob, userStartingBalance);

        tokenSale = new TokenSale(slope);
        myToken = MyToken(tokenSale.getMyToken());
    }

    function test_Soak() public {
        vm.startPrank(alice);
        uint256 amountOfTokens = 5;
        uint256 expectedPrice = 15 ether;

        uint256 priceInEth = tokenSale.calculateBuyingPrice(amountOfTokens);
        assertEq(priceInEth, expectedPrice);

        tokenSale.buyTokensForEth{value: expectedPrice}(amountOfTokens, expectedPrice);

        assertEq(alice.balance, userStartingBalance - priceInEth);
        assertEq(address(tokenSale).balance, priceInEth);
        assertEq(myToken.balanceOf(alice), amountOfTokens);
        vm.stopPrank();

        vm.startPrank(bob);
        uint256 secondBuyPriceInEth = tokenSale.calculateBuyingPrice(amountOfTokens);
        uint256 secondBuyExpectedPrice = 40 ether;
        assertEq(secondBuyPriceInEth, secondBuyExpectedPrice);

        tokenSale.buyTokensForEth{value: secondBuyExpectedPrice}(amountOfTokens, secondBuyExpectedPrice);

        assertEq(bob.balance, userStartingBalance - secondBuyPriceInEth);
        assertEq(address(tokenSale).balance, priceInEth + secondBuyPriceInEth);
        assertEq(myToken.balanceOf(bob), amountOfTokens);
        vm.stopPrank();

        vm.startPrank(alice);
        uint256 sellingPriceInEth = tokenSale.calculateSellingPrice(amountOfTokens);
        uint256 mainimumEthWillingToReceive = 35 ether;
        uint256 expectedProfit = sellingPriceInEth - expectedPrice;

        tokenSale.sellTokensForEth(amountOfTokens, mainimumEthWillingToReceive);

        assertEq(alice.balance, userStartingBalance + expectedProfit);
        assertEq(address(tokenSale).balance, priceInEth + secondBuyPriceInEth - sellingPriceInEth);
        assertEq(myToken.balanceOf(alice), 0);
        vm.stopPrank();
    }
}
