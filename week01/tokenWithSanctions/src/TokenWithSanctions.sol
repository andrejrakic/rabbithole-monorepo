// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC20} from "./vendor/openzeppelin/contracts/v5.0.0/token/ERC20/ERC20.sol";
import {Ownable} from "./utils/Ownable.sol";

contract TokenWithSanctions is ERC20, Ownable {
    mapping(address tokenHolder => uint256 isBanned) internal s_banned;

    event Banned(address indexed tokenHolder);
    event Unbanned(address indexed tokenHolder);

    error TokenWithSanctions__BannedFromSending(address);
    error TokenWithSanctions__BannedFromReceiving(address);

    constructor(address _owner, address _pendingOwner) ERC20("MyToken", "MTK") Ownable(_owner, _pendingOwner) {}

    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }

    function ban(address _tokenHolder) external onlyOwner {
        s_banned[_tokenHolder] = 1;

        emit Banned(_tokenHolder);
    }

    function unban(address _tokenHolder) external onlyOwner {
        s_banned[_tokenHolder] = 0;

        emit Unbanned(_tokenHolder);
    }

    function isBanned(address _tokenHolder) public view returns (uint256) {
        return s_banned[_tokenHolder];
    }

    function _update(address from, address to, uint256 amount) internal override {
        if (isBanned(from) == 1) {
            revert TokenWithSanctions__BannedFromSending(from);
        }
        if (isBanned(to) == 1) {
            revert TokenWithSanctions__BannedFromReceiving(to);
        }

        super._update(from, to, amount);
    }
}
