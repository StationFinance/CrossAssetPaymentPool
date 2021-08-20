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

pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

import "@balancer-labs/v2-solidity-utils/contracts/math/FixedPoint.sol";
import "@balancer-labs/v2-solidity-utils/contracts/math/Math.sol";

library MathLib {
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
        uint256 totalInValue;
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
}

contract StationMath {
    using FixedPoint for uint256;
    using MathLib for *;
    // solhint-disable private-vars-leading-underscore
    // solhint-disable var-name-mixedcase
    uint256 internal constant ONEH = 100;
    uint256 internal constant TENTHOU = 10000;

    function _inGivenOut(
        uint256 tokenIndexIn,
        uint256 tokenIndexOut,
        uint256 tokenAmountOut,
        uint256[] memory prices
    ) internal pure returns (uint256) {
        if (tokenAmountOut == 0) {
            return 0;
        }
        uint256 totalPrice = tokenAmountOut.mulUp(prices[tokenIndexOut]);
        uint256 tokenAmountIn = totalPrice.divDown(prices[tokenIndexIn]);
        return tokenAmountIn;
    }

    function _outGivenIn(
        uint256 tokenIndexIn,
        uint256 tokenIndexOut,
        uint256 tokenAmountIn,
        uint256[] memory prices
    ) internal pure returns (uint256) {
        if (tokenAmountIn == 0) {
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
        if(totalBPT == 1e18){
            return 1e18;
        }

        MathLib.ValueInfo memory VAL;
        MathLib.RateInfo memory RT;
        MathLib.BptInfo memory BPT;
        uint256 len = balances.length;
        uint256 result;
        (VAL.values, VAL.inValues, VAL.totalValue, VAL.totalInValue) = (new uint256[](len), new uint256[](len), 0, 0);
      
        for (uint256 i = 0; i < len; i++) {
            VAL.values[i] = balances[i].mulUp(prices[i]);
            VAL.totalValue += VAL.values[i];
            VAL.inValues[i] = amountsIn[i].mulUp(prices[i]);
            VAL.totalInValue += VAL.inValues[i];
        } 
        if (VAL.totalInValue > VAL.totalValue) {
            VAL.totalValue == 0 ? result = totalBPT : result = VAL.totalInValue.divDown(VAL.totalValue).mulUp(totalBPT);
            return result;
        }

        if (VAL.totalInValue == VAL.totalValue) {
            return totalBPT;
        }

        RT.meanRate = ONEH / len;
        //RT.rateDiffs = new uint256[](len);
        RT.rates = new uint256[](len);
        RT.amountsInRates = new uint256[](len);

        uint256 tempBPT;
        for (uint256 i = 0; i < len; i++) {
            if (VAL.inValues[i] != 0) {
                BPT.bptTempOut;
                 RT.rates[i] = ONEH.divDown(VAL.totalValue.divDown(VAL.values[i]));
                //RT.meanRate >= RT.rates[i] ? RT.rateDiffs[i] = RT.meanRate - RT.rates[i] : 
                //RT.rateDiffs[i] = RT.rates[i] - RT.meanRate;
                RT.amountsInRates[i] = ONEH.divUp(VAL.totalValue.add(VAL.totalInValue).divUp(VAL.inValues[i]));
                BPT.bptTempOut = (totalBPT.mulUp(RT.amountsInRates[i])).divUp(ONEH);
                //if(RT.rateDiffs[i] != 0) {
                   // BPT.bptTempOut += BPT.bptTempOut.divDown(RT.rateDiffs[i]);
                //} else 
                tempBPT += BPT.bptTempOut;
            }
        }

        return tempBPT;
    }

    function _bptInForAllTokensOut(
        uint256[] memory balances,
        uint256[] memory amountsOut,
        uint256 totalBPT,
        uint256[] memory prices
    ) internal pure returns (uint256, uint256[] memory) {
        MathLib.ValueInfo memory VAL;
        MathLib.RateInfo memory RT;
        MathLib.BptInfo memory BPT;
        uint256 len = balances.length;
        (VAL.values, VAL.outValues, VAL.totalValue, VAL.totalOutValue) = (new uint256[](len), new uint256[](len), 0, 0);
        (RT.rates, BPT.bptIn) = (new uint256[](len), 0);

        for (uint256 i = 0; i < len; i++) {
            VAL.values[i] = balances[i].mulUp(prices[i]);
            VAL.totalValue += VAL.values[i];
            VAL.outValues[i] = amountsOut[i].mulUp(prices[i]);
            VAL.totalOutValue += VAL.outValues[i];
        }
        if (VAL.totalValue == VAL.totalOutValue) {
            return (totalBPT, amountsOut);
        }

        for (uint256 i = 0; i < len; i++) {
            RT.rates[i] = VAL.outValues[i].divDown(VAL.totalValue);

            if (amountsOut[i] != 0) {
                BPT.bptIn += totalBPT.mulUp(RT.rates[i]);
            }
        }
        return (BPT.bptIn, amountsOut);
    }

    function _tokensOutForExactBptIn(
        uint256[] memory balances,
        uint256 bptAmountIn,
        uint256 totalBPT,
        uint256[] memory prices
    ) internal pure returns (uint256[] memory) {
        MathLib.ValueInfo memory VAL;
        MathLib.RateInfo memory RT;
        MathLib.BptInfo memory BPT;
        uint256 len = balances.length;
        (VAL.values, VAL.outValues, VAL.totalValue) = (new uint256[](len), new uint256[](len), 0);
        (RT.rates, BPT.bptIn) = (new uint256[](len), bptAmountIn);

        for (uint256 i = 0; i < len; i++) {
            VAL.values[i] = balances[i].mulUp(prices[i]);
            VAL.totalValue += VAL.values[i];
        }
        uint256 bptRatio = BPT.bptIn.divDown(totalBPT);
        uint256[] memory amountsOut = new uint256[](balances.length);

        for (uint256 i = 0; i < balances.length; i++) {
            VAL.outValues[i] = VAL.values[i].mulUp(bptRatio);
            amountsOut[i] = VAL.outValues[i].divDown(prices[i]);
        }
        return amountsOut;
    }

    // finish this function, last loop need to calculate the if else chain for score based on ratio
    function _calculateSwapFeeRate(
        uint256[] memory balances,
        uint256[] memory amountsIn,
        uint256[] memory amountsOut,
        uint256 amp,
        uint256[] memory prices
    ) internal pure returns (uint256 feeRate) {
        MathLib.ValueInfo memory VAL;
        uint256 len = balances.length;
        (VAL.values, VAL.inValues, VAL.outValues) = (new uint256[](len), new uint256[](len), new uint256[](len));
        VAL.totalValue = 0;
        uint256[] memory weights = new uint256[](len);
        uint256 balanceScore = 0;

        for (uint256 i = 0; i < len; i++) {
            VAL.values[i] = balances[i].mulUp(prices[i]);
            VAL.inValues[i] = amountsIn[i].mulUp(prices[i]);
            VAL.outValues[i] = amountsOut[i].mulUp(prices[i]);
            VAL.totalValue += VAL.values[i];
        }
        for (uint256 i = 0; i < len; i++) {
            if (VAL.values[i] != 0) {
                weights[i] = ONEH.divDown(VAL.totalValue.divDown(VAL.values[i]));
            } else {
                weights[i] = 0;
            }
            if (weights[i] <= 30) {
                balanceScore += 25;
            } else if (weights[i] > 30 && weights[i] <= 40) {
                balanceScore += 20;
            } else if (weights[i] > 40 && weights[i] <= 50) {
                balanceScore += 15;
            } else if (weights[i] > 50 && weights[i] <= 60) {
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
    ) internal pure returns (uint256) {
        uint256 len = balances.length;
        uint256 feeRate = _calculateSwapFeeRate(balances, amountsIn, amountsOut, amp, prices);
        uint256 amountInTotal;
        for (uint256 i = 0; i < len; i++) {
            amountInTotal += amountsIn[i].mulUp(prices[i]);
        }
        uint256 feeTotal = amountInTotal.divUp(feeRate);
        return feeTotal;
    }

    function _calcDueTokenProtocolSwapFeeAmount(
        uint256[] memory feeTotals,
        uint256[] memory prices,
        uint256 protocolSwapFeePercentage
    ) internal pure returns (uint256[] memory) {
        MathLib.ValueInfo memory VAL;
        VAL.totalValue;
        for(uint i = 0; i < prices.length; i++){
            uint256 tempVal = feeTotals[i].mulDown(prices[i]);
            VAL.totalValue += tempVal; 
        }
        uint256[] memory feesDue = new uint256[](prices.length);
        feesDue[0] = protocolSwapFeePercentage.mulDown(VAL.totalValue.divDown(prices[0]));
        return feesDue;
    }

    function _calculateWithdrawFee(
        //zero division on withdraw fee rate = 0
        uint256[] memory amountsOut,
        uint256 withdrawFeeRate,
        uint256[] memory prices
    ) internal pure returns (uint256[] memory) {
        uint256 len = amountsOut.length;
        uint256[] memory withdrawFees = new uint256[](len);
        if (withdrawFeeRate != 0) {
            //added for potential zero withdraw rate for promotions and customer service
            for (uint256 i = 0; i < len; i++) {
                if (amountsOut[i] != 0) {
                    uint256 valueOut;
                    valueOut = amountsOut[i].mulUp(prices[i]);
                    withdrawFees[i] = valueOut.divUp(withdrawFeeRate);
                } else {
                    withdrawFees[i] = 0;
                }
            }
        }
        return withdrawFees;
    }



}