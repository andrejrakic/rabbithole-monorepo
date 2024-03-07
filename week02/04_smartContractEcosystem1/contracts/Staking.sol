// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {LPToken} from "./LPToken.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";

contract Staking is IERC721Receiver, ReentrancyGuard {
    struct Deposit {
        address tokenOwner;
        uint256 claimed;
        uint256 depositedAt;
    }

    uint256 constant INTERVAL = 1 days;
    uint256 constant DAILY_REWARD = 10 ether;

    LPToken immutable i_lpToken;
    address immutable i_nftAddress;

    mapping(uint256 tokenId => Deposit) internal s_deposits;

    event Stake(address indexed owner, uint256 indexed tokenId);
    event Unstake(address indexed owner, uint256 indexed tokenId);

    error Staking__OnlyNFTCanCall();
    error Staking__OnlyTokenOwnerCanUnstake();
    error Staking__NothingToClaim();

    constructor(address nftAddress) {
        i_lpToken = new LPToken();
        i_nftAddress = nftAddress;
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        nonReentrant
        returns (bytes4)
    {
        if (msg.sender != i_nftAddress) revert Staking__OnlyNFTCanCall();

        _stake(from, tokenId);

        return IERC721Receiver.onERC721Received.selector;
    }

    function _stake(address from, uint256 tokenId) internal {
        s_deposits[tokenId].tokenOwner = from;
        s_deposits[tokenId].depositedAt = block.timestamp;

        emit Stake(from, tokenId);
    }

    function unstake(uint256 tokenId) external nonReentrant {
        Deposit memory depositedNft = s_deposits[tokenId];

        if (msg.sender != depositedNft.tokenOwner) {
            revert Staking__OnlyTokenOwnerCanUnstake();
        }

        delete s_deposits[tokenId];

        // if have unclaimed rewards mint those as well
        uint256 totalAvailableRewards = _availableRewards(depositedNft.depositedAt);
        uint256 claimable = totalAvailableRewards - depositedNft.claimed;
        if (claimable > 0) {
            i_lpToken.mint(msg.sender, claimable);
        }

        IERC721(i_nftAddress).safeTransferFrom(address(this), msg.sender, tokenId);

        emit Unstake(msg.sender, tokenId);
    }

    function availableRewards(uint256 tokenId) public view returns (uint256) {
        uint256 totalAvailableRewards = _availableRewards(s_deposits[tokenId].depositedAt);
        return totalAvailableRewards - s_deposits[tokenId].claimed;
    }

    function claimRewards(uint256 tokenId) external nonReentrant {
        Deposit memory depositedNft = s_deposits[tokenId];

        // no msg.sender == depositedNft.owner check because user can automate claiming rewards

        uint256 totalAvailableRewards = _availableRewards(depositedNft.depositedAt);
        uint256 claimable = totalAvailableRewards - depositedNft.claimed;

        if (claimable == 0) revert Staking__NothingToClaim();

        s_deposits[tokenId].claimed = totalAvailableRewards;

        i_lpToken.mint(depositedNft.tokenOwner, claimable);
    }

    function _availableRewards(uint256 genesisTimestamp) internal view returns (uint256) {
        return ((block.timestamp - genesisTimestamp) / INTERVAL) * DAILY_REWARD;
    }
}
