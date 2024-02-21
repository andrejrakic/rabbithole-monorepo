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

- Use Linear Bonding Curve. The formula for calculating price in ETH for both buying and selling is inherited from the general arithmetic series sum formula which looks like this: $S = \frac{n}{2} \cdot (a_1 + a_n)$ where $n$ is the number of terms, $a_1$ is the first term, and $a_n$ is the $n$-th term. Combining this formula with the Linear Bonding Curve formula ($price = slope \cdot totalSupply + initialPrice$) where $slope$ is a fixed price increase per each new token sold, we got the final formula for calculating buying/selling prices in ETH:

  $price = \frac{slope \cdot numberOfTokens}{2} \cdot (2 \cdot totalSupply + numberOfTokens + 1)$

- Do not rely on `address(this).balance` because there is no way to prevent ETH from coming to your smart contract yet, so it can mess up calculations. Use dedicated functions for calculating prices instead.
- Fight against the sandwich attacks by introducing sleepage tolerance for ETH values for both buying and selling.

```solidity
if (priceInEth > maximumEthWillingToSpend) {
    revert TokenSale__SlippageToleranceExceeded(priceInEth, maximumEthWillingToSpend);
}


if (minimumEthWillingToReceive > priceInEth) {
    revert TokenSale__SlippageToleranceExceeded(priceInEth, minimumEthWillingToReceive);
}
```

- Use OpenZeppelin's `ReentrancyGuard`
- Transfer ETH using `.call` only, instead of `transfer()` or `send()`
