const { MerkleTree } = require("merkletreejs")
const keccak256 = require("keccak256")

let whitelistAddress = [
    "0x3D64FB07e24a6543c3A5B9c08a55122910f67655",
    "0x45821AF32F0368fEeb7686c4CC10B7215E00Ab04",
]

const leafNodes = whitelistAddress.map((addr) => keccak256(addr))
const merkleTree = new MerkleTree(leafNodes, keccak256, { sortPairs: true })
const rootHash = merkleTree.getHexRoot()

console.log("Whitelist Merkle Tree\n", merkleTree.toString())
console.log("RootHash\n", rootHash)

for (i = 0; i < whitelistAddress.length; i++) {
    const claimAddress = leafNodes[i]
    const hexProof = merkleTree.getHexProof(claimAddress)
    console.log(`MerkleTree Proof for Address - leafNodes[${i}]\n`, hexProof)
}
