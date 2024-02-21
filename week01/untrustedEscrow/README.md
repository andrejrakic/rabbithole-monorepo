## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

## Design Decisions

- The ERC-20 standard requires that `transfer()` and `transferFrom()` return a boolean indicating the success or failure of the call. The implementations of one or both of these functions on some tokens, including popular ones like Tether (USDT) and Binance Coin (BNB), instead have no return value. To handle these non-standard and unusual tokens we are using OpenZeppelin's `SafeERC20` library.

```solidity
using SafeERC20 for IERC20;

IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), amount);
```

- Some tokens have hooks on transfer functions which can lead to reentrancy attacks. Also, for a contract holding any amount of tokens, withdraw functions are common targets for exploiters. Because of that, we are using OpenZeppelin's `ReentrancyGuard` smart contract.

```solidity
function withdraw(bytes32 escrowId) external whenNotPaused nonReentrant {}
```

- In an unlikely case of some unpredicted issue, there is a usage of OpenZeppelin's `Pausable` contract which is controlled by our `Ownable` contract which has a two-step ownership transfer implemented.

```solidity
function withdraw(bytes32 escrowId) external whenNotPaused nonReentrant {}

function pause() external onlyOwner {
    _pause();
}

function unpause() external onlyOwner {
     _unpause();
}
```

- To handle fee-on transfer tokens we are relying on the actually received amount of tokens into the smart contract, instead of the provided amount.

```solidity
uint256 balanceBefore = IERC20(tokenAddress).balanceOf(address(this));
IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), amount);
uint256 balanceAfter = IERC20(tokenAddress).balanceOf(address(this));

uint256 actuallyDeposited = balanceAfter - balanceBefore;
```

- And the most challenging part was handling rebasing tokens. Rebasing tokens can alter the balance of any addresses holding their tokens arbitrarily. A negative rebasing token, the more common variant, deflates the balances of token owners. Positive rebasing tokens arbitrarily increase the balances of token holders. Because the rebasing is not triggered by transfers, the `UnsturstedEscrow` cannot expect when or how a rebasing will happen. To handle rebasing tokens, we introduced a percentage shares mechanism. So instead of tracking actual amounts deposited, we track percentage shares of a total amount of the particular token locked inside the smart contract. For example, if Alice deposits 20 tokens, and Bob deposits 60 tokens, when withdrawing Alice's escrow, the withdrawer is entitled to 25% of `token.balanceOf(address(this))` value in that moment, because 20 / 80 = 25% and 60 / 80 = 75%.

```solidity
sharePercentage: actuallyDeposited


uint256 share = (escrow.sharePercentage * HUNDRED_PERCENT_BPS) / s_totalTokens[escrow.tokenAddress];

uint256 amountToWithdraw = (share * IERC20(escrow.tokenAddress).balanceOf(address(this))) / HUNDRED_PERCENT_BPS;

s_totalTokens[escrow.tokenAddress] -= escrow.sharePercentage;
```

- To allow multiple escrows between the same parties (same buyers and sellers, same tokens and amounts, etc) we introduced a mechanism for creating unique escrow IDs to distinguish escrows between themselves.

```solidity
Escrow memory escrow = Escrow({
    sharePercentage: actuallyDeposited,
    tokenAddress: tokenAddress,
    buyer: msg.sender,
    seller: seller,
    releaseTimestamp: SafeCast.toUint48(releaseTimestamp)
});

escrowId = keccak256(abi.encode(escrow, s_nonce++));
```
