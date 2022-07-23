// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/// @title An NFT Marketplace to trade NFTs
/// @author Shanmugadevan
contract PandaMarket {
    // Type variables
    struct Listing{
        address nftAddress;
        address seller;
        uint256 tokenId;
        uint256 price;
    }

    // State Variables
    uint8 private immutable marketFee;
    mapping(address => mapping(uint256 => Listing)) private listed;

    // Events

    // Modifiers


    // Functions

    /// @notice Sets the market fees
    /// @dev Initialises immutable market fees on deployment
    constructor(uint8 fee){
        marketFee = fee;
    }

    function listNft(address nftAddress, uint256 tokenId, uint256 price) external {
        
    }
}