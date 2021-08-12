// File: contracts/vault/interfaces/IAuthorizer.sol

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

interface IAuthorizer {
    function hasRole(bytes32 role, address account) external view returns (bool);
}

// File: contracts/lib/helpers/Authentication.sol



pragma solidity ^0.7.0;

abstract contract Authentication {
    /**
     * @dev Reverts unless the caller is allowed to call this function. Should only be applied to external functions.
     */
    modifier authenticate() {
        _authenticateCaller();
        _;
    }

    /**
     * @dev Reverts unless the caller is allowed to call the entry point function.
     */
    function _authenticateCaller() internal view {
        // Each external function is dynamically assigned a role ID as the hash of the contract address
        // and the function selector.
        bytes32 roleId = keccak256(abi.encodePacked(address(this), msg.sig));
        require(_canPerform(roleId, msg.sender), "SENDER_NOT_ALLOWED");
    }

    function _canPerform(bytes32 roleId, address user) internal view virtual returns (bool);
}

// File: contracts/lib/helpers/EmergencyPeriod.sol



pragma solidity ^0.7.0;

// solhint-disable not-rely-on-time
contract EmergencyPeriod {
    uint256 private constant _MAX_EMERGENCY_PERIOD = 1000 days;
    uint256 private constant _MAX_EMERGENCY_PERIOD_CHECK_EXT = 30 days;

    bool private _emergencyPeriodActive;
    uint256 internal immutable _emergencyPeriodEndDate;
    uint256 internal immutable _emergencyPeriodCheckEndDate;

    event EmergencyPeriodChanged(bool active);

    modifier noEmergencyPeriod() {
        _ensureInactiveEmergencyPeriod();
        _;
    }

    constructor(uint256 emergencyPeriod, uint256 emergencyPeriodCheckExtension) {
        require(emergencyPeriod <= _MAX_EMERGENCY_PERIOD, "MAX_EMERGENCY_PERIOD");
        require(emergencyPeriodCheckExtension <= _MAX_EMERGENCY_PERIOD_CHECK_EXT, "MAX_EMERGENCY_PERIOD_CHECK_EXT");

        _emergencyPeriodEndDate = block.timestamp + emergencyPeriod;
        _emergencyPeriodCheckEndDate = block.timestamp + emergencyPeriod + emergencyPeriodCheckExtension;
    }

    function getEmergencyPeriod()
        external
        view
        returns (
            bool active,
            uint256 endDate,
            uint256 checkEndDate
        )
    {
        return (!_isEmergencyPeriodInactive(), _emergencyPeriodEndDate, _emergencyPeriodCheckEndDate);
    }

    function _setEmergencyPeriod(bool active) internal {
        require(block.timestamp < _emergencyPeriodEndDate, "EMERGENCY_PERIOD_FINISHED");
        _emergencyPeriodActive = active;
        emit EmergencyPeriodChanged(active);
    }

    function _ensureInactiveEmergencyPeriod() internal view {
        require(_isEmergencyPeriodInactive(), "EMERGENCY_PERIOD_ON");
    }

    function _isEmergencyPeriodInactive() internal view returns (bool) {
        return (block.timestamp >= _emergencyPeriodCheckEndDate) || !_emergencyPeriodActive;
    }
}

// File: contracts/lib/helpers/ReentrancyGuard.sol



pragma solidity ^0.7.0;

// Based on the ReentrancyGuard library from OpenZeppelin contracts, altered to reduce bytecode size.
// Modifier code is inlined by the compiler, which causes its code to appear multiple times in the codebase. By using
// private functions, we achieve the same end result with slightly higher runtime gas costs but reduced bytecode size.

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _enterNonReentrant();
        _;
        _exitNonReentrant();
    }

    function _enterNonReentrant() private {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "REENTRANCY");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _exitNonReentrant() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/vault/interfaces/IFlashLoanReceiver.sol



pragma solidity ^0.7.0;

// Inspired by Aave Protocol's IFlashLoanReceiver


interface IFlashLoanReceiver {
    function receiveFlashLoan(
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        uint256[] calldata feeAmounts,
        bytes calldata receiverData
    ) external;
}

// File: contracts/vault/interfaces/IVault.sol



pragma experimental ABIEncoderV2;




pragma solidity ^0.7.0;

/**
 * @dev Full external interface for the Vault core contract - no external or public methods exist in the contract that
 * don't override one of these declarations.
 */
interface IVault {
    // Generalities about the Vault:
    //
    // - Whenever documentation refers to 'tokens', it strictly refers to ERC20-compliant token contracts. Tokens are
    // transferred out of the Vault by calling the `IERC20.transfer` function, and transferred in by calling
    // `IERC20.transferFrom`. In these cases, the sender must have previously allowed the Vault to use their tokens by
    // calling `IERC20.approve`. The only deviation from the ERC20 standard that is supported is functions not returning
    // a boolean value: in these scenarios, a non-reverting call is assumed to be successful.
    //
    // - All non-view functions in the Vault are non-reentrant: calling them while another one is mid-execution (e.g.
    // while execution control is transferred to a token contract during a swap) will result in a revert. View
    // functions can be called in a re-reentrant way, but doing so might cause them to return inconsistent results.
    // Contracts calling view functions in the Vault must make sure the Vault has not already been entered.
    //
    // - View functions revert if referring to either unregistered Pools, or unregistered tokens for registered Pools.

    // Authorizer
    //
    // Some system actions are permissioned, like setting and collecting protocol fees. This permissioning system exists
    // outside of the Vault in the Authorizer contract: the Vault simply calls the Authorizer to check if the caller
    // can perform a given action.
    // The only exception to this are relayers. A relayer is an account (typically a contract) that can use the Internal
    // Balance and Vault allowance of other accounts. For an account to be able to wield this power, two things must
    // happen:
    //  - it must be allowed by the Authorizer to call the functions where it intends to use this permission
    //  - it must be allowed by each individual user to act in their stead
    // This combined requirements means users cannot be tricked into allowing malicious relayers (because they will not
    // have been allowed by the Authorizer), nor can a malicious Authorizer allow malicious relayers to drain user funds
    // (unless the user then allows this malicious relayer).

    /**
     * @dev Returns the Vault's Authorizer.
     */
    function getAuthorizer() external view returns (IAuthorizer authorizer);

    /**
     * @dev Sets a new Authorizer for the Vault. The caller must be allowed by the current Authorizer to do this.
     */
    function changeAuthorizer(IAuthorizer newAuthorizer) external;

    /**
     * @dev Returns true if `user` has allowed `relayer` as a relayer for them.
     */
    function hasAllowedRelayer(address user, address relayer) external view returns (bool has);

    /**
     * @dev Allows `relayer` to act as a relayer for the caller if `allowed` is true, and disallows it otherwise.
     */
    function changeRelayerAllowance(address relayer, bool allowed) external;

    // Internal Balance
    //
    // Users can deposit tokens into the Vault, where it is known as Internal Balance. This Internal Balance can be
    // withdrawn or transferred, and it can also be used when joining Pools or performing swaps, with greatly reduced
    // gas costs. Swaps and Pool exits can also be made to deposit to Internal Balance.
    //
    // Internal Balance functions feature batching, which means each call can be used to perform multiple operations of
    // the same kind (deposit, withdraw or transfer) at once.

    /**
     * @dev Data for internal balance transfers - encompassing deposits, withdrawals, and transfers between accounts.
     *
     * This gives aggregators maximum flexibility, and makes it possible for an asset manager to manage multiple tokens
     * and pools with less gas and fewer calls to the vault.
     */

    struct BalanceTransfer {
        IERC20 token;
        uint256 amount;
        address sender;
        address recipient;
    }

    /**
     * @dev Returns `user`'s Internal Balance for a set of tokens.
     */
    function getInternalBalance(address user, IERC20[] memory tokens) external view returns (uint256[] memory balance);

    /**
     * @dev Deposits tokens from each `sender` address into Internal Balances of the corresponding `recipient`
     * accounts specified in the struct. The sources must have allowed the Vault to use their tokens
     * via `IERC20.approve()`.
     * Allows aggregators to settle multiple accounts in a single transaction.
     */
    function depositToInternalBalance(BalanceTransfer[] memory transfers) external;

    /**
     * @dev Transfers tokens from each `sender` address to the corresponding `recipient` accounts specified
     * in the struct, making use of the Vault's allowance (like an internal balance deposit, but without recording it,
     * since it is really just transferred directly between the sender and receiver). The sources must have allowed
     * the Vault to use their tokens via `IERC20.approve()`.
     * This will allow relayers to leverage the allowance given to the vault by each sender, to transfer tokens to
     * external accounts
     */
    function transferToExternalBalance(BalanceTransfer[] memory transfers) external;

    /**
     * @dev Withdraws tokens from each the internal balance of each `sender` address into the `recipient` accounts
     * specified in the struct. Allows aggregators to settle multiple accounts in a single transaction.
     *
     * This charges protocol withdrawal fees.
     */
    function withdrawFromInternalBalance(BalanceTransfer[] memory transfers) external;

    /**
     * @dev Transfers tokens from the internal balance of each `sender` address to Internal Balances
     * of each `recipient`. Allows aggregators to settle multiple accounts in a single transaction.
     *
     * This does not charge protocol withdrawal fees.
     */
    function transferInternalBalance(BalanceTransfer[] memory transfers) external;

    /**
     * @dev Emitted when a user's Internal Balance changes, either due to calls to the Internal Balance functions, or
     * due to interacting with Pools using Internal Balance.
     */
    event InternalBalanceChanged(address indexed user, IERC20 indexed token, uint256 balance);

    // Pools
    //
    // There are three specialization settings for Pools, which allow for lower swap gas costs at the cost of reduced
    // functionality:
    //
    //  - general: no specialization, suited for all Pools. IGeneralPool is used for swap request callbacks, passing the
    // balance of all tokens in the Pool. These Pools have the largest swap costs (because of the extra storage reads),
    // and these increase with the number of registered tokens.
    //
    //  - minimal swap info: IMinimalSwapInfoPool is used instead of IGeneralPool, which saves gas by only passing the
    // balance of the two tokens involved in the swap. This is suitable for some pricing algorithms, like the weighted
    // constant product one popularized by Balancer v1. Swap costs are smaller compared to general Pools, and are
    // independent of the number of registered tokens.
    //
    //  - two tokens: only allows two tokens to be registered. This achieves the lowest possible swap gas costs. Like
    // minimal swap info Pools, these are called via IMinimalSwapInfoPool.

    enum PoolSpecialization { GENERAL, MINIMAL_SWAP_INFO, TWO_TOKEN }

    /**
     * @dev Registers a the caller as a Pool with a chosen specialization setting. Returns the Pool's ID, which is used
     * in all Pool-related functions. Pools cannot be deregistered, nor can the Pool's specialization be changed.
     *
     * The caller is expected to be a smart contract that implements one of `IGeneralPool` or `IMinimalSwapInfoPool`.
     * This contract is known as the Pool's contract. Note that the same caller may register itself as multiple Pools
     * with unique Pool IDs, or in other words, multiple Pools may have the same contract.
     *
     * Emits a `PoolRegistered` event.
     */
    function registerPool(PoolSpecialization specialization) external returns (bytes32 pool);

    /**
     * @dev Emitted when a Pool is registered by calling `registerPool`.
     */
    event PoolRegistered(bytes32 poolId);

    /**
     * @dev Returns a Pool's contract address and specialization setting.
     */
    function getPool(bytes32 poolId) external view returns (address poolAddress, PoolSpecialization pool);

    /**
     * @dev Registers `tokens` for the `poolId` Pool. Must be called by the Pool's contract.
     *
     * Pools can only interact with tokens they have registered. Users join a Pool by transferring registered tokens,
     * exit by receiving registered tokens, and can only swap registered tokens.
     *
     * Each token can only be registered once. For Pools with the Two Token specialization, `tokens` must have a length
     * of two, that is, both tokens must be registered in the same `registerTokens` call.
     *
     * The `tokens` and `assetManagers` arrays must have the same length, and each entry in these indicates the Asset
     * Manager for each token. Asset Managers can manage a Pool's tokens by withdrawing and depositing them directly
     * (via `withdrawFromPoolBalance` and `depositToPoolBalance`), and even set them to arbitrary amounts
     * (`updateManagedBalance`). They are therefore expected to be highly secured smart contracts with sound design
     * principles, and the decision to add an Asset Manager should not be made lightly.
     *
     * Pools can not set an Asset Manager by setting them to the zero address. Once an Asset Manager is set, it cannot
     * be changed, except by deregistering the associated token and registering again with a different Manager.
     *
     * Emits `TokensRegistered` events.
     */
    function registerTokens(
        bytes32 poolId,
        IERC20[] calldata tokens,
        address[] calldata assetManagers
    ) external;

    /**
     * @dev Emitted when a Pool registers tokens by calling `registerTokens`.
     */
    event TokensRegistered(bytes32 poolId, IERC20[] tokens, address[] assetManagers);

    /**
     * @dev Deregisters `tokens` for the `poolId` Pool. Must be called by the Pool's contract.
     *
     * Only registered tokens (via `registerTokens`) can be deregistered. Additionally, they must have zero total
     * balance. For Pools with the Two Token specialization, `tokens` must have a length of two, that is, both tokens
     * must be deregistered in the same `deregisterTokens` call.
     *
     * A deregistered token can be re-registered later on, possibly with a different Asset Manager.
     *
     * Emits a `TokensDeregistered` event.
     */
    function deregisterTokens(bytes32 poolId, IERC20[] calldata tokens) external;

    /**
     * @dev Emitted when a Pool deregisters tokens by calling `deregisterTokens`.
     */
    event TokensDeregistered(bytes32 poolId, IERC20[] tokens);

    /**
     * @dev Returns a Pool's registered tokens and total balance for each.
     *
     * The order of the `tokens` array is the same order that will be used in `joinPool`, `exitPool`, as well as in all
     * Pool hooks (where applicable). Calls to `registerTokens` and `deregisterTokens` may change this order.
     *
     * If a Pool only registers tokens once, and these are sorted in ascending order, they will be stored in the same
     * order as passed to `registerTokens`.
     *
     * Total balances include both tokens held by the Vault and those withdrawn by the Pool's Asset Managers. These are
     * the amounts used by joins, exits and swaps.
     */
    function getPoolTokens(bytes32 poolId) external view returns (IERC20[] memory tokens, uint256[] memory balances);

    /**
     * @dev Returns detailed information for a Pool's registered token.
     *
     * `cash` is the number of tokens the Vault currently holds for the Pool. `managed` is the number of tokens
     * withdrawn and reported by the Pool's token Asset Manager. The Pool's total balance for `token` equals the sum of
     * `cash` and `managed`.
     *
     * `blockNumber` is the number of the block in which `token`'s balance was last modified (via either a join, exit,
     * swap, or Asset Management interactions). This value is useful to avoid so-called 'sandwich attacks', for example
     * when developing price oracles.
     *
     * `assetManager` is the Pool's token Asset Manager.
     */
    function getPoolTokenInfo(bytes32 poolId, IERC20 token)
        external
        view
        returns (
            uint256 cash,
            uint256 managed,
            uint256 blockNumber,
            address assetManager
        );

    /**
     * @dev Called by users to join a Pool, which transfers tokens from `sender` into the Pool's balance. This will
     * trigger custom Pool behavior, which will typically grant something in return to `recipient` - often tokenized
     * Pool shares.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `tokens` and `maxAmountsIn` arrays must have the same length, and each entry in these indicates the maximum
     * token amount to send for each token contract. The amounts to send are decided by the Pool and not the Vault: it
     * just enforces these maximums.
     *
     * `tokens` must have the same length and order as the one returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently.
     *
     * If `fromInternalBalance` is true, the caller's Internal Balance will be preferred: ERC20 transfers will only
     * be made for the difference between the requested amount and Internal Balance (if any).
     *
     * This causes the Vault to call the `IBasePool.onJoinPool` hook on the Pool's contract, where Pools implements
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares to obtain). This can be encoded in the `userData` argument, which is ignored by the Vault and
     * passed directly to the Pool's contract, as is `recipient`.
     *
     * Emits a `PoolJoined` event.
     */
    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        IERC20[] memory tokens,
        uint256[] memory maxAmountsIn,
        bool fromInternalBalance,
        bytes memory userData
    ) external;

    /**
     * @dev Emitted when a user joins a Pool by calling `joinPool`.
     */
    event PoolJoined(
        bytes32 indexed poolId,
        address indexed liquidityProvider,
        IERC20[] tokens,
        uint256[] amountsIn,
        uint256[] protocolFees
    );

    /**
     * @dev Called by users to exit a Pool, which transfers tokens from the Pool's balance to `recipient`. This will
     * trigger custom Pool behavior, which will typically ask for something in return from `sender` - often tokenized
     * Pool shares. The amount of tokens that can be withdraw is limited by the Pool's `cash` balance (see
     * `getPoolTokenInfo`).
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `tokens` and `minAmountsOut` arrays must have the same length, and each entry in these indicates the minimum
     * token amount to receive for each token contract. The amounts to send are decided by the Pool and not the Vault:
     * it just enforces these minimums.
     *
     * `tokens` must have the same length and order as the one returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently.
     *
     * If `toInternalBalance` is true, the tokens will be deposited to `recipient`'s Internal Balance. Otherwise,
     * an ERC20 transfer will be performed, charging protocol withdraw fees.
     *
     * `minAmountsOut` is the minimum amount of tokens the user expects to get out of the Pool, for each token in the
     * `tokens` array. This array must match the Pool's registered tokens.
     *
     * Pools are free to implement any arbitrary logic in the `IPool.onExitPool` hook, and may require additional
     * information (such as the number of Pool shares to provide). This can be encoded in the `userData` argument, which
     * is ignored by the Vault and passed directly to the Pool.
     *
     * This causes the Vault to call the `IBasePool.onExitPool` hook on the Pool's contract, where Pools implements
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares to return). This can be encoded in the `userData` argument, which is ignored by the Vault and
     * passed directly to the Pool's contract.
     *
     * Emits a `PoolExited` event.
     */
    function exitPool(
        bytes32 poolId,
        address sender,
        address recipient,
        IERC20[] memory tokens,
        uint256[] memory minAmountsOut,
        bool toInternalBalance,
        bytes memory userData
    ) external;

    /**
     * @dev Emitted when a user exits a pool by calling `exitPool`.
     */
    event PoolExited(
        bytes32 indexed poolId,
        address indexed liquidityProvider,
        IERC20[] tokens,
        uint256[] amountsOut,
        uint256[] protocolFees
    );

    // Swaps
    //
    // Users can swap tokens with Pools by calling the `batchSwapGivenIn` and `batchSwapGivenOut` functions. To do this,
    // they need not trust Pool contracts in any way: all security checks are made by the Vault. They must however be
    // aware of the Pools' pricing algorithms in order to estimate the prices Pools will quote.
    //
    // Both swap functions are batched, meaning they perform multiple of swaps in sequence. In each individual swap,
    // tokens of one kind are sent from the sender to the Pool (this is the 'token in'), and tokens of one
    // other kind are sent from the Pool to the sender in exchange (this is the 'token out'). More complex swaps, such
    // as one token in to multiple tokens out can be achieved by batching together individual swaps.
    //
    // Additionally, it is possible to chain swaps by using the output of one of them as the input for the other, as
    // well as the opposite. This extended swap is known as a 'multihop' swap, since it 'hops' through a number of
    // intermediate tokens before arriving at the final intended token.
    //
    // In all cases, tokens are only transferred in and out of the Vault (or withdrawn from and deposited into Internal
    // Balance) after all individual swaps have been completed, and the net token balance change computed. This makes
    // certain swap patterns, such as multihops, or swaps that interact with the same token pair in multiple Pools, cost
    // much less gas than they would otherwise.
    //
    // It also means that it is possible to e.g. under certain conditions perform arbitrage by swapping with multiple
    // Pools in a way that results in net token movement out of the Vault (profit), with no tokens being sent in (but
    // updating the Pool's internal balances).
    //
    // To protect users from front-running or the market changing rapidly, they supply a list of 'limits' for each token
    // involved in the swap, where either the maximum number of tokens to send (by passing a positive value) or minimum
    // amount of tokens to receive (by passing a negative value) is specified.
    //
    // Additionally, a 'deadline' timestamp can also be provided, forcing the swap to fail if it occurs after
    // this point in time (e.g. if the transaction failed to be included in a block promptly).
    //
    // Finally, Internal Balance can be used both when sending and receiving tokens.

    /**
     * @dev Performs a series of swaps with one or multiple Pools. In individual each swap, the amount of tokens sent to
     * the Pool is determined by the caller. For swaps where the amount of tokens received from the Pool is instead
     * determined, see `batchSwapGivenOut`.
     *
     * Returns an array with the net Vault token balance deltas. Positive amounts represent tokens sent to the Vault,
     * and negative amounts tokens sent by the Vault. Each delta corresponds to the token at the same index in the
     * `tokens` array.
     *
     * Swaps are executed sequentially, in the order specified by the `swaps` array. Each array element describes a
     * Pool, the token and amount to send to this Pool, and the token to receive from it (but not the amount). This will
     * be determined by the Pool's pricing algorithm once the Vault calls the `onSwapGivenIn` hook on it.
     *
     * Multihop swaps can be executed by passing an `amountIn` value of zero for a swap. This will cause the amount out
     * of the previous swap to be used as the amount in of the current one. In such a scenario, `tokenIn` must equal the
     * previous swap's `tokenOut`.
     *
     * The `tokens` array contains the addresses of all tokens involved in the swaps. Each entry in the `swaps` array
     * specifies tokens in and out by referencing an index in `tokens`.
     *
     * Internal Balance usage and recipient are determined by the `funds` struct.
     *
     * Emits `Swap` events.
     */
    function batchSwapGivenIn(
        SwapIn[] calldata swaps,
        IERC20[] memory tokens,
        FundManagement calldata funds,
        int256[] memory limits,
        uint256 deadline
    ) external returns (int256[] memory batch);

    /**
     * @dev Data for each individual swap executed by `batchSwapGivenIn`. The tokens in and out are indexed in the
     * `tokens` array passed to that function.
     *
     * If `amountIn` is zero, the multihop mechanism is used to determine the actual amount based on the amount out from
     * the previous swap.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwapGivenIn` hook, and may be
     * used to extend swap behavior.
     */
    struct SwapIn {
        bytes32 poolId;
        uint256 tokenInIndex;
        uint256 tokenOutIndex;
        uint256 amountIn;
        bytes userData;
    }

    /**
     * @dev Performs a series of swaps with one or multiple Pools. In individual each swap, the amount of tokens
     * received from the Pool is determined by the caller. For swaps where the amount of tokens sent to the Pool is
     * instead determined, see `batchSwapGivenIn`.
     *
     * Returns an array with the net Vault token balance deltas. Positive amounts represent tokens sent to the Vault,
     * and negative amounts tokens sent by the Vault. Each delta corresponds to the token at the same index in the
     * `tokens` array.
     *
     * Swaps are executed sequentially, in the order specified by the `swaps` array. Each array element describes a
     * Pool, the token and amount to receive from this Pool, and the token to send to it (but not the amount). This will
     * be determined by the Pool's pricing algorithm once the Vault calls the `onSwapGivenOut` hook on it.
     *
     * Multihop swaps can be executed by passing an `amountOut` value of zero for a swap. This will cause the amount in
     * of the previous swap to be used as the amount out of the current one. In such a scenario, `tokenOut` must equal
     * the previous swap's `tokenIn`.
     *
     * The `tokens` array contains the addresses of all tokens involved in the swaps. Each entry in the `swaps` array
     * specifies tokens in and out by referencing an index in `tokens`.
     *
     * Internal Balance usage and recipient are determined by the `funds` struct.
     *
     * Emits `Swap` events.
     */
    function batchSwapGivenOut(
        SwapOut[] calldata swaps,
        IERC20[] memory tokens,
        FundManagement calldata funds,
        int256[] memory limits,
        uint256 deadline
    ) external returns (int256[] memory batch);

    /**
     * @dev Data for each individual swap executed by `batchSwapGivenOut`. The tokens in and out are indexed in the
     * `tokens` array passed to that function.
     *
     * If `amountOut` is zero, the multihop mechanism is used to determine the actual amount based on the amount in from
     * the previous swap.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwapGivenOut` hook, and may be
     * used to extend swap behavior.
     */
    struct SwapOut {
        bytes32 poolId;
        uint256 tokenInIndex;
        uint256 tokenOutIndex;
        uint256 amountOut;
        bytes userData;
    }

    /**
     * @dev Emitted for each individual swap performed by `batchSwapGivenIn` and `batchSwapGivenOut`.
     */
    event Swap(
        bytes32 indexed poolId,
        IERC20 indexed tokenIn,
        IERC20 indexed tokenOut,
        uint256 tokensIn,
        uint256 tokensOut
    );

    /**
     * @dev All tokens in a swap are sent to the Vault from the `sender`'s account, and sent to `recipient`.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * If `fromInternalBalance` is true, the `sender`'s Internal Balance will be preferred, performing an ERC20
     * transfer for the difference between the requested amount and the User's Internal Balance (if any). The `sender`
     * must have allowed the Vault to use their tokens via `IERC20.approve()`. This matches the behavior of
     * `joinPool`.
     *     * If `toInternalBalance` is true, tokens will be deposited to `recipient`'s internal balance instead of
     * transferred. This matches the behavior of `exitPool`.
     */
    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address recipient;
        bool toInternalBalance;
    }

    /**
     * @dev Simulates a call to `batchSwapGivenIn` or `batchSwapGivenOut`, returning an array of Vault token deltas.
     * Each element in the array corresponds to the token at the same index, and indicates the number of tokens the
     * Vault would take from the sender (if positive) or send to the recipient (if negative). The arguments it receives
     * are the same that an equivalent `batchSwapGivenIn` or `batchSwapGivenOut` call would receive, except the
     * `SwapRequest` struct is used instead, and the `kind` argument specifies whether the swap is given in or given
     * out.
     *
     * Unlike `batchSwapGivenIn` and `batchSwapGivenOut`, this function performs no checks on the sender nor recipient
     * field in the `funds` struct. This makes it suitable to be called by off-chain applications via eth_call without
     * needing to hold tokens, approve them for the Vault, or even know a user's address.
     *
     * Note that this function is not 'view' (due to implementation details): the client code must explicitly execute
     * eth_call instead of eth_sendTransaction.
     */
    function queryBatchSwap(
        SwapKind kind,
        SwapRequest[] memory swaps,
        IERC20[] memory tokens,
        FundManagement memory funds
    ) external returns (int256[] memory tokenDeltas);

    enum SwapKind { GIVEN_IN, GIVEN_OUT }

    // This struct is identical in layout to SwapIn and SwapOut, except the 'amountIn/Out' field is named 'amount'.
    struct SwapRequest {
        bytes32 poolId;
        uint256 tokenInIndex;
        uint256 tokenOutIndex;
        uint256 amount;
        bytes userData;
    }

    // Flash Loans

    /**
     * @dev Performs a 'flash loan', sending tokens to `receiver` and executing the `receiveFlashLoan` hook on it,
     * and then reverting unless the tokens plus a protocol fee have been returned.
     *
     * The `tokens` and `amounts` arrays must have the same length, and each entry in these indicates the amount to
     * loan for each token contract. `tokens` must be sorted in ascending order.
     *
     * The 'receiverData' field is ignored by the Vault, and forwarded as-is to `receiver` as part of the
     * `receiveFlashLoan` call.
     */
    function flashLoan(
        IFlashLoanReceiver receiver,
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        bytes calldata receiverData
    ) external;

    // Asset Management
    //
    // Each token registered for a Pool can be assigned an Asset Manager, which is able to freely withdraw the Pool's
    // tokens from the Vault, deposit them, or assign arbitrary values to its `managed` balance (see
    // `getPoolTokenInfo`). This makes them extremely powerful and dangerous, as they can not only steal a Pool's tokens
    // but also manipulate its prices. However, a properly designed Asset Manager smart contract can be used to the
    // Pool's benefit, for example by lending unused tokens at an interest, or using them to participate in voting
    // protocols.

    struct AssetManagerTransfer {
        IERC20 token;
        uint256 amount;
    }

    /**
     * @dev Returns the Pool's Asset Managers for the given `tokens`. Asset Managers can manage a Pool's assets
     * by taking them out of the Vault via `withdrawFromPoolBalance`, `depositToPoolBalance` and `updateManagedBalance`.
     */
    function getPoolAssetManagers(bytes32 poolId, IERC20[] memory tokens)
        external
        view
        returns (address[] memory assetManagers);

    /**
     * @dev Emitted when a Pool's token Asset manager withdraws or deposits token balance via `withdrawFromPoolBalance`
     * or `depositToPoolBalance`.
     */
    event PoolBalanceChanged(bytes32 indexed poolId, address indexed assetManager, IERC20 indexed token, int256 amount);

    /**
     * @dev Called by a Pool's Asset Manager to withdraw tokens from the Vault. This decreases
     * the Pool's cash but increases its managed balance, leaving the total balance unchanged.
     * Array input allows asset managers to manage multiple tokens for a pool in a single transaction.
     */
    function withdrawFromPoolBalance(bytes32 poolId, AssetManagerTransfer[] memory transfers) external;

    /**
     * @dev Called by a Pool's Asset Manager to deposit tokens into the Vault. This increases the Pool's cash,
     * but decreases its managed balance, leaving the total balance unchanged. The Asset Manager must have approved
     * the Vault to use each token. Array input allows asset managers to manage multiple tokens for a pool in a
     * single transaction.
     */
    function depositToPoolBalance(bytes32 poolId, AssetManagerTransfer[] memory transfers) external;

    /**
     * @dev Called by a Pool's Asset Manager for to update the amount held outside the vault. This does not affect
     * the Pool's cash balance, but because the managed balance changes, it does alter the total. The external
     * amount can be either increased or decreased by this call (i.e., reporting a gain or a loss).
     * Array input allows asset managers to manage multiple tokens for a pool in a single transaction.
     */
    function updateManagedBalance(bytes32 poolId, AssetManagerTransfer[] memory transfers) external;

    // Protocol Fees
    //
    // Some operations cause the Vault to collect tokens in the form of protocol fees, which can then be withdrawn by
    // permissioned accounts.
    //
    // There are three kinds of protocol fees:
    //
    //  - flash loan fees: charged on all flash loans, as a percentage of the amounts lent.
    //
    //  - withdraw fees: charged when users take tokens out of the Vault, by either calling
    // `withdrawFromInternalBalance` or calling `exitPool` without depositing to Internal Balance. The fee is a
    // percentage of the amount withdrawn. Swaps are unaffected by withdraw fees.
    //
    //  - swap fees: a percentage of the fees charged by Pools when performing swaps. For a number of reasons, including
    // swap gas costs and interface simplicity, protocol swap fees are not charged on each individual swap. Rather,
    // Pools are expected to keep track of how many swap fees they have charged, and pay any outstanding debts to the
    // Vault when they are joined or exited. This prevents users from joining a Pool with unpaid debt, as well as
    // exiting a Pool in debt without first paying their share.

    /**
     * @dev Returns the current protocol fee percentages. These are 18 decimals fixed point numbers, which means that
     * e.g. a value of 0.1e18 stands for a 10% fee.
     */
    function getProtocolFees()
        external
        view
        returns (
            uint256 swapFee,
            uint256 withdrawFee,
            uint256 flashLoanFee
        );

    /**
     * @dev Sets new Protocol fees. The caller must be allowed by the Authorizer to do this, and the new fee values must
     * not be above the absolute maximum amounts.
     */
    function setProtocolFees(
        uint256 swapFee,
        uint256 withdrawFee,
        uint256 flashLoanFee
    ) external;

    /**
     * @dev Returns the amount of protocol fees collected by the Vault for each token in the `tokens` array.
     */
    function getCollectedFees(IERC20[] memory tokens) external view returns (uint256[] memory fees);

    /**
     * @dev Withdraws collected protocol fees, transferring them to `recipient`. The caller must be allowed by the
     * Authorizer to do this.
     */
    function withdrawCollectedFees(
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        address recipient
    ) external;
}

// File: contracts/vault/VaultAuthorization.sol



pragma solidity ^0.7.0;







abstract contract VaultAuthorization is IVault, Authentication, EmergencyPeriod, ReentrancyGuard {
    IAuthorizer private _authorizer;
    mapping(address => mapping(address => bool)) private _allowedRelayers;

    /**
     * @dev Reverts unless `user` has allowed the caller as a relayer, and the caller is allowed by the Authorizer to
     * call this function. Should only be applied to external functions.
     */
    modifier authenticateFor(address user) {
        _authenticateCallerFor(user);
        _;
    }

    constructor(IAuthorizer authorizer) {
        _authorizer = authorizer;
    }

    function changeAuthorizer(IAuthorizer newAuthorizer) external override nonReentrant authenticate {
        _authorizer = newAuthorizer;
    }

    function getAuthorizer() external view override returns (IAuthorizer authorizer) {
        authorizer = _authorizer;
        return authorizer;
    }

    function changeRelayerAllowance(address relayer, bool allowed) external override nonReentrant noEmergencyPeriod {
        _allowedRelayers[msg.sender][relayer] = allowed;
    }

    function hasAllowedRelayer(address user, address relayer) external view override returns (bool has) {
        has = _hasAllowedRelayer(user, relayer);
        return has;
    }

    /**
     * @dev Reverts unless  `user` has allowed the caller as a relayer, and the caller is allowed by the Authorizer to
     * call the entry point function.
     */
    function _authenticateCallerFor(address user) internal view {
        if (msg.sender != user) {
            _authenticateCaller();
            require(_hasAllowedRelayer(user, msg.sender), "USER_DOESNT_ALLOW_RELAYER");
        }
    }

    function _hasAllowedRelayer(address user, address relayer) internal view returns (bool has) {
        has = _allowedRelayers[user][relayer];
        return has;
    }

    function _canPerform(bytes32 roleId, address user) internal view override returns (bool has) {
        has = _authorizer.hasRole(roleId, user);
        return has;
    }
}

// File: @openzeppelin/contracts/math/SafeMath.sol



pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol



pragma solidity ^0.7.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol



pragma solidity ^0.7.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/lib/math/Math.sol



pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow checks.
 * Adapted from OpenZeppelin's SafeMath library
 */
library Math {
    /**
     * @dev Returns the addition of two unsigned integers of 256 bits, reverting on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ADD_OVERFLOW");
        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "ADD_OVERFLOW");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers of 256 bits, reverting on overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SUB_OVERFLOW");
        uint256 c = a - b;
        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SUB_OVERFLOW");
        return c;
    }

    /**
     * @dev Returns the largest of two numbers of 256 bits.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers of 256 bits.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b, "MUL_OVERFLOW");
        return c;
    }

    function divDown(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "ZERO_DIVISION");
        return a / b;
    }

    function divUp(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "ZERO_DIVISION");

        if (a == 0) {
            return 0;
        } else {
            return 1 + (a - 1) / b;
        }
    }

    function sqrtUp(uint256 x) internal pure returns (uint256) {
        //TODO: implement rounding in sqrt function
        return sqrt(x);
    }

    function sqrtDown(uint256 x) internal pure returns (uint256) {
        //TODO: implement rounding in sqrt function
        return sqrt(x);
    }

    // credit for this implementation goes to
    // https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        // this block is equivalent to r = uint256(1) << (BitMath.mostSignificantBit(x) / 2);
        // however that code costs significantly more gas
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

// File: contracts/lib/math/LogExpMath.sol

pragma solidity ^0.7.0;

// There's plenty of linter errors caused by this file, we'll eventually
// revisit it to make it more readable, verfiable and testable.
/* solhint-disable */

/**
 * @title Ethereum library for logarithm and exponential functions with 18 decimal precision.
 * @author Fernando Martinelli - @fernandomartinelli
 * @author Sergio Yuhjtman - @sergioyuhjtman
 * @author Daniel Fernandez - @dmf7z
 */
library LogExpMath {
    int256 constant DECIMALS = 1e18;
    int256 constant DOUBLE_DECIMALS = DECIMALS * DECIMALS;
    int256 constant PRECISION = 10**20;
    int256 constant DOUBLE_PRECISION = PRECISION * PRECISION;
    int256 constant PRECISION_LOG_UNDER_BOUND = DECIMALS - 10**17;
    int256 constant PRECISION_LOG_UPPER_BOUND = DECIMALS + 10**17;
    int256 constant EXPONENT_LB = -41446531673892822312;
    int256 constant EXPONENT_UB = 130700829182905140221;
    uint256 constant MILD_EXPONENT_BOUND = 2**254 / uint256(PRECISION);

    int256 constant x0 = 128000000000000000000; //2ˆ7
    int256 constant a0 = 38877084059945950922200000000000000000000000000000000000; //eˆ(x0)
    int256 constant x1 = 64000000000000000000; //2ˆ6
    int256 constant a1 = 6235149080811616882910000000; //eˆ(x1)
    int256 constant x2 = 3200000000000000000000; //2ˆ5
    int256 constant a2 = 7896296018268069516100000000000000; //eˆ(x2)
    int256 constant x3 = 1600000000000000000000; //2ˆ4
    int256 constant a3 = 888611052050787263676000000; //eˆ(x3)
    int256 constant x4 = 800000000000000000000; //2ˆ3
    int256 constant a4 = 298095798704172827474000; //eˆ(x4)
    int256 constant x5 = 400000000000000000000; //2ˆ2
    int256 constant a5 = 5459815003314423907810; //eˆ(x5)
    int256 constant x6 = 200000000000000000000; //2ˆ1
    int256 constant a6 = 738905609893065022723; //eˆ(x6)
    int256 constant x7 = 100000000000000000000; //2ˆ0
    int256 constant a7 = 271828182845904523536; //eˆ(x7)
    int256 constant x8 = 50000000000000000000; //2ˆ-1
    int256 constant a8 = 164872127070012814685; //eˆ(x8)
    int256 constant x9 = 25000000000000000000; //2ˆ-2
    int256 constant a9 = 128402541668774148407; //eˆ(x9)
    int256 constant x10 = 12500000000000000000; //2ˆ-3
    int256 constant a10 = 113314845306682631683; //eˆ(x10)
    int256 constant x11 = 6250000000000000000; //2ˆ-4
    int256 constant a11 = 106449445891785942956; //eˆ(x11)

    /**
     * Calculate the natural exponentiation of a number with 18 decimals precision.
     * @param x Exponent with 18 decimal places.
     * @notice Max x is log((2^255 - 1) / 10^20) = 130.700829182905140221
     * @notice Min x log(0.000000000000000001) = -41.446531673892822312
     * @return eˆx
     */
    function n_exp(int256 x) internal pure returns (int256) {
        require(x >= EXPONENT_LB && x <= EXPONENT_UB, "OUT_OF_BOUNDS");

        if (x < 0) return (DOUBLE_DECIMALS / n_exp(-x));
        int256 ans = PRECISION;
        int256 last = 1;
        if (x >= x0) {
            last = a0;
            x -= x0;
        }
        if (x >= x1) {
            last *= a1;
            x -= x1;
        }
        x *= 100;
        if (x >= x2) {
            ans = (ans * a2) / PRECISION;
            x -= x2;
        }
        if (x >= x3) {
            ans = (ans * a3) / PRECISION;
            x -= x3;
        }
        if (x >= x4) {
            ans = (ans * a4) / PRECISION;
            x -= x4;
        }
        if (x >= x5) {
            ans = (ans * a5) / PRECISION;
            x -= x5;
        }
        if (x >= x6) {
            ans = (ans * a6) / PRECISION;
            x -= x6;
        }
        if (x >= x7) {
            ans = (ans * a7) / PRECISION;
            x -= x7;
        }
        if (x >= x8) {
            ans = (ans * a8) / PRECISION;
            x -= x8;
        }
        if (x >= x9) {
            ans = (ans * a9) / PRECISION;
            x -= x9;
        }
        int256 s = PRECISION;
        int256 t = x;
        s += t;
        t = ((t * x) / 2) / PRECISION;
        s += t;
        t = ((t * x) / 3) / PRECISION;
        s += t;
        t = ((t * x) / 4) / PRECISION;
        s += t;
        t = ((t * x) / 5) / PRECISION;
        s += t;
        t = ((t * x) / 6) / PRECISION;
        s += t;
        t = ((t * x) / 7) / PRECISION;
        s += t;
        t = ((t * x) / 8) / PRECISION;
        s += t;
        t = ((t * x) / 9) / PRECISION;
        s += t;
        t = ((t * x) / 10) / PRECISION;
        s += t;
        t = ((t * x) / 11) / PRECISION;
        s += t;
        t = ((t * x) / 12) / PRECISION;
        s += t;
        return (((ans * s) / PRECISION) * last) / 100;
    }

    /**
     * Calculate the natural logarithm of a number with 18 decimals precision.
     * @param a Positive number with 18 decimal places.
     * @return ln(x)
     */
    function n_log(int256 a) internal pure returns (int256) {
        require(a > 0, "OUT_OF_BOUNDS");
        if (a < DECIMALS) return (-n_log(DOUBLE_DECIMALS / a));
        int256 ans = 0;
        if (a >= a0 * DECIMALS) {
            ans += x0;
            a /= a0;
        }
        if (a >= a1 * DECIMALS) {
            ans += x1;
            a /= a1;
        }
        a *= 100;
        ans *= 100;
        if (a >= a2) {
            ans += x2;
            a = (a * PRECISION) / a2;
        }
        if (a >= a3) {
            ans += x3;
            a = (a * PRECISION) / a3;
        }
        if (a >= a4) {
            ans += x4;
            a = (a * PRECISION) / a4;
        }
        if (a >= a5) {
            ans += x5;
            a = (a * PRECISION) / a5;
        }
        if (a >= a6) {
            ans += x6;
            a = (a * PRECISION) / a6;
        }
        if (a >= a7) {
            ans += x7;
            a = (a * PRECISION) / a7;
        }
        if (a >= a8) {
            ans += x8;
            a = (a * PRECISION) / a8;
        }
        if (a >= a9) {
            ans += x9;
            a = (a * PRECISION) / a9;
        }
        if (a >= a10) {
            ans += x10;
            a = (a * PRECISION) / a10;
        }
        if (a >= a11) {
            ans += x11;
            a = (a * PRECISION) / a11;
        }
        int256 z = (PRECISION * (a - PRECISION)) / (a + PRECISION);
        int256 s = z;
        int256 z_squared = (z * z) / PRECISION;
        int256 t = (z * z_squared) / PRECISION;
        s += t / 3;
        t = (t * z_squared) / PRECISION;
        s += t / 5;
        t = (t * z_squared) / PRECISION;
        s += t / 7;
        t = (t * z_squared) / PRECISION;
        s += t / 9;
        t = (t * z_squared) / PRECISION;
        s += t / 11;
        return (ans + 2 * s) / 100;
    }

    /**
     * Computes x to the power of y for numbers with 18 decimals precision.
     * @param x Base with 18 decimal places.
     * @param y Exponent with 18 decimal places.
     * @notice Must fulfil: -41.446531673892822312  < (log(x) * y) <  130.700829182905140221
     * @return xˆy
     */
    function pow(uint256 x, uint256 y) internal pure returns (uint256) {
        if (y == 0) {
            return uint256(DECIMALS);
        }

        if (x == 0) {
            return 0;
        }

        require(x < 2**255, "X_OUT_OF_BOUNDS"); // uint256 can be casted to a positive int256
        require(y < MILD_EXPONENT_BOUND, "Y_OUT_OF_BOUNDS");
        int256 x_int256 = int256(x);
        int256 y_int256 = int256(y);
        int256 logx_times_y;
        if (PRECISION_LOG_UNDER_BOUND < x_int256 && x_int256 < PRECISION_LOG_UPPER_BOUND) {
            int256 logbase = n_log_36(x_int256);
            logx_times_y = ((logbase / DECIMALS) * y_int256 + ((logbase % DECIMALS) * y_int256) / DECIMALS);
        } else {
            logx_times_y = n_log(x_int256) * y_int256;
        }
        require(
            EXPONENT_LB * DECIMALS <= logx_times_y && logx_times_y <= EXPONENT_UB * DECIMALS,
            "PRODUCT_OUT_OF_BOUNDS"
        );
        logx_times_y /= DECIMALS;
        return uint256(n_exp(logx_times_y));
    }

    /**
     * Computes log of a number in base of another number, both numbers with 18 decimals precision.
     * @param arg Argument with 18 decimal places.
     * @param base Base with 18 decimal places.
     * @notice Must fulfil: -41.446531673892822312  < (log(x) * y) <  130.700829182905140221
     * @return log[base](arg)
     */
    function log(int256 arg, int256 base) internal pure returns (int256) {
        int256 logbase;
        if (PRECISION_LOG_UNDER_BOUND < base && base < PRECISION_LOG_UPPER_BOUND) {
            logbase = n_log_36(base);
        } else {
            logbase = n_log(base) * DECIMALS;
        }
        int256 logarg;
        if (PRECISION_LOG_UNDER_BOUND < arg && arg < PRECISION_LOG_UPPER_BOUND) {
            logarg = n_log_36(arg);
        } else {
            logarg = n_log(arg) * DECIMALS;
        }
        return (logarg * DECIMALS) / logbase;
    }

    /**
     * Private function to calculate the natural logarithm of a number with 36 decimals precision.
     * @param a Positive number with 18 decimal places.
     * @return ln(x)
     */
    function n_log_36(int256 a) private pure returns (int256) {
        a *= DECIMALS;
        int256 z = (DOUBLE_DECIMALS * (a - DOUBLE_DECIMALS)) / (a + DOUBLE_DECIMALS);
        int256 s = z;
        int256 z_squared = (z * z) / DOUBLE_DECIMALS;
        int256 t = (z * z_squared) / DOUBLE_DECIMALS;
        s += t / 3;
        t = (t * z_squared) / DOUBLE_DECIMALS;
        s += t / 5;
        t = (t * z_squared) / DOUBLE_DECIMALS;
        s += t / 7;
        t = (t * z_squared) / DOUBLE_DECIMALS;
        s += t / 9;
        t = (t * z_squared) / DOUBLE_DECIMALS;
        s += t / 11;
        t = (t * z_squared) / DOUBLE_DECIMALS;
        s += t / 13;
        t = (t * z_squared) / DOUBLE_DECIMALS;
        s += t / 15;
        return 2 * s;
    }
}

// File: contracts/lib/math/FixedPoint.sol



pragma solidity ^0.7.0;


/* solhint-disable private-vars-leading-underscore */

library FixedPoint {
    uint256 internal constant ONE = 1e18; // 18 decimal places
    uint256 internal constant MAX_POW_RELATIVE_ERROR = 10000; // 10^(-14)

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        // Fixed Point addition is the same as regular checked addition

        uint256 c = a + b;
        require(c >= a, "ADD_OVERFLOW");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        // Fixed Point addition is the same as regular checked addition

        require(b <= a, "SUB_OVERFLOW");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c0 = a * b;
        require(a == 0 || c0 / a == b, "MUL_OVERFLOW");
        uint256 c1 = c0 + (ONE / 2);
        require(c1 >= c0, "MUL_OVERFLOW");
        uint256 c2 = c1 / ONE;
        return c2;
    }

    function mulDown(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 product = a * b;
        require(a == 0 || product / a == b, "MUL_OVERFLOW");

        return product / ONE;
    }

    function mulUp(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 product = a * b;
        require(a == 0 || product / a == b, "MUL_OVERFLOW");

        if (product == 0) {
            return 0;
        } else {
            // The traditional divUp formula is:
            // divUp(x, y) := (x + y - 1) / y
            // To avoid intermediate overflow in the addition, we distribute the division and get:
            // divUp(x, y) := (x - 1) / y + 1
            // Note that this requires x != 0, which we already tested for.

            return ((product - 1) / ONE) + 1;
        }
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "ZERO_DIVISION");
        uint256 c0 = a * ONE;
        require(a == 0 || c0 / a == ONE, "DIV_INTERNAL"); // mul overflow
        uint256 c1 = c0 + (b / 2);
        require(c1 >= c0, "DIV_INTERNAL"); // add require
        uint256 c2 = c1 / b;
        return c2;
    }

    function divDown(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "ZERO_DIVISION");

        if (a == 0) {
            return 0;
        } else {
            uint256 aInflated = a * ONE;
            require(aInflated / a == ONE, "DIV_INTERNAL"); // mul overflow

            return aInflated / b;
        }
    }

    function divUp(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "ZERO_DIVISION");

        if (a == 0) {
            return 0;
        } else {
            uint256 aInflated = a * ONE;
            require(aInflated / a == ONE, "DIV_INTERNAL"); // mul overflow

            // The traditional divUp formula is:
            // divUp(x, y) := (x + y - 1) / y
            // To avoid intermediate overflow in the addition, we distribute the division and get:
            // divUp(x, y) := (x - 1) / y + 1
            // Note that this requires x != 0, which we already tested for.

            return ((aInflated - 1) / b) + 1;
        }
    }

    function pow(uint256 x, uint256 y) internal pure returns (uint256) {
        return LogExpMath.pow(x, y);
    }

    function powDown(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 result = LogExpMath.pow(x, y);
        if (result == 0) {
            return 0;
        }
        return sub(sub(result, mulDown(result, MAX_POW_RELATIVE_ERROR)), 1);
    }

    function powUp(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 result = LogExpMath.pow(x, y);
        return add(add(result, mulUp(result, MAX_POW_RELATIVE_ERROR)), 1);
    }

    /**
     * @dev Tells the complement of a given value capped to zero to avoid overflow
     */
    function complement(uint256 x) internal pure returns (uint256) {
        return x >= ONE ? 0 : sub(ONE, x);
    }
}

// File: contracts/lib/helpers/InputHelpers.sol



pragma solidity ^0.7.0;


library InputHelpers {
    function ensureInputLengthMatch(uint256 a, uint256 b) internal pure {
        require(a == b, "INPUT_LENGTH_MISMATCH");
    }

    function ensureInputLengthMatch(
        uint256 a,
        uint256 b,
        uint256 c
    ) internal pure {
        require(a == b && b == c, "INPUT_LENGTH_MISMATCH");
    }

    function ensureArrayIsSorted(IERC20[] memory array) internal pure {
        if (array.length < 2) {
            return;
        }

        IERC20 previous = array[0];
        for (uint256 i = 1; i < array.length; ++i) {
            IERC20 current = array[i];
            require(previous < current, "UNSORTED_ARRAY");
            previous = current;
        }
    }
}

// File: contracts/vault/Fees.sol



pragma solidity ^0.7.0;










abstract contract Fees is IVault, ReentrancyGuard, VaultAuthorization {
    using Math for uint256;
    using SafeERC20 for IERC20;

    // Stores the fee collected per each token that is only withdrawable by the admin.
    mapping(IERC20 => uint256) private _collectedProtocolFees;

    // All fixed are 18-decimal fixed point numbers.

    // The withdraw fee is charged whenever tokens exit the vault (except in the case of swaps), and is a
    // percentage of the tokens exiting.
    uint256 private _protocolWithdrawFee;

    // The swap fee is charged whenever a swap occurs, and is a percentage of the fee charged by the Pool. These are not
    // actually charged on each individual swap: the `Vault` relies on the Pools being honest and reporting due fees
    // when joined and exited.
    uint256 private _protocolSwapFee;

    // The flash loan fee is charged whenever a flash loan occurs, and is a percentage of the tokens lent.
    uint256 private _protocolFlashLoanFee;

    // Absolute maximum fee percentages (1e18 = 100%, 1e16 = 1%).
    uint256 private constant _MAX_PROTOCOL_SWAP_FEE = 50e16; // 50%
    uint256 private constant _MAX_PROTOCOL_WITHDRAW_FEE = 0.5e16; // 0.5%
    uint256 private constant _MAX_PROTOCOL_FLASH_LOAN_FEE = 1e16; // 1%

    function setProtocolFees(
        uint256 newSwapFee,
        uint256 newWithdrawFee,
        uint256 newFlashLoanFee
    ) external override nonReentrant authenticate {
        require(newSwapFee <= _MAX_PROTOCOL_SWAP_FEE, "SWAP_FEE_TOO_HIGH");
        require(newWithdrawFee <= _MAX_PROTOCOL_WITHDRAW_FEE, "WITHDRAW_FEE_TOO_HIGH");
        require(newFlashLoanFee <= _MAX_PROTOCOL_FLASH_LOAN_FEE, "FLASH_LOAN_FEE_TOO_HIGH");

        _protocolSwapFee = newSwapFee;
        _protocolWithdrawFee = newWithdrawFee;
        _protocolFlashLoanFee = newFlashLoanFee;
    }

    function getProtocolFees()
        external
        view
        override
        returns (
            uint256 swapFee,
            uint256 withdrawFee,
            uint256 flashLoanFee
        )
    {
        return (_protocolSwapFee, _protocolWithdrawFee, _protocolFlashLoanFee);
    }

    /**
     * @dev Returns the protocol swap fee percentage.
     */
    function _getProtocolSwapFee() internal view returns (uint256) {
        return _protocolSwapFee;
    }

    /**
     * @dev Returns the protocol fee to charge for a withdrawal of `amount`.
     */
    function _calculateProtocolWithdrawFeeAmount(uint256 amount) internal view returns (uint256) {
        // Fixed point multiplication introduces error: we round up, which means in certain scenarios the charged
        // percentage can be slightly higher than intended.
        return FixedPoint.mulUp(amount, _protocolWithdrawFee);
    }

    /**
     * @dev Returns the protocol fee to charge for a flash loan of `amount`.
     */
    function _calculateProtocolFlashLoanFeeAmount(uint256 amount) internal view returns (uint256) {
        // Fixed point multiplication introduces error: we round up, which means in certain scenarios the charged
        // percentage can be slightly higher than intended.
        return FixedPoint.mulUp(amount, _protocolFlashLoanFee);
    }

    function getCollectedFees(IERC20[] memory tokens) external view override returns (uint256[] memory) {
        return _getCollectedFees(tokens);
    }

    function withdrawCollectedFees(
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        address recipient
    ) external override nonReentrant noEmergencyPeriod authenticate {
        InputHelpers.ensureInputLengthMatch(tokens.length, amounts.length);

        for (uint256 i = 0; i < tokens.length; ++i) {
            IERC20 token = tokens[i];
            uint256 amount = amounts[i];
            _decreaseCollectedFees(token, amount);
            token.safeTransfer(recipient, amount);
        }
    }

    /**
     * @dev Increases the number of collected protocol fees for `token` by `amount`.
     */
    function _increaseCollectedFees(IERC20 token, uint256 amount) internal {
        uint256 currentCollectedFees = _collectedProtocolFees[token];
        uint256 newTotal = currentCollectedFees.add(amount);
        _setCollectedFees(token, newTotal);
    }

    /**
     * @dev Decreases the number of collected protocol fees for `token` by `amount`.
     */
    function _decreaseCollectedFees(IERC20 token, uint256 amount) internal {
        uint256 currentCollectedFees = _collectedProtocolFees[token];
        require(currentCollectedFees >= amount, "INSUFFICIENT_COLLECTED_FEES");

        uint256 newTotal = currentCollectedFees - amount;
        _setCollectedFees(token, newTotal);
    }

    /**
     * @dev Sets the number of collected protocol fees for `token` to `newTotal`.
     *
     * This costs less gas than `_increaseCollectedFees` or `_decreaseCollectedFees`, since the current collected fees
     * do not need to be read.
     */
    function _setCollectedFees(IERC20 token, uint256 newTotal) internal {
        _collectedProtocolFees[token] = newTotal;
    }

    /**
     * @dev Returns the number of collected fees for each token in the `tokens` array.
     */
    function _getCollectedFees(IERC20[] memory tokens) internal view returns (uint256[] memory fees) {
        fees = new uint256[](tokens.length);

        for (uint256 i = 0; i < tokens.length; ++i) {
            fees[i] = _collectedProtocolFees[tokens[i]];
        }
    }
}

// File: contracts/vault/FlashLoanProvider.sol



// This flash loan provider was based on the Aave protocol's open source
// implementation and terminology and interfaces are intentionally kept
// similar

pragma solidity ^0.7.0;







abstract contract FlashLoanProvider is ReentrancyGuard, Fees {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    function flashLoan(
        IFlashLoanReceiver receiver,
        IERC20[] memory tokens,
        uint256[] memory amounts,
        bytes calldata receiverData
    ) external override nonReentrant noEmergencyPeriod {
        InputHelpers.ensureInputLengthMatch(tokens.length, amounts.length);

        uint256[] memory feeAmounts = new uint256[](tokens.length);
        uint256[] memory preLoanBalances = new uint256[](tokens.length);

        IERC20 previousToken = IERC20(0);
        for (uint256 i = 0; i < tokens.length; ++i) {
            IERC20 token = tokens[i];
            uint256 amount = amounts[i];

            require(token > previousToken, "UNSORTED_TOKENS"); // Prevents duplicate tokens
            previousToken = token;

            // Not checking amount against current balance, transfer will revert if it is exceeded
            preLoanBalances[i] = token.balanceOf(address(this));
            feeAmounts[i] = _calculateProtocolFlashLoanFeeAmount(amount);

            token.safeTransfer(address(receiver), amount);
        }

        receiver.receiveFlashLoan(tokens, amounts, feeAmounts, receiverData);

        for (uint256 i = 0; i < tokens.length; ++i) {
            IERC20 token = tokens[i];
            uint256 preLoanBalance = preLoanBalances[i];

            uint256 postLoanBalance = token.balanceOf(address(this));
            require(postLoanBalance >= preLoanBalance, "INVALID_POST_LOAN_BALANCE");

            uint256 receivedFees = postLoanBalance - preLoanBalance;
            require(receivedFees >= feeAmounts[i], "INSUFFICIENT_COLLECTED_FEES");

            _increaseCollectedFees(token, receivedFees);
        }
    }
}

// File: @openzeppelin/contracts/utils/EnumerableSet.sol



pragma solidity ^0.7.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// File: contracts/lib/helpers/EnumerableMap.sol



pragma solidity ^0.7.0;

// Based on the EnumerableSet library from OpenZeppelin contracts, altered to include
// the following:
//  * a map from IERC20 to bytes32
//  * entries are stored in mappings instead of arrays, reducing implicit storage reads for out-of-bounds checks
//  * _unchecked_at and _unchecked_valueAt, which allow for more gas efficient data reads in some scenarios
//  * _indexOf and _unchecked_setAt, which allow for more gas efficient data writes in some scenarios

// We're using non-standard casing for the unchecked functions to differentiate them, so we need to turn off that rule
// solhint-disable func-name-mixedcase


/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 */
library EnumerableMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Number of entries in the map
        uint256 _length;
        // Storage of map keys and values
        mapping(uint256 => MapEntry) _entries;
        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(
        Map storage map,
        bytes32 key,
        bytes32 value
    ) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        // Equivalent to !contains(map, key)
        if (keyIndex == 0) {
            uint256 previousLength = map._length;
            map._entries[previousLength] = MapEntry({ _key: key, _value: value });
            map._length = previousLength + 1;

            // The entry is stored at previousLength, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = previousLength + 1;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Returns the index for `key`, which can be used alongside the {at} family of functions, including critically
     * {unchecked_setAt}. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _indexOf(Map storage map, bytes32 key) private view returns (uint256) {
        return _indexOf(map, key, "OUT_OF_BOUNDS");
    }

    /**
     * @dev Same as {_indexOf}, with a custom error message when `key` is not in the map.
     */
    function _indexOf(
        Map storage map,
        bytes32 key,
        string memory notFoundErrorMessage
    ) private view returns (uint256) {
        uint256 index = map._indexes[key];
        require(index > 0, notFoundErrorMessage);
        return index - 1;
    }

    /**
     * @dev Updates the value for an entry, given its key's index. The key index can be retrieved via {indexOf}, and it
     * should be noted that key indices may change when calling {add} or {remove}. O(1).
     *
     * This function performs one less storage read than {set}, but it should only be used when `index` is known to be
     * within bounds.
     */
    function _unchecked_setAt(
        Map storage map,
        uint256 index,
        bytes32 value
    ) private {
        map._entries[index]._value = value;
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        // Equivalent to contains(map, key)
        if (keyIndex != 0) {
            // To delete a key-value pair from the _entries pseudo-array in O(1), we swap the entry to delete with the
            // one at the highest index, and then remove this last entry (sometimes called as 'swap and pop').
            // This modifies the order of the pseudo-array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            delete map._entries[lastIndex];
            map._length = lastIndex;

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._length;
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._length > index, "OUT_OF_BOUNDS");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Same as {at}, except this doesn't revert if `index` it outside of the map (i.e. if it is
     * equal or larger than {length}). O(1).
     *
     * This function performs one less storage read than {at}, but should only be used when `index` is known to be
     * within bounds.
     */
    function _unchecked_at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Same as {unchecked_valueAt}, except it only returns the value and not the key (performing one less storage
     * read). O(1).
     */
    function _unchecked_valueAt(Map storage map, uint256 index) private view returns (bytes32) {
        return map._entries[index]._value;
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        return _get(map, key, "OUT_OF_BOUNDS");
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     */
    function _get(
        Map storage map,
        bytes32 key,
        string memory notFoundErrorMessage
    ) private view returns (bytes32) {
        uint256 index = _indexOf(map, key, notFoundErrorMessage);
        return _unchecked_valueAt(map, index);
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(value)));
    }

    /**
     * @dev Returns the index for `key`, which can be used alongside the {at} family of functions, including critically
     * {unchecked_setAt}. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function indexOf(UintToAddressMap storage map, uint256 key) internal view returns (uint256) {
        return _indexOf(map._inner, bytes32(uint256(address(key))));
    }

    /**
     * @dev Updates the value for an entry, given its key's index. The key index can be retrieved via {indexOf}, and it
     * should be noted that key indices may change when calling {add} or {remove}. O(1).
     *
     * This function performs one less storage read than {set}, but it should only be used when `index` is known to be
     * within bounds.
     */
    function unchecked_setAt(
        UintToAddressMap storage map,
        uint256 index,
        address value
    ) internal {
        _unchecked_setAt(map._inner, index, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint256(value)));
    }

    /**
     * @dev Same as {at}, except this doesn't revert if `index` it outside of the map (i.e. if it is
     * equal or larger than {length}). O(1).
     *
     * This function performs one less storage read than {at}, but should only be used when `index` is known to be
     * within bounds.
     */
    function unchecked_at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _unchecked_at(map._inner, index);
        return (uint256(key), address(uint256(value)));
    }

    /**
     * @dev Same as {unchecked_valueAt}, except it only returns the value and not the key (performing one less storage
     * read). O(1).
     */
    function unchecked_valueAt(UintToAddressMap storage map, uint256 index) internal view returns (address) {
        return address(uint256(_unchecked_valueAt(map._inner, index)));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key), errorMessage)));
    }

    // IERC20ToBytes32Map

    struct IERC20ToBytes32Map {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        IERC20ToBytes32Map storage map,
        IERC20 key,
        bytes32 value
    ) internal returns (bool) {
        return _set(map._inner, bytes32(uint256(address(key))), value);
    }

    /**
     * @dev Returns the index for `key`, which can be used alongside the {at} family of functions, including critically
     * {unchecked_setAt}. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function indexOf(IERC20ToBytes32Map storage map, IERC20 key) internal view returns (uint256) {
        return _indexOf(map._inner, bytes32(uint256(address(key))));
    }

    /**
     * @dev Same as {indexOf}, with a custom error message when `key` is not in the map.
     */
    function indexOf(
        IERC20ToBytes32Map storage map,
        IERC20 key,
        string memory notFoundErrorMessage
    ) internal view returns (uint256) {
        return _indexOf(map._inner, bytes32(uint256(address(key))), notFoundErrorMessage);
    }

    /**
     * @dev Updates the value for an entry, given its key's index. The key index can be retrieved via {indexOf}, and it
     * should be noted that key indices may change when calling {add} or {remove}. O(1).
     *
     * This function performs one less storage read than {set}, but it should only be used when `index` is known to be
     * within bounds.
     */
    function unchecked_setAt(
        IERC20ToBytes32Map storage map,
        uint256 index,
        bytes32 value
    ) internal {
        _unchecked_setAt(map._inner, index, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(IERC20ToBytes32Map storage map, IERC20 key) internal returns (bool) {
        return _remove(map._inner, bytes32(uint256(address(key))));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(IERC20ToBytes32Map storage map, IERC20 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(uint256(address(key))));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(IERC20ToBytes32Map storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(IERC20ToBytes32Map storage map, uint256 index) internal view returns (IERC20, bytes32) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (IERC20(uint256(key)), value);
    }

    /**
     * @dev Same as {at}, except this doesn't revert if `index` it outside of the map (i.e. if it is
     * equal or larger than {length}). O(1).
     *
     * This function performs one less storage read than {at}, but should only be used when `index` is known to be
     * within bounds.
     */
    function unchecked_at(IERC20ToBytes32Map storage map, uint256 index) internal view returns (IERC20, bytes32) {
        (bytes32 key, bytes32 value) = _unchecked_at(map._inner, index);
        return (IERC20(uint256(key)), value);
    }

    /**
     * @dev Same as {unchecked_valueAt}, except it only returns the value and not the key (performing one less storage
     * read). O(1).
     */
    function unchecked_valueAt(IERC20ToBytes32Map storage map, uint256 index) internal view returns (bytes32) {
        return _unchecked_valueAt(map._inner, index);
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(IERC20ToBytes32Map storage map, IERC20 key) internal view returns (bytes32) {
        return _get(map._inner, bytes32(uint256(address(key))));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(
        IERC20ToBytes32Map storage map,
        IERC20 key,
        string memory errorMessage
    ) internal view returns (bytes32) {
        return _get(map._inner, bytes32(uint256(address(key))), errorMessage);
    }
}

// File: @openzeppelin/contracts/utils/SafeCast.sol



pragma solidity ^0.7.0;


/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// File: @openzeppelin/contracts/utils/Counters.sol



pragma solidity ^0.7.0;


/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// File: contracts/vault/interfaces/IBasePool.sol



pragma solidity ^0.7.0;



/**
 * @dev Interface all Pool contracts should implement. Note that this is not the complete Pool contract interface, as it
 * is missing the swap hooks: Pool contracts should instead inherit from either IGeneralPool or IMinimalSwapInfoPool.
 */
interface IBasePool {
    /**
     * @dev Called by the Vault when a user calls `IVault.joinPool` to join this Pool. Returns how many tokens the user
     * should provide for each registered token, as well as how many protocol fees the Pool owes to the Vault. After
     * returning, the Vault will take tokens from the `sender` and add it to the Pool's balance, as well as collect
     * reported protocol fees. The current protocol swap fee percentage is provided to help compute this value.
     *
     * Due protocol fees are reported and charged on join events so that new users join the Pool free of debt.
     *
     * `sender` is the account performing the join (from whom tokens will be withdrawn), and `recipient` an account
     * designated to receive any benefits (typically pool shares). `currentBalances` contains the total token balances
     * for each token the Pool registered in the Vault, in the same order as `IVault.getPoolTokens` would return.
     *
     * `latestBlockNumberUsed` is the last block number in which any of the Pool's registered tokens last changed its
     * balance. This can be used to implement price oracles that are resilient to 'sandwich' attacks.
     *
     * Contracts implementing this function should check that the caller is indeed the Vault before performing any
     * state-changing operations, such as minting pool shares.
     */
    function onJoinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] calldata currentBalances,
        uint256 latestBlockNumberUsed,
        uint256 protocolSwapFee,
        bytes calldata userData
    ) external returns (uint256[] memory amountsIn, uint256[] memory dueProtocolFeeAmounts);

    /**
     * @dev Called by the Vault when a user calls `IVault.exitPool` to exit this Pool. Returns how many tokens the Vault
     * should deduct from the Pool, as well as how many protocol fees the Pool owes to the Vault. After returning, the
     * Vault will take tokens from the Pool's balance and add grant them to `recipient`, as well as collect reported
     * protocol fees. The current protocol swap fee percentage is provided to help compute this value.
     *
     * Due protocol fees are reported and charged on exit events so that users exit the Pool having paid all debt.
     *
     * `sender` is the account performing the exit (typically the holder of pool shares), and `recipient` the account to
     * which the Vault will grant tokens. `currentBalances` contains the total token balances for each token the Pool
     * registered in the Vault, in the same order as `IVault.getPoolTokens` would return.
     *
     * `latestBlockNumberUsed` is the last block number in which any of the Pool's registered tokens last changed its
     * balance. This can be used to implement price oracles that are resilient to 'sandwich' attacks.
     *
     * Contracts implementing this function should check that the caller is indeed the Vault before performing any
     * state-changing operations, such as burning pool shares.
     */
    function onExitPool(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] calldata currentBalances,
        uint256 latestBlockNumberUsed,
        uint256 protocolSwapFee,
        bytes calldata userData
    ) external returns (uint256[] memory amountsOut, uint256[] memory dueProtocolFeeAmounts);
}

// File: contracts/vault/InternalBalance.sol



pragma solidity ^0.7.0;







abstract contract InternalBalance is ReentrancyGuard, Fees {
    using Math for uint256;
    using SafeERC20 for IERC20;

    // Stores all account's Internal Balance for each token.
    mapping(address => mapping(IERC20 => uint256)) private _internalTokenBalance;

    function getInternalBalance(address user, IERC20[] memory tokens)
        external
        view
        override
        returns (uint256[] memory balances)
    {
        balances = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            balances[i] = _getInternalBalance(user, tokens[i]);
        }
    }

    function depositToInternalBalance(BalanceTransfer[] memory transfers)
        external
        override
        nonReentrant
        noEmergencyPeriod
    {
        for (uint256 i = 0; i < transfers.length; i++) {
            address sender = transfers[i].sender;
            _authenticateCallerFor(sender);

            IERC20 token = transfers[i].token;
            uint256 amount = transfers[i].amount;
            address recipient = transfers[i].recipient;

            _increaseInternalBalance(recipient, token, amount);
            token.safeTransferFrom(sender, address(this), amount);
        }
    }

    function transferToExternalBalance(BalanceTransfer[] memory transfers) external override nonReentrant {
        for (uint256 i = 0; i < transfers.length; i++) {
            address sender = transfers[i].sender;
            _authenticateCallerFor(sender);

            IERC20 token = transfers[i].token;
            uint256 amount = transfers[i].amount;
            address recipient = transfers[i].recipient;

            // Do not charge withdrawal fee, since it's just making use of the Vault's allowance
            token.safeTransferFrom(sender, recipient, amount);
        }
    }

    function withdrawFromInternalBalance(BalanceTransfer[] memory transfers) external override nonReentrant {
        for (uint256 i = 0; i < transfers.length; i++) {
            address sender = transfers[i].sender;
            _authenticateCallerFor(sender);

            IERC20 token = transfers[i].token;
            uint256 amount = transfers[i].amount;
            address recipient = transfers[i].recipient;

            uint256 feeAmount = _calculateProtocolWithdrawFeeAmount(amount);
            _increaseCollectedFees(token, feeAmount);

            _decreaseInternalBalance(sender, token, amount);
            token.safeTransfer(recipient, amount.sub(feeAmount));
        }
    }

    function transferInternalBalance(BalanceTransfer[] memory transfers)
        external
        override
        nonReentrant
        noEmergencyPeriod
    {
        for (uint256 i = 0; i < transfers.length; i++) {
            address sender = transfers[i].sender;
            _authenticateCallerFor(sender);

            IERC20 token = transfers[i].token;
            uint256 amount = transfers[i].amount;
            address recipient = transfers[i].recipient;

            _decreaseInternalBalance(sender, token, amount);
            _increaseInternalBalance(recipient, token, amount);
        }
    }

    /**
     * @dev Increases `account`'s Internal Balance for `token` by `amount`.
     */
    function _increaseInternalBalance(
        address account,
        IERC20 token,
        uint256 amount
    ) internal {
        uint256 currentInternalBalance = _getInternalBalance(account, token);
        uint256 newBalance = currentInternalBalance.add(amount);
        _setInternalBalance(account, token, newBalance);
    }

    /**
     * @dev Decreases `account`'s Internal Balance for `token` by `amount`.
     */
    function _decreaseInternalBalance(
        address account,
        IERC20 token,
        uint256 amount
    ) internal {
        uint256 currentInternalBalance = _getInternalBalance(account, token);
        require(currentInternalBalance >= amount, "INSUFFICIENT_INTERNAL_BALANCE");
        uint256 newBalance = currentInternalBalance - amount;
        _setInternalBalance(account, token, newBalance);
    }

    /**
     * @dev Sets `account`'s Internal Balance for `token` to `balance`.
     *
     * This costs less gas than `_increaseInternalBalance` or `_decreaseInternalBalance`, since the current collected
     * fees do not need to be read.
     */
    function _setInternalBalance(
        address account,
        IERC20 token,
        uint256 balance
    ) internal {
        _internalTokenBalance[account][token] = balance;
        emit InternalBalanceChanged(account, token, balance);
    }

    /**
     * @dev Returns `account`'s Internal Balance for `token`.
     */
    function _getInternalBalance(address account, IERC20 token) internal view returns (uint256) {
        return _internalTokenBalance[account][token];
    }
}

// File: contracts/vault/balances/BalanceAllocation.sol



pragma solidity ^0.7.0;


// This library is used to create a data structure that represents a token's balance for a Pool. 'cash' is how many
// tokens the Pool has sitting inside of the Vault. 'managed' is how many tokens were withdrawn from the Vault by the
// Pool's Asset Manager. 'total' is the sum of these two, and represents the Pool's total token balance, including
// tokens that are *not* inside of the Vault.
//
// 'cash' is updated whenever tokens enter and exit the Vault, while 'managed' is only updated if the reason tokens are
// moving is due to an Asset Manager action. This is reflected in the different methods available: 'increaseCash'
// and 'decreaseCash' for swaps and add/remove liquidity events, and 'cashToManaged' and 'managedToCash' for
// events transferring funds to and from the asset manager.
//
// The Vault disallows the Pool's 'cash' ever becoming negative, in other words, it can never use any tokens that
// are not inside of the Vault.
//
// One of the goals of this library is to store the entire token balance in a single storage slot, which is we we use
// 112 bit unsigned integers for 'cash' and 'managed'. Since 'total' is also a 112 bit unsigned value, any combination
// of 'cash' and 'managed' that yields a 'total' that doesn't fit in that range is disallowed.
//
// The remaining 32 bits of each storage slot are used to store the most recent block number where a balance was
// updated. This can be used to implement price oracles that are resilient to 'sandwich' attacks.
//
// We could use a Solidity struct to pack these two values together in a single storage slot, but unfortunately Solidity
// only allows for structs to live in either storage, calldata or memory. Because a memory struct still takes up a
// slot in the stack (to store its memory location), and because the entire balance fits in a single stack slot (two
// 112 bit values), using memory is strictly less gas performant. Therefore, we do manual packing and unpacking. The
// type we use to represent these values is bytes32, as it doesn't have any arithmetic operations and therefore reduces
// the chance of misuse.
library BalanceAllocation {
    using Math for uint256;

    // The 'cash' portion of the balance is stored in the least significant 112 bits of a 256 bit word, while the
    // 'managed' part uses the following 112 bits. The remaining 32 bits are used to store the block number.

    /**
     * @dev Returns the total amount of Pool tokens, including those that are not currently in the Vault ('managed').
     */
    function total(bytes32 balance) internal pure returns (uint256) {
        return cash(balance).add(managed(balance));
    }

    /**
     * @dev Returns the amount of Pool tokens currently in the Vault.
     */
    function cash(bytes32 balance) internal pure returns (uint256) {
        uint256 mask = 2**(112) - 1;
        return uint256(balance) & mask;
    }

    /**
     * @dev Returns the amount of Pool tokens that have been withdrawn (or reported) by its Asset Manager.
     */
    function managed(bytes32 balance) internal pure returns (uint256) {
        uint256 mask = 2**(112) - 1;
        return uint256(balance >> 112) & mask;
    }

    /**
     * @dev Returns the last block number when a balance was updated.
     */
    function blockNumber(bytes32 balance) internal pure returns (uint256) {
        uint256 mask = 2**(32) - 1;
        return uint256(balance >> 224) & mask;
    }

    /**
     * @dev Returns the total balance for each entry in `balances`.
     */
    function totals(bytes32[] memory balances) internal pure returns (uint256[] memory results) {
        results = new uint256[](balances.length);
        for (uint256 i = 0; i < results.length; i++) {
            results[i] = total(balances[i]);
        }
    }

    /**
     * @dev Returns the total balance for each entry in `balances`, as well as the latest block number when any of them
     * was last updated.
     */
    function totalsAndMaxBlockNumber(bytes32[] memory balances)
        internal
        pure
        returns (uint256[] memory results, uint256 maxBlockNumber)
    {
        maxBlockNumber = 0;
        results = new uint256[](balances.length);

        for (uint256 i = 0; i < results.length; i++) {
            bytes32 balance = balances[i];
            results[i] = total(balance);
            maxBlockNumber = Math.max(maxBlockNumber, blockNumber(balance));
        }
    }

    /**
     * @dev Returns true if `balance`'s total balance is zero. Costs less gas than computing the total.
     */
    function isZero(bytes32 balance) internal pure returns (bool) {
        // We simply need to check the least significant 224 bytes of the word, the block number does not affect this.
        uint256 mask = 2**(224) - 1;
        return (uint256(balance) & mask) == 0;
    }

    /**
     * @dev Returns true if `balance`'s total balance is not zero. Costs less gas than computing the total.
     */
    function isNotZero(bytes32 balance) internal pure returns (bool) {
        return !isZero(balance);
    }

    /**
     * @dev Packs together cash and managed amounts with a block number to create a balance value.
     * Critically, this also checks the sum of cash and external doesn't overflow, that is, that `total()` can be
     * computed.
     */
    function toBalance(
        uint256 _cash,
        uint256 _managed,
        uint256 _blockNumber
    ) internal pure returns (bytes32) {
        uint256 balance = _cash + _managed;
        require(balance >= _cash && balance < 2**112, "BALANCE_TOTAL_OVERFLOW");
        // We assume the block number will fits in an uint32 - this is expected to hold for at least a few decades.
        return _pack(_cash, _managed, _blockNumber);
    }

    /**
     * @dev Increases a Pool's 'cash' (and therefore its 'total'). Called when Pool tokens are sent to the Vault (except
     * when an Asset Manager action decreases the managed balance).
     */
    function increaseCash(bytes32 balance, uint256 amount) internal view returns (bytes32) {
        uint256 newCash = cash(balance).add(amount);
        uint256 currentManaged = managed(balance);
        uint256 newBlockNumber = block.number;

        return toBalance(newCash, currentManaged, newBlockNumber);
    }

    /**
     * @dev Decreases a Pool's 'cash' (and therefore its 'total'). Called when Pool tokens are sent from the Vault
     * (except as an Asset Manager action that increases the managed balance).
     */
    function decreaseCash(bytes32 balance, uint256 amount) internal view returns (bytes32) {
        uint256 newCash = cash(balance).sub(amount);
        uint256 currentManaged = managed(balance);
        uint256 newBlockNumber = block.number;

        return toBalance(newCash, currentManaged, newBlockNumber);
    }

    /**
     * @dev Moves 'cash' into 'managed', leaving 'total' unchanged. Called when Pool tokens are sent from the Vault
     * when an Asset Manager action increases the managed balance.
     */
    function cashToManaged(bytes32 balance, uint256 amount) internal pure returns (bytes32) {
        uint256 newCash = cash(balance).sub(amount);
        uint256 newManaged = managed(balance).add(amount);
        uint256 currentBlockNumber = blockNumber(balance);

        return toBalance(newCash, newManaged, currentBlockNumber);
    }

    /**
     * @dev Moves 'managed' into 'cash', leaving 'total' unchanged. Called when Pool tokens are sent to the Vault when
     * an Asset Manager action decreases the managed balance.
     */
    function managedToCash(bytes32 balance, uint256 amount) internal pure returns (bytes32) {
        uint256 newCash = cash(balance).add(amount);
        uint256 newManaged = managed(balance).sub(amount);
        uint256 currentBlockNumber = blockNumber(balance);

        return toBalance(newCash, newManaged, currentBlockNumber);
    }

    /**
     * @dev Sets 'managed' balance to an arbitrary value, changing 'total'. Called when the Asset Manager reports
     * profits or losses. It's the Manager's responsibility to provide a meaningful value.
     */
    function setManaged(bytes32 balance, uint256 newManaged) internal view returns (bytes32) {
        uint256 currentCash = cash(balance);
        uint256 newBlockNumber = block.number;
        return toBalance(currentCash, newManaged, newBlockNumber);
    }

    // Alternative mode for Pools with the token token specialization setting

    // Instead of storing cash and external for each token in a single storage slot, two token pools store the cash for
    // both tokens in the same slot, and the external for both in another one. This reduces the gas cost for swaps,
    // because the only slot that needs to be updated is the one with the cash. However, it also means that managing
    // balances is more cumbersome, as both tokens need to be read/written at the same time.
    // The field with both cash balances packed is called sharedCash, and the one with external amounts is called
    // sharedManaged. These two are collectively called the 'shared' balance fields. In both of these, the portion
    // that corresponds to token A is stored in the least significant 112 bits of a 256 bit word, while token B's part
    // uses the most significant 112 bits.
    // Because only cash is written to during a swap, we store the block number there. Typically Pools have a distinct
    // block number per token: in the case of two token Pools this is not necessary, as both values will be the same.

    /**
     * @dev Unpacks the shared token A and token B cash and managed balances into the balance for token A.
     */
    function fromSharedToBalanceA(bytes32 sharedCash, bytes32 sharedManaged) internal pure returns (bytes32) {
        return toBalance(_decodeBalanceA(sharedCash), _decodeBalanceA(sharedManaged), blockNumber(sharedCash));
    }

    /**
     * @dev Unpacks the shared token A and token B cash and managed balances into the balance for token B.
     */
    function fromSharedToBalanceB(bytes32 sharedCash, bytes32 sharedManaged) internal pure returns (bytes32) {
        return toBalance(_decodeBalanceB(sharedCash), _decodeBalanceB(sharedManaged), blockNumber(sharedCash));
    }

    /**
     * @dev Returns the sharedCash shared field, given the current balances for tokenA and tokenB.
     */
    function toSharedCash(bytes32 tokenABalance, bytes32 tokenBBalance) internal pure returns (bytes32) {
        // Both balances have the block number, since both balances are always updated at the same time it does not
        // mater where we pick it from.
        return _pack(cash(tokenABalance), cash(tokenBBalance), blockNumber(tokenABalance));
    }

    /**
     * @dev Returns the sharedManaged shared field, given the current balances for tokenA and tokenB.
     */
    function toSharedManaged(bytes32 tokenABalance, bytes32 tokenBBalance) internal pure returns (bytes32) {
        return _pack(managed(tokenABalance), managed(tokenBBalance), 0);
    }

    /**
     * @dev Unpacks the balance corresponding to token A for a shared balance
     * Note that this function can be used to decode both cash and managed balances.
     */
    function _decodeBalanceA(bytes32 sharedBalance) private pure returns (uint256) {
        uint256 mask = 2**(112) - 1;
        return uint256(sharedBalance) & mask;
    }

    /**
     * @dev Unpacks the balance corresponding to token B for a shared balance
     * Note that this function can be used to decode both cash and managed balances.
     */
    function _decodeBalanceB(bytes32 sharedBalance) private pure returns (uint256) {
        uint256 mask = 2**(112) - 1;
        return uint256(sharedBalance >> 112) & mask;
    }

    // Shared functions

    /**
     * @dev Packs together two uint112 and one uint32 into a bytes32
     */
    function _pack(
        uint256 _leastSignificant,
        uint256 _midSignificant,
        uint256 _mostSignificant
    ) private pure returns (bytes32) {
        return bytes32((_mostSignificant << 224) + (_midSignificant << 112) + _leastSignificant);
    }
}

// File: contracts/vault/balances/GeneralPoolsBalance.sol



pragma solidity ^0.7.0;




contract GeneralPoolsBalance {
    using BalanceAllocation for bytes32;
    using EnumerableMap for EnumerableMap.IERC20ToBytes32Map;

    // Data for Pools with General Pool Specialization setting
    //
    // These Pools use the IGeneralPool interface, which means the Vault must query the balance for *all* of their
    // tokens in every swap. If we kept a mapping of token to balance plus a set (array) of tokens, it'd be very gas
    // intensive to read all token addresses just to then do a lookup on the balance mapping.
    // Instead, we use our customized EnumerableMap, which lets us read the N balances in N+1 storage accesses (one for
    // the number of tokens in the Pool), as well as access the index of any token in a single read (required for the
    // IGeneralPool call) and update an entry's value given its index.

    mapping(bytes32 => EnumerableMap.IERC20ToBytes32Map) internal _generalPoolsBalances;

    /**
     * @dev Registers a list of tokens in a General Pool.
     *
     * Requirements:
     *
     * - Each token must not be the zero address.
     * - Each token must not be registered in the Pool.
     */
    function _registerGeneralPoolTokens(bytes32 poolId, IERC20[] memory tokens) internal {
        EnumerableMap.IERC20ToBytes32Map storage poolBalances = _generalPoolsBalances[poolId];

        for (uint256 i = 0; i < tokens.length; ++i) {
            IERC20 token = tokens[i];
            require(token != IERC20(0), "ZERO_ADDRESS_TOKEN");
            bool added = poolBalances.set(token, 0);
            require(added, "TOKEN_ALREADY_REGISTERED");
        }
    }

    /**
     * @dev Deregisters a list of tokens in a General Pool.
     *
     * Requirements:
     *
     * - Each token must be registered in the Pool.
     * - Each token must have non balance in the Vault.
     */
    function _deregisterGeneralPoolTokens(bytes32 poolId, IERC20[] memory tokens) internal {
        EnumerableMap.IERC20ToBytes32Map storage poolBalances = _generalPoolsBalances[poolId];

        for (uint256 i = 0; i < tokens.length; ++i) {
            IERC20 token = tokens[i];
            bytes32 currentBalance = _getGeneralPoolBalance(poolBalances, token);
            require(currentBalance.isZero(), "NONZERO_TOKEN_BALANCE");

            // We don't need to check remove's return value, since _getGeneralPoolBalance already checks that the token
            // was registered.
            poolBalances.remove(token);
        }
    }

    function _setGeneralPoolBalances(bytes32 poolId, bytes32[] memory balances) internal {
        EnumerableMap.IERC20ToBytes32Map storage poolBalances = _generalPoolsBalances[poolId];
        for (uint256 i = 0; i < balances.length; ++i) {
            // Note we assume all balances are properly ordered.
            // Thus, we can use `unchecked_setAt` to avoid one less storage read per call.
            poolBalances.unchecked_setAt(i, balances[i]);
        }
    }

    function _generalPoolCashToManaged(
        bytes32 poolId,
        IERC20 token,
        uint256 amount
    ) internal {
        _updateGeneralPoolBalance(poolId, token, BalanceAllocation.cashToManaged, amount);
    }

    function _generalPoolManagedToCash(
        bytes32 poolId,
        IERC20 token,
        uint256 amount
    ) internal {
        _updateGeneralPoolBalance(poolId, token, BalanceAllocation.managedToCash, amount);
    }

    function _setGeneralPoolManagedBalance(
        bytes32 poolId,
        IERC20 token,
        uint256 amount
    ) internal {
        _updateGeneralPoolBalance(poolId, token, BalanceAllocation.setManaged, amount);
    }

    function _updateGeneralPoolBalance(
        bytes32 poolId,
        IERC20 token,
        function(bytes32, uint256) returns (bytes32) mutation,
        uint256 amount
    ) internal {
        EnumerableMap.IERC20ToBytes32Map storage poolBalances = _generalPoolsBalances[poolId];
        bytes32 currentBalance = _getGeneralPoolBalance(poolBalances, token);
        poolBalances.set(token, mutation(currentBalance, amount));
    }

    /**
     * @dev Returns an array with all the tokens and balances in a General Pool.
     * This order may change when tokens are added to or removed from the Pool.
     */
    function _getGeneralPoolTokens(bytes32 poolId)
        internal
        view
        returns (IERC20[] memory tokens, bytes32[] memory balances)
    {
        EnumerableMap.IERC20ToBytes32Map storage poolBalances = _generalPoolsBalances[poolId];
        tokens = new IERC20[](poolBalances.length());
        balances = new bytes32[](tokens.length);

        for (uint256 i = 0; i < tokens.length; ++i) {
            // Because the iteration is bounded by `tokens.length` already fetched from the enumerable map,
            // we can use `unchecked_at` as we know `i` is a valid token index, saving storage reads.
            (IERC20 token, bytes32 balance) = poolBalances.unchecked_at(i);
            tokens[i] = token;
            balances[i] = balance;
        }
    }

    function _getGeneralPoolBalance(bytes32 poolId, IERC20 token) internal view returns (bytes32) {
        EnumerableMap.IERC20ToBytes32Map storage poolBalances = _generalPoolsBalances[poolId];
        return _getGeneralPoolBalance(poolBalances, token);
    }

    function _getGeneralPoolBalance(EnumerableMap.IERC20ToBytes32Map storage poolBalances, IERC20 token)
        internal
        view
        returns (bytes32)
    {
        return poolBalances.get(token, "TOKEN_NOT_REGISTERED");
    }

    function _isGeneralPoolTokenRegistered(bytes32 poolId, IERC20 token) internal view returns (bool) {
        EnumerableMap.IERC20ToBytes32Map storage poolBalances = _generalPoolsBalances[poolId];
        return poolBalances.contains(token);
    }
}

// File: contracts/vault/balances/MinimalSwapInfoPoolsBalance.sol



pragma solidity ^0.7.0;




contract MinimalSwapInfoPoolsBalance {
    using BalanceAllocation for bytes32;
    using EnumerableSet for EnumerableSet.AddressSet;

    // Data for Pools with Minimal Swap Info Specialization setting
    //
    // These Pools use the IMinimalSwapInfoPool interface, and so the Vault must read the balance of the two tokens
    // in the swap. The best solution is to use a mapping from token to balance, which lets us read or write any token's
    // balance in a single storage access.
    // We also keep a set with all tokens in the Pool, and update this set when cash is added or removed from the pool.
    // Tokens in the set always have a non-zero balance, so we don't need
    // to check the set for token existence during a swap: the non-zero balance check achieves this for less gas.

    mapping(bytes32 => EnumerableSet.AddressSet) internal _minimalSwapInfoPoolsTokens;
    mapping(bytes32 => mapping(IERC20 => bytes32)) internal _minimalSwapInfoPoolsBalances;

    /**
     * @dev Registers a list of tokens in a Minimal Swap Info Pool.
     *
     * Requirements:
     *
     * - Each token must not be the zero address.
     * - Each token must not be registered in the Pool.
     */
    function _registerMinimalSwapInfoPoolTokens(bytes32 poolId, IERC20[] memory tokens) internal {
        EnumerableSet.AddressSet storage poolTokens = _minimalSwapInfoPoolsTokens[poolId];

        for (uint256 i = 0; i < tokens.length; ++i) {
            IERC20 token = tokens[i];
            require(token != IERC20(0), "ZERO_ADDRESS_TOKEN");
            bool added = poolTokens.add(address(token));
            require(added, "TOKEN_ALREADY_REGISTERED");
        }
    }

    /**
     * @dev Deregisters a list of tokens in a Minimal Swap Info Pool.
     *
     * Requirements:
     *
     * - Each token must be registered in the Pool.
     * - Each token must have non balance in the Vault.
     */
    function _deregisterMinimalSwapInfoPoolTokens(bytes32 poolId, IERC20[] memory tokens) internal {
        EnumerableSet.AddressSet storage poolTokens = _minimalSwapInfoPoolsTokens[poolId];

        for (uint256 i = 0; i < tokens.length; ++i) {
            IERC20 token = tokens[i];
            require(_minimalSwapInfoPoolsBalances[poolId][token].isZero(), "NONZERO_TOKEN_BALANCE");
            bool removed = poolTokens.remove(address(token));
            require(removed, "TOKEN_NOT_REGISTERED");
            // No need to delete the balance entries, since they already are zero
        }
    }

    function _setMinimalSwapInfoPoolBalances(
        bytes32 poolId,
        IERC20[] memory tokens,
        bytes32[] memory balances
    ) internal {
        for (uint256 i = 0; i < tokens.length; ++i) {
            _minimalSwapInfoPoolsBalances[poolId][tokens[i]] = balances[i];
        }
    }

    function _minimalSwapInfoPoolCashToManaged(
        bytes32 poolId,
        IERC20 token,
        uint256 amount
    ) internal {
        _updateMinimalSwapInfoPoolBalance(poolId, token, BalanceAllocation.cashToManaged, amount);
    }

    function _minimalSwapInfoPoolManagedToCash(
        bytes32 poolId,
        IERC20 token,
        uint256 amount
    ) internal {
        _updateMinimalSwapInfoPoolBalance(poolId, token, BalanceAllocation.managedToCash, amount);
    }

    function _setMinimalSwapInfoPoolManagedBalance(
        bytes32 poolId,
        IERC20 token,
        uint256 amount
    ) internal {
        _updateMinimalSwapInfoPoolBalance(poolId, token, BalanceAllocation.setManaged, amount);
    }

    function _updateMinimalSwapInfoPoolBalance(
        bytes32 poolId,
        IERC20 token,
        function(bytes32, uint256) returns (bytes32) mutation,
        uint256 amount
    ) internal {
        bytes32 currentBalance = _getMinimalSwapInfoPoolBalance(poolId, token);
        _minimalSwapInfoPoolsBalances[poolId][token] = mutation(currentBalance, amount);
    }

    /**
     * @dev Returns an array with all the tokens and balances in a Minimal Swap Info Pool.
     * This order may change when tokens are added to or removed from the Pool.
     */
    function _getMinimalSwapInfoPoolTokens(bytes32 poolId)
        internal
        view
        returns (IERC20[] memory tokens, bytes32[] memory balances)
    {
        EnumerableSet.AddressSet storage poolTokens = _minimalSwapInfoPoolsTokens[poolId];
        tokens = new IERC20[](poolTokens.length());
        balances = new bytes32[](tokens.length);

        for (uint256 i = 0; i < tokens.length; ++i) {
            IERC20 token = IERC20(poolTokens.at(i));
            tokens[i] = token;
            balances[i] = _minimalSwapInfoPoolsBalances[poolId][token];
        }
    }

    /**
     * @dev Returns the balance for a token in a Minimal Swap Info Pool.
     *
     * Requirements:
     *
     * - `token` must be in the Pool.
     */
    function _getMinimalSwapInfoPoolBalance(bytes32 poolId, IERC20 token) internal view returns (bytes32) {
        bytes32 balance = _minimalSwapInfoPoolsBalances[poolId][token];
        bool existsToken = balance.isNotZero() || _minimalSwapInfoPoolsTokens[poolId].contains(address(token));
        require(existsToken, "TOKEN_NOT_REGISTERED");
        return balance;
    }

    function _isMinimalSwapInfoPoolTokenRegistered(bytes32 poolId, IERC20 token) internal view returns (bool) {
        EnumerableSet.AddressSet storage poolTokens = _minimalSwapInfoPoolsTokens[poolId];
        return poolTokens.contains(address(token));
    }
}

// File: contracts/vault/balances/TwoTokenPoolsBalance.sol



pragma solidity ^0.7.0;



contract TwoTokenPoolsBalance {
    using BalanceAllocation for bytes32;

    // Data for Pools with Two Tokens
    //
    // These are similar to the Minimal Swap Info Pool case (because the Pool only has two tokens, and therefore there
    // are only two balances to read), but there's a key difference in how data is stored. Keeping a set makes little
    // sense, as it will only ever hold two tokens, so we can just store those two directly.
    // The gas savings associated with using these Pools come from how token balances are stored: cash for token A and
    // token B is packed together, as are external amounts. Because only cash changes in a swap, there's no need to
    // write to this second storage slot.
    // This however makes Vault code that interacts with these Pools cumbersome: both balances must be accessed at the
    // same time by using both token addresses, and some logic is needed to differentiate token A from token B. In this
    // case, token A is always the token with the lowest numerical address value. The token X and token Y names are used
    // in functions when it is unknown which one is A and which one is B.

    struct TwoTokenPoolBalances {
        bytes32 sharedCash;
        bytes32 sharedManaged;
    }

    struct TwoTokenPoolTokens {
        IERC20 tokenA;
        IERC20 tokenB;
        mapping(bytes32 => TwoTokenPoolBalances) balances;
    }

    // We could just keep a mapping from Pool ID to TwoTokenSharedBalances, but there's an issue: we wouldn't know to
    // which tokens those balances correspond. This would mean having to also check the tokens struct in a swap, to make
    // sure the tokens being swapped are the ones in the Pool.
    // What we do instead to save those storage reads is keep a nested mapping from token pair hash to the balances
    // struct. The Pool only has two tokens, so only a single entry of this mapping is set (the one that corresponds to
    // that pair's hash). This means queries for token pairs where any of the tokens is not in the Pool will generate a
    // hash for a mapping entry that was not set, containing zero balances. Non-zero balances are only possible if both
    // tokens in the pair are the Pool's tokens, which means we don't have to check the TwoTokensTokens struct and save
    // storage reads.
    mapping(bytes32 => TwoTokenPoolTokens) private _twoTokenPoolTokens;

    /**
     * @dev Registers the tokens of a Two Token Pool.
     *
     * Requirements:
     *
     * - `tokenX` and `tokenY` cannot be the same.
     * - Both tokens must not be the zero address.
     * - Both tokens must not be registered in the Pool.
     * - Tokens must be ordered: tokenX < tokenY.
     */
    function _registerTwoTokenPoolTokens(
        bytes32 poolId,
        IERC20 tokenX,
        IERC20 tokenY
    ) internal {
        require(tokenX != IERC20(0) && tokenY != IERC20(0), "ZERO_ADDRESS_TOKEN");

        // Not technically true since we didn't register yet, but this is consistent with the error messages of other
        // specialization settings.
        require(tokenX != tokenY, "TOKEN_ALREADY_REGISTERED");
        require(tokenX < tokenY, "UNSORTED_TOKENS");

        TwoTokenPoolTokens storage poolTokens = _twoTokenPoolTokens[poolId];
        require(poolTokens.tokenA == IERC20(0) && poolTokens.tokenB == IERC20(0), "TOKENS_ALREADY_SET");

        poolTokens.tokenA = tokenX;
        poolTokens.tokenB = tokenY;
    }

    /**
     * @dev Deregisters the tokens of a Two Token Pool.
     *
     * Requirements:
     *
     * - `tokenX` and `tokenY` must be the Pool's tokens.
     * - Both tokens must have non balance in the Vault.
     */
    function _deregisterTwoTokenPoolTokens(
        bytes32 poolId,
        IERC20 tokenX,
        IERC20 tokenY
    ) internal {
        (bytes32 balanceA, bytes32 balanceB, ) = _getTwoTokenPoolSharedBalances(poolId, tokenX, tokenY);
        require(balanceA.isZero() && balanceB.isZero(), "NONZERO_TOKEN_BALANCE");

        delete _twoTokenPoolTokens[poolId];
        // No need to delete the balance entries, since they already are zero
    }

    /**
     * @dev This setter is only used when adding/removing liquidity, where tokens are guaranteed to be ordered and
     * registered. These methods actually fetch the tokens from `_getTwoTokenPoolTokens` first.
     */
    function _setTwoTokenPoolCashBalances(
        bytes32 poolId,
        IERC20 tokenA,
        bytes32 balanceA,
        IERC20 tokenB,
        bytes32 balanceB
    ) internal {
        bytes32 hash = _getTwoTokenPairHash(tokenA, tokenB);
        TwoTokenPoolBalances storage poolBalances = _twoTokenPoolTokens[poolId].balances[hash];
        poolBalances.sharedCash = BalanceAllocation.toSharedCash(balanceA, balanceB);
    }

    function _twoTokenPoolCashToManaged(
        bytes32 poolId,
        IERC20 token,
        uint256 amount
    ) internal {
        _updateTwoTokenPoolSharedBalance(poolId, token, BalanceAllocation.cashToManaged, amount);
    }

    function _twoTokenPoolManagedToCash(
        bytes32 poolId,
        IERC20 token,
        uint256 amount
    ) internal {
        _updateTwoTokenPoolSharedBalance(poolId, token, BalanceAllocation.managedToCash, amount);
    }

    function _setTwoTokenPoolManagedBalance(
        bytes32 poolId,
        IERC20 token,
        uint256 amount
    ) internal {
        _updateTwoTokenPoolSharedBalance(poolId, token, BalanceAllocation.setManaged, amount);
    }

    function _updateTwoTokenPoolSharedBalance(
        bytes32 poolId,
        IERC20 token,
        function(bytes32, uint256) returns (bytes32) mutation,
        uint256 amount
    ) private {
        (
            TwoTokenPoolBalances storage balances,
            IERC20 tokenA,
            bytes32 balanceA,
            IERC20 tokenB,
            bytes32 balanceB
        ) = _getTwoTokenPoolBalances(poolId);

        if (token == tokenA) {
            balanceA = mutation(balanceA, amount);
        } else if (token == tokenB) {
            balanceB = mutation(balanceB, amount);
        } else {
            revert("TOKEN_NOT_REGISTERED");
        }

        balances.sharedCash = BalanceAllocation.toSharedCash(balanceA, balanceB);
        balances.sharedManaged = BalanceAllocation.toSharedManaged(balanceA, balanceB);
    }

    /**
     * @dev Returns the balance for a token pair in a Two Token Pool, reverting if either of the tokens is
     * not registered by the Pool.
     *
     * The returned balances are those of token A and token B, where token A is the lowest of token X and token Y, and
     * token B the other.
     *
     * This function also returns a storage pointer to the TwoTokenSharedBalances entry associated with the token pair,
     * which can be used to update this entry without having to recompute the pair hash and storage slot.
     */
    function _getTwoTokenPoolSharedBalances(
        bytes32 poolId,
        IERC20 tokenX,
        IERC20 tokenY
    )
        internal
        view
        returns (
            bytes32 balanceA,
            bytes32 balanceB,
            TwoTokenPoolBalances storage poolBalances
        )
    {
        (IERC20 tokenA, IERC20 tokenB) = _sortTwoTokens(tokenX, tokenY);
        bytes32 pairHash = _getTwoTokenPairHash(tokenA, tokenB);
        poolBalances = _twoTokenPoolTokens[poolId].balances[pairHash];

        bytes32 sharedCash = poolBalances.sharedCash;
        bytes32 sharedManaged = poolBalances.sharedManaged;

        // Only registered tokens can have non-zero balances, so we can use this as a shortcut to avoid the
        // expensive _hasPoolTwoTokens check.
        bool exists = sharedCash.isNotZero() || sharedManaged.isNotZero() || _hasPoolTwoTokens(poolId, tokenA, tokenB);
        require(exists, "TOKEN_NOT_REGISTERED");

        balanceA = BalanceAllocation.fromSharedToBalanceA(sharedCash, sharedManaged);
        balanceB = BalanceAllocation.fromSharedToBalanceB(sharedCash, sharedManaged);
    }

    /**
     * @dev Returns an array with all the tokens and balances in a Two Token Pool.
     * This array will have either two or zero entries (if the Pool doesn't have any tokens).
     */
    function _getTwoTokenPoolTokens(bytes32 poolId)
        internal
        view
        returns (IERC20[] memory tokens, bytes32[] memory balances)
    {
        (, IERC20 tokenA, bytes32 balanceA, IERC20 tokenB, bytes32 balanceB) = _getTwoTokenPoolBalances(poolId);

        // Both tokens will either be zero or non-zero, but we keep the full check for clarity
        if (tokenA == IERC20(0) || tokenB == IERC20(0)) {
            return (new IERC20[](0), new bytes32[](0));
        }

        // Note that functions relying on this getter expect tokens to be properly ordered, so it's extremely important
        // to always return (A,B)

        tokens = new IERC20[](2);
        tokens[0] = tokenA;
        tokens[1] = tokenB;

        balances = new bytes32[](2);
        balances[0] = balanceA;
        balances[1] = balanceB;
    }

    /**
     * @dev Returns the balance for a token in a Two Token Pool.
     *
     * This function is convenient but not particularly gas efficient, and should be avoided during gas-sensitive
     * operations, such as swaps. For those, _getTwoTokenPoolSharedBalances provides a more flexible interface.
     *
     * Requirements:
     *
     * - `token` must be in the Pool.
     */
    function _getTwoTokenPoolBalance(bytes32 poolId, IERC20 token) internal view returns (bytes32 balance) {
        // We can't just read the balance of token, because we need to know the full pair in order to compute the pair
        // hash and access the balance mapping. We therefore also read the TwoTokenPoolTokens struct.
        (, IERC20 tokenA, bytes32 balanceA, IERC20 tokenB, bytes32 balanceB) = _getTwoTokenPoolBalances(poolId);

        if (token == tokenA) {
            return balanceA;
        } else if (token == tokenB) {
            return balanceB;
        } else {
            revert("TOKEN_NOT_REGISTERED");
        }
    }

    function _hasPoolTwoTokens(
        bytes32 poolId,
        IERC20 tokenA,
        IERC20 tokenB
    ) internal view returns (bool) {
        TwoTokenPoolTokens storage poolTokens = _twoTokenPoolTokens[poolId];
        return poolTokens.tokenA == tokenA && tokenB == poolTokens.tokenB;
    }

    function _isTwoTokenPoolTokenRegistered(bytes32 poolId, IERC20 token) internal view returns (bool) {
        TwoTokenPoolTokens storage poolTokens = _twoTokenPoolTokens[poolId];
        return (token == poolTokens.tokenA || token == poolTokens.tokenB) && token != IERC20(0);
    }

    function _getTwoTokenPoolBalances(bytes32 poolId)
        private
        view
        returns (
            TwoTokenPoolBalances storage poolBalances,
            IERC20 tokenA,
            bytes32 balanceA,
            IERC20 tokenB,
            bytes32 balanceB
        )
    {
        TwoTokenPoolTokens storage poolTokens = _twoTokenPoolTokens[poolId];
        tokenA = poolTokens.tokenA;
        tokenB = poolTokens.tokenB;

        bytes32 pairHash = _getTwoTokenPairHash(tokenA, tokenB);
        poolBalances = poolTokens.balances[pairHash];

        bytes32 sharedCash = poolBalances.sharedCash;
        bytes32 sharedManaged = poolBalances.sharedManaged;

        balanceA = BalanceAllocation.fromSharedToBalanceA(sharedCash, sharedManaged);
        balanceB = BalanceAllocation.fromSharedToBalanceB(sharedCash, sharedManaged);
    }

    /**
     * @dev Returns a hash associated with a given token pair.
     */
    function _getTwoTokenPairHash(IERC20 tokenA, IERC20 tokenB) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(tokenA, tokenB));
    }

    /**
     * @dev Sorts two tokens ascendingly, returning them as a (tokenA, tokenB) tuple.
     */
    function _sortTwoTokens(IERC20 tokenX, IERC20 tokenY) private pure returns (IERC20, IERC20) {
        return tokenX < tokenY ? (tokenX, tokenY) : (tokenY, tokenX);
    }
}

// File: contracts/vault/PoolRegistry.sol



pragma solidity ^0.7.0;















abstract contract PoolRegistry is
    ReentrancyGuard,
    InternalBalance,
    GeneralPoolsBalance,
    MinimalSwapInfoPoolsBalance,
    TwoTokenPoolsBalance
{
    using Math for uint256;
    using SafeCast for uint256;
    using SafeERC20 for IERC20;
    using BalanceAllocation for bytes32;
    using BalanceAllocation for bytes32[];
    using Counters for Counters.Counter;

    // Ensure Pool IDs are unique.
    Counters.Counter private _poolNonce;

    // Pool IDs are stored as `bytes32`.
    mapping(bytes32 => bool) private _isPoolRegistered;

    // Stores the Asset Manager for each token of each Pool.
    mapping(bytes32 => mapping(IERC20 => address)) private _poolAssetManagers;

    /**
     * @dev Reverts unless `poolId` corresponds to a registered Pool.
     */
    modifier withRegisteredPool(bytes32 poolId) {
        _ensureRegisteredPool(poolId);
        _;
    }

    /**
     * @dev Reverts unless `poolId` corresponds to a registered Pool, and the caller is the Pool's contract.
     */
    modifier onlyPool(bytes32 poolId) {
        _ensurePoolIsSender(poolId);
        _;
    }

    /**
     * @dev Creates a Pool ID.
     *
     * These are deterministically created by packing into the ID the Pool's contract address and its specialization
     * setting. This saves gas as this data does not need to be written to or read from storage with interacting with
     * the Pool.
     *
     * Since a single contract can register multiple Pools, a unique nonce must be provided to ensure Pool IDs are
     * unique.
     */
    function _toPoolId(
        address pool,
        PoolSpecialization specialization,
        uint80 nonce
    ) internal pure returns (bytes32) {
        uint256 serialized;

        // | 20 bytes pool address | 2 bytes specialization setting | 10 bytes nonce |
        serialized |= uint256(nonce);
        serialized |= uint256(specialization) << (10 * 8);
        serialized |= uint256(pool) << (12 * 8);

        return bytes32(serialized);
    }

    /**
     * @dev Returns a Pool's address.
     *
     * Due to how Pool IDs are created, this is done with no storage accesses and costs little gas.
     */
    function _getPoolAddress(bytes32 poolId) internal pure returns (address) {
        // | 20 bytes pool address | 2 bytes specialization setting | 10 bytes nonce |
        return address((uint256(poolId) >> (12 * 8)) & (2**(20 * 8) - 1));
    }

    /**
     * @dev Returns a Pool's specialization setting.
     *
     * Due to how Pool IDs are created, this is done with no storage accesses and costs little gas.
     */
    function _getPoolSpecialization(bytes32 poolId) internal pure returns (PoolSpecialization) {
        // | 20 bytes pool address | 2 bytes specialization setting | 10 bytes nonce |
        return PoolSpecialization(uint256(poolId >> (10 * 8)) & (2**(2 * 8) - 1));
    }

    function registerPool(PoolSpecialization specialization)
        external
        override
        nonReentrant
        noEmergencyPeriod
        returns (bytes32)
    {
        // Use _totalPools as the Pool ID nonce. uint80 assumes there will never be more than than 2**80 Pools.
        bytes32 poolId = _toPoolId(msg.sender, specialization, uint80(_poolNonce.current()));
        require(!_isPoolRegistered[poolId], "INVALID_POOL_ID"); // Should never happen

        _poolNonce.increment();
        _isPoolRegistered[poolId] = true;

        emit PoolRegistered(poolId);
        return poolId;
    }

    function getPoolTokens(bytes32 poolId)
        external
        view
        override
        withRegisteredPool(poolId)
        returns (IERC20[] memory tokens, uint256[] memory balances)
    {
        bytes32[] memory rawBalances;
        (tokens, rawBalances) = _getPoolTokens(poolId);
        balances = rawBalances.totals();
    }

    function getPoolTokenInfo(bytes32 poolId, IERC20 token)
        external
        view
        override
        withRegisteredPool(poolId)
        returns (
            uint256 cash,
            uint256 managed,
            uint256 blockNumber,
            address assetManager
        )
    {
        bytes32 balance;
        PoolSpecialization specialization = _getPoolSpecialization(poolId);

        if (specialization == PoolSpecialization.TWO_TOKEN) {
            balance = _getTwoTokenPoolBalance(poolId, token);
        } else if (specialization == PoolSpecialization.MINIMAL_SWAP_INFO) {
            balance = _getMinimalSwapInfoPoolBalance(poolId, token);
        } else {
            balance = _getGeneralPoolBalance(poolId, token);
        }

        cash = balance.cash();
        managed = balance.managed();
        blockNumber = balance.blockNumber();
        assetManager = _poolAssetManagers[poolId][token];
    }

    function getPool(bytes32 poolId)
        external
        view
        override
        withRegisteredPool(poolId)
        returns (address, PoolSpecialization)
    {
        return (_getPoolAddress(poolId), _getPoolSpecialization(poolId));
    }

    function registerTokens(
        bytes32 poolId,
        IERC20[] calldata tokens,
        address[] calldata assetManagers
    ) external override nonReentrant noEmergencyPeriod onlyPool(poolId) {
        InputHelpers.ensureInputLengthMatch(tokens.length, assetManagers.length);

        PoolSpecialization specialization = _getPoolSpecialization(poolId);
        if (specialization == PoolSpecialization.TWO_TOKEN) {
            require(tokens.length == 2, "TOKENS_LENGTH_MUST_BE_2");
            _registerTwoTokenPoolTokens(poolId, tokens[0], tokens[1]);
        } else if (specialization == PoolSpecialization.MINIMAL_SWAP_INFO) {
            _registerMinimalSwapInfoPoolTokens(poolId, tokens);
        } else {
            _registerGeneralPoolTokens(poolId, tokens);
        }

        // Assign each token's asset manager
        for (uint256 i = 0; i < tokens.length; ++i) {
            IERC20 token = tokens[i];
            address assetManager = assetManagers[i];

            _poolAssetManagers[poolId][token] = assetManager;
        }

        emit TokensRegistered(poolId, tokens, assetManagers);
    }

    function deregisterTokens(bytes32 poolId, IERC20[] calldata tokens)
        external
        override
        nonReentrant
        noEmergencyPeriod
        onlyPool(poolId)
    {
        PoolSpecialization specialization = _getPoolSpecialization(poolId);
        if (specialization == PoolSpecialization.TWO_TOKEN) {
            require(tokens.length == 2, "TOKENS_LENGTH_MUST_BE_2");
            _deregisterTwoTokenPoolTokens(poolId, tokens[0], tokens[1]);
        } else if (specialization == PoolSpecialization.MINIMAL_SWAP_INFO) {
            _deregisterMinimalSwapInfoPoolTokens(poolId, tokens);
        } else {
            _deregisterGeneralPoolTokens(poolId, tokens);
        }

        // The deregister calls above ensure the total token balance is zero. It is therefore safe to now remove any
        // associated Asset Managers, since they hold no Pool balance.
        for (uint256 i = 0; i < tokens.length; ++i) {
            delete _poolAssetManagers[poolId][tokens[i]];
        }

        emit TokensDeregistered(poolId, tokens);
    }

    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        IERC20[] memory tokens,
        uint256[] memory maxAmountsIn,
        bool fromInternalBalance,
        bytes memory userData
    ) external override nonReentrant noEmergencyPeriod withRegisteredPool(poolId) authenticateFor(sender) {
        InputHelpers.ensureInputLengthMatch(tokens.length, maxAmountsIn.length);

        bytes32[] memory balances = _validateTokensAndGetBalances(poolId, tokens);

        // Call the `onJoinPool` hook to get the amounts to send to the Pool and to charge as protocol swap fees for
        // each token.
        (uint256[] memory amountsIn, uint256[] memory dueProtocolFeeAmounts) = _callOnJoinPool(
            poolId,
            tokens,
            balances,
            sender,
            recipient,
            userData
        );

        for (uint256 i = 0; i < tokens.length; ++i) {
            uint256 amountIn = amountsIn[i];
            require(amountIn <= maxAmountsIn[i], "JOIN_ABOVE_MAX");

            // Receive tokens from the caller - possibly from Internal Balance
            _receiveTokens(tokens[i], amountIn, sender, fromInternalBalance);

            uint256 feeToPay = dueProtocolFeeAmounts[i];

            // Compute the new Pool balances - we reuse the `balances` array to avoid allocating more memory. Note that
            // due protocol fees might be larger than amounts in, resulting in an overall decrease of the Pool's balance
            // for a token.
            balances[i] = amountIn >= feeToPay
                ? balances[i].increaseCash(amountIn - feeToPay) // Don't need checked arithmetic
                : balances[i].decreaseCash(feeToPay - amountIn); // Same as -(int256(amountIn) - int256(feeToPay))

            _increaseCollectedFees(tokens[i], feeToPay);
        }

        // Update the Pool's balance - how this is done depends on the Pool specialization setting.
        PoolSpecialization specialization = _getPoolSpecialization(poolId);
        if (specialization == PoolSpecialization.TWO_TOKEN) {
            _setTwoTokenPoolCashBalances(poolId, tokens[0], balances[0], tokens[1], balances[1]);
        } else if (specialization == PoolSpecialization.MINIMAL_SWAP_INFO) {
            _setMinimalSwapInfoPoolBalances(poolId, tokens, balances);
        } else {
            _setGeneralPoolBalances(poolId, balances);
        }

        emit PoolJoined(poolId, sender, tokens, amountsIn, dueProtocolFeeAmounts);
    }

    function exitPool(
        bytes32 poolId,
        address sender,
        address recipient,
        IERC20[] memory tokens,
        uint256[] memory minAmountsOut,
        bool toInternalBalance,
        bytes memory userData
    ) external override nonReentrant withRegisteredPool(poolId) authenticateFor(sender) {
        InputHelpers.ensureInputLengthMatch(tokens.length, minAmountsOut.length);

        bytes32[] memory balances = _validateTokensAndGetBalances(poolId, tokens);

        // Call the `onExitPool` hook to get the amounts to take from the Pool and to charge as protocol swap fees for
        // each token.
        (uint256[] memory amountsOut, uint256[] memory dueProtocolFeeAmounts) = _callOnExitPool(
            poolId,
            tokens,
            balances,
            sender,
            recipient,
            userData
        );

        for (uint256 i = 0; i < tokens.length; ++i) {
            require(amountsOut[i] >= minAmountsOut[i], "EXIT_BELOW_MIN");
            uint256 amountOut = amountsOut[i];

            // Send tokens from the recipient - possibly to Internal Balance
            uint256 withdrawFee = _sendTokens(tokens[i], amountOut, recipient, toInternalBalance);

            uint256 feeToPay = dueProtocolFeeAmounts[i];

            // Compute the new Pool balances - we reuse the `balances` array to avoid allocating more memory. A Pool's
            // token balance always decreases after an exit (potentially by 0).
            uint256 delta = amountOut.add(feeToPay);
            balances[i] = balances[i].decreaseCash(delta);

            _increaseCollectedFees(tokens[i], feeToPay.add(withdrawFee));
        }

        // Update the Pool's balance - how this is done depends on the Pool specialization setting.
        PoolSpecialization specialization = _getPoolSpecialization(poolId);
        if (specialization == PoolSpecialization.TWO_TOKEN) {
            _setTwoTokenPoolCashBalances(poolId, tokens[0], balances[0], tokens[1], balances[1]);
        } else if (specialization == PoolSpecialization.MINIMAL_SWAP_INFO) {
            _setMinimalSwapInfoPoolBalances(poolId, tokens, balances);
        } else {
            _setGeneralPoolBalances(poolId, balances);
        }

        emit PoolExited(poolId, sender, tokens, amountsOut, dueProtocolFeeAmounts);
    }

    /**
     * @dev Takes `amount` tokens of `token` from `sender`.
     *
     * If `fromInternalBalance` is false, tokens will be transferred via `ERC20.transferFrom`. If true, Internal Balance
     * will be deducted instead, and only the difference between `amount` and available Internal Balance transferred (if
     * any).
     */
    function _receiveTokens(
        IERC20 token,
        uint256 amount,
        address sender,
        bool fromInternalBalance
    ) internal {
        if (amount == 0) {
            return;
        }

        uint256 toReceive = amount;
        if (fromInternalBalance) {
            uint256 currentInternalBalance = _getInternalBalance(sender, token);
            uint256 toWithdraw = Math.min(currentInternalBalance, amount);

            // toWithdraw is by construction smaller or equal than currentInternalBalance and toReceive, so we don't
            // need checked arithmetic.
            _setInternalBalance(sender, token, currentInternalBalance - toWithdraw);
            toReceive -= toWithdraw;
        }

        if (toReceive > 0) {
            token.safeTransferFrom(sender, address(this), toReceive);
        }
    }

    /**
     * @dev Grants `amount` tokens of `token` to `recipient`.
     *
     * If `toInternalBalance` is false, tokens are transferred via `ERC20.transfer`, after being charged with protocol
     * withdraw fees. If true, the tokens are deposited to Internal Balance, and no fees are charged.
     *
     * Returns the amount of charged protocol fees.
     */
    function _sendTokens(
        IERC20 token,
        uint256 amount,
        address recipient,
        bool toInternalBalance
    ) internal returns (uint256) {
        if (amount == 0) {
            return 0;
        }

        if (toInternalBalance) {
            _increaseInternalBalance(recipient, token, amount);
            return 0;
        } else {
            uint256 withdrawFee = _calculateProtocolWithdrawFeeAmount(amount);
            token.safeTransfer(recipient, amount.sub(withdrawFee));
            return withdrawFee;
        }
    }

    /**
     * @dev Internal helper to call the `onJoinPool` hook on a Pool's contract and perform basic validation on the
     * returned values. Avoid stack-too-deep issues.
     */
    function _callOnJoinPool(
        bytes32 poolId,
        IERC20[] memory tokens,
        bytes32[] memory balances,
        address sender,
        address recipient,
        bytes memory userData
    ) private returns (uint256[] memory amountsIn, uint256[] memory dueProtocolFeeAmounts) {
        (uint256[] memory totalBalances, uint256 latestBlockNumberUsed) = balances.totalsAndMaxBlockNumber();

        address pool = _getPoolAddress(poolId);
        (amountsIn, dueProtocolFeeAmounts) = IBasePool(pool).onJoinPool(
            poolId,
            sender,
            recipient,
            totalBalances,
            latestBlockNumberUsed,
            _getProtocolSwapFee(),
            userData
        );

        InputHelpers.ensureInputLengthMatch(tokens.length, amountsIn.length, dueProtocolFeeAmounts.length);
    }

    /**
     * @dev Internal helper to call the `onExitPool` hook on a Pool's contract and perform basic validation on the
     * returned values. Avoid stack-too-deep issues.
     */
    function _callOnExitPool(
        bytes32 poolId,
        IERC20[] memory tokens,
        bytes32[] memory balances,
        address sender,
        address recipient,
        bytes memory userData
    ) private returns (uint256[] memory amountsOut, uint256[] memory dueProtocolFeeAmounts) {
        (uint256[] memory totalBalances, uint256 latestBlockNumberUsed) = balances.totalsAndMaxBlockNumber();

        address pool = _getPoolAddress(poolId);
        (amountsOut, dueProtocolFeeAmounts) = IBasePool(pool).onExitPool(
            poolId,
            sender,
            recipient,
            totalBalances,
            latestBlockNumberUsed,
            _getProtocolSwapFee(),
            userData
        );

        InputHelpers.ensureInputLengthMatch(tokens.length, amountsOut.length, dueProtocolFeeAmounts.length);
    }

    /**
     * @dev Returns the total balance for `poolId`'s `expectedTokens`.
     *
     * `expectedTokens` must equal exactly the token array returned by `getPoolTokens`: both arrays must have the same
     * length, elements and order.
     */
    function _validateTokensAndGetBalances(bytes32 poolId, IERC20[] memory expectedTokens)
        internal
        view
        returns (bytes32[] memory)
    {
        (IERC20[] memory actualTokens, bytes32[] memory balances) = _getPoolTokens(poolId);
        InputHelpers.ensureInputLengthMatch(actualTokens.length, expectedTokens.length);

        for (uint256 i = 0; i < actualTokens.length; ++i) {
            require(actualTokens[i] == expectedTokens[i], "TOKENS_MISMATCH");
        }

        return balances;
    }

    // Assets under management

    function getPoolAssetManagers(bytes32 poolId, IERC20[] memory tokens)
        external
        view
        override
        returns (address[] memory assetManagers)
    {
        _ensureRegisteredPool(poolId);
        assetManagers = new address[](tokens.length);

        for (uint256 i = 0; i < tokens.length; ++i) {
            IERC20 token = tokens[i];

            _ensureTokenRegistered(poolId, token);
            assetManagers[i] = _poolAssetManagers[poolId][token];
        }
    }

    function withdrawFromPoolBalance(bytes32 poolId, AssetManagerTransfer[] memory transfers)
        external
        override
        nonReentrant
        noEmergencyPeriod
    {
        _ensureRegisteredPool(poolId);
        PoolSpecialization specialization = _getPoolSpecialization(poolId);

        for (uint256 i = 0; i < transfers.length; ++i) {
            IERC20 token = transfers[i].token;
            _ensurePoolAssetManagerIsSender(poolId, token);

            uint256 amount = transfers[i].amount;
            if (specialization == PoolSpecialization.MINIMAL_SWAP_INFO) {
                _minimalSwapInfoPoolCashToManaged(poolId, token, amount);
            } else if (specialization == PoolSpecialization.TWO_TOKEN) {
                _twoTokenPoolCashToManaged(poolId, token, amount);
            } else {
                _generalPoolCashToManaged(poolId, token, amount);
            }

            token.safeTransfer(msg.sender, amount);
            emit PoolBalanceChanged(poolId, msg.sender, token, -(amount.toInt256()));
        }
    }

    function depositToPoolBalance(bytes32 poolId, AssetManagerTransfer[] memory transfers)
        external
        override
        nonReentrant
        noEmergencyPeriod
    {
        _ensureRegisteredPool(poolId);
        PoolSpecialization specialization = _getPoolSpecialization(poolId);

        for (uint256 i = 0; i < transfers.length; ++i) {
            IERC20 token = transfers[i].token;
            _ensurePoolAssetManagerIsSender(poolId, token);

            uint256 amount = transfers[i].amount;
            if (specialization == PoolSpecialization.MINIMAL_SWAP_INFO) {
                _minimalSwapInfoPoolManagedToCash(poolId, token, amount);
            } else if (specialization == PoolSpecialization.TWO_TOKEN) {
                _twoTokenPoolManagedToCash(poolId, token, amount);
            } else {
                _generalPoolManagedToCash(poolId, token, amount);
            }

            token.safeTransferFrom(msg.sender, address(this), amount);
            emit PoolBalanceChanged(poolId, msg.sender, token, amount.toInt256());
        }
    }

    function updateManagedBalance(bytes32 poolId, AssetManagerTransfer[] memory transfers)
        external
        override
        nonReentrant
        noEmergencyPeriod
    {
        _ensureRegisteredPool(poolId);
        PoolSpecialization specialization = _getPoolSpecialization(poolId);

        for (uint256 i = 0; i < transfers.length; ++i) {
            IERC20 token = transfers[i].token;
            _ensurePoolAssetManagerIsSender(poolId, token);

            uint256 amount = transfers[i].amount;
            if (specialization == PoolSpecialization.MINIMAL_SWAP_INFO) {
                _setMinimalSwapInfoPoolManagedBalance(poolId, token, amount);
            } else if (specialization == PoolSpecialization.TWO_TOKEN) {
                _setTwoTokenPoolManagedBalance(poolId, token, amount);
            } else {
                _setGeneralPoolManagedBalance(poolId, token, amount);
            }
        }
    }

    /**
     * @dev Returns all of `poolId`'s registered tokens, along with their raw balances.
     */
    function _getPoolTokens(bytes32 poolId) internal view returns (IERC20[] memory tokens, bytes32[] memory balances) {
        PoolSpecialization specialization = _getPoolSpecialization(poolId);
        if (specialization == PoolSpecialization.TWO_TOKEN) {
            return _getTwoTokenPoolTokens(poolId);
        } else if (specialization == PoolSpecialization.MINIMAL_SWAP_INFO) {
            return _getMinimalSwapInfoPoolTokens(poolId);
        } else {
            return _getGeneralPoolTokens(poolId);
        }
    }

    /**
     * @dev Reverts unless `poolId` corresponds to a registered Pool.
     */
    function _ensureRegisteredPool(bytes32 poolId) internal view {
        require(_isPoolRegistered[poolId], "INVALID_POOL_ID");
    }

    /**
     * @dev Reverts unless `poolId` corresponds to a registered Pool, and the caller is the Pool's contract.
     */
    function _ensurePoolIsSender(bytes32 poolId) private view {
        _ensureRegisteredPool(poolId);
        address pool = _getPoolAddress(poolId);
        require(pool == msg.sender, "CALLER_NOT_POOL");
    }

    /**
     * @dev Reverts unless `poolId` corresponds to a registered Pool, `token` is registered for that Pool, and the
     * caller is the Pool's Asset Manager for `token`.
     */
    function _ensurePoolAssetManagerIsSender(bytes32 poolId, IERC20 token) private view {
        _ensureTokenRegistered(poolId, token);
        require(_poolAssetManagers[poolId][token] == msg.sender, "SENDER_NOT_ASSET_MANAGER");
    }

    /**
     * @dev Reverts unless `token` is registered for `poolId`.
     */
    function _ensureTokenRegistered(bytes32 poolId, IERC20 token) private view {
        require(_isTokenRegistered(poolId, token), "TOKEN_NOT_REGISTERED");
    }

    /**
     * @dev Returns true if `token` is registered for `poolId`.
     */
    function _isTokenRegistered(bytes32 poolId, IERC20 token) private view returns (bool) {
        PoolSpecialization specialization = _getPoolSpecialization(poolId);
        if (specialization == PoolSpecialization.TWO_TOKEN) {
            return _isTwoTokenPoolTokenRegistered(poolId, token);
        } else if (specialization == PoolSpecialization.MINIMAL_SWAP_INFO) {
            return _isMinimalSwapInfoPoolTokenRegistered(poolId, token);
        } else {
            return _isGeneralPoolTokenRegistered(poolId, token);
        }
    }
}

// File: contracts/vault/interfaces/IPoolSwapStructs.sol



pragma solidity ^0.7.0;


interface IPoolSwapStructs {
    // This is not really an interface - it just defines common structs used by other interfaces: IGeneralPool and
    // IMinimalSwapInfoPool.

    // This data structure represents a request for a token swap, where the amount received by the Pool is known.
    //
    // `tokenIn` and `tokenOut` are the tokens the Pool will receive and send, respectively. `amountIn` is the number of
    // `tokenIn` tokens that the Pool will receive.
    //
    // `poolId` is the ID of the Pool involved in the swap - this is useful for Pool contracts that implement more than
    // one Pool.
    //
    // All other fields are not strictly necessary for most swaps, but are provided to support advanced scenarios in
    // some Pools.
    // `from` is the origin address where funds the Pool receives are coming from, and `to` is the destination address
    // where the funds the Pool sends are going to.
    // `userData` is extra data provided by the caller - typically a signature from a trusted party.
    struct SwapRequestGivenIn {
        IERC20 tokenIn;
        IERC20 tokenOut;
        uint256 amountIn;
        // Misc data
        bytes32 poolId;
        uint256 latestBlockNumberUsed;
        address from;
        address to;
        bytes userData;
    }

    // This data structure represents a request for a token swap, where the amount sent by the Pool is known.
    //
    // `tokenIn` and `tokenOut` are the tokens the Pool will receive and send, respectively. `amountOut` is the number
    // of `tokenOut` tokens that the Pool will send.
    //
    // All other fields are not strictly necessary for most swaps, but are provided to support advanced scenarios in
    // some Pools.
    // `poolId` is the ID of the Pool involved in the swap - this is useful for Pool contracts that implement more than
    // one Pool.
    // `from` is the origin address where funds the Pool receives are coming from, and `to` is the destination address
    // where the funds the Pool sends are going to.
    // `userData` is extra data provided by the caller - typically a signature from a trusted party.
    struct SwapRequestGivenOut {
        IERC20 tokenIn;
        IERC20 tokenOut;
        uint256 amountOut;
        // Misc data
        bytes32 poolId;
        uint256 latestBlockNumberUsed;
        address from;
        address to;
        bytes userData;
    }
}

// File: contracts/vault/interfaces/IGeneralPool.sol



pragma solidity ^0.7.0;




/**
 * @dev Interface contracts for Pools with the general specialization setting should implement.
 */
interface IGeneralPool is IBasePool {
    /**
     * @dev Called by the Vault when a user calls `IVault.batchSwapGivenIn` to swap with this Pool. Returns the number
     * of tokens the Pool will grant to the user as part of the swap.
     *
     * This can be often implemented by a `view` function, since many pricing algorithms don't need to track state
     * changes in swaps. However, contracts implementing this in non-view functions should check that the caller is
     * indeed the Vault.
     */
    function onSwapGivenIn(
        IPoolSwapStructs.SwapRequestGivenIn calldata swapRequest,
        uint256[] calldata balances,
        uint256 indexIn,
        uint256 indexOut
    ) external returns (uint256 amountOut);

    /**
     * @dev Called by the Vault when a user calls `IVault.batchSwapGivenOut` to swap with this Pool. Returns the number
     * of tokens the user must grant to the Pool as part of the swap.
     *
     * This can be often implemented by a `view` function, since many pricing algorithms don't need to track state
     * changes in swaps. However, contracts implementing this in non-view functions should check that the caller is
     * indeed the Vault.
     */
    function onSwapGivenOut(
        IPoolSwapStructs.SwapRequestGivenOut calldata swapRequest,
        uint256[] calldata balances,
        uint256 indexIn,
        uint256 indexOut
    ) external returns (uint256 amountIn);
}

// File: contracts/vault/interfaces/IMinimalSwapInfoPool.sol



pragma solidity ^0.7.0;




/**
 * @dev Interface contracts for Pools with the minimal swap info or two token specialization settings should implement.
 */
interface IMinimalSwapInfoPool is IBasePool {
    /**
     * @dev Called by the Vault when a user calls `IVault.batchSwapGivenIn` to swap with this Pool. Returns the number
     * of tokens the Pool will grant to the user as part of the swap.
     *
     * This can be often implemented by a `view` function, since many pricing algorithms don't need to track state
     * changes in swaps. However, contracts implementing this in non-view functions should check that the caller is
     * indeed the Vault.
     */
    function onSwapGivenIn(
        IPoolSwapStructs.SwapRequestGivenIn calldata swapRequest,
        uint256 currentBalanceTokenIn,
        uint256 currentBalanceTokenOut
    ) external returns (uint256 amountOut);

    /**
     * @dev Called by the Vault when a user calls `IVault.batchSwapGivenOut` to swap with this Pool. Returns the number
     * of tokens the user must grant to the Pool as part of the swap.
     *
     * This can be often implemented by a `view` function, since many pricing algorithms don't need to track state
     * changes in swaps. However, contracts implementing this in non-view functions should check that the caller is
     * indeed the Vault.
     */
    function onSwapGivenOut(
        IPoolSwapStructs.SwapRequestGivenOut calldata swapRequest,
        uint256 currentBalanceTokenIn,
        uint256 currentBalanceTokenOut
    ) external returns (uint256 amountIn);
}

// File: contracts/vault/Swaps.sol



pragma solidity ^0.7.0;














abstract contract Swaps is ReentrancyGuard, PoolRegistry {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableMap for EnumerableMap.IERC20ToBytes32Map;

    using Math for int256;
    using SafeCast for uint256;
    using BalanceAllocation for bytes32;

    // Despite the external API having two separate functions for given in and given out, internally their are handled
    // together to avoid unnecessary code duplication. This enum indicates which kind of swap we're processing.

    // We use inline assembly to convert arrays of different struct types that have the same underlying data
    // representation. This doesn't trigger any actual conversions or runtime analysis: it is just coercing the type
    // system to reinterpret the data as another type.

    /**
     * @dev Converts an array of `SwapIn` into an array of `SwapRequest`, with no runtime cost.
     */

    function _toInternalSwap(SwapIn[] memory swapsIn) private pure returns (SwapRequest[] memory internalSwapRequests) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            internalSwapRequests := swapsIn
        }
    }

    /**
     * @dev Converts an array of `SwapOut` into an array of `InternalSwap`, with no runtime cost.
     */
    function _toInternalSwap(SwapOut[] memory swapsOut)
        private
        pure
        returns (SwapRequest[] memory internalSwapRequests)
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            internalSwapRequests := swapsOut
        }
    }

    // This struct is identical in layout to SwapRequestGivenIn and SwapRequestGivenOut from IPoolSwapStructs, except
    // the 'amountIn/Out' is named 'amount'.
    struct InternalSwapRequest {
        IERC20 tokenIn;
        IERC20 tokenOut;
        uint256 amount;
        bytes32 poolId;
        uint256 latestBlockNumberUsed;
        address from;
        address to;
        bytes userData;
    }

    /**
     * @dev Converts an InternalSwapRequest into a SwapRequestGivenIn, with no runtime cost.
     */
    function _toSwapRequestGivenIn(InternalSwapRequest memory internalSwapRequest)
        private
        pure
        returns (IPoolSwapStructs.SwapRequestGivenIn memory swapRequestGivenIn)
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            swapRequestGivenIn := internalSwapRequest
        }
    }

    /**
     * @dev Converts an InternalSwapRequest into a SwapRequestGivenOut, with no runtime cost.
     */
    function _toSwapRequestGivenOut(InternalSwapRequest memory internalSwapRequest)
        private
        pure
        returns (IPoolSwapStructs.SwapRequestGivenOut memory swapRequestGivenOut)
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            swapRequestGivenOut := internalSwapRequest
        }
    }

    function batchSwapGivenIn(
        SwapIn[] memory swaps,
        IERC20[] memory tokens,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external override nonReentrant noEmergencyPeriod authenticateFor(funds.sender) returns (int256[] memory batch) {
        batch = _batchSwap(_toInternalSwap(swaps), tokens, funds, limits, deadline, SwapKind.GIVEN_IN);
        return batch;
    }

    function batchSwapGivenOut(
        SwapOut[] memory swaps,
        IERC20[] memory tokens,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external override nonReentrant noEmergencyPeriod authenticateFor(funds.sender) returns (int256[] memory batch) {
        batch = _batchSwap(_toInternalSwap(swaps), tokens, funds, limits, deadline, SwapKind.GIVEN_OUT);
        return batch;
    }

    /**
     * @dev Implements both `batchSwapGivenIn` and `batchSwapGivenIn`, depending on the `kind` value.
     */
    function _batchSwap(
        SwapRequest[] memory swaps,
        IERC20[] memory tokens,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline,
        SwapKind kind
    ) private returns (int256[] memory tokenDeltas) {
        // The deadline is timestamp-based: it should not be relied on having sub-minute accuracy.
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp <= deadline, "SWAP_DEADLINE");

        InputHelpers.ensureInputLengthMatch(tokens.length, limits.length);

        // Perform the swaps, updating the Pool token balances and computing the net Vault token deltas.
        tokenDeltas = _swapWithPools(swaps, tokens, funds, kind);

        // Process token deltas, by either transferring tokens from the sender (for positive deltas) or to the recipient
        // (for negative deltas).
        for (uint256 i = 0; i < tokens.length; ++i) {
            IERC20 token = tokens[i];
            int256 delta = tokenDeltas[i];

            require(delta <= limits[i], "SWAP_LIMIT");

            // Ignore zeroed deltas
            if (delta > 0) {
                _receiveTokens(token, uint256(delta), funds.sender, funds.fromInternalBalance);
            } else if (delta < 0) {
                uint256 toSend = uint256(-delta);

                if (funds.toInternalBalance) {
                    _increaseInternalBalance(funds.recipient, token, toSend);
                } else {
                    // Note protocol withdraw fees are not charged in this transfer
                    token.safeTransfer(funds.recipient, toSend);
                }
            }
        }
    }

    // For `_swapWithPools` to handle both given in and given out swaps, it internally tracks the 'given' amount
    // (supplied by the caller), and the 'calculated' one (returned by the Pool in response to the swap request).

    /**
     * @dev Given the two swap tokens and the swap kind, returns which one is the 'given' token (the one for which the
     * amount is supplied by the caller).
     */
    function _tokenGiven(
        SwapKind kind,
        IERC20 tokenIn,
        IERC20 tokenOut
    ) private pure returns (IERC20 token) {
        kind == SwapKind.GIVEN_IN ? token = tokenIn : token = tokenOut;
        return token;
    }

    /**
     * @dev Given the two swap tokens and the swap kind, returns which one is the 'calculated' token (the one for
     * which the amount is calculated by the Pool).
     */
    function _tokenCalculated(
        SwapKind kind,
        IERC20 tokenIn,
        IERC20 tokenOut
    ) private pure returns (IERC20 token) {
        kind == SwapKind.GIVEN_IN ? token = tokenIn : token = tokenOut;
        return token;
    }

    /**
     * @dev Returns an ordered pair (amountIn, amountOut) given the amounts given and calculated and the swap kind.
     */
    function _getAmounts(
        SwapKind kind,
        uint256 amountGiven,
        uint256 amountCalculated
    ) private pure returns (uint256 amountIn, uint256 amountOut) {
        if (kind == SwapKind.GIVEN_IN) {
            (amountIn, amountOut) = (amountGiven, amountCalculated);
        } else {
            (amountIn, amountOut) = (amountCalculated, amountGiven);
        }
    }

    // This struct helps implement the multihop logic: if the amount given is not provided for a swap, then the given
    // token must match the previous calculated token, and the previous calculated amount becomes the new given amount.
    // For swaps of kind given in, amount in and token in are given, while amount out and token out are calculated.
    // For swaps of kind given out, amount out and token out are given, while amount in and token in are calculated.
    struct LastSwapData {
        IERC20 tokenCalculated;
        uint256 amountCalculated;
    }

    /**
     * @dev Performs all `swaps`, calling swap hooks on the Pool contracts and updating their balances. Does not cause
     * any transfer of tokens - it instead returns the net Vault token deltas: positive if the Vault should receive
     * tokens, and negative if it should send them.
     */
    function _swapWithPools(
        SwapRequest[] memory swaps,
        IERC20[] memory tokens,
        FundManagement memory funds,
        SwapKind kind
    ) private returns (int256[] memory tokenDeltas) {
        tokenDeltas = new int256[](tokens.length);

        // Passed to _swapWithPool, which stores data about the previous swap here to implement multihop logic across
        // swaps.
        LastSwapData memory previous;

        // This variable could be declared inside the loop, but that causes the compiler to allocate memory on each loop
        // iteration, increasing gas costs.
        SwapRequest memory swap;
        for (uint256 i = 0; i < swaps.length; ++i) {
            swap = swaps[i];
            _ensureRegisteredPool(swap.poolId);
            require(swap.tokenInIndex < tokens.length && swap.tokenOutIndex < tokens.length, "OUT_OF_BOUNDS");

            IERC20 tokenIn = tokens[swap.tokenInIndex];
            IERC20 tokenOut = tokens[swap.tokenOutIndex];
            require(tokenIn != tokenOut, "CANNOT_SWAP_SAME_TOKEN");

            // Sentinel value for multihop logic
            if (swap.amount == 0) {
                // When the amount given is zero, we use the calculated amount for the previous swap, as long as the
                // current swap's given token is the previous' calculated token. This makes it possible to e.g. swap a
                // given amount of token A for token B, and then use the resulting token B amount to swap for token C.
                if (swaps.length > 1) {
                    bool usingPreviousToken = previous.tokenCalculated == _tokenGiven(kind, tokenIn, tokenOut);
                    require(usingPreviousToken, "MALCONSTRUCTED_MULTIHOP_SWAP");
                    swap.amount = previous.amountCalculated;
                } else {
                    revert("UNKNOWN_AMOUNT_IN_FIRST_SWAP");
                }
            }

            (uint256 amountIn, uint256 amountOut) = _swapWithPool(
                tokenIn,
                tokenOut,
                swap,
                funds.sender,
                funds.recipient,
                previous,
                kind
            );

            // Accumulate Vault deltas across swaps
            tokenDeltas[swap.tokenInIndex] = tokenDeltas[swap.tokenInIndex].add(amountIn.toInt256());
            tokenDeltas[swap.tokenOutIndex] = tokenDeltas[swap.tokenOutIndex].sub(amountOut.toInt256());

            emit Swap(swap.poolId, tokenIn, tokenOut, amountIn, amountOut);
        }
    }

    /**
     * @dev Performs `swap`, calling the Pool's contract hook and updating the Pool balance. Returns a pair with the
     * amount of tokens going into and out of the Vault as a result of this swap.
     *
     * This function expects to be called with the `previous` swap struct, which will be updated internally to
     * implement multihop logic.
     */
    function _swapWithPool(
        IERC20 tokenIn,
        IERC20 tokenOut,
        SwapRequest memory swap,
        address from,
        address to,
        LastSwapData memory previous,
        SwapKind kind
    ) private returns (uint256 amountIn, uint256 amountOut) {
        InternalSwapRequest memory request = InternalSwapRequest({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amount: swap.amount,
            poolId: swap.poolId,
            latestBlockNumberUsed: 0, // will be updated later on based on the pool specialization
            from: from,
            to: to,
            userData: swap.userData
        });

        // Get the calculated amount from the Pool and update its balances
        uint256 amountCalculated = _processSwapRequest(request, kind);

        // Store swap information for next swap
        previous.tokenCalculated = _tokenCalculated(kind, tokenIn, tokenOut);
        previous.amountCalculated = amountCalculated;

        (amountIn, amountOut) = _getAmounts(kind, swap.amount, amountCalculated);
    }

    /**
     * @dev Calls the swap hook on the Pool and updates its balances as a result of the swap being executed. The
     * interface used for the call will depend on the Pool's specialization setting.
     *
     * Returns the token amount calculated by the Pool.
     */
    function _processSwapRequest(InternalSwapRequest memory request, SwapKind kind) private returns (uint256) {
        address pool = _getPoolAddress(request.poolId);
        PoolSpecialization specialization = _getPoolSpecialization(request.poolId);

        if (specialization == PoolSpecialization.MINIMAL_SWAP_INFO) {
            return _processMinimalSwapInfoPoolSwapRequest(request, IMinimalSwapInfoPool(pool), kind);
        } else if (specialization == PoolSpecialization.TWO_TOKEN) {
            return _processTwoTokenPoolSwapRequest(request, IMinimalSwapInfoPool(pool), kind);
        } else {
            return _processGeneralPoolSwapRequest(request, IGeneralPool(pool), kind);
        }
    }

    function _processTwoTokenPoolSwapRequest(
        InternalSwapRequest memory request,
        IMinimalSwapInfoPool pool,
        SwapKind kind
    ) private returns (uint256 amountCalculated) {
        // Due to gas efficiency reasons, this function uses low-level knowledge of how Two Token Pool balances are
        // stored internally, instead of using getters and setters for all operations.

        (
            bytes32 tokenABalance,
            bytes32 tokenBBalance,
            TwoTokenPoolBalances storage poolBalances
        ) = _getTwoTokenPoolSharedBalances(request.poolId, request.tokenIn, request.tokenOut);

        // We have the two Pool balances, but we don't know which one is the token in and which one is the token out.
        bytes32 tokenInBalance;
        bytes32 tokenOutBalance;

        // In Two Token Pools, token A has a smaller address than token B
        if (request.tokenIn < request.tokenOut) {
            // in is A, out is B
            tokenInBalance = tokenABalance;
            tokenOutBalance = tokenBBalance;
        } else {
            // in is B, out is A
            tokenOutBalance = tokenABalance;
            tokenInBalance = tokenBBalance;
        }

        // Perform the swap request and compute the new balances for token in and token out after the swap
        (tokenInBalance, tokenOutBalance, amountCalculated) = _callMinimalSwapInfoPoolOnSwapHook(
            request,
            pool,
            kind,
            tokenInBalance,
            tokenOutBalance
        );

        // We check the token ordering again to create the new shared cash packed struct
        poolBalances.sharedCash = request.tokenIn < request.tokenOut
            ? BalanceAllocation.toSharedCash(tokenInBalance, tokenOutBalance) // in is A, out is B
            : BalanceAllocation.toSharedCash(tokenOutBalance, tokenInBalance); // in is B, out is A
    }

    function _processMinimalSwapInfoPoolSwapRequest(
        InternalSwapRequest memory request,
        IMinimalSwapInfoPool pool,
        SwapKind kind
    ) private returns (uint256 amountCalculated) {
        bytes32 tokenInBalance = _getMinimalSwapInfoPoolBalance(request.poolId, request.tokenIn);
        bytes32 tokenOutBalance = _getMinimalSwapInfoPoolBalance(request.poolId, request.tokenOut);

        // Perform the swap request and compute the new balances for token in and token out after the swap
        (tokenInBalance, tokenOutBalance, amountCalculated) = _callMinimalSwapInfoPoolOnSwapHook(
            request,
            pool,
            kind,
            tokenInBalance,
            tokenOutBalance
        );

        _minimalSwapInfoPoolsBalances[request.poolId][request.tokenIn] = tokenInBalance;
        _minimalSwapInfoPoolsBalances[request.poolId][request.tokenOut] = tokenOutBalance;
    }

    /**
     * @dev Calls the onSwap hook for a Pool that implements IMinimalSwapInfoPool, which are both minimal swap info
     * pools and two token pools.
     */
    function _callMinimalSwapInfoPoolOnSwapHook(
        InternalSwapRequest memory request,
        IMinimalSwapInfoPool pool,
        SwapKind kind,
        bytes32 tokenInBalance,
        bytes32 tokenOutBalance
    )
        internal
        returns (
            bytes32 newTokenInBalance,
            bytes32 newTokenOutBalance,
            uint256 amountCalculated
        )
    {
        uint256 tokenInTotal = tokenInBalance.total();
        uint256 tokenOutTotal = tokenOutBalance.total();
        request.latestBlockNumberUsed = Math.max(tokenInBalance.blockNumber(), tokenOutBalance.blockNumber());

        // Perform the swap request callback and compute the new balances for token in and token out after the swap
        if (kind == SwapKind.GIVEN_IN) {
            IPoolSwapStructs.SwapRequestGivenIn memory swapIn = _toSwapRequestGivenIn(request);
            uint256 amountOut = pool.onSwapGivenIn(swapIn, tokenInTotal, tokenOutTotal);

            newTokenInBalance = tokenInBalance.increaseCash(request.amount);
            newTokenOutBalance = tokenOutBalance.decreaseCash(amountOut);
            amountCalculated = amountOut;
        } else {
            IPoolSwapStructs.SwapRequestGivenOut memory swapOut = _toSwapRequestGivenOut(request);
            uint256 amountIn = pool.onSwapGivenOut(swapOut, tokenInTotal, tokenOutTotal);

            newTokenInBalance = tokenInBalance.increaseCash(amountIn);
            newTokenOutBalance = tokenOutBalance.decreaseCash(request.amount);
            amountCalculated = amountIn;
        }
    }

    function _processGeneralPoolSwapRequest(
        InternalSwapRequest memory request,
        IGeneralPool pool,
        SwapKind kind
    ) private returns (uint256 amountCalculated) {
        bytes32 tokenInBalance;
        bytes32 tokenOutBalance;

        EnumerableMap.IERC20ToBytes32Map storage poolBalances = _generalPoolsBalances[request.poolId];
        uint256 indexIn = poolBalances.indexOf(request.tokenIn, "TOKEN_NOT_REGISTERED");
        uint256 indexOut = poolBalances.indexOf(request.tokenOut, "TOKEN_NOT_REGISTERED");

        uint256 tokenAmount = poolBalances.length();
        uint256[] memory currentBalances = new uint256[](tokenAmount);

        for (uint256 i = 0; i < tokenAmount; i++) {
            // Because the iteration is bounded by `tokenAmount` and no tokens are registered or deregistered here, we
            // can use `unchecked_valueAt` as we know `i` is a valid token index, saving storage reads.
            bytes32 balance = poolBalances.unchecked_valueAt(i);

            currentBalances[i] = balance.total();
            request.latestBlockNumberUsed = Math.max(request.latestBlockNumberUsed, balance.blockNumber());

            if (i == indexIn) {
                tokenInBalance = balance;
            } else if (i == indexOut) {
                tokenOutBalance = balance;
            }
        }

        // Perform the swap request callback and compute the new balances for token in and token out after the swap
        if (kind == SwapKind.GIVEN_IN) {
            IPoolSwapStructs.SwapRequestGivenIn memory swapRequestIn = _toSwapRequestGivenIn(request);
            uint256 amountOut = pool.onSwapGivenIn(swapRequestIn, currentBalances, indexIn, indexOut);

            amountCalculated = amountOut;
            tokenInBalance = tokenInBalance.increaseCash(request.amount);
            tokenOutBalance = tokenOutBalance.decreaseCash(amountOut);
        } else {
            IPoolSwapStructs.SwapRequestGivenOut memory swapRequestOut = _toSwapRequestGivenOut(request);
            uint256 amountIn = pool.onSwapGivenOut(swapRequestOut, currentBalances, indexIn, indexOut);

            amountCalculated = amountIn;
            tokenInBalance = tokenInBalance.increaseCash(amountIn);
            tokenOutBalance = tokenOutBalance.decreaseCash(request.amount);
        }

        // Because no token registrations or unregistrations happened between now and when we retrieved the indexes for
        // token in and token out, we can use `unchecked_setAt`, saving storage reads.
        poolBalances.unchecked_setAt(indexIn, tokenInBalance);
        poolBalances.unchecked_setAt(indexOut, tokenOutBalance);
    }

    // This function is not marked as `nonReentrant` because the underlying mechanism relies on reentrancy
    function queryBatchSwap(
        SwapKind kind,
        SwapRequest[] memory swaps,
        IERC20[] memory tokens,
        FundManagement memory funds
    ) external override returns (int256[] memory) {
        // In order to accurately 'simulate' swaps, this function actually does perform the swaps, including calling the
        // Pool hooks and updating  balances in storage. However, once it computes the final Vault Deltas it then
        // reverts unconditionally, returning this array as the revert data.
        // By wrapping this reverting call, we can decode the deltas 'returned' and return them as a normal Solidity
        // function would. The only caveat is the function becomes non-view, but off-chain clients can still call it
        // via eth_call to get the expected result.
        //
        // This technique was inspired by the work from the Gnosis team in the Gnosis Safe contract:
        // https://github.com/gnosis/safe-contracts/blob/v1.2.0/contracts/GnosisSafe.sol#L265

        // Most of this function is implemented using inline assembly, as the actual work it needs to do is not
        // significant, and Solidity is not particularly well-suited to generate this behavior, resulting in a large
        // amount of generated bytecode.

        if (msg.sender != address(this)) {
            // We perform an external call to ourselves, forwarding the same calldata. In this call, the else clause of
            // the preceding if statement will be executed instead.

            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = address(this).call(msg.data);

            // solhint-disable-next-line no-inline-assembly
            assembly {
                // This call should always revert to decode the actual token deltas from the revert reason
                switch success
                    case 0 {
                        // Note we are manually writing the memory slot 0. We can safely overwrite whatever is
                        // stored there as we take full control of the execution and then immediately return.

                        // We copy the first 4 bytes to check if it matches with the expected signature, otherwise
                        // there was another revert reason and we should forward it.
                        returndatacopy(0, 0, 0x04)
                        let error := and(mload(0), 0xffffffff00000000000000000000000000000000000000000000000000000000)

                        // If the first 4 bytes don't match with the expected signature, we forward the revert reason.
                        if eq(eq(error, 0xfa61cc1200000000000000000000000000000000000000000000000000000000), 0) {
                            returndatacopy(0, 0, returndatasize())
                            revert(0, returndatasize())
                        }

                        // The returndata contains the signature, followed by the raw memory representation of an array:
                        // length + data. We need to return an ABI-encoded representation of this array.
                        // An ABI-encoded array contains an additional field when compared to its raw memory
                        // representation: an offset to the location of the length. The offset itself is 32 bytes long,
                        // so the smallest value we  can use is 32 for the data to be located immediately after it.
                        mstore(0, 32)

                        // We now copy the raw memory array from returndata into memory. Since the offset takes up 32
                        // bytes, we start copying at address 0x20. We also get rid of the error signature, which takes
                        // the first four bytes of returndata.
                        let size := sub(returndatasize(), 0x04)
                        returndatacopy(0x20, 0x04, size)

                        // We finally return the ABI-encoded array, which has a total length equal to that of the array
                        // (returndata), plus the 32 bytes for the offset.
                        return(0, add(size, 32))
                    }
                    default {
                        // This call should always revert, but we fail nonetheless if that didn't happen
                        invalid()
                    }
            }
        } else {
            int256[] memory deltas = _swapWithPools(swaps, tokens, funds, kind);

            // solhint-disable-next-line no-inline-assembly
            assembly {
                // We will return a raw representation of the array in memory, which is composed of a 32 byte length,
                // followed by the 32 byte int256 values. Because revert expects a size in bytes, we multiply the array
                // length (stored at `deltas`) by 32.
                let size := mul(mload(deltas), 32)

                // We send one extra value for the error signature "QueryError(int256[])" which is 0xfa61cc12.
                // We store it in the previous slot to the `deltas` array. We know there will be at least one available
                // slot due to how the memory scratch space works.
                // We can safely overwrite whatever is stored in this slot as we will revert immediately after that.
                mstore(sub(deltas, 0x20), 0x00000000000000000000000000000000000000000000000000000000fa61cc12)
                let start := sub(deltas, 0x04)

                // When copying from `deltas` into returndata, we copy an additional 36 bytes to also return the array's
                // length and the error signature.
                revert(start, add(size, 36))
            }
        }
    }
}

// File: contracts/vault/Vault.sol



pragma solidity ^0.7.0;






/**
 * @dev The `Vault` is Balancer V2's core contract. A single instance of it exists in the entire network, and it is the
 * entity used to interact with Pools by joining, exiting, or swapping with them.
 *
 * The `Vault`'s source code is split among a number of sub-contracts with the goal of improving readability and making
 * understanding the system easier. All sub-contracts have been marked as `abstract` to make explicit the fact that only
 * the full `Vault` is meant to be deployed.
 *
 * Roughly speaking, these are the contents of each sub-contract:
 *
 *  - `InternalBalance`: deposit, withdrawal and transfer of Internal Balance.
 *  - `Fees`: set and compute protocol fees.
 *  - `FlashLoanProvider`: flash loans.
 *  - `PoolRegistry`: Pool registration, joining, exiting, and Asset Manager interactions.
 *  - `Swaps`: Pool swaps.
 *
 * Additionally, the different Pool specializations are handled by the `GeneralPoolsBalance`,
 * `MinimalSwapInfoPoolsBalance` and `TwoTokenPoolsBalance` sub-contracts, which in turn make use of the
 * `BalanceAllocation` library.
 *
 * The most important goal of the `Vault` is to make token swaps use as little gas as possible. This is reflected in a
 * multitude of design decisions, from minor things like the format used to store Pool IDs, to major features such as
 * the different Pool specialization settings.
 *
 * Finally, the large number of tasks carried out by the Vault mean its bytecode is very large, which is at odds with
 * the contract size limit imposed by EIP 170 (https://eips.ethereum.org/EIPS/eip-170). Manual tuning of the source code
 * was required to improve code generation and bring the bytecode size below this limit. This includes extensive
 * utilization of `internal` functions (particularly inside modifiers), usage of named return arguments, and dedicated
 * storage access methods, to name a few.
 */
contract Vault is VaultAuthorization, FlashLoanProvider, Swaps {
    constructor(
        IAuthorizer authorizer,
        uint256 emergencyPeriod,
        uint256 emergencyPeriodCheckExtension
    ) VaultAuthorization(authorizer) EmergencyPeriod(emergencyPeriod, emergencyPeriodCheckExtension) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function setEmergencyPeriod(bool active) external authenticate {
        _setEmergencyPeriod(active);
    }
}
