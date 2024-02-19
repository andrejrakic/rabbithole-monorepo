## Non-transferable NFT hook

```solidity
    /**
     * @dev Hook that is called before token transfer.
     *      See {ERC721 - _beforeTokenTransfer}.
     * @notice This hook disallows token transfers.
     */
    function _update(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        if (!(from == address(0) || to == address(0))) {
            revert NonTransferrableToken();
        }
        super._update(from, to, tokenId);
    }
```

### Rules of Hooks [OLD]

There’s a few guidelines you should follow when writing code that uses hooks in order to prevent issues. They are very simple, but do make sure you follow them:

1. Whenever you override a parent’s hook, re-apply the `virtual` attribute to the hook. That will allow child contracts to add more functionality to the hook.

2. **Always** call the parent’s hook in your override using super. This will make sure all hooks in the inheritance tree are called: contracts like ERC20Pausable rely on this behavior.

```solidity
contract MyToken is ERC20 {
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal virtual override // Add virtual here!
    {
        super._beforeTokenTransfer(from, to, amount); // Call parent hook
        ...
    }
}
```

That’s it! Enjoy simpler code using hooks!

### 5.0.0 Release [NEW]

These breaking changes will require modifications to ERC20, ERC721, and ERC1155 contracts, since the `_afterTokenTransfer` and `_beforeTokenTransfer` functions were removed. Thus, any customization made through those hooks should now be done overriding the new `_update` function instead.

Minting and burning are implemented by `_update` and customizations should be done by overriding this function as well. `_transfer`, `_mint` and `_burn` are no longer virtual (meaning they are not overridable) to guard against possible inconsistencies.

For example, a contract using `ERC20`'s `_beforeTokenTransfer` hook would have to be changed in the following way.

```diff
-function _beforeTokenTransfer(
+function _update(
   address from,
   address to,
   uint256 amount
 ) internal virtual override {
-  super._beforeTokenTransfer(from, to, amount);
   require(!condition(), "ERC20: wrong condition");
+  super._update(from, to, amount);
 }
```
