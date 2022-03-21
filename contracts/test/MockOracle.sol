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

interface MockIStdReference {
    /// A structure returned whenever someone requests for standard reference data.
    struct ReferenceData {
        uint256 rate; // base/quote exchange rate, multiplied by 1e18.
        uint256 lastUpdatedBase; // UNIX epoch of the last time when base price gets updated.
        uint256 lastUpdatedQuote; // UNIX epoch of the last time when quote price gets updated.
    }

    /// Returns the price data for the given base/quote pair. Revert if not available.
    function getReferenceData(string memory _base, string memory _quote)
        external
        view
        returns (ReferenceData memory);

    /// Similar to getReferenceData, but with multiple base/quote pairs at once.
    function getReferenceDataBulk(string[] memory _bases, string[] memory _quotes)
        external
        view
        returns (ReferenceData[] memory);
}
contract MockOracle {

    MockIStdReference public ref;

    uint256 public price;

    constructor() {
    
    }

    function getMultiPrices() external pure returns (uint256[] memory){
        string[] memory baseSymbols = new string[](4);
        baseSymbols[0] = "BTC";
        baseSymbols[1] = "DAI";
        baseSymbols[2] = "ETH";
        baseSymbols[3] = "USDC";

        string[] memory quoteSymbols = new string[](4);
        quoteSymbols[0] = "USD";
        quoteSymbols[1] = "USD";
        quoteSymbols[2] = "USD";
        quoteSymbols[3] = "USD";

        uint256[] memory prices = new uint256[](4);
        prices[0] = 42000;
        prices[1] = 1;
        prices[2] = 3000;
        prices[3] = 1;

        return prices;
    }
}