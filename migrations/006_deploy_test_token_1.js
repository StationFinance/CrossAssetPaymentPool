const TestToken1 = artifacts.require('TestToken1');

module.exports = async function(deployer, _network, _accounts) {
    await deployer.deploy(TestToken1, _accounts[0], 'TestToken1', 'TK1', 18)
    const testToken1 = await TestToken1.deployed()
}