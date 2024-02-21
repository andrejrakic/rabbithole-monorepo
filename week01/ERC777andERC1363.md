## ERC777

[ERC777](https://eips.ethereum.org/EIPS/eip-777) is a standard for fungible tokens, designed to be an alternative to ERC20. ERC777 introduces several features aimed at improving the user and developer experience, addressing some limitations of ERC20:

- Hooks for Smart Contracts: ERC777 allows tokens to interact with smart contracts seamlessly within transactions. This is facilitated through hooks that notify contracts when they are involved in a token transaction, enabling more complex logic like automatic token fee deductions or triggering other contract actions upon receiving tokens.

- Elimination of the Approval Mechanism: One of the significant improvements over ERC20 is the reduction of the two-step transfer process (`approve` and `transferFrom`). ERC777 enables a more direct interaction model, reducing complexity and potential security risks associated with the approval mechanism.

- Mitigation of ERC20's Implicit Approval Risk: ERC20's approve mechanism has been known to be susceptible to race conditions and security vulnerabilities. ERC777's operator approach mitigates these risks by providing a more secure and explicit permission system.

## Issues with ERC777

While ERC777 addressed many ERC20 limitations, it also introduced several issues:

- Reentrancy Attacks: The introduction of hooks in ERC777, which allow contracts to execute code when receiving tokens. Here is the exploit PoC:

  - https://github.com/OpenZeppelin/exploit-uniswap
  - https://blog.openzeppelin.com/exploiting-uniswap-from-reentrancy-to-actual-profit

- Adoption Concerns: Despite its advantages, the complexity and potential security considerations of implementing ERC777 correctly have led to slower adoption compared to the simpler ERC20 standard.
  - https://github.com/OpenZeppelin/openzeppelin-contracts/issues/2620

## ERC1363

[ERC1363](https://eips.ethereum.org/EIPS/eip-1363) is another token standard, introduced to further extend the capabilities of ERC20 tokens by enabling them to be used for payments and any kind of authorization process. It builds upon the ERC20 standard by introducing functions that allow a token to be transferred and a notification to be triggered in a single transaction.

- Single-Transaction Payments and Notifications: ERC1363 allows tokens to be spent and simultaneously notify the recipient contract, facilitating the execution of additional logic, such as paying for a service, in a single transaction.

- Token Utility: By enabling tokens to carry additional information and trigger contract actions upon transfer, ERC1363 opens new possibilities for token utility beyond simple transfers, including subscriptions, fees, rewards, and more.

## Did ERC1363 Solve ERC777's Reentrancy Issues?

No :)

While ERC1363 provides tools that can be used in a way that mitigates reentrancy risks, it doesn't inherently solve reentrancy issues by itself. The security of contracts implementing ERC1363 (like those implementing any smart contract standard) depends on how they're written and whether they employ best practices for avoiding reentrancy and other vulnerabilities, such as OpenZeppelin's `ReentrancyGuard`, usage of Check-Effects-Interactions pattern and [FREI-PI](https://www.nascent.xyz/idea/youre-writing-require-statements-wrong) (Function Requirements-Effects-Interactions + Protocol Invariants) pattern, and more.
