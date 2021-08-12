const TestToken3 = artifacts.require('TestToken3');

module.exports = async function(deployer, _network, _accounts) {
    await deployer.deploy(TestToken3, _accounts[0], 'TestToken3', 'TK3', 18)
    const testToken3 = await TestToken3.deployed()
}