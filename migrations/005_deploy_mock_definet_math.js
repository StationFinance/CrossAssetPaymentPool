const MockStationMath = artifacts.require('MockStationMath');

module.exports = async function(deployer, _network, _accounts) {
    await deployer.deploy(MockStationMath)
    const mockStationMath = await MockStationMath.deployed()
}