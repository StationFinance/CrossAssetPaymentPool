const Vault = artifacts.require('@balancer-labs/v2-vault/contracts/Vault.sol')
const StationPoolFactory = artifacts.require('StationPoolFactory')

module.exports = async function(deployer, _network, _accounts) {
     //deploy station pool factory
     await deployer.deploy(StationPoolFactory, Vault.address)
     const stationPoolFactory = await StationPoolFactory.deployed()
}