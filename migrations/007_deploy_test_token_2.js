const TestToken2 = artifacts.require('TestToken2');

module.exports = async function(deployer, _network, _accounts) {
    await deployer.deploy(TestToken2, _accounts[0], 'TestToken2', 'TK2', 18)
    const testToken2 = await TestToken2.deployed()
}