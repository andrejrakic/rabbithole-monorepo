// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {
    ERC721Enumerable,
    ERC721
} from "./vendor/@openzeppelin/contracts/v5.0.0/token/ERC721/extensions/ERC721Enumerable.sol";
import {ReentrancyGuard} from "./vendor/@openzeppelin/contracts/v5.0.0/utils/ReentrancyGuard.sol";

contract NFTCollection is ERC721Enumerable, ReentrancyGuard {
    constructor(address mintTo) ERC721("NFTCollection", "NFT") nonReentrant {
        for (uint256 i = 1; i < 100; i += 5) {
            _safeMint(mintTo, i);
        }
    }
}
