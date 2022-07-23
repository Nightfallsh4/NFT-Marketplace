const { expect, assert } = require("chai")
const { network, getNamedAccounts, deployments, ethers } = require("hardhat")
const { developmentChains } = require("../../helper-hardhat-config")
/* global BigInt */

!developmentChains.includes(network.name)
	? describe.skip
	: describe("Marketplace Unit tests", function () {
			beforeEach(async () => {})
	  })
