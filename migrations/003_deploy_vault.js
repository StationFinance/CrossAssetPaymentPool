const Vault = artifacts.require('Vault')
const TestWETH = artifacts.require('TestWETH')


module.exports = async function(deployer, _network, _accounts) {
    await deployer.deploy(Vault, TestWETH.address, _accounts[0], 90, 30)
    const vault = await Vault.deployed()
}