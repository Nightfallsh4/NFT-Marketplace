const { network } = require("hardhat")

module.exports = async function ({ getNamedAccounts, deployments }) {
	const { deploy, log } = deployments
	const { deployer } = await getNamedAccounts()
	log("\nGetting Panda Ready..........\n")
	const pandaNft = await deploy("PandaNft", {
		from: deployer,
		log: true,
		args: [],
		waitConfirmations: network.config.blockConfirmations || 1,
	})

	log("Panda Ready!\n")
	log("-----------------------------------\n")
}

module.exports.tags = ["all", "PandaNft"]
