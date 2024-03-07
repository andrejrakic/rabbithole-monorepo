// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";

contract NFT is ERC721A, ERC2981, ReentrancyGuard, Ownable2Step {
    uint256 constant MAX_TOTAL_SUPPLY = 1_000; // costs less than being uint16
    uint256 immutable i_priceInEth;
    uint256 immutable i_discountPriceInEth; // instead of storing discount percentage it's better to calculate discount once and store that price
    bytes32 immutable i_merkleRoot;

    BitMaps.BitMap internal s_claimedBitMap;

    event Mint(address indexed to, uint256 indexed firstTokenId, uint256 indexed lastTokenId, uint256 priceInEth);

    error NFT__WithdrawFailed();
    error NFT__CapExceeded();
    error NFT__NotEnoughEth();
    error NFT__InvalidProof();
    error NFT__AlreadyBoughtWithDiscount(address sender);

    constructor(
        uint256 priceInEth,
        uint256 discountInBasisPoints,
        address royaltyReceiver,
        bytes32 merkleRoot,
        address initialOwner
    ) ERC721A("NFT", "NFT") Ownable(initialOwner) {
        i_merkleRoot = merkleRoot;
        i_priceInEth = priceInEth;

        uint256 discount = (priceInEth * discountInBasisPoints) / ERC2981._feeDenominator();
        i_discountPriceInEth = priceInEth - discount;

        uint96 royaltyInBasisPoints = 250; // 2.5% royalty
        ERC2981._setDefaultRoyalty(royaltyReceiver, royaltyInBasisPoints);
    }

    function mint(address to, uint256 quantity) external payable nonReentrant {
        uint256 firstTokenId = ERC721A._nextTokenId();
        if ((firstTokenId + quantity) > MAX_TOTAL_SUPPLY) {
            revert NFT__CapExceeded();
        }
        if (i_priceInEth * quantity > msg.value) revert NFT__NotEnoughEth();

        _safeMint(to, quantity);

        uint256 lastTokenId = firstTokenId + quantity - 1;

        emit Mint(to, firstTokenId, lastTokenId, i_priceInEth);
    }

    function mintWithDiscount(uint256 quantity, bytes32[] calldata proof, uint256 index)
        external
        payable
        nonReentrant
    {
        uint256 firstTokenId = ERC721A._nextTokenId();
        if ((firstTokenId + quantity) > MAX_TOTAL_SUPPLY) {
            revert NFT__CapExceeded();
        }
        if (i_discountPriceInEth * quantity > msg.value) {
            revert NFT__NotEnoughEth();
        }
        if (BitMaps.get(s_claimedBitMap, index)) {
            revert NFT__AlreadyBoughtWithDiscount(msg.sender);
        }

        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(index, msg.sender))));

        if (!MerkleProof.verifyCalldata(proof, i_merkleRoot, leaf)) {
            revert NFT__InvalidProof();
        }

        BitMaps.set(s_claimedBitMap, index);

        _safeMint(msg.sender, quantity);

        uint256 lastTokenId = firstTokenId + quantity - 1;

        emit Mint(msg.sender, firstTokenId, lastTokenId, i_discountPriceInEth);
    }

    function getPricePerToken() external view returns (uint256 priceInEth, uint256 discountPriceInEth) {
        priceInEth = i_priceInEth;
        discountPriceInEth = i_discountPriceInEth;
    }

    function withdrawEth(address to, uint256 amount) external onlyOwner {
        (bool success,) = to.call{value: amount}("");
        if (!success) revert NFT__WithdrawFailed();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }
}
