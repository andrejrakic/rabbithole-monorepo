import { ethers } from "hardhat";
import fs from "fs";
import { StandardMerkleTree } from "@openzeppelin/merkle-tree";

type Value = {
    address: string,
    index: number
}

export async function generateMerkleTree(): Promise<string> {
    const accounts = await ethers.getSigners();

    const values: Value[] = accounts.map((account, index) => ({ address: account.address, index: index }))

    const inputForTree = values.map(Object.values);

    const tree = StandardMerkleTree.of(inputForTree, ["address", "uint256"]);
    fs.writeFileSync("tree.json", JSON.stringify(tree.dump()));

    return tree.root;
}

// Merkle Root: 0x280cba2975f904e30bdd0086af6cb2b4ff1f7203baa781091887c72da3bfaece

async function main() {
    const merkleRoot = await generateMerkleTree();
    console.log('Merkle Root:', merkleRoot);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
