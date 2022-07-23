const { expect, assert } = require("chai")
const { network, getNamedAccounts, deployments, ethers } = require("hardhat")
const { developmentChains } = require("../../helper-hardhat-config")
/* global BigInt */

!developmentChains.includes(network.name)
	? describe.skip
	: describe("Marketplace Unit tests", function () {
			let deployer, player, deployerMarketplace, nft, tokenId
			beforeEach(async () => {
				deployer = (await getNamedAccounts()).deployer
				player = (await getNamedAccounts()).player
				await deployments.fixture(["all"])
				deployerMarketplace = await ethers.getContract("PandaMarket", deployer)
				playerMarketplace = await ethers.getContract("PandaMarket", player)
				nft = await ethers.getContract("PandaNft", deployer)
				await nft.mintNft()
				tokenId = await nft.getCounter()
			})

			describe("listNft test", async () => {
				it("Reverts if value is zero", async () => {
					await nft.approve(deployerMarketplace.address, tokenId)
					await expect(
						deployerMarketplace.listNft(nft.address, tokenId, 0),
					).to.be.revertedWith("PandaMarket__PriceShouldNotBeZero")
				})

				it("Reverts if notOwner try to list", async () => {
					const price = ethers.utils.parseEther("0.4")
					await nft.approve(deployerMarketplace.address, tokenId)
					await expect(
						playerMarketplace.listNft(nft.address, tokenId, price),
					).to.be.revertedWith("PandaMarket__NotTheOwner")
				})
				it("Reverts if Already Listed", async () => {
					const price = ethers.utils.parseEther("0.4")
					await nft.approve(deployerMarketplace.address, tokenId)
					const tx = await deployerMarketplace.listNft(
						nft.address,
						tokenId,
						price,
					)
					await tx.wait(1)
					await expect(
						deployerMarketplace.listNft(nft.address, tokenId, price),
					).to.be.revertedWith("PandaMarket__AlreadyListed")
				})
				it("Reverts if not approved", async () => {
					const price = ethers.utils.parseEther("0.4")
					await expect(
						deployerMarketplace.listNft(nft.address, tokenId, price),
					).to.be.revertedWith("PandaMarket__NotApproved")
				})
				it("Adds to listing", async () => {
					const price = ethers.utils.parseEther("0.4")
					await nft.approve(deployerMarketplace.address, tokenId)
					await deployerMarketplace.listNft(nft.address, tokenId, price)
                    const listed = await deployerMarketplace.getListed(nft.address, tokenId)
                    assert.equal(listed.price.toString(), price.toString())
                    assert.equal(deployer,listed.seller)
				})
                it("Emits event", async () => {
                    const price = ethers.utils.parseEther("0.4")
					await nft.approve(deployerMarketplace.address, tokenId)
                    await expect(deployerMarketplace.listNft(nft.address, tokenId, price)).to.emit(deployerMarketplace,"NftListed")
                })
			})
	  })
