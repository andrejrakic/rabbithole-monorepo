// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {MyToken} from "./MyToken.sol";
import {ReentrancyGuard} from "./vendor/openzeppelin/contracts/v5.0.0/utils/ReentrancyGuard.sol";

contract TokenSale is ReentrancyGuard {
    MyToken internal immutable i_tokenOnSale;
    uint256 internal immutable i_slope; // The fixed price increase per token sold

    event TokensBought(address buyer, uint256 amountOfTokensToBuy, uint256 priceInEth);
    event TokensSold(address seller, uint256 amountOfTokensToSell, uint256 priceInEth);

    error TokenSale__InsufficientEth(uint256 priceInEth);
    error TokenSale__SlippageToleranceExceeded(uint256 priceInEth, uint256 userLimit);
    error TokenSale__EthTransferFailed();

    constructor(uint256 slope) {
        i_tokenOnSale = new MyToken(address(this));
        i_slope = slope;
    }

    function buyTokensForEth(uint256 amountOfTokensToBuy, uint256 maximumEthWillingToSpend)
        external
        payable
        nonReentrant
    {
        uint256 priceInEth = calculateBuyingPrice(amountOfTokensToBuy);
        if (priceInEth > msg.value) {
            revert TokenSale__InsufficientEth(priceInEth);
        }
        if (priceInEth > maximumEthWillingToSpend) {
            revert TokenSale__SlippageToleranceExceeded(priceInEth, maximumEthWillingToSpend);
        }

        i_tokenOnSale.mint(msg.sender, amountOfTokensToBuy);

        if (msg.value > priceInEth) {
            uint256 refundAmount = msg.value - priceInEth;
            transferETH(msg.sender, refundAmount);
        }

        emit TokensBought(msg.sender, amountOfTokensToBuy, priceInEth);
    }

    function sellTokensForEth(uint256 amountOfTokensToSell, uint256 minimumEthWillingToReceive) external nonReentrant {
        // No need to check for balanceOf(msg.sender) > amountOfTokensToSell, because MyToken.sol will handle the revert
        uint256 priceInEth = calculateSellingPrice(amountOfTokensToSell);
        if (minimumEthWillingToReceive > priceInEth) {
            revert TokenSale__SlippageToleranceExceeded(priceInEth, minimumEthWillingToReceive);
        }

        i_tokenOnSale.burn(msg.sender, amountOfTokensToSell);
        transferETH(msg.sender, priceInEth);

        emit TokensSold(msg.sender, amountOfTokensToSell, priceInEth);
    }

    function calculateBuyingPrice(uint256 amountOfTokensToBuy) public view returns (uint256 priceInEth) {
        priceInEth = ((amountOfTokensToBuy * i_slope) / 2) * (2 * i_tokenOnSale.totalSupply() + amountOfTokensToBuy + 1);
    }

    function calculateSellingPrice(uint256 amountOfTokensToSell) public view returns (uint256 priceInEth) {
        uint256 tokenSupplyAfter = i_tokenOnSale.totalSupply() - amountOfTokensToSell;
        priceInEth = ((amountOfTokensToSell * i_slope) / 2) * (2 * tokenSupplyAfter + amountOfTokensToSell + 1);
    }

    function getMyToken() public view returns (address) {
        return address(i_tokenOnSale);
    }

    function transferETH(address to, uint256 amount) private {
        (bool success,) = to.call{value: amount}("");
        if (!success) revert TokenSale__EthTransferFailed();
    }
}
