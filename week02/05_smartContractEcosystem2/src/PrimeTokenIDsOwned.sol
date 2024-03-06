// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {NFTCollection} from "./NFTCollection.sol";
import {PrimeLib} from "./PrimeLib.sol";

contract PrimeTokenIDsOwned {
    using PrimeLib for uint256;

    address immutable i_nftCollection;

    constructor(address nftCollection) {
        i_nftCollection = nftCollection;
    }

    function primeTokenIDsOwned(address account) public view returns (uint256 primes) {
        NFTCollection nftCollection = NFTCollection(i_nftCollection);
        uint256 balance = nftCollection.balanceOf(account);

        for (uint256 i = 0; i < balance; ++i) {
            if (nftCollection.tokenOfOwnerByIndex(account, i).isPrime()) {
                primes++;
            }
        }
    }
}
