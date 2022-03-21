const TestWETH = artifacts.require('TestWETH')

module.exports = async function(deployer, _network, _accounts) {
    await deployer.deploy(TestWETH, _accounts[0])
    const weth = await TestWETH.deployed()
}