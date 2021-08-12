// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

import "../../lib/math/FixedPoint.sol";
import "../../lib/math/LogExpMath.sol";
import "../../lib/math/Math.sol";


// This is a contract to emulate file-level functions. Convert to a library
// after the migration to solc v0.7.1.

/* solhint-disable private-vars-leading-underscore */

/* solhint-disable var-name-mixedcase */

contract StationMath {
    using FixedPoint for uint256;
    struct RateInfo {
      uint256[] rates;
      uint256[] rateDiffs;
      uint256[] amountsInRates;
      uint256[] amountsOutRates;
      uint256 meanRate;
    }

    struct ValueInfo {
      uint256[] values;
      uint256[] inValues;
      uint256[] outValues;
      uint256 totalValue;
      uint256 totalOutValue;
    }

    struct TokenSwapInfo {
      uint128 tokenIndexIn;
      uint128 tokenIndexOut;
      uint256[] amountsIn;
      uint256[] amountsOut;
      uint256[] balances;
    }

    struct BptInfo {
      uint256 bptOut;
      uint256 bptIn;
      uint256 bptTempOut;
      uint256 bptTempIn;
    }

    uint256 constant internal ONEH = 100;
    uint256 constant internal TENTHOU = 10000;

    function _inGivenOut(
        uint256 tokenIndexIn,
        uint256 tokenIndexOut,
        uint256 tokenAmountOut,
        uint256[] memory prices
    ) internal pure returns (uint256) {
      if(tokenAmountOut == 0){
        return 0;
      }
        uint256 totalPrice = tokenAmountOut.mulUp(prices[tokenIndexOut]);
        uint256 tokenAmountIn = totalPrice.divUp(prices[tokenIndexIn]);
        return tokenAmountIn;
      }

    function _outGivenIn(
      uint256 tokenIndexIn,
      uint256 tokenIndexOut,
      uint256 tokenAmountIn,
      uint256[] memory prices
    ) internal pure returns (uint256) {
      if(tokenAmountIn == 0){
        return 0;
      }
      uint256 totalPrice = tokenAmountIn.mulUp(prices[tokenIndexIn]);
      uint256 tokenAmountOut = totalPrice.divUp(prices[tokenIndexOut]);
      return tokenAmountOut;
    }

    function _bptOutForAllTokensIn(
        uint256[] memory balances,
        uint256[] memory amountsIn,
        uint256 totalBPT,
        uint256[] memory prices
    ) internal pure returns (uint256) {

      if(totalBPT == 0){
        return 10 ** 19;
      }
        ValueInfo memory VAL;
        RateInfo memory RT;
        BptInfo memory BPT;
        uint256 len = balances.length;
        
        VAL.values = new uint256[](len);
        VAL.inValues = new uint256[](len);
        VAL.totalValue;
        uint256 totalInValue;
        

        for (uint i = 0; i < len; i++) {
            VAL.values[i] = balances[i].mulDown(prices[i]);
            VAL.totalValue = VAL.totalValue.add(VAL.values[i]);
            VAL.inValues[i] = amountsIn[i].mulUp(prices[i]);
            totalInValue = totalInValue.add(VAL.inValues[i]);
            
        }

        BPT.bptOut;

        if(totalInValue > VAL.totalValue){
          BPT.bptOut = totalInValue.divDown(VAL.totalValue).mulDown(totalBPT);
          return BPT.bptOut;
        }

        if(totalInValue == VAL.totalValue){
          return totalBPT;
        }

        RT.meanRate = ONEH / len;
        RT.rateDiffs = new uint256[](len);
        RT.rates = new uint256[](len);
        RT.amountsInRates = new uint256[](len);

        uint256 tempBPT;
       for(uint i = 0; i < len; i++){
         if(VAL.inValues[i] != 0){
         BPT.bptTempOut;
         RT.rates[i] = ONEH.divUp(VAL.totalValue.divUp(VAL.values[i]));
   
         RT.meanRate >= RT.rates[i] ? RT.rateDiffs[i] = RT.meanRate - RT.rates[i] : RT.rateDiffs[i] = RT.rates[i] - RT.meanRate;
         RT.amountsInRates[i] = ONEH.divDown(VAL.totalValue.div(VAL.inValues[i]));
         BPT.bptTempOut = totalBPT.divDown(RT.amountsInRates[i]).mulDown(RT.amountsInRates[i].divUp(ONEH.divUp(RT.amountsInRates[i]))); //ONEH.div(totalBPT.divDown(RT.amountsInRates[i]));
        
         BPT.bptTempOut += BPT.bptTempOut.divDown(RT.rateDiffs[i]).mulDown(RT.rateDiffs[i].divUp(ONEH.divUp(RT.rateDiffs[i])));
         tempBPT += BPT.bptTempOut;
         }
       }
       
       BPT.bptOut = tempBPT;
       
       return BPT.bptOut;
    }

    function _bptInForAllTokensOut (
        uint256[] memory balances,
        uint256[] memory amountsOut,
        uint256 totalBPT,
        uint256[] memory prices
    ) internal pure returns (uint256) {
       ValueInfo memory VAL;
       RateInfo memory RT;
       BptInfo memory BPT;
       uint256 len = balances.length;

       VAL.values = new uint256[](len);
       VAL.outValues = new uint256[](len);
       VAL.totalValue;
       BPT.bptIn;
       
      
       for(uint i = 0; i < len; i++) {
         VAL.values[i] = balances[i].mul(prices[i]);
         VAL.totalValue += VAL.values[i];
         VAL.outValues[i] = amountsOut[i].mul(prices[i]);
         VAL.totalOutValue += VAL.outValues[i];
       }
       if(VAL.totalValue == VAL.totalOutValue){
         return totalBPT;
       }
       RT.rates = new uint256[](len);

       for(uint i = 0; i < len; i++){
         RT.rates[i] = (TENTHOU.mul(VAL.outValues[i])).div(VAL.totalValue);

         if(amountsOut[i] != 0){
         BPT.bptIn += totalBPT.mul(RT.rates[i]).div(TENTHOU);
         }
       }
       return BPT.bptIn;
    }
    // finish this function, last loop need to calculate the if else chain for score based on ratio
    function _calculateSwapFeeRate(
      uint256[] memory balances,
      uint256[] memory amountsIn,
      uint256[] memory amountsOut,
      uint256 amp,
      uint256[] memory prices
    ) internal pure returns(uint256 feeRate){
      uint256 balanceScore = 0;
      ValueInfo memory VAL;
      uint256 len = balances.length;
      uint256[] memory weights = new uint256[](len);
      (VAL.values, VAL.inValues, VAL.outValues) = (new uint256[](len), new uint256[](len), new uint256[](len));

      //VAL.inValues = new uint256[](len);
      //VAL.outValues = new uint256[](len);
      uint256 sum;

      for(uint i = 0; i < len; i++){
        VAL.values[i] = balances[i].mul(prices[i]);
        VAL.inValues[i] = amountsIn[i].mul(prices[i]);
        VAL.outValues[i] = amountsOut[i].mul(prices[i]);
        uint256 newValue = VAL.values[i].add(VAL.inValues[i]);
        if(newValue >= VAL.outValues[i]){
          VAL.values[i] = newValue.sub(VAL.outValues[i]);
        }
        sum += VAL.values[i];
      }
      for (uint i = 0; i < len; i++) {

        if(VAL.values[i] != 0){
        
        weights[i] = ONEH.div(sum.div(VAL.values[i]));
        } else {
          weights[i] = 0;
        }
        if(weights[i] <= 30){
          balanceScore += 25;
        } else if(weights[i] > 30 && weights[i] <= 40){
          balanceScore += 20;
        } else if(weights[i] > 40 && weights[i] <= 50){
          balanceScore += 15;
        } else if(weights[i] > 50 && weights[i] <= 60){
          balanceScore += 10;
        } else {
          balanceScore += 5;
        }
        
        }
        balanceScore = balanceScore.mulUp(amp);
        feeRate = balanceScore;
        return feeRate;
    }
    
    function _calculateSwapFeeAmount(
      uint256[] memory balances,
      uint256[] memory amountsIn,
      uint256[] memory amountsOut,
      uint256 amp,
      uint256[] memory prices
    ) internal pure returns(uint256) {
      uint256 len = balances.length;
      uint256 feeRate = _calculateSwapFeeRate(balances, amountsIn, amountsOut, amp, prices);
      uint256 amountInTotal;
      for(uint i = 0; i < len; i++){
        amountInTotal += amountsIn[i].mul(prices[i]);
      }
      uint256 feeTotal = amountInTotal.divUp(feeRate);
      return feeTotal;
    }

    function _calculateWithdrawFee( //zero division on withdraw fee rate = 0
      uint256[] memory amountsOut,
      uint256 withdrawFeeRate,
      uint256[] memory prices
    ) internal pure returns(uint256[] memory){
      uint256 len = amountsOut.length;
      uint256[] memory withdrawFees = new uint256[](len);
      if(withdrawFeeRate != 0){ //added for potential zero withdraw rate for promotions and customer service
      for(uint i = 0; i < len; i++){
        if(amountsOut[i] != 0){
          uint256 valueOut;
          valueOut = amountsOut[i].mul(prices[i]);
          withdrawFees[i] = valueOut.divUp(withdrawFeeRate);
        } else {
          withdrawFees[i] = 0;
        }
      }
      }
      return withdrawFees;
    }
    
}