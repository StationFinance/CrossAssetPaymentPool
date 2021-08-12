const Vault = artifacts.require('Vault')

module.exports = async function(deployer, _network, _accounts) {
    await deployer.deploy(Vault, _accounts[0], 90, 30)
    const vault = await Vault.deployed()
}