const MockStationMath = artifacts.require('MockStationMath');

module.exports = async function(deployer, _network, _accounts) {
    await deployer.deploy(MockStationMath)
    mockStationMath = await MockStationMath.deployed()
}