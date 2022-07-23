// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol';

contract PandaNft is ERC721Royalty{
    uint256 private s_counter;
    string public constant TOKEN_URI = "ipfs://bafybeig37ioir76s7mg5oobetncojcm3c3hxasyd4rvid4jqhy4gkaheg4/?filename=0-PUG.json";

    constructor() ERC721("Panda","PAN"){
        s_counter = 0;
        _setDefaultRoyalty(msg.sender,500);
    }

    function mintNft() public {
        s_counter += 1;
        _safeMint(msg.sender, s_counter);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory){
        require(_exists(tokenId));
        return TOKEN_URI;
    }

    function getCounter() public view returns (uint256) {
        return s_counter;
    }
}