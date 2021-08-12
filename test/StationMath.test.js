//const { Contract } = require('@ethersproject/contracts');
const { assert } = require('chai');
const BigNumber = require('bignumber.js');
//const { camelCase } = require('lodash');         
//const { DH_UNABLE_TO_CHECK_GENERATOR } = require('node:constants');
//const _deploy_contracts = require('../migrations/006_mock_station_math.js')

//the commented out imports got added randomly, ignore them or don't, who cares

const MockStationMath = artifacts.require('MockStationMath');

require('chai')
    .use(require('chai-as-promised'))
    .should()
    function tokens(n) { // you can include this to see real numbers instead of 1mil 0's
        return web3utils.toWei(n, 'Ether');
    }

contract('MockStationMath', () => {

    // tests fns go in this scope and have close param syntax like the current scope

    //load contracts
    before (async() => {
        mockStationMath = await MockStationMath.new()

    })
//describe
//describe
//it
//it
    describe('inGivenOut', async() => {
      describe('returns amount in given out', async() => {
        it('Equal Prices', async() => {
            const PRICES = [BigNumber(1e18), BigNumber(1e18)];
            
            let result;

            let tokenIndexIn = 0;
            let tokenIndexOut = 1;
            let tokenAmountOut = BigNumber(1e18);
            
            result = await mockStationMath.inGivenOut(tokenIndexIn, tokenIndexOut, tokenAmountOut, PRICES);
            assert.equal(result.toString(), BigNumber(1e18) , 'token amount in was not correct')
            })
        it('Higher Price Token In', async() => {
            const PRICES = [BigNumber(2e18), BigNumber(1e18)];

            let result;

            let tokenIndexIn = 0;
            let tokenIndexOut = 1;
            let tokenAmountOut = BigNumber(2e18);

            result = await mockStationMath.inGivenOut(tokenIndexIn, tokenIndexOut, tokenAmountOut, PRICES);
            assert.equal(result.toString(), BigNumber(1e18), 'token amount in was not correct')
            })

        it('Higher Price Token Out', async() => {
            const PRICES = [BigNumber(1e18), BigNumber(2e18)];
            let tokenIndexIn = 0;
            let tokenIndexOut = 1;
            let tokenAmountOut = BigNumber(1e18);
            let result;

            result = await mockStationMath.inGivenOut(tokenIndexIn, tokenIndexOut, tokenAmountOut, PRICES);
            assert.equal(result.toString(), BigNumber(2e18), 'token amount out was not correct')
            })
            
        it('Zero Tokens Out', async() => {
            const PRICES = [BigNumber(1e18), BigNumber(2e18)];
            let tokenIndexIn = 0;
            let tokenIndexOut = 1;
            let tokenAmountOut = BigNumber(0e18);
            let result;
    
            result = await mockStationMath.inGivenOut(tokenIndexIn, tokenIndexOut, tokenAmountOut, PRICES);
            assert.equal(result.toString(), BigNumber(0e18), 'token amount out was not correct')
            })
        
        })       
    })
    describe('OutGivenIn', async() => {
        describe('returns amount out given in', async() => {
          
        it('Equal Prices', async() => {
            const PRICES = [BigNumber(1e18), BigNumber(1e18)];                        
            let tokenIndexIn = 0;
            let tokenIndexOut = 1;
            let tokenAmountIn = BigNumber(1e18);
            let result;
            
            result = await mockStationMath.outGivenIn(tokenIndexIn, tokenIndexOut, tokenAmountIn, PRICES)
            assert.equal(result.toString(), BigNumber(1e18), 'token amount in was not correct')
          })
        
        it('Higher Price Token In', async() => {
            const PRICES = [BigNumber(2e18), BigNumber(1e18)];                        
            let tokenIndexIn = 0;
            let tokenIndexOut = 1;
            let tokenAmountIn = BigNumber(1e18);
            let result;
            
            result = await mockStationMath.outGivenIn(tokenIndexIn, tokenIndexOut, tokenAmountIn, PRICES)
            assert.equal(result.toString(), BigNumber(2e18), 'token amount out was not correct')
          })

        it('Higher Price Token Out', async() => {
            const PRICES = [BigNumber(1e18), BigNumber(2e18)];                        
            let tokenIndexIn = 0;
            let tokenIndexOut = 1;
            let tokenAmountIn = BigNumber(2e18);
            let result;
            
            result = await mockStationMath.outGivenIn(tokenIndexIn, tokenIndexOut, tokenAmountIn, PRICES)
            assert.equal(result.toString(), BigNumber(1e18), 'token amount out was not correct')
          })

        it('Zero Tokens In', async() => {
            const PRICES = [BigNumber(1e18), BigNumber(1e18)];                        
            let tokenIndexIn = 0;
            let tokenIndexOut = 1;
            let tokenAmountIn = BigNumber(0e18);
            let result;
            
            result = await mockStationMath.outGivenIn(tokenIndexIn, tokenIndexOut, tokenAmountIn, PRICES)
            assert.equal(result.toString(), BigNumber(0e18), 'token amount in was not correct')
          })  
        })
    })

    describe('bptOutForAllTokensIn', async() => {
        describe('returns amount of pool tokens to send', async() => {
            it('Equal Balance/Price, 0 Pool tokens', async() => {
                const PRICES = [BigNumber(1e18), BigNumber(1e18)];
                let balances = [BigNumber(0), BigNumber(0)];
                let amountsIn = [BigNumber(1e18), BigNumber(1e18)];
                let totalBPT = BigNumber(0e18);
                let result;
                result = await mockStationMath.bptOutForAllTokensIn(balances, amountsIn, totalBPT, PRICES)
                assert.equal(result.toString(), BigNumber(10e18), 'bpt amount out was incorrect')
            })

            it('Equal Balance/Price, 10 Pool tokens', async() => {
                const PRICES = [BigNumber(1e18), BigNumber(1e18)];
                let balances = [BigNumber(1e18), BigNumber(1e18)];
                let amountsIn = [BigNumber(1e18), BigNumber(1e18)];
                let totalBPT = BigNumber(10e18);
                let result;
                result = await mockStationMath.bptOutForAllTokensIn(balances, amountsIn, totalBPT, PRICES)
                assert.equal(result.toString(), BigNumber(10e18), 'bpt amount out was incorrect')
            })

            it('Equal Balance, Price 0,  0 Pool tokens', async() => {
                const PRICES = [BigNumber(1e18), BigNumber(1e18)];
                let balances = [BigNumber(2e18), BigNumber(2e18)];
                let amountsIn = [BigNumber(1e18), BigNumber(1e18)];
                let totalBPT = BigNumber(0e18);
                let result;
                result = await mockStationMath.bptOutForAllTokensIn(balances, amountsIn, totalBPT, PRICES)
                assert.equal(result.toString(), BigNumber(10e18), 'bpt amount out was incorrect')
            })

            it('Equal Balance, Price Different, Amount in Different', async() => {
                const PRICES = [BigNumber(1e18), BigNumber(5e18)];
                let balances = [BigNumber(5e18), BigNumber(2e18)];
                let amountsIn = [BigNumber(5e18), BigNumber(11e18)];
                let totalBPT = BigNumber(10e18);
                let result;
                result = await mockStationMath.bptOutForAllTokensIn(balances, amountsIn, totalBPT, PRICES)
                assert.equal(result.toString(), BigNumber(40e18), 'bpt amount out was incorrect')
            })

            it('Equal Balance, Price Different, Amount in Different Flipped', async() => {
                const PRICES = [BigNumber(5e18), BigNumber(1e18)];
                let balances = [BigNumber(2e18), BigNumber(5e18)];
                let amountsIn = [BigNumber(11e18), BigNumber(5e18)];
                let totalBPT = BigNumber(10e18);
                let result;
                result = await mockStationMath.bptOutForAllTokensIn(balances, amountsIn, totalBPT, PRICES)
                assert.equal(result.toString(), BigNumber(40e18), 'bpt amount out was incorrect')
            })

            it('Amount in Zero', async() => {
                const PRICES = [BigNumber(5e18), BigNumber(1e18)];
                let balances = [BigNumber(2e18), BigNumber(5e18)];
                let amountsIn = [BigNumber(0), BigNumber(0)];
                let totalBPT = BigNumber(10e18);
                let result;
                result = await mockStationMath.bptOutForAllTokensIn(balances, amountsIn, totalBPT, PRICES)
                assert.equal(result.toString(), BigNumber(0), 'bpt amount out was incorrect')
            })

            it('Amount in less than balance', async() => {
                const PRICES = [Number(1), Number(1)];
                let balances = [BigNumber(6e18), BigNumber(4e18)];
                let amountsIn = [BigNumber(2e18), BigNumber(2e18)];
                let totalBPT = BigNumber(10e18);
                let result;
                result = await mockStationMath.bptOutForAllTokensIn(balances, amountsIn, totalBPT, PRICES)
                assert.equal(result.toString(), BigNumber(4.4e18).toString(), 'bpt amount out was incorrect')
            })
        })
    })

    describe('bptInForAllTokensOut', async() => {
        describe('placeholder text', async() => {
            it('Equal Balance/Price, 1 Pool token', async() => {
                const PRICES = [BigNumber(1e18), BigNumber(1e18)];
                let balances = [BigNumber(1e18), BigNumber(1e18)];
                let amountsOut = [BigNumber(1e18), BigNumber(1e18)];
                let totalBPT = BigNumber(1e18);
                let result;
                result = await mockStationMath.bptInForAllTokensOut(balances, amountsOut, totalBPT, PRICES)
                assert.equal(result.toString(), BigNumber(1e18), 'bpt amount out was incorrect')
            })

            it('Equal Balance/Price, 10 Pool tokens', async() => {
                const PRICES = [BigNumber(1e18), BigNumber(1e18)];
                let balances = [BigNumber(1e18), BigNumber(1e18)];
                let amountsOut = [BigNumber(1e18), BigNumber(1e18)];
                let totalBPT = BigNumber(10e18);
                let result;
                result = await mockStationMath.bptInForAllTokensOut(balances, amountsOut, totalBPT, PRICES)
                assert.equal(result.toString(), BigNumber(10e18), 'bpt amount out was incorrect')
            })

            it('Equal Balance, Price 1,  10 Pool tokens', async() => {
                const PRICES = [BigNumber(1e18), BigNumber(1e18)];
                let balances = [BigNumber(2e18), BigNumber(2e18)];
                let amountsOut = [BigNumber(1e18), BigNumber(1e18)];
                let totalBPT = BigNumber(10e18);
                let result;
                result = await mockStationMath.bptInForAllTokensOut(balances, amountsOut, totalBPT, PRICES)
                assert.equal(result.toString(), BigNumber(5e18).toString(), 'bpt amount out was incorrect')
            }) 

            it('Equal Balance, Price Different, Amount in Different', async() => {
                const PRICES = [BigNumber(1e18), BigNumber(5e18)];
                let balances = [BigNumber(5e18), BigNumber(2e18)];
                let amountsOut = [BigNumber(5e18), BigNumber(11e18)];
                let totalBPT = BigNumber(10e18);
                let result;
                result = await mockStationMath.bptInForAllTokensOut(balances, amountsOut, totalBPT, PRICES)
                assert.equal(result.toString(), BigNumber(40e18), 'bpt amount out was incorrect')
            })

            it('Equal Balance, Price Different, Amount in Different Flipped', async() => {
                const PRICES = [BigNumber(5e18), BigNumber(1e18)];
                let balances = [BigNumber(2e18), BigNumber(5e18)];
                let amountsOut = [BigNumber(11e18), BigNumber(5e18)];
                let totalBPT = BigNumber(10e18);
                let result;
                result = await mockStationMath.bptInForAllTokensOut(balances, amountsOut, totalBPT, PRICES)
                assert.equal(result.toString(), BigNumber(40e18), 'bpt amount out was incorrect')
            })

            it('Amount in Zero', async() => {
                const PRICES = [BigNumber(5e18), BigNumber(1e18)];
                let balances = [BigNumber(2e18), BigNumber(5e18)];
                let amountsOut = [BigNumber(0), BigNumber(0)];
                let totalBPT = BigNumber(10e18);
                let result;
                result = await mockStationMath.bptInForAllTokensOut(balances, amountsOut, totalBPT, PRICES)
                assert.equal(result.toString(), BigNumber(0), 'bpt amount out was incorrect')
            })

            it('Amount in less than balance', async() => {
                const PRICES = [Number(1), Number(1)];
                let balances = [BigNumber(6e18), BigNumber(4e18)];
                let amountsOut = [BigNumber(2e18), BigNumber(2e18)];
                let totalBPT = BigNumber(10e18);
                let result;
                result = await mockStationMath.bptInForAllTokensOut(balances, amountsOut, totalBPT, PRICES)
                assert.equal(result.toString(), BigNumber(0), 'bpt amount out was incorrect')
            })
        })
    })

    describe('calculateSwapFeeAmount', async() => {
        describe('Fee Amount', async() => {
            it('2 in 2 out', async() => {
                const PRICES = [BigNumber(1), BigNumber(1)];
                let balances = [BigNumber(10e18), BigNumber(10e18)];
                let amountsIn = [BigNumber(2e18), BigNumber(0)];
                let amountsOut = [BigNumber(0), BigNumber(2e18)];
                let amp = Number(10);
                let result;
                result = await mockStationMath.calculateSwapFeeAmount(balances, amountsIn, amountsOut, amp, PRICES)
                assert.equal(result.toString(), BigNumber(2e18), 'placeholder text')
            })
            it('5amp', async() => {
                const PRICES = [BigNumber(1), BigNumber(1)];
                let balances = [BigNumber(10e18), BigNumber(10e18)];
                let amountsIn = [BigNumber(2e18), BigNumber(0)];
                let amountsOut = [BigNumber(0), BigNumber(2e18)];
                let amp = Number(5);
                let result;
                result = await mockStationMath.calculateSwapFeeAmount(balances, amountsIn, amountsOut, amp, PRICES)
                assert.equal(result.toString(), BigNumber(2e18), 'placeholder text')
            })
            it('big math', async() => {
                const PRICES = [BigNumber(1), BigNumber(1)];
                let balances = [BigNumber(10e18), BigNumber(10e18)];
                let amountsIn = [BigNumber(7e18), BigNumber(0)];
                let amountsOut = [BigNumber(0), BigNumber(9e18)];
                let amp = Number(10);
                let result;
                result = await mockStationMath.calculateSwapFeeAmount(balances, amountsIn, amountsOut, amp, PRICES)
                assert.equal(result.toString(), BigNumber(7e18), 'placeholder text')
            })
            it('zero amounts', async() => {
                const PRICES = [BigNumber(1), BigNumber(1)];
                let balances = [BigNumber(10e18), BigNumber(10e18)];
                let amountsIn = [BigNumber(0), BigNumber(0)];
                let amountsOut = [BigNumber(0), BigNumber(0)];
                let amp = Number(10);
                let result;
                result = await mockStationMath.calculateSwapFeeAmount(balances, amountsIn, amountsOut, amp, PRICES)
                assert.equal(result.toString(), BigNumber(0), 'placeholder text')
            })
        })
    })
    describe('calculateWithdrawFee', async() => {
        describe('returns correct withdraw fee', async() => {
            it('zero withdraw amount', async() => {
                let amountsOut = [BigNumber(0), BigNumber(0)];
                const PRICES = [BigNumber(1), BigNumber(1)];
                let withdrawFeeRate = Number(10);
                
                result = await mockStationMath.calculateWithdrawFee(amountsOut, withdrawFeeRate, PRICES)
                assert.equal(result.toString(), [BigNumber(0), BigNumber(0)], 'amounts out is zero, output should be zero')
            })
            it('large withdraw amount', async() => {
                let amountsOut = [BigNumber(5e18), BigNumber(6e18)];
                const PRICES = [BigNumber(1), BigNumber(1)];
                let withdrawFeeRate = Number(10);
                
                result = await mockStationMath.calculateWithdrawFee(amountsOut, withdrawFeeRate, PRICES)
                assert.equal(result.toString(), [BigNumber(5e17), BigNumber(6e17)], 'amounts out is [5e18, 6e18], output should be 10%')
            })
            it('zero rate', async() => {
                let amountsOut = [BigNumber(5e18), BigNumber(6e18)];
                const PRICES = [BigNumber(1), BigNumber(1)];
                let withdrawFeeRate = Number(0);
                
                result = await mockStationMath.calculateWithdrawFee(amountsOut, withdrawFeeRate, PRICES)
                assert.equal(result.toString(), [BigNumber(0), BigNumber(0)], 'amounts out is [5e18, 6e18], output should be 0%')
            })
            it('high rate', async() => {
                let amountsOut = [BigNumber(5e18), BigNumber(6e18)];
                const PRICES = [BigNumber(1), BigNumber(1)];
                let withdrawFeeRate = Number(20);
                
                result = await mockStationMath.calculateWithdrawFee(amountsOut, withdrawFeeRate, PRICES)
                assert.equal(result.toString(), [BigNumber(2.5e17), BigNumber(3e17)], 'amounts out is [5e18, 6e18], output should be 20%')
            })
        })
    })
})
//added this later

//here
