// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// Errors
error PandaMarket__NotTheOwner();
error PandaMarket__PriceShouldNotBeZero();
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
    mapping(address => mapping(uint256 => Listing)) private s_listed;

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
        if (s_listed[nftAddress][tokenId].price != 0){
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
    // External Functions

    /// @notice Lists an NFT for sale. Inputs are nftAddress, tokenId and price
    /// @dev Lists an NFT for sale
    /// @param nftAddress - The address of the NFT contract to be listed
    /// @param tokenId - The tokenId of the NFT to be listed
    /// @param price - The price the NFT should listed
    function listNft(address nftAddress, uint256 tokenId, uint256 price) external isOwner(nftAddress,tokenId) notListed(nftAddress, tokenId){

        if (price <= 0) {
            revert PandaMarket__PriceShouldNotBeZero();
        }
        IERC721 nft = IERC721(nftAddress);
        if (nft.getApproved(tokenId)!= address(this)) {
            revert PandaMarket__NotApproved();
        }

        s_listed[nftAddress][tokenId] = Listing(msg.sender,price);
        emit NftListed(nftAddress, tokenId,msg.sender,price);
    }

    // Public Functions


    // Getter Functions
    
    /// @notice Gets the listed struct:- nftAddress, tokenId
    /// @dev Returns the listed struct
    /// @notice
    /// @param nftAddress - the address of the listed NFT to get,
    /// @param tokenId - the tokenId of the listed NFT to get
    function getListed(address nftAddress, uint256 tokenId) public view returns(Listing memory) {
        return s_listed[nftAddress][tokenId];
    }

}