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
import "./BaseStationPool.sol";


contract StationPool is BaseStationPool{
    using FixedPoint for uint256;
    // solhint-disable private-vars-leading-underscore
    // The protocol fees will always be charged using the token associated with the max weight in the pool.
    // Since these Pools will register tokens only once, we can assume this index will be constant.
    uint256 private constant _MINIMUM_BPT = 1e18;
    uint256 private immutable _maxValWeightTokenIndex;
    uint256 internal constant _MIN_WEIGHT = 0.01e18;

    uint256 private immutable _normValWeight0;
    uint256 private immutable _normValWeight1;
    uint256 private immutable _normValWeight2;
    uint256 private immutable _normValWeight3;
    uint256 private immutable _normValWeight4;
    uint256 private immutable _normValWeight5;
    uint256 private immutable _normValWeight6;
    uint256 private immutable _normValWeight7;
    uint256 public immutable _amp;

    constructor(
        IVault vault,
        string memory name,
        string memory symbol,
        IERC20[] memory tokens,
        uint256[] memory normValWeights,
        uint256 amp,
        address[] memory assetManagers,
        uint256 swapFeePercentage,
        uint256 pauseWindowDuration,
        uint256 bufferPeriodDuration,
        address owner
    ) BaseStationPool(
            vault,
            name,
            symbol,
            tokens,
            assetManagers,
            swapFeePercentage,
            pauseWindowDuration,
            bufferPeriodDuration,
            owner
        )
    {
        _amp = amp;
        uint256 numTokens = tokens.length;

        // Ensure  each normalized weight is above them minimum and find the token index of the maximum weight
        uint256 normalizedSum = 0;
        uint256 maxValWeightTokenIndex = 0;
        uint256 maxNormValWeight = 0;
        for (uint8 i = 0; i < numTokens; i++) {
            uint256 normValWeight = normValWeights[i];
            _require(normValWeight >= _MIN_WEIGHT, Errors.MIN_WEIGHT);

            normalizedSum = normalizedSum.add(normValWeight);
            if (normValWeight > maxNormValWeight) {
                maxValWeightTokenIndex = i;
                maxNormValWeight = normValWeight;
            }
        }
        // Ensure that the normalized weights sum to ONE
        _require(normalizedSum == FixedPoint.ONE, Errors.NORMALIZED_WEIGHT_INVARIANT);

        _maxValWeightTokenIndex = maxValWeightTokenIndex;
        _normValWeight0 = numTokens > 0 ? normValWeights[0] : 0;
        _normValWeight1 = numTokens > 1 ? normValWeights[1] : 0;
        _normValWeight2 = numTokens > 2 ? normValWeights[2] : 0;
        _normValWeight3 = numTokens > 3 ? normValWeights[3] : 0;
        _normValWeight4 = numTokens > 4 ? normValWeights[4] : 0;
        _normValWeight5 = numTokens > 5 ? normValWeights[5] : 0;
        _normValWeight6 = numTokens > 6 ? normValWeights[6] : 0;
        _normValWeight7 = numTokens > 7 ? normValWeights[7] : 0;
    }

    function _getNormValWeight(IERC20 token) internal view virtual override returns (uint256) {
        // prettier-ignore
        if (token == _token0) { return _normValWeight0; }
        else if (token == _token1) { return _normValWeight1; }
        else if (token == _token2) { return _normValWeight2; }
        else if (token == _token3) { return _normValWeight3; }
        else if (token == _token4) { return _normValWeight4; }
        else if (token == _token5) { return _normValWeight5; }
        else if (token == _token6) { return _normValWeight6; }
        else if (token == _token7) { return _normValWeight7; }
        else {
            _revert(Errors.INVALID_TOKEN);
        }
    }

    function _getNormValWeights() internal view virtual override returns (uint256[] memory) {
        uint256 totalTokens = _getTotalTokens();
        uint256[] memory normValWeights = new uint256[](totalTokens);

        // prettier-ignore
        {
            if (totalTokens > 0) { normValWeights[0] = _normValWeight0; } else { return normValWeights; }
            if (totalTokens > 1) { normValWeights[1] = _normValWeight1; } else { return normValWeights; }
            if (totalTokens > 2) { normValWeights[2] = _normValWeight2; } else { return normValWeights; }
            if (totalTokens > 3) { normValWeights[3] = _normValWeight3; } else { return normValWeights; }
            if (totalTokens > 4) { normValWeights[4] = _normValWeight4; } else { return normValWeights; }
            if (totalTokens > 5) { normValWeights[5] = _normValWeight5; } else { return normValWeights; }
            if (totalTokens > 6) { normValWeights[6] = _normValWeight6; } else { return normValWeights; }
            if (totalTokens > 7) { normValWeights[7] = _normValWeight7; } else { return normValWeights; }
        }

        return normValWeights;
    }

    function _getNormValWeightsAndMaxWeightIndex()
        internal
        view
        virtual
        override
        returns (uint256[] memory, uint256)
    {
        return (_getNormValWeights(), _maxValWeightTokenIndex);
    }

}