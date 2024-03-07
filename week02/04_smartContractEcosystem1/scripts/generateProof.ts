import { task } from "hardhat/config";
import { BytesLike } from 'ethers';
import { StandardMerkleTree } from "@openzeppelin/merkle-tree";
import fs from "fs";

// Merkle Root: 0x280cba2975f904e30bdd0086af6cb2b4ff1f7203baa781091887c72da3bfaece

export function generateProof(address: string): { index: bigint, proof: BytesLike[] } | null {
    const tree = StandardMerkleTree.load(JSON.parse(fs.readFileSync("tree.json", "utf8")));

    for (const [i, v] of tree.entries()) {
        if (v[0] === address) {
            const proof = tree.getProof(i);
            console.log('Value:', v);
            console.log('Proof:', proof);

            return { index: v[1], proof: proof }
        }
    }

    return null;
}

// npx hardhat generateProof --address 0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199

task("generateProof", "Generates proof")
    .addParam("address")
    .setAction(async ({ address }) => {
        generateProof(address);
    });


