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

import "../pools/station/StationMath.sol";

contract MockStationMath is StationMath {

    function inGivenOut(
        uint256 tokenIndexIn,
        uint256 tokenIndexOut,
        uint256 tokenAmountOut,
        uint256[] memory prices
    ) external pure returns (uint256){
        return _inGivenOut(tokenIndexIn, tokenIndexOut, tokenAmountOut, prices); 
    }

    function outGivenIn(
      uint256 tokenIndexIn,
      uint256 tokenIndexOut,
      uint256 tokenAmountIn,
      uint256[] memory prices
    ) external pure returns (uint256){
        return StationMath._outGivenIn(tokenIndexIn, tokenIndexOut, tokenAmountIn, prices);
    }

    function bptOutForAllTokensIn(
        uint256[] memory balances,
        uint256[] memory amountsIn,
        uint256 totalBPT,
        uint256[] memory prices
    ) external pure returns (uint256){
        return StationMath._bptOutForAllTokensIn(balances, amountsIn, totalBPT, prices);
    }

    function bptInForAllTokensOut (
        uint256[] memory balances,
        uint256[] memory amountsOut,
        uint256 totalBPT,
        uint256[] memory prices
    ) external pure returns (uint256) {
        return StationMath._bptInForAllTokensOut(balances, amountsOut, totalBPT, prices);
    }

    function calculateSwapFeeRate(
      uint256[] memory balances,
      uint256[] memory amountsIn,
      uint256[] memory amountsOut,
      uint256 amp,
      uint256[] memory prices
    ) internal pure returns(uint256){
        return StationMath._calculateSwapFeeRate(balances, amountsIn, amountsOut, amp, prices);
    }

    function calculateSwapFeeAmount(
      uint256[] memory balances,
      uint256[] memory amountsIn,
      uint256[] memory amountsOut,
      uint256 amp,
      uint256[] memory prices
    ) external pure returns(uint256) {
        return StationMath._calculateSwapFeeAmount(balances, amountsIn, amountsOut, amp, prices);
    }

    function calculateWithdrawFee(
      uint256[] memory amountsOut,
      uint256 withdrawFeeRate,
      uint256[] memory prices
    ) external pure returns(uint256[] memory) {
        return StationMath._calculateWithdrawFee(amountsOut, withdrawFeeRate, prices);
    }
}