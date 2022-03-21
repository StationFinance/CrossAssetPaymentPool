const TestBTC = artifacts.require('TestBTC');

module.exports = async function(deployer, _network, _accounts) {
    await deployer.deploy(TestBTC, _accounts[0], 'BTC', 'BTC', 18)
    const btc = await TestBTC.deployed()
}