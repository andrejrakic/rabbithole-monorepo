// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "./vendor/openzeppelin/contracts/v5.0.0/token/ERC20/ERC20.sol";
import {Ownable} from "./utils/Ownable.sol";

contract TokenWithSanctions is ERC20, Ownable {
    mapping(address tokenHolder => bool isBanned) internal s_banned;

    event Banned(address indexed tokenHolder);
    event Unbanned(address indexed tokenHolder);

    error TokenWithSanctions__BannedFromSending(address);
    error TokenWithSanctions__BannedFromReceiving(address);

    constructor(
        address _owner,
        address _pendingOwner
    ) ERC20("MyToken", "MTK") Ownable(_owner, _pendingOwner) {}

    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }

    function ban(address _tokenHolder) external onlyOwner {
        s_banned[_tokenHolder] = true;

        emit Banned(_tokenHolder);
    }

    function unban(address _tokenHolder) external onlyOwner {
        s_banned[_tokenHolder] = false;

        emit Unbanned(_tokenHolder);
    }

    function isBanned(address _tokenHolder) public view returns (bool) {
        return s_banned[_tokenHolder];
    }

    function _update(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (isBanned(from)) revert TokenWithSanctions__BannedFromSending(from);
        if (isBanned(to)) revert TokenWithSanctions__BannedFromReceiving(to);

        super._update(from, to, amount);
    }
}
