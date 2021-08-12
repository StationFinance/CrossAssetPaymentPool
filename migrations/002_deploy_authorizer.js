const Authorizer = artifacts.require('Authorizer')
module.exports = async function(deployer, _network, _accounts) {
    //deploy authorizer
    await deployer.deploy(Authorizer, _accounts[0])
    const authorizer = await Authorizer.deployed()
}