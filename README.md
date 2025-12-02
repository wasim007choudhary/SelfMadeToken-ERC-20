# SelfmadeToken

[![Solidity](https://img.shields.io/badge/Solidity-0.8.19-blue.svg)](https://docs.soliditylang.org/en/v0.8.19/)
[![Foundry](https://img.shields.io/badge/Foundry-v1.0.0-orange)](https://github.com/foundry-rs/foundry)
[![Coverage](https://img.shields.io/badge/Coverage-100%25-brightgreen)](https://github.com/<your-repo>/actions/workflows/test.yml)

[![X (Twitter)](https://img.shields.io/badge/X-@i___wasim-black?logo=x)](https://x.com/i___wasim)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Wasim%20Choudhary-blue?logo=linkedin)](https://www.linkedin.com/in/wasim-007-choudhary/)

A simple, gas-optimized ERC-20 compatible token implemented in Solidity 0.8.19, with custom errors and safe allowance handling. Designed and tested using Foundry.

---

## Features Details

- Standard ERC-20 token functions: `transfer`, `approve`, `transferFrom`, `increaseAllowance`, `decreaseAllowance`
- Custom errors for efficient gas usage and clear revert reasons
- Owner-only `mint` and public `burn` functions with safety checks
- Safe approval method to mitigate race conditions
- Thorough unit tests achieving 100% coverage
- Network-aware deployment using `HelperConfig` for Sepolia, Mainnet, and local Anvil
- Deployment script supporting environment-based initial supply and owner override for testing

---

## Contracts

| Contract              | Description                                                           |
| --------------------- | --------------------------------------------------------------------- |
| `SelfmadeToken`       | ERC-20 token implementation with custom errors and safety features    |
| `HelperConfig`        | Network configuration contract to identify chain and settings         |
| `DeploySelfMadeToken` | Script to deploy token and helper contract with environment detection |

---

## Getting Started

### Prerequisites

- [Foundry](https://foundry.paradigm.xyz/) installed
- Solidity 0.8.19 and above compatible environment
- Unix-based shell (for scripts)

### Installation

````bash
git clone <repo-url>
cd <repo-folder>
forge install

```bash
forge script script/deploy.s.sol --broadcast --rpc-url <your_rpc_url>
forge test --coverage
````

## Contract Details

# SelfmadeToken.sol

- Implements ERC-20 standard functions with balance and allowance mappings

- Uses custom errors to save gas and provide clear revert reasons

- Includes safeApprove for preventing allowance race conditions

- Owner-only mint function and public burn function with validations

# HelperConfig.s.sol

- Detects current network by chain ID

- Restricts owner actions to deployer or local Anvil environment

- Emits events on ownership and network configuration changes

# DeploySelfMadeToken.s.sol

- Reads previous deployments from a JSON file

- Prevents redeployments on Mainnet for safety

- Sets initial supply based on network environment

- Supports owner override for testing

## Contribution

Contributions are welcome! Please open an issue or submit a pull request.

# Guidelines:

- Write clear, concise commit messages

- Include tests for any new features or bug fixes

- Follow the existing code style and conventions

## FAQ

Q: Why use custom errors instead of require strings?
A: Custom errors save gas by encoding error signatures instead of full revert strings, and they provide more structured error handling.

Q: Can I mint tokens on Mainnet?
A: Minting is restricted to the owner only, and you should exercise caution when minting on Mainnet to avoid inflation or misuse.

Q: How is the initial supply determined?
A: Initial supply is 20 million tokens on Mainnet and 1000 tokens on test/local networks.

## License

This project is licensed under the MIT License.

Made with 🦾🧠⚙️ using Foundry and Solidity.

- yaml
- Copy
- Edit
