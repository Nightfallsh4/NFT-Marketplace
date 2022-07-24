// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";

// Errors
error PandaMarket__NotTheOwner();
error PandaMarket__PriceShouldNotBeZero();
error PandaMarket__NotApproved();
error PandaMarket__AlreadyListed();
error PandaMarket__NotListed();
error PandaMarket__NotEnoughFunds();

/// @title An NFT Marketplace to trade NFTs
/// @author Shanmugadevan
contract PandaMarket {
    // Type variables
    struct Listing{
        address seller;
        uint256 price;
    }

    // State Variables
    uint8 private immutable i_marketFee;
    address private immutable i_owner;
    uint256 private s_marketTreasury;
    mapping(address => mapping(uint256 => Listing)) private s_listed;
    mapping(address => uint256) private s_proceeds;
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    // Events
    event NftListed(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 price

    );

    event NftBought(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed buyer
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

    modifier isListed(address nftAddress, uint256 tokenId) {
        if (s_listed[nftAddress][tokenId].price == 0) {
            revert PandaMarket__NotListed();
        }
        _;
    }

    // Functions

    /// @notice Sets the market fees percentage
    /// @dev Initialises immutable market fee percentage on deployment
    constructor(uint8 fee){
        i_marketFee = fee;
        i_owner = msg.sender;
    }


    // External Functions

    /// @notice Lists an NFT for sale. Inputs are nftAddress, tokenId and price
    /// @dev Lists an NFT for sale
    /// @param nftAddress - The address of the NFT contract to be listed
    /// @param tokenId - The tokenId of the NFT to be listed
    /// @param price - The price the NFT should listed
    function listNft(address nftAddress, uint256 tokenId, uint256 price) external 
        isOwner(nftAddress,tokenId) 
        notListed(nftAddress, tokenId)
        {

        if (price <= 0) {
            revert PandaMarket__PriceShouldNotBeZero();
        }
        IERC721 nft = ERC721Royalty(nftAddress);
        if (nft.getApproved(tokenId)!= address(this)) {
            revert PandaMarket__NotApproved();
        }

        s_listed[nftAddress][tokenId] = Listing(msg.sender,price);
        emit NftListed(nftAddress, tokenId,msg.sender,price);
    }


    /// @notice Buys listed NFT with nftAddress and tokenId. A percentage of proceeds from sale go to the market and the creator.
    /// @dev Looks for a royaltyInfo from ERC721Royalty, if not creator fee is not paid. 
    /// @param nftAddress - the Address of the NFT to buy
    /// @param tokenId - the Token ID of the NFT to buy
    function buyNft(address nftAddress, uint256 tokenId) external payable isListed(nftAddress, tokenId){
        
        Listing memory list = getListed(nftAddress,tokenId);

        if (msg.value < list.price){
            revert PandaMarket__NotEnoughFunds();
        }

        delete s_listed[nftAddress][tokenId];
        
        IERC721 nft = ERC721Royalty(nftAddress);
        uint256 marketFee = getMarketFee(list.price);
        bool isRoyaltyEnabled = checkRoyalties(nftAddress);

        if (isRoyaltyEnabled) {
        
            (address creatorAddress, uint256 creatorFee) = getRoyaltyData(nftAddress, tokenId, list.price);
            uint256 sellerProceeds = msg.value -marketFee;
            sellerProceeds -= creatorFee; 
        
            nft.safeTransferFrom(list.seller, msg.sender, tokenId);
            s_proceeds[list.seller] += sellerProceeds;
            s_proceeds[creatorAddress] += creatorFee;
            s_marketTreasury += marketFee;
        
        }else {
        
            uint256 sellerProceeds = msg.value - marketFee;
        
            nft.safeTransferFrom(list.seller, msg.sender, tokenId);
            s_proceeds[list.seller] += sellerProceeds;
        
        }
        
        emit NftBought(nftAddress, tokenId, msg.sender);
    }

    // Public Functions


    // Getter Functions
    
    /// @notice Gets the listed struct:- nftAddress, tokenId
    /// @dev Returns the listed struct
    /// @param nftAddress - the address of the listed NFT to get,
    /// @param tokenId - the tokenId of the listed NFT to get
    function getListed(address nftAddress, uint256 tokenId) public view returns(Listing memory) {
        return s_listed[nftAddress][tokenId];
    }

    function getProceeds(address userAddress) public view returns (uint256) {
        return s_proceeds[userAddress];
    }

    function getMarketFee(uint256 price) public view returns (uint256){
        return price * i_marketFee / 100;
    }

    function getTreasuryBalance() public view returns (uint256){
        return s_marketTreasury;
    }

    function checkRoyalties(address _contract) internal view returns (bool) {
        (bool success) = IERC165(_contract).supportsInterface(_INTERFACE_ID_ERC2981);
        return success;
    }
    function getRoyaltyData(address nftAddress, uint256 tokenId,uint256 price) public view returns(address,uint256) {
        return ERC721Royalty(nftAddress).royaltyInfo(tokenId,price);
    }

}