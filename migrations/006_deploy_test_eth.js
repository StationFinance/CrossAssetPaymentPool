const TestETH = artifacts.require('TestETH');

module.exports = async function(deployer, _network, _accounts) {
    await deployer.deploy(TestETH, _accounts[0], 'ETH', 'ETH', 18)
    const eth = await TestETH.deployed()
}