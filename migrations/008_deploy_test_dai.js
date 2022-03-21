const TestDAI = artifacts.require('TestDAI');

module.exports = async function(deployer, _network, _accounts) {
    await deployer.deploy(TestDAI, _accounts[0], 'DAI', 'DAI', 18)
    const dai = await TestDAI.deployed()
}