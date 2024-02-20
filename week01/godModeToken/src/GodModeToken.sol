// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "./vendor/openzeppelin/contracts/v5.0.0/token/ERC20/ERC20.sol";
import {Ownable} from "./utils/Ownable.sol";

contract GodModeToken is ERC20, Ownable {
    constructor(address _owner, address _pendingOwner) ERC20("MyToken", "MTK") Ownable(_owner, _pendingOwner) {}

    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }

    function godModeTransfer(address _from, address _to, uint256 _amount) external onlyOwner returns (bool) {
        _transfer(_from, _to, _amount);
        return true;
    }
}
