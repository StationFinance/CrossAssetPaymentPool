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
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./StationMath.sol";
import "./StationPoolUserDataHelpers.sol";
import "../BasePool.sol";
import "../../vault/interfaces/IPoolSwapStructs.sol";

import "./Oracle.sol";

// This contract relies on tons of immutable state variables to
// perform efficient lookup, without resorting to storage reads.
// solhint-disable max-states-count

contract StationPool is
    BasePool,
    StationMath
{
    using StationPoolUserDataHelpers for bytes;

    Oracle constant public PRICE_PROVIDER = Oracle(0xCD9B0fc977f1Baf6Fbc96e8373915078fB095154);

    uint256 private constant _MIN_TOKENS = 2;
    uint256 private constant _MAX_TOKENS = 16;
    uint256 internal immutable _protocolSwapFee = 0;

    uint256 public _amp;
    uint256 private constant _MIN_AMP = 10;
    uint256 private constant _MAX_AMP = 50;

    constructor(
        IVault vault,
        string memory name,
        string memory symbol,
        IERC20[] memory tokens,
        uint256 amp,
        uint256 swapFee,
        uint256 emergencyPeriod,
        uint256 emergencyPeriodCheckExtension
    )BasePool(
        vault,
        IVault.PoolSpecialization.GENERAL,
        name,
        symbol,
        tokens,
        swapFee,
        emergencyPeriod,
        emergencyPeriodCheckExtension)
    {
        require(tokens.length >= _MIN_TOKENS, "MIN_TOKENS");
        require(tokens.length <= _MAX_TOKENS, "MAX_TOKENS");
        require(amp >= _MIN_AMP, "MIN_AMP");
        require(amp <= _MAX_AMP, "MAX_AMP");

        _amp = amp;

    }

    // Getters / Setters

   
    function getAmp() public view returns (uint256) {
        return _amp;
    }


    // Join / Exit Hooks
    
    function _onInitializePool(
        bytes32,
        address,
        address,
        bytes memory userData
    ) internal override view returns (uint256 bptAmountOut, uint256[] memory amountsIn) {
        StationPoolUserDataHelpers.JoinKind kind = userData.joinKind();
        require(
            kind == StationPoolUserDataHelpers.JoinKind.INIT,
            "UNINITIALIZED"
        );

        amountsIn = userData.initialAmountsIn();
        InputHelpers.ensureInputLengthMatch(amountsIn.length, _totalTokens);
        _upscaleArray(amountsIn, _scalingFactors());

        bptAmountOut = 100;

        return (bptAmountOut, amountsIn);
    }

    function _onJoinPool(
        bytes32,
        address,
        address,
        uint256[] memory currentBalances,
        uint256,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    )
        internal
        override
        view
        returns (
            uint256,
            uint256[] memory,
            uint256[] memory
        )
    {
        // Due protocol swap fees are computed by measuring the growth of the invariant from the previous join or exit
        // event and now - the invariant's growth is due exclusively to swap fees.
        protocolSwapFeePercentage = _protocolSwapFee;
        uint256[] memory dueProtocolFeeAmounts =
            new uint256[](currentBalances.length);

        (uint256 bptAmountOut, uint256[] memory amountsIn) =
            _doJoin(currentBalances, userData);

        return (bptAmountOut, amountsIn, dueProtocolFeeAmounts);
    }

    function _doJoin(uint256[] memory currentBalances, bytes memory userData)
        private
        view
        returns (uint256, uint256[] memory)
    {
        StationPoolUserDataHelpers.JoinKind kind = userData.joinKind();

        if (
            kind ==
            StationPoolUserDataHelpers.JoinKind.BPT_OUT_FOR_ALL_TOKENS_IN
        ) {
            return _joinBPTOutForAllTokensIn(currentBalances, userData);
        } else {
            revert("UNHANDLED_JOIN_KIND");
        }
    }

    function _joinBPTOutForAllTokensIn(
        uint256[] memory currentBalances,
        bytes memory userData
    ) private view returns (uint256, uint256[] memory) {
        uint256[] memory amountsIn = userData.bptOutForAllTokensIn();
        uint256 bptAmountOut =
            StationMath._bptOutForAllTokensIn(
                currentBalances,
                amountsIn,
                totalSupply(),
                PRICE_PROVIDER.getMultiPrices()
            );

        return (bptAmountOut, amountsIn);
    }

    function _onExitPool(
        bytes32,
        address,
        address,
        uint256[] memory currentBalances,
        uint256,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    )
        internal
        override
        view
        returns (
            uint256,
            uint256[] memory,
            uint256[] memory
        )
    {
        // Due protocol swap fees are computed by measuring the growth of the invariant from the previous join or exit
        // event and now - the invariant's growth is due exclusively to swap fees.
        protocolSwapFeePercentage = _protocolSwapFee;
        uint256[] memory dueProtocolFeeAmounts =
            new uint256[](currentBalances.length);

        (uint256 bptAmountIn, uint256[] memory amountsOut) =
            _doExit(currentBalances, userData);

        // Update the balances by subtracting the protocol fees that will be charged by the Vault once this function
        // returns.

        // Update the invariant with the balances the Pool will have after the exit, in order to compute the due
        // protocol swap fees in future joins and exits.

        return (bptAmountIn, amountsOut, dueProtocolFeeAmounts);
    }

    function _doExit(uint256[] memory currentBalances, bytes memory userData)
        private
        view
        returns (uint256, uint256[] memory)
    {
        StationPoolUserDataHelpers.ExitKind kind = userData.exitKind();

        if (
            kind ==
            StationPoolUserDataHelpers.ExitKind.BPT_IN_FOR_ALL_TOKENS_OUT
        ) {
            return _exitBPTInForAllTokensOut(currentBalances, userData);
        } else {
            revert("UNHANDLED_EXIT_KIND");
        }
    }

    function _exitBPTInForAllTokensOut(
        uint256[] memory currentBalances,
        bytes memory userData
    ) private view returns (uint256, uint256[] memory) {
        uint256[] memory amountsOut = userData.bptInForAllTokensOut();
        //uint256[] memory withdrawFees = _calculateWithdrawFee(amountsOut, withdrawFeeRate);

        uint256 bptAmountIn =
            StationMath._bptInForAllTokensOut(
                currentBalances,
                amountsOut,
                totalSupply(),
                PRICE_PROVIDER.getMultiPrices()
            );

        return (bptAmountIn, amountsOut);
    }

    function _onSwapGivenIn(
        uint256 indexIn,
        uint256 indexOut,
        IPoolSwapStructs.SwapRequestGivenIn memory swapRequest
    ) internal view returns (uint256 amountsOut) {
        return StationMath._outGivenIn(indexIn, indexOut, swapRequest.amountIn, PRICE_PROVIDER.getMultiPrices());
    }

    function _onSwapGivenOut(
        uint256 indexIn,
        uint256 indexOut,
        IPoolSwapStructs.SwapRequestGivenOut memory swapRequest
    ) internal view returns (uint256 amountsIn) {
        return
            StationMath._inGivenOut(indexIn, indexOut, swapRequest.amountOut, PRICE_PROVIDER.getMultiPrices());
    }

}