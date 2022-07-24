const { network } = require("hardhat")
const { developmentChains } = require("../helper-hardhat-config")

module.exports = async function ({ getNamedAccounts, deployments }) {
	const { deploy, log } = deployments
	const { deployer } = await getNamedAccounts()
	const args = []
    const basicNft = await deploy("BasicNft",{
        from:deployer,
        args:args,
        log:true,
        waitConfirmations: network.config.blockconfirmations || 1
    })

//     if (!developmentChains.includes(network.name)) {
//         log(basicNft)
//     }
    log("-------------------------------------")

}

module.exports.tags = ["all", "BasicNft"]