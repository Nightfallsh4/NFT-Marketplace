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
error PandaMarket__DontStealNotOwner();
error PandaMarket__TransferNotSuccess();
error PandaMarket__NotOwner__StopTryingToStealDumbass();

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

    event NftCancelled(
        address indexed nftAddress,
        uint256 indexed tokenId
    );

    // Modifiers

    /// @notice Checks to see if the transaction sender is the owner of the NFT. Input- nftAddress, tokenId
    /// @dev Checks if msg.sender is the ownerOf the NFT address
    /// @param nftAddress - Address of the NFT
    /// @param tokenId - Token ID of the NFT
    modifier isOwner(address nftAddress, uint256 tokenId){
        IERC721 nft = IERC721(nftAddress);
        if (msg.sender != nft.ownerOf(tokenId)){
            revert PandaMarket__NotTheOwner();
        }
        _;
    }

    /// @notice Checks if the NFT is not listed already. Input- nftAddress, tokenId
    /// @param nftAddress - Address of the NFT
    /// @param tokenId - Token ID of the NFT
    modifier notListed(address nftAddress, uint256 tokenId) {
        if (s_listed[nftAddress][tokenId].price != 0){
            revert PandaMarket__AlreadyListed();
        }
        _;
    }

    /// @notice Checks if the NFT is listed already. Input- nftAddress, tokenId
    /// @param nftAddress - Address of the NFT
    /// @param tokenId - Token ID of the NFT
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

    /// @notice Cancels Listing if NFT. Takes Inputs as NftAddress, tokenId
    /// @param nftAddress - Address of the NFT to be delisted
    /// @param tokenId - Token ID of the NFT to be delisted
    function cancelNft(address nftAddress, uint256 tokenId) external isOwner(nftAddress,tokenId) isListed(nftAddress, tokenId) {
        delete s_listed[nftAddress][tokenId];
        emit NftCancelled(nftAddress, tokenId);
    }
    
    /// @notice Updates the Listed Price of the NFT. Takes Input as nftAddress, tokenId and newPrice
    /// @param nftAddress - Address of the NFT to be updated
    /// @param tokenId - tokenId of the NFT to be updated
    /// @param newPrice -The new price it should be updated to.
    function updateNft(address nftAddress, uint256 tokenId, uint256 newPrice) external isOwner(nftAddress,tokenId) isListed(nftAddress, tokenId) {
        s_listed[nftAddress][tokenId] = Listing(msg.sender,newPrice);
        emit NftListed(nftAddress, tokenId, msg.sender, newPrice);
    }

    /// @notice Withdraw the proceeds of an account from sales
    function withdrawProceeds() external {
        uint256 proceed = getProceeds(msg.sender);
        if (proceed <= 0) {
            revert PandaMarket__NotEnoughFunds();
        }
        s_proceeds[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value:proceed}("");
        if (!success) {
            revert PandaMarket__TransferNotSuccess();
        }
    }
    /// @notice Withdraws the market treasury to the owner's address
    function withdrawTreasury() external {
        if (msg.sender != i_owner) {
            revert PandaMarket__NotOwner__StopTryingToStealDumbass();
        }
        uint256 treasuryBalance = getTreasuryBalance();
        if (treasuryBalance <= 0) {
            revert PandaMarket__NotEnoughFunds();
        }
        s_marketTreasury = 0;
        (bool success, ) = payable(i_owner).call{value:treasuryBalance}("");
        if (!success) {
            revert PandaMarket__TransferNotSuccess();
        }
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

    /// @notice Gets the proceeds of a user from NFT sales. Takes userAddress as input
    /// @dev returns the proceeds of a address from NFT sales.
    /// @param userAddress - the Address which the proceeds is needed
    function getProceeds(address userAddress) public view returns (uint256) {
        return s_proceeds[userAddress];
    }

    /// @notice Calculates the market fee of an NFT sale. Takes price as the input
    /// @param price - the price of the sale
    function getMarketFee(uint256 price) public view returns (uint256){
        return price * i_marketFee / 100;
    }

    /// @notice returns the balance of the market treasury
    function getTreasuryBalance() public view returns (uint256){
        return s_marketTreasury;
    }

    /// @notice Checks whether the NFT contract is ERC2981 compatible for creator royalty. Takes _contract of the NFT as an input.
    /// @param _contract - the Contract Address of the NFT
    function checkRoyalties(address _contract) internal view returns (bool) {
        (bool success) = IERC165(_contract).supportsInterface(_INTERFACE_ID_ERC2981);
        return success;
    }

    /// @notice Returns the amount and the address to pay the royalty to. Takes input as nftAddress, tokenId and price.
    /// @param nftAddress - The Address of the NFT
    /// @param tokenId - The Token ID of the NFT
    /// @param price - The Price of the NFT
    function getRoyaltyData(address nftAddress, uint256 tokenId,uint256 price) public view returns(address,uint256) {
        return ERC721Royalty(nftAddress).royaltyInfo(tokenId,price);
    }

}