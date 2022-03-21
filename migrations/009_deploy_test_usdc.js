const TestUSDC = artifacts.require('TestUSDC');

module.exports = async function(deployer, _network, _accounts) {
    await deployer.deploy(TestUSDC, _accounts[0], 'USDC', 'USDC', 18)
    usdc = await TestUSDC.deployed()
}