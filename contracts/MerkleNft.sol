// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MerkleNft is ERC721URIStorage, Ownable, ReentrancyGuard {
    //状态变量
    bytes32 private _MerkleRoot =
        0x975f9edd1da8a193f4281170fb2cb66be905a61001f063759188081df2ffb006;
    uint256 public MAX_SUPPLY;
    uint256 public MINT_COST;
    uint256 public ItemId;
    uint256 public nowItemId;

    //白名单映射
    mapping(address => bool) public whitelistClaimed;

    //计数器
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    //错误提示
    error MintAlreadyClaimed();
    error MerkleProofInvalid();

    //事件
    event Mint(address indexed minter, uint256 indexed tokenId);
    event SetRoot(bytes32 indexed Root);

    //函数修饰符
    modifier onlyIfValidMerkleProof(bytes32 root, bytes32[] calldata proof) {
        if (!MerkleProof.verify(proof, root, keccak256(abi.encodePacked(msg.sender))))
            revert MerkleProofInvalid();
        _;
    }

    modifier onlyIfNotAlreadyClaimed() {
        if (whitelistClaimed[msg.sender]) revert MintAlreadyClaimed();
        _;
    }

    //初始化
    constructor(uint256 maxSupply, uint256 mintCost) ERC721("MerkleNFT", "MRK") {
        MAX_SUPPLY = maxSupply;
        MINT_COST = mintCost;
    }

    //函数
    function setMerkleRoot(bytes32 newRoot) external onlyOwner {
        _MerkleRoot = newRoot;
        emit SetRoot(_MerkleRoot);
    }

    function whitelistMint(bytes32[] calldata _merkleProof)
        external
        payable
        onlyIfNotAlreadyClaimed
        onlyIfValidMerkleProof(_MerkleRoot, _merkleProof)
        nonReentrant
    {
        ItemId = _tokenIds.current();
        require(msg.value >= MINT_COST, "Pls pay enough ETH");
        require(ItemId < MAX_SUPPLY, "Mint Over");

        _tokenIds.increment();
        nowItemId = _tokenIds.current();
        whitelistClaimed[msg.sender] = true;

        _safeMint(msg.sender, nowItemId);

        if (msg.value > MINT_COST) {
            payable(msg.sender).transfer(msg.value - MINT_COST);
        }

        emit Mint(msg.sender, nowItemId);
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}
