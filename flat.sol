// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

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

// File: contracts/vault/interfaces/IAuthorizer.sol


pragma solidity ^0.7.0;

interface IAuthorizer {
    function hasRole(bytes32 role, address account) external view returns (bool);
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

// File: contracts/pools/BasePoolFactory.sol



pragma solidity ^0.7.0;




abstract contract BasePoolFactory {
    IVault public immutable vault;

    event PoolRegistered(address indexed pool);

    constructor(IVault _vault) {
        vault = _vault;
    }

    /**
     * @dev Registers a new created pool. Emits a `PoolRegistered` event.
     */
    function _register(address pool) internal {
        emit PoolRegistered(pool);
    }
}

// File: @openzeppelin/contracts/GSN/Context.sol


pragma solidity ^0.7.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol



pragma solidity ^0.7.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
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

// File: contracts/pools/station/StationMath.sol



pragma solidity ^0.7.0;





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
        return 1 * 10 ** 18;
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

// File: contracts/pools/station/StationPoolUserDataHelpers.sol



pragma solidity ^0.7.0;


library StationPoolUserDataHelpers {

    enum JoinKind { INIT, BPT_OUT_FOR_ALL_TOKENS_IN }
    enum ExitKind { BPT_IN_FOR_ALL_TOKENS_OUT }

    function joinKind(bytes memory self) internal pure returns (JoinKind) {
        return abi.decode(self, (JoinKind));
    }

    function exitKind(bytes memory self) internal pure returns (ExitKind) {
        return abi.decode(self, (ExitKind));
    }

    function initialAmountsIn(bytes memory self) internal pure returns (uint256[] memory amountsIn) {
        (, amountsIn) = abi.decode(self, (JoinKind, uint256[]));
    }

    function bptOutForAllTokensIn(bytes memory self) internal pure returns (uint256[] memory amountsIn) {
        (, amountsIn) = abi.decode(self, (JoinKind, uint256[]));
    }

    function bptInForAllTokensOut(bytes memory self) internal pure returns (uint256[] memory amountsOut) {
        (, amountsOut) = abi.decode(self, (ExitKind, uint256[]));
    }
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

// File: contracts/pools/BasePoolAuthorization.sol



pragma solidity ^0.7.0;



/**
 * @dev Base authorization layer implementation for pools. It shares the same concept as the one defined for the Vault.
 * It's built on top of OpenZeppelin's Access Control, which allows to define specific roles to control the access of
 * external accounts to the different functionalities of the contract.
 */
abstract contract BasePoolAuthorization is Authentication {
    function getAuthorizer() external view returns (IAuthorizer) {
        return _getAuthorizer();
    }

    function _canPerform(bytes32 roleId, address account) internal view override returns (bool) {
        return _getAuthorizer().hasRole(roleId, account);
    }

    function _getAuthorizer() internal view virtual returns (IAuthorizer);
}

// File: contracts/pools/BalancerPoolToken.sol



pragma solidity ^0.7.0;



/**
 * @title Highly opinionated token implementation
 * @author Balancer Labs
 * @dev
 * - Includes functions to increase and decrease allowance as a workaround
 *   for the well-known issue with `approve`:
 *   https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
 * - Allows for 'infinite allowance', where an allowance of 0xff..ff is not
 *   decreased by calls to transferFrom
 * - Lets a token holder use `transferFrom` to send their own tokens,
 *   without first setting allowance
 * - Emits 'Approval' events whenever allowance is changed by `transferFrom`
 */
contract BalancerPoolToken is IERC20 {
    using Math for uint256;

    // State variables

    uint8 private constant _DECIMALS = 18;

    mapping(address => uint256) private _balance;
    mapping(address => mapping(address => uint256)) private _allowance;
    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    // Function declarations

    constructor(string memory tokenName, string memory tokenSymbol) {
        _name = tokenName;
        _symbol = tokenSymbol;
    }

    // External functions

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowance[owner][spender];
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balance[account];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _setAllowance(msg.sender, spender, amount);

        return true;
    }

    function increaseApproval(address spender, uint256 amount) external returns (bool) {
        _setAllowance(msg.sender, spender, _allowance[msg.sender][spender].add(amount));

        return true;
    }

    function decreaseApproval(address spender, uint256 amount) external returns (bool) {
        uint256 currentAllowance = _allowance[msg.sender][spender];

        if (amount >= currentAllowance) {
            _setAllowance(msg.sender, spender, 0);
        } else {
            _setAllowance(msg.sender, spender, currentAllowance.sub(amount));
        }

        return true;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _move(msg.sender, recipient, amount);

        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        uint256 currentAllowance = _allowance[sender][msg.sender];
        require(msg.sender == sender || currentAllowance >= amount, "INSUFFICIENT_ALLOWANCE");

        _move(sender, recipient, amount);

        if (msg.sender != sender && currentAllowance != uint256(-1)) {
            require(currentAllowance >= amount, "INSUFFICIENT_ALLOWANCE");
            _setAllowance(sender, msg.sender, currentAllowance - amount);
        }

        return true;
    }

    // Public functions

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _DECIMALS;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    // Internal functions

    function _mintPoolTokens(address recipient, uint256 amount) internal {
        _balance[recipient] = _balance[recipient].add(amount);
        _totalSupply = _totalSupply.add(amount);
        emit Transfer(address(0), recipient, amount);
    }

    function _burnPoolTokens(address sender, uint256 amount) internal {
        uint256 currentBalance = _balance[sender];
        require(currentBalance >= amount, "INSUFFICIENT_BALANCE");

        _balance[sender] = currentBalance - amount;
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(sender, address(0), amount);
    }

    function _move(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        uint256 currentBalance = _balance[sender];
        require(currentBalance >= amount, "INSUFFICIENT_BALANCE");

        _balance[sender] = currentBalance - amount;
        _balance[recipient] = _balance[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
    }

    // Private functions

    function _setAllowance(
        address owner,
        address spender,
        uint256 amount
    ) private {
        _allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
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

// File: contracts/pools/station/Oracle.sol


pragma solidity ^0.7.0;


// This Contract is the Band Protocol Standard Data Reference. It is used to get prices For
// all tokens in the pool in USD, using the 1e18 format.
interface IStdReference {
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

    contract Oracle {

    IStdReference public ref;

    uint256 public price;

    constructor(IStdReference _ref) {
      //// Kovan testnet address where reference data can be queried.
        ref = _ref;
    }

    function getPrice() external view returns (uint256){
        IStdReference.ReferenceData memory data = ref.getReferenceData("ETH","USD");
        return data.rate;
    }

    function getMultiPrices() external view returns (uint256[] memory){
        string[] memory baseSymbols = new string[](5);
        baseSymbols[0] = "BTC";
        baseSymbols[1] = "DAI";
        baseSymbols[2] = "ETH";
        baseSymbols[3] = "USDC";
        baseSymbols[4] = "USDT";

        string[] memory quoteSymbols = new string[](5);
        quoteSymbols[0] = "USD";
        quoteSymbols[1] = "USD";
        quoteSymbols[2] = "USD";
        quoteSymbols[3] = "USD";
        quoteSymbols[4] = "USD";
        IStdReference.ReferenceData[] memory data = ref.getReferenceDataBulk(baseSymbols,quoteSymbols);

        uint256[] memory prices = new uint256[](5);
        prices[0] = data[0].rate;
        prices[1] = data[1].rate;
        prices[2] = data[2].rate;
        prices[3] = data[3].rate;
        prices[4] = data[4].rate;

        return prices;
    }

    function savePrice(string memory base, string memory quote) external {
        IStdReference.ReferenceData memory data = ref.getReferenceData(base,quote);
        price = data.rate;
    }
}

// File: contracts/pools/station/StationPool.sol



pragma solidity ^0.7.0;











// This contract relies on tons of immutable state variables to
// perform efficient lookup, without resorting to storage reads.
// solhint-disable max-states-count

contract StationPool is
    IGeneralPool,
    BasePoolAuthorization,
    StationMath,
    BalancerPoolToken,
    EmergencyPeriod
{
    using StationPoolUserDataHelpers for bytes;

    Oracle constant public PRICE_PROVIDER = Oracle(0xCD9B0fc977f1Baf6Fbc96e8373915078fB095154);

    uint256 private constant _MIN_TOKENS = 2;
    uint256 private constant _MAX_TOKENS = 16;
    uint256 internal immutable _protocolSwapFee = 0;

    uint256 private _amp;
    uint256 private constant _MIN_AMP = 10;
    uint256 private constant _MAX_AMP = 50;
    uint256 private constant _MINIMUM_BPT = 0;

    IVault internal immutable _vault;
    bytes32 internal immutable _poolId;
    uint256 internal immutable _totalTokens;

    IERC20 internal immutable _token0;
    IERC20 internal immutable _token1;
    IERC20 internal immutable _token2;
    IERC20 internal immutable _token3;
    IERC20 internal immutable _token4;
    IERC20 internal immutable _token5;
    IERC20 internal immutable _token6;
    IERC20 internal immutable _token7;
    IERC20 internal immutable _token8;
    IERC20 internal immutable _token9;
    IERC20 internal immutable _token10;
    IERC20 internal immutable _token11;
    IERC20 internal immutable _token12;
    IERC20 internal immutable _token13;
    IERC20 internal immutable _token14;
    IERC20 internal immutable _token15;

    // Scaling factors for each token
    uint256 internal immutable _scalingFactor0;
    uint256 internal immutable _scalingFactor1;
    uint256 internal immutable _scalingFactor2;
    uint256 internal immutable _scalingFactor3;
    uint256 internal immutable _scalingFactor4;
    uint256 internal immutable _scalingFactor5;
    uint256 internal immutable _scalingFactor6;
    uint256 internal immutable _scalingFactor7;
    uint256 internal immutable _scalingFactor8;
    uint256 internal immutable _scalingFactor9;
    uint256 internal immutable _scalingFactor10;
    uint256 internal immutable _scalingFactor11;
    uint256 internal immutable _scalingFactor12;
    uint256 internal immutable _scalingFactor13;
    uint256 internal immutable _scalingFactor14;
    uint256 internal immutable _scalingFactor15;

    constructor(
        IVault vault,
        string memory name,
        string memory symbol,
        IERC20[] memory tokens,
        uint256 amp,
        uint256 emergencyPeriod,
        uint256 emergencyPeriodCheckExtension,
        IVault.PoolSpecialization specialization
    )
        BasePoolAuthorization()
        BalancerPoolToken(name, symbol)
        EmergencyPeriod(emergencyPeriod, emergencyPeriodCheckExtension)
    {
        require(tokens.length >= _MIN_TOKENS, "MIN_TOKENS");
        require(tokens.length <= _MAX_TOKENS, "MAX_TOKENS");
        require(amp >= _MIN_AMP, "MIN_AMP");
        require(amp <= _MAX_AMP, "MAX_AMP");

        InputHelpers.ensureArrayIsSorted(tokens);

        bytes32 poolId = vault.registerPool(specialization);
        vault.registerTokens(poolId, tokens, new address[](tokens.length));

        // Set immutable state variables - these cannot be read from during construction

        _vault = vault;
        _poolId = poolId;
        _totalTokens = tokens.length;

        _amp = amp;

        // Immutable variables cannot be initialized inside an if statement, so we must do conditional assignments

        _token0 = tokens.length > 0 ? tokens[0] : IERC20(0);
        _token1 = tokens.length > 1 ? tokens[1] : IERC20(0);
        _token2 = tokens.length > 2 ? tokens[2] : IERC20(0);
        _token3 = tokens.length > 3 ? tokens[3] : IERC20(0);
        _token4 = tokens.length > 4 ? tokens[4] : IERC20(0);
        _token5 = tokens.length > 5 ? tokens[5] : IERC20(0);
        _token6 = tokens.length > 6 ? tokens[6] : IERC20(0);
        _token7 = tokens.length > 7 ? tokens[7] : IERC20(0);
        _token8 = tokens.length > 8 ? tokens[8] : IERC20(0);
        _token9 = tokens.length > 9 ? tokens[9] : IERC20(0);
        _token10 = tokens.length > 10 ? tokens[10] : IERC20(0);
        _token11 = tokens.length > 11 ? tokens[11] : IERC20(0);
        _token12 = tokens.length > 12 ? tokens[12] : IERC20(0);
        _token13 = tokens.length > 13 ? tokens[13] : IERC20(0);
        _token14 = tokens.length > 14 ? tokens[14] : IERC20(0);
        _token15 = tokens.length > 15 ? tokens[15] : IERC20(0);

        _scalingFactor0 = tokens.length > 0
            ? _computeScalingFactor(tokens[0])
            : 0;
        _scalingFactor1 = tokens.length > 1
            ? _computeScalingFactor(tokens[1])
            : 0;
        _scalingFactor2 = tokens.length > 2
            ? _computeScalingFactor(tokens[2])
            : 0;
        _scalingFactor3 = tokens.length > 3
            ? _computeScalingFactor(tokens[3])
            : 0;
        _scalingFactor4 = tokens.length > 4
            ? _computeScalingFactor(tokens[4])
            : 0;
        _scalingFactor5 = tokens.length > 5
            ? _computeScalingFactor(tokens[5])
            : 0;
        _scalingFactor6 = tokens.length > 6
            ? _computeScalingFactor(tokens[6])
            : 0;
        _scalingFactor7 = tokens.length > 7
            ? _computeScalingFactor(tokens[7])
            : 0;
        _scalingFactor8 = tokens.length > 8
            ? _computeScalingFactor(tokens[8])
            : 0;
        _scalingFactor9 = tokens.length > 9
            ? _computeScalingFactor(tokens[9])
            : 0;
        _scalingFactor10 = tokens.length > 10
            ? _computeScalingFactor(tokens[10])
            : 0;
        _scalingFactor11 = tokens.length > 11
            ? _computeScalingFactor(tokens[11])
            : 0;
        _scalingFactor12 = tokens.length > 12
            ? _computeScalingFactor(tokens[12])
            : 0;
        _scalingFactor13 = tokens.length > 13
            ? _computeScalingFactor(tokens[13])
            : 0;
        _scalingFactor14 = tokens.length > 14
            ? _computeScalingFactor(tokens[14])
            : 0;
        _scalingFactor15 = tokens.length > 15
            ? _computeScalingFactor(tokens[15])
            : 0;
    }

    // Getters / Setters

    function getVault() public view returns (IVault) {
        return _vault;
    }
    function getAmp() public view returns (uint256) {
        return _amp;
    }

    function getPoolId() external view returns (bytes32) {
        return _poolId;
    }

    function setEmergencyPeriod(bool active) external authenticate {
        _setEmergencyPeriod(active);
    }

    // Join / Exit Hooks

    modifier onlyVault(bytes32 poolId) {
        require(msg.sender == address(_vault), "CALLER_NOT_VAULT");
        require(poolId == _poolId, "INVALID_POOL_ID");
        _;
    }

    function onJoinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] memory currentBalances,
        uint256 latestBlockNumberUsed,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    )
        external
        override
        onlyVault(poolId)
        returns (uint256[] memory, uint256[] memory)
    {
        uint256[] memory scalingFactors = _scalingFactors();
        _upscaleArray(currentBalances, scalingFactors);

        if (totalSupply() == 0) {
            (uint256 bptAmountOut, uint256[] memory amountsIn) =
                _onInitializePool(poolId, sender, recipient, userData);

            // On initialization, we lock _MINIMUM_BPT by minting it for the zero address. This BPT acts as a minimum
            // as it will never be burned, which reduces potential issues with rounding, and also prevents the Pool from
            // ever being fully drained.
            require(bptAmountOut >= _MINIMUM_BPT, "MINIMUM_BPT");
            _mintPoolTokens(address(0), _MINIMUM_BPT);
            _mintPoolTokens(recipient, bptAmountOut - _MINIMUM_BPT);

            // amountsIn are amounts entering the Pool, so we round up.
            _downscaleUpArray(amountsIn, scalingFactors);

            return (amountsIn, new uint256[](_totalTokens));
        } else {
            (
                uint256 bptAmountOut,
                uint256[] memory amountsIn,
                uint256[] memory dueProtocolFeeAmounts
            ) =
                _onJoinPool(
                    poolId,
                    sender,
                    recipient,
                    currentBalances,
                    latestBlockNumberUsed,
                    protocolSwapFeePercentage,
                    userData
                );

            _mintPoolTokens(recipient, bptAmountOut);

            // amountsIn are amounts entering the Pool, so we round up.
            _downscaleUpArray(amountsIn, scalingFactors);
            // dueProtocolFeeAmounts are amounts exiting the Pool, so we round down.
            _downscaleDownArray(dueProtocolFeeAmounts, scalingFactors);

            return (amountsIn, dueProtocolFeeAmounts);
        }
    }

    function queryJoin(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] memory currentBalances,
        uint256 latestBlockNumberUsed,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    ) external returns (uint256 bptOut, uint256[] memory amountsIn) {
        return
            _queryAction(
                poolId,
                sender,
                recipient,
                currentBalances,
                latestBlockNumberUsed,
                protocolSwapFeePercentage,
                userData,
                _onJoinPool,
                _downscaleUpArray
            );
    }

    function onExitPool(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] memory currentBalances,
        uint256 latestBlockNumberUsed,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    )
        external
        override
        onlyVault(poolId)
        returns (uint256[] memory, uint256[] memory)
    {
        uint256[] memory scalingFactors = _scalingFactors();
        _upscaleArray(currentBalances, scalingFactors);

        (
            uint256 bptAmountIn,
            uint256[] memory amountsOut,
            uint256[] memory dueProtocolFeeAmounts
        ) =
            _onExitPool(
                poolId,
                sender,
                recipient,
                currentBalances,
                latestBlockNumberUsed,
                protocolSwapFeePercentage,
                userData
            );

        _burnPoolTokens(sender, bptAmountIn);

        // Both amountsOut and dueProtocolFees are amounts exiting the Pool, so we round down.
        _downscaleDownArray(amountsOut, scalingFactors);
        _downscaleDownArray(dueProtocolFeeAmounts, scalingFactors);

        return (amountsOut, dueProtocolFeeAmounts);
    }

    function queryExit(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] memory currentBalances,
        uint256 latestBlockNumberUsed,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    ) external returns (uint256 bptIn, uint256[] memory amountsOut) {
        return
            _queryAction(
                poolId,
                sender,
                recipient,
                currentBalances,
                latestBlockNumberUsed,
                protocolSwapFeePercentage,
                userData,
                _onExitPool,
                _downscaleDownArray
            );
    }

    function _onInitializePool(
        bytes32,
        address,
        address,
        bytes memory userData
    ) internal view returns (uint256 bptAmountOut, uint256[] memory amountsIn) {
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

    function onSwapGivenIn(
        IPoolSwapStructs.SwapRequestGivenIn memory swapRequest,
        uint256[] memory balances,
        uint256 indexIn,
        uint256 indexOut
    ) external view override returns (uint256) {
        _validateIndexes(indexIn, indexOut, _totalTokens);

        uint256[] memory scalingFactors = _scalingFactors();

        // All token amounts are upscaled.
        swapRequest.amountIn = _upscale(
            swapRequest.amountIn,
            scalingFactors[indexIn]
        );

        uint256 amountOut = _onSwapGivenIn(indexIn, indexOut, swapRequest);
        amountOut = amountOut + (balances[1] - balances[1]);

        // amountOut tokens are exiting the Pool, so we round down.
        return _downscaleDown(amountOut, scalingFactors[indexOut]);
    }

    function onSwapGivenOut(
        IPoolSwapStructs.SwapRequestGivenOut memory swapRequest,
        uint256[] memory balances,
        uint256 indexIn,
        uint256 indexOut
    ) external view override returns (uint256) {
        _validateIndexes(indexIn, indexOut, _totalTokens);

        uint256[] memory scalingFactors = _scalingFactors();

        // All token amounts are upscaled.
        swapRequest.amountOut = _upscale(
            swapRequest.amountOut,
            scalingFactors[indexOut]
        );

        uint256 amountIn = _onSwapGivenOut(indexIn, indexOut, swapRequest);
        amountIn = amountIn + (balances[1] - balances[1]);
        // amountIn are tokens entering the Pool, so we round up.
        amountIn = _downscaleUp(amountIn, scalingFactors[indexIn]);

        // Fees are added after scaling happens, to reduce complexity of rounding direction analysis.
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

    function _validateIndexes(
        uint256 indexIn,
        uint256 indexOut,
        uint256 limit
    ) private pure {
        require(indexIn < limit && indexOut < limit, "OUT_OF_BOUNDS");
    }

    /**
     * @dev Returns a scaling factor that, when multiplied to a token amount for `token`, normalizes its balance as if
     * it had 18 decimals.
     */
    function _computeScalingFactor(IERC20 token)
        private
        view
        returns (uint256)
    {
        // Tokens that don't implement the `decimals` method are not supported.
        uint256 tokenDecimals = ERC20(address(token)).decimals();

        // Tokens with more than 18 decimals are not supported.
        uint256 decimalsDifference = Math.sub(18, tokenDecimals);
        return 10**decimalsDifference;
    }

    function _scalingFactor(IERC20 token) internal view returns (uint256) {
        // prettier-ignore
        if (token == _token0) { return _scalingFactor0; }
        else if (token == _token1) { return _scalingFactor1; }
        else if (token == _token2) { return _scalingFactor2; }
        else if (token == _token3) { return _scalingFactor3; }
        else if (token == _token4) { return _scalingFactor4; }
        else if (token == _token5) { return _scalingFactor5; }
        else if (token == _token6) { return _scalingFactor6; }
        else if (token == _token7) { return _scalingFactor7; }
        else if (token == _token8) { return _scalingFactor8; }
        else if (token == _token9) { return _scalingFactor9; }
        else if (token == _token10) { return _scalingFactor10; }
        else if (token == _token11) { return _scalingFactor11; }
        else if (token == _token12) { return _scalingFactor12; }
        else if (token == _token13) { return _scalingFactor13; }
        else if (token == _token14) { return _scalingFactor14; }
        else if (token == _token15) { return _scalingFactor15; }
        else {
            revert("INVALID_TOKEN");
        }
    }

    function _scalingFactors() internal view returns (uint256[] memory) {
        uint256[] memory scalingFactors = new uint256[](_totalTokens);

        // prettier-ignore
        {
            if (_totalTokens > 0) { scalingFactors[0] = _scalingFactor0; } else { return scalingFactors; }
            if (_totalTokens > 1) { scalingFactors[1] = _scalingFactor1; } else { return scalingFactors; }
            if (_totalTokens > 2) { scalingFactors[2] = _scalingFactor2; } else { return scalingFactors; }
            if (_totalTokens > 3) { scalingFactors[3] = _scalingFactor3; } else { return scalingFactors; }
            if (_totalTokens > 4) { scalingFactors[4] = _scalingFactor4; } else { return scalingFactors; }
            if (_totalTokens > 5) { scalingFactors[5] = _scalingFactor5; } else { return scalingFactors; }
            if (_totalTokens > 6) { scalingFactors[6] = _scalingFactor6; } else { return scalingFactors; }
            if (_totalTokens > 7) { scalingFactors[7] = _scalingFactor7; } else { return scalingFactors; }
            if (_totalTokens > 8) { scalingFactors[8] = _scalingFactor8; } else { return scalingFactors; }
            if (_totalTokens > 9) { scalingFactors[9] = _scalingFactor9; } else { return scalingFactors; }
            if (_totalTokens > 10) { scalingFactors[10] = _scalingFactor10; } else { return scalingFactors; }
            if (_totalTokens > 11) { scalingFactors[11] = _scalingFactor11; } else { return scalingFactors; }
            if (_totalTokens > 12) { scalingFactors[12] = _scalingFactor12; } else { return scalingFactors; }
            if (_totalTokens > 13) { scalingFactors[13] = _scalingFactor13; } else { return scalingFactors; }
            if (_totalTokens > 14) { scalingFactors[14] = _scalingFactor14; } else { return scalingFactors; }
            if (_totalTokens > 15) { scalingFactors[15] = _scalingFactor15; } else { return scalingFactors; }
        }

        return scalingFactors;
    }

    function _upscale(uint256 amount, uint256 scalingFactor)
        internal
        pure
        returns (uint256)
    {
        return Math.mul(amount, scalingFactor);
    }

    function _upscaleArray(
        uint256[] memory amount,
        uint256[] memory scalingFactors
    ) internal view {
        for (uint256 i = 0; i < _totalTokens; ++i) {
            amount[i] = Math.mul(amount[i], scalingFactors[i]);
        }
    }

    function _downscaleDown(uint256 amount, uint256 scalingFactor)
        internal
        pure
        returns (uint256)
    {
        return Math.divDown(amount, scalingFactor);
    }

    function _downscaleDownArray(
        uint256[] memory amount,
        uint256[] memory scalingFactors
    ) internal view {
        for (uint256 i = 0; i < _totalTokens; ++i) {
            amount[i] = Math.divDown(amount[i], scalingFactors[i]);
        }
    }

    function _downscaleUp(uint256 amount, uint256 scalingFactor)
        internal
        pure
        returns (uint256)
    {
        return Math.divUp(amount, scalingFactor);
    }

    function _downscaleUpArray(
        uint256[] memory amount,
        uint256[] memory scalingFactors
    ) internal view {
        for (uint256 i = 0; i < _totalTokens; ++i) {
            amount[i] = Math.divUp(amount[i], scalingFactors[i]);
        }
    }

    function _getAuthorizer() internal view override returns (IAuthorizer) {
        return _vault.getAuthorizer();
    }

    function _queryAction(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] memory currentBalances,
        uint256 latestBlockNumberUsed,
        uint256 protocolSwapFeePercentage,
        bytes memory userData,
        function(
            bytes32,
            address,
            address,
            uint256[] memory,
            uint256,
            uint256,
            bytes memory
        )
            internal
            returns (uint256, uint256[] memory, uint256[] memory) _action,
        function(uint256[] memory, uint256[] memory)
            internal
            view _downscaleArray
    ) private returns (uint256, uint256[] memory) {
        // This uses the same technique used by the Vault in queryBatchSwap. Refer to that function for a detailed
        // explanation.

        if (msg.sender != address(this)) {
            // We perform an external call to ourselves, forwarding the same calldata. In this call, the else clause of
            // the preceding if statement will be executed instead.

            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = address(this).call(msg.data);

            // solhint-disable-next-line no-inline-assembly
            assembly {
                // This call should always revert to decode the bpt and token amounts from the revert reason
                switch success
                    case 0 {
                        // Note we are manually writing the memory slot 0. We can safely overwrite whatever is
                        // stored there as we take full control of the execution and then immediately return.

                        // We copy the first 4 bytes to check if it matches with the expected signature, otherwise
                        // there was another revert reason and we should forward it.
                        returndatacopy(0, 0, 0x04)
                        let error := and(
                            mload(0),
                            0xffffffff00000000000000000000000000000000000000000000000000000000
                        )

                        // If the first 4 bytes don't match with the expected signature, we forward the revert reason.
                        if eq(
                            eq(
                                error,
                                0x43adbafb00000000000000000000000000000000000000000000000000000000
                            ),
                            0
                        ) {
                            returndatacopy(0, 0, returndatasize())
                            revert(0, returndatasize())
                        }

                        // The returndata contains the signature, followed by the raw memory representation of the
                        // `bptAmount` and `tokenAmounts` (array: length + data). We need to return an ABI-encoded
                        // representation of these.
                        // An ABI-encoded response will include one additional field to indicate the starting offset of
                        // the `tokenAmounts` array. The `bptAmount` will be laid out in the first word of the
                        // returndata.
                        //
                        // In returndata:
                        // [ signature ][ bptAmount ][ tokenAmounts length ][ tokenAmounts values ]
                        // [  4 bytes  ][  32 bytes ][       32 bytes      ][ (32 * length) bytes ]
                        //
                        // We now need to return (ABI-encoded values):
                        // [ bptAmount ][ tokeAmounts offset ][ tokenAmounts length ][ tokenAmounts values ]
                        // [  32 bytes ][       32 bytes     ][       32 bytes      ][ (32 * length) bytes ]

                        // We copy 32 bytes for the `bptAmount` from returndata into memory.
                        // Note that we skip the first 4 bytes for the error signature
                        returndatacopy(0, 0x04, 32)

                        // The offsets are 32-bytes long, so the array of `tokenAmounts` will start after
                        // the initial 64 bytes.
                        mstore(0x20, 64)

                        // We now copy the raw memory array for the `tokenAmounts` from returndata into memory.
                        // Since bpt amount and offset take up 64 bytes, we start copying at address 0x40. We also
                        // skip the first 36 bytes from returndata, which correspond to the signature plus bpt amount.
                        returndatacopy(0x40, 0x24, sub(returndatasize(), 36))

                        // We finally return the ABI-encoded uint256 and the array, which has a total length equal to
                        // the size of returndata, plus the 32 bytes of the offset but without the 4 bytes of the
                        // error signature.
                        return(0, add(returndatasize(), 28))
                    }
                    default {
                        // This call should always revert, but we fail nonetheless if that didn't happen
                        invalid()
                    }
            }
        } else {
            uint256[] memory scalingFactors = _scalingFactors();
            _upscaleArray(currentBalances, scalingFactors);

            (uint256 bptAmount, uint256[] memory tokenAmounts, ) =
                _action(
                    poolId,
                    sender,
                    recipient,
                    currentBalances,
                    latestBlockNumberUsed,
                    protocolSwapFeePercentage,
                    userData
                );

            _downscaleArray(tokenAmounts, scalingFactors);

            // solhint-disable-next-line no-inline-assembly
            assembly {
                // We will return a raw representation of `bptAmount` and `tokenAmounts` in memory, which is composed of
                // a 32-byte uint256, followed by a 32-byte for the array length, and finally the 32-byte uint256 values
                // Because revert expects a size in bytes, we multiply the array length (stored at `tokenAmounts`) by 32
                let size := mul(mload(tokenAmounts), 32)

                // We store the `bptAmount` in the previous slot to the `tokenAmounts` array. We can make sure there
                // will be at least one available slot due to how the memory scratch space works.
                // We can safely overwrite whatever is stored in this slot as we will revert immediately after that.
                let start := sub(tokenAmounts, 0x20)
                mstore(start, bptAmount)

                // We send one extra value for the error signature "QueryError(uint256,uint256[])" which is 0x43adbafb
                // We use the previous slot to `bptAmount`.
                mstore(
                    sub(start, 0x20),
                    0x0000000000000000000000000000000000000000000000000000000043adbafb
                )
                start := sub(start, 0x04)

                // When copying from `tokenAmounts` into returndata, we copy the additional 68 bytes to also return
                // the `bptAmount`, the array 's length, and the error signature.
                revert(start, add(size, 68))
            }
        }
    }
}

// File: contracts/pools/station/StationPoolFactory.sol



pragma solidity ^0.7.0;





contract StationPoolFactory is BasePoolFactory {
     constructor(IVault _vault) BasePoolFactory(_vault) {
        // solhint-disable-previous-line no-empty-blocks
    }

     /**
     * @dev Deploys a new `StationPool`.
     */

     function create(
        string memory name,
        string memory symbol,
        IERC20[] memory tokens,
        uint256 amp,
        uint256 emergencyPeriod,
        uint256 emergencyPeriodCheckExtension
        ) external returns (address) {
             IVault.PoolSpecialization specialization = IVault.PoolSpecialization.GENERAL;
        address pool = address(
       new StationPool(vault, name, symbol, tokens, amp, emergencyPeriod, emergencyPeriodCheckExtension, specialization)
        );
        _register(pool);
        return pool;
    }
}
