const MockOracle = artifacts.require("MockOracle")

module.exports = async function(deployer, _network, _accounts) {
    await deployer.deploy(MockOracle)
    const mockOracle = await MockOracle.deployed()
}