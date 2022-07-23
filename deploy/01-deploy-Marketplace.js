const { network } = require("hardhat")

module.exports = async function ({ getNamedAccounts, deployments }) {
	const { deploy, log } = deployments
	const { deployer } = await getNamedAccounts()
    log("\n")
    await deploy("PandaMarket",{
        from:deployer,
        args: [5],
        log:true,
        waitConfirmations: network.config.blockConfirmations || 1
    })
    log("Deployed Marketplace")
}

module.exports.tags = ["all","PandaMarketplace"]