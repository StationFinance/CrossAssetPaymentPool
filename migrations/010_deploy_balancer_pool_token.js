const BalancerPoolToken = artifacts.require('BalancerPoolToken');

module.exports = async function(deployer, _network, _accounts) {
    await deployer.deploy(BalancerPoolToken, 'BalancerPoolToken', 'BPT')
    balancerPoolToken = await BalancerPoolToken.deployed()
}