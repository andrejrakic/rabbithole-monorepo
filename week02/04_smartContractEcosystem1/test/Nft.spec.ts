import {
    time,
    loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";
import { generateMerkleTree } from "../scripts/createMerkleTree";
import { generateProof } from "../scripts/generateProof";

describe("NFT", function () {
    // We define a fixture to reuse the same setup in every test.
    // We use loadFixture to run this setup once, snapshot that state,
    // and reset Hardhat Network to that snapshot in every test.
    async function deployNftFixture() {
        // Contracts are deployed using the first signer/account by default
        const [owner, royaltyReceiver, alice] = await ethers.getSigners();

        const priceInEth = ethers.parseEther("0.1");
        const discountInBasisPoints = 1_000; // 10%
        const merkleRoot = await generateMerkleTree();

        const nftFactory = await ethers.getContractFactory("NFT");
        const nft = await nftFactory.deploy(priceInEth,
            discountInBasisPoints,
            royaltyReceiver,
            merkleRoot,
            owner);

        return { nft, alice };
    }

    describe("Smoke test", function () {
        it("Should test the happy path", async function () {
            const { nft, alice } = await loadFixture(deployNftFixture);

            const prices = await nft.getPricePerToken();
            const quantityToMint: bigint = 2n;
            prices.discountPriceInEth;

            const proof = generateProof(alice.address);
            if (!proof) return;

            const msgValue = quantityToMint * prices.discountPriceInEth;

            await nft.connect(alice).mintWithDiscount(quantityToMint, proof?.proof, proof?.index, { value: msgValue });

            expect(quantityToMint).to.equal(await nft.balanceOf(alice.address));
            expect(await ethers.provider.getBalance(nft.target)).to.equal(msgValue);
        });



    });


});


