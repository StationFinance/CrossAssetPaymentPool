const TestToken4 = artifacts.require('TestToken4');

module.exports = async function(deployer, _network, _accounts) {
    await deployer.deploy(TestToken4, _accounts[0], 'TestToken4', 'TK4', 18)
    testToken4 = await TestToken4.deployed()
}