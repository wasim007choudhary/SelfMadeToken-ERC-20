// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

contract HelperConfig is Script {
    // Custom errors
    error HelperConfig__UnsupportedChainId(uint256 chainId);
    error HelperConfig__InvalidNetworkOverride(string reason);
    error HelperConfig__OnlyOwnerCanSetNetwork();
    error HelperConfig__OwnerCannotBeZeroAddress();

    // 1. Enums
    enum NetworkChainName {
        Sepolia,
        Mainnet,
        AnvilFoundry
    }

    // 2. Structs
    struct NetworkConfig {
        NetworkChainName networkName;
        bool isConfigured;
    }

    // 3. State variables
    uint256 constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 constant MAINNET_CHAIN_ID = 1;
    uint256 constant ANVIL_CHAIN_ID = 31337;
    NetworkConfig public activeNetworkConfig;
    address public immutable i_owner;

    // 4. Events
    event OwnershipSet(address indexed Owner);
    event NetworkConfigUpdated(NetworkChainName indexed networkChainName, address indexed updater);

    // 5. Modifiers
    modifier onlyOwnerOrAnvil() {
        if (block.chainid != ANVIL_CHAIN_ID && msg.sender != i_owner) {
            revert HelperConfig__OnlyOwnerCanSetNetwork();
        }
        _;
    }

    // 6. Constructor
    constructor() {
        if (msg.sender == address(0)) {
            revert HelperConfig__OwnerCannotBeZeroAddress();
        }
        i_owner = msg.sender;
        emit OwnershipSet(i_owner);
        activeNetworkConfig = getActiveNetworkConfig();
    }

    // 7. External functions
    function setNetworkConfig(NetworkChainName _name) external onlyOwnerOrAnvil {
        if (
            _name != NetworkChainName.Sepolia && _name != NetworkChainName.Mainnet
                && _name != NetworkChainName.AnvilFoundry
        ) {
            revert HelperConfig__InvalidNetworkOverride("Only Sepolia and Mainnet are supported for override");
        }
        if (_name == activeNetworkConfig.networkName && activeNetworkConfig.isConfigured) {
            console.log("Network configuration already set to:", getNetworkName(_name));
            return;
        }

        activeNetworkConfig = NetworkConfig(_name, true);
        emit NetworkConfigUpdated(_name, msg.sender);
        console.log("Network configuration set to:", getNetworkName(_name));
    }

    // 8. Internal functions
    function getActiveNetworkConfig() internal view returns (NetworkConfig memory) {
        if (block.chainid == SEPOLIA_CHAIN_ID) {
            return NetworkConfig(NetworkChainName.Sepolia, true);
        }
        if (block.chainid == MAINNET_CHAIN_ID) {
            return NetworkConfig(NetworkChainName.Mainnet, true);
        }
        if (block.chainid == ANVIL_CHAIN_ID) {
            return NetworkConfig(NetworkChainName.AnvilFoundry, true);
        }

        revert HelperConfig__UnsupportedChainId(block.chainid);
    }

    function getNetworkName(NetworkChainName _name) internal pure returns (string memory) {
        if (_name == NetworkChainName.Sepolia) {
            return "Sepolia";
        } else if (_name == NetworkChainName.Mainnet) {
            return "Mainnet";
        } else if (_name == NetworkChainName.AnvilFoundry) {
            return "Anvil Foundry";
        } else {
            revert HelperConfig__UnsupportedChainId(uint256(_name));
        }
    }

    function getCurrentNetworkInfo() external view returns (NetworkChainName, uint256) {
        return (activeNetworkConfig.networkName, block.chainid);
    }

    function isMainnet() public view returns (bool) {
        return block.chainid == MAINNET_CHAIN_ID;
    }
}
