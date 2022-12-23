//SPDX-License-Identifier: Unlicense

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MintNft721 is ERC721, Ownable {
    using Strings for uint256;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint public constant MAX_TOKENS = 150;
    uint public constant MAX_MINT_AMOUNT = 5;

    bool public isPaused = true;
    bool public isRevealed;
    uint public totalSupply;
    string public baseUri;

    mapping (address => uint256) mintedPerWallet;

    string private revealUrl = "ipfs://QmRJNba53KRPuWrbqy5kJooQY32mbBp5DDTSKFGdbwWjK1/1.json";


    constructor(
    ) ERC721("nftCollection", "EXDL") {
        //baseUri = _baseUri;
        //baseUri = "ipfs://QmRYUNY95wZYLrNCucAzyse54BeUWUByXSC4KNBzTPW1fr"; // -- correct;
    }

    function mint() public {
        address sender = msg.sender;

        require(!isPaused, "Err: Minting is not started yet");
        require(mintedPerWallet[sender] < MAX_MINT_AMOUNT, "Err: Exceeds max mint amount per wallet.");
        require(totalSupply + 1 <= MAX_TOKENS, "Err: Exceeds total supply.");

        totalSupply += 1;
        mintedPerWallet[sender] += 1;

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(sender, newItemId);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        if(!isRevealed) {
            // returns notRevealed img
            return revealUrl;
        }

        return string(
            abi.encodePacked(baseUri, "/", _tokenId, ".json")
        );
    }

    // Owner-only functions
    function setPause(bool _isPaused) external onlyOwner {
        isPaused = _isPaused;
    }

    // call this function to Start Minting
    function startSale() external onlyOwner {
        isPaused = false;
    }

    function setIsRevealed(bool _isRevealed) external onlyOwner {
        isRevealed = _isRevealed;
    }

    // call this function to reveal Collection
    function revealCollection() external onlyOwner {
        isRevealed = true;
        baseUri = "ipfs://QmRYUNY95wZYLrNCucAzyse54BeUWUByXSC4KNBzTPW1fr";
    }

    function setBaseUri(string memory _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }
}
