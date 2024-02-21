// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC20} from "../src/vendor/openzeppelin/contracts/v5.0.0/token/ERC20/ERC20.sol";

contract MyToken is ERC20 {
    address internal immutable i_tokenSaleContractAddress;

    error MyToken__OnlyTokenSaleCanCall();

    modifier onlyTokenSale() {
        if (msg.sender != i_tokenSaleContractAddress) {
            revert MyToken__OnlyTokenSaleCanCall();
        }
        _;
    }

    constructor(address tokenSaleContractAddress) ERC20("MyToken", "MTK") {
        i_tokenSaleContractAddress = tokenSaleContractAddress;
    }

    function mint(address _to, uint256 _amount) external onlyTokenSale {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external onlyTokenSale {
        _burn(_from, _amount);
    }
}
