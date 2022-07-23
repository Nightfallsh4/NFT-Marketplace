// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// Errors
error PandaMarket__NotTheOwner();
error PandaMarket__PriceShouldBeZero();
error PandaMarket__NotApproved();
error PandaMarket__AlreadyListed();

/// @title An NFT Marketplace to trade NFTs
/// @author Shanmugadevan
contract PandaMarket {
    // Type variables
    struct Listing{
        address seller;
        uint256 price;
    }

    // State Variables
    uint8 private immutable marketFee;
    mapping(address => mapping(uint256 => Listing)) private listed;

    // Events
    event NftListed(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 price

    );

    // Modifiers
    modifier isOwner(address nftAddress, uint256 tokenId){
        IERC721 nft = IERC721(nftAddress);
        if (msg.sender != nft.ownerOf(tokenId)){
            revert PandaMarket__NotTheOwner();
        }
        _;
    }

    modifier notListed(address nftAddress, uint256 tokenId) {
        if (listed[nftAddress][tokenId].price != 0){
            revert PandaMarket__AlreadyListed();
        }
        _;
    }

    // Functions

    /// @notice Sets the market fees
    /// @dev Initialises immutable market fees on deployment
    constructor(uint8 fee){
        marketFee = fee;
    }

    /// @notice Lists an NFT for sale
    /// @dev Lists an NFT for sale
    function listNft(address nftAddress, uint256 tokenId, uint256 price) external isOwner(nftAddress,tokenId) notListed(nftAddress, tokenId){

        if (price <= 0) {
            revert PandaMarket__PriceShouldBeZero();
        }
        IERC721 nft = IERC721(nftAddress);
        if (nft.getApproved(tokenId)!= address(this)) {
            revert PandaMarket__NotApproved();
        }

        listed[nftAddress][tokenId] = Listing(msg.sender,price);
        emit NftListed(nftAddress, tokenId,msg.sender,price);
    }
}