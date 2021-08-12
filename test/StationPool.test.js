const { assert, expect } = require('chai');
const BigNumber = require('bignumber.js');
const Vault = artifacts.require('Vault')
const BalancerPoolToken = artifacts.require('BalancerPoolToken')
const {ethers} = require('ethers');
const { result } = require('lodash');
const StationPoolFactory = artifacts.require('StationPoolFactory');
const StationPool = artifacts.require('StationPool');
const TestToken1 = artifacts.require('TestToken1');
const TestToken2 = artifacts.require('TestToken2');
const TestToken3 = artifacts.require('TestToken3');
const TestToken4 = artifacts.require('TestToken4');

const JOIN_STATION_POOL_INIT_TAG = 0;
const JOIN_STATION_POOL_BPT_OUT_FOR_ALL_TOKENS_IN_TAG = 1;

var JoinStationPoolInit = {
  kind: 'Init',
  amountsIn: Array()
};

var JoinStationPoolBPTOutForAllTokensIn = {
  kind: 'bptOutForAllTokensIn',
  amountsIn: Array()
};
joinData = JoinStationPoolInit | JoinStationPoolBPTOutForAllTokensIn
function encodeJoinStationPool(joinData){
  if (joinData.kind == 'Init') {
    return ethers.utils.defaultAbiCoder.encode(
      ['uint256', 'uint256[]'],
      [JOIN_STATION_POOL_INIT_TAG, joinData.amountsIn]
    );
  } else {
    return ethers.utils.defaultAbiCoder.encode(
      ['uint256', 'uint256[]'],
      [JOIN_STATION_POOL_BPT_OUT_FOR_ALL_TOKENS_IN_TAG, joinData.amountsIn]
    );
  }
}

const EXIT_STATION_POOL_BPT_IN_FOR_ALL_TOKENS_OUT_TAG = 0;

var ExitStationPoolBPTInForAllTokensOut = {
  kind: 'bptInForAllTokensOut',
  amountsOut: Array()
}
exitData = ExitStationPoolBPTInForAllTokensOut
function encodeExitStationPool(exitData){
  return ethers.utils.defaultAbiCoder.encode(
    ['uint256', 'uint256[]'],
    [EXIT_STATION_POOL_BPT_IN_FOR_ALL_TOKENS_OUT_TAG, exitData.amountsOut]
  );
}


require('chai')
    .use(require('chai-as-promised'))
    .should()

        contract('StationPool', (_accounts,) =>{
            before(async () => {
                stationPoolFactory = await StationPoolFactory.deployed()
                testToken1 = await TestToken1.deployed()
                testToken2 = await TestToken2.deployed()
                testToken3 = await TestToken3.deployed()
                testToken4 = await TestToken4.deployed()
                vault = await Vault.deployed()
                balances = new Array()
                tokens = [testToken1.address, testToken2.address, testToken3.address, testToken4.address]
                tokensC = [testToken1, testToken2, testToken3, testToken4]
                poolAddress = await stationPoolFactory.create('BalancerPoolToken', 'BPT', tokens, 10, 10, 100, 10)
                stationPoolA = poolAddress.logs[0].args[0]
                stationPool = await StationPool.at(poolAddress.logs[0].args[0])
                poolId = await stationPool.getPoolId()
                console.log(_accounts[0]);
                
            })
            describe('Mint tokens', async() => {
                it('mints the correct token amounts', async() =>{
                    for(i = 0; i < tokensC.length; i++){
                        await tokensC[i].mint(_accounts[0], BigNumber(150e18))
                        balances.push(await tokensC[i].balanceOf(_accounts[0]))
                    }
                    expected = [BigNumber(150e18), BigNumber(150e18), BigNumber(150e18), BigNumber(150e18)]
                    assert.equal(balances.toString(), expected.toString(), 'the token amounts are not correct')
                })
            })
            describe('the StationPool is deployed', async () =>{
                it('has the correct amp', async() =>{
                    assert.equal(await stationPool.getAmp(), 10, 'the amp is not the same')
                })
                it('has a poolID', async() =>{
                    assert.notEqual(await stationPool.getPoolId(), 0 , 'the poolId has not been set')
                })
                it('is connected to the vault', async() =>{
                    assert.equal(await stationPool.getVault(), vault.address, 'the pool is not connected to the vault')
                })
                it('has registered tokens', async() =>{
                    balancesT = [0, 0, 0, 0]
                    results = await vault.getPoolTokens(poolId)
                    assert.equal((results.tokens.toString(), results.balances.toString()), (tokens, balancesT) , 'the tokens are registered')
                })
            })
            describe('JoinPool', async() => {
              
                it('initializes', async() => {

                    for(i = 0; i < tokensC.length; i++){
                      await tokensC[i].approve(vault.address, BigNumber(50e18))
                      }
                    amounts = [BigNumber(50e18).toString(), BigNumber(50e18).toString(), BigNumber(50e18).toString(), BigNumber(50e18).toString()]
                    joinUserData = encodeJoinStationPool({ kind: 'Init', amountsIn: amounts });
                    await vault.joinPool(poolId, _accounts[0], _accounts[0], tokens, amounts, false, joinUserData)
                    results = await vault.getPoolTokens(poolId)
                    for(i = 0; i < tokensC.length; i++){
                      balances[i] -= amounts[i]
                    }
                    assert.equal((results.tokens.toString(), results.balances.toString()), (tokens, amounts), 'join pool unsuccessful')
                })
                it('joins pool', async() => {

                  for(i = 0; i < tokensC.length; i++){
                    await tokensC[i].approve(vault.address, BigNumber(50e18))
                    }
                  amounts = [BigNumber(50e18).toString(), BigNumber(50e18).toString(), BigNumber(50e18).toString(), BigNumber(50e18).toString()]
                  joinUserData = encodeJoinStationPool({ kind: 'bptOutForAllTokensIn', amountsIn: amounts });
                  await vault.joinPool(poolId, _accounts[0], _accounts[0], tokens, amounts, false, joinUserData)
                  results = await vault.getPoolTokens(poolId)
                  for(i = 0; i < tokensC.length; i++){
                    balances[i] = await tokensC[i].balanceOf(_accounts[0])
                  }
                  assert.equal((results.tokens.toString(), results.balances.toString()), (tokens, amounts), 'join pool unsuccessful')
              })
                it('Exits after Joins', async() => {
                  bptBalance = await stationPool.balanceOf(_accounts[0])
                  console.log('HERE ' + bptBalance.toString())
                  poolTokenInfo = await vault.getPoolTokenInfo(poolId, tokens[0])
                  console.log('INFO ' + poolTokenInfo.cash.toString())
                  await stationPool.approve(vault.address, bptBalance.toString())
                  amounts = [0, 0, 0, 0]
                  results = await vault.getPoolTokens(poolId)
                  amts = [BigNumber(50e18).toString(), BigNumber(50e18).toString(), BigNumber(50e18).toString(), BigNumber(50e18).toString()]
                  console.log(amts)
                  exitUserData = encodeExitStationPool({kind: 'bptInForAllTokensOut', amountsOut: amts})
                  await vault.exitPool(poolId, _accounts[0], _accounts[0], tokens, amts, false, exitUserData)
                  
                  assert.equal((results.tokens.toString(), results.balances.toString()), (tokens, amounts), 'exit pool unsuccessful')
                })
            })
        })