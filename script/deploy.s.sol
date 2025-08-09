// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {SelfmadeToken} from "src/SelfToken.sol";
import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "script/helperConfig.s.sol";
import {stdJson} from "forge-std/StdJson.sol";

// CUSTOM-ERROR for mainnet deployment only
error DeploySelfMadeToken___OwnerOverrideIsDisabledOnMainnet();
error DeploySelfMadeToken___TokenContractAlreadyDeployedOnMainnet();
error DeploySelfMadeToken___HelperContractAlreadyDeployedOnMainnet();

contract DeploySelfMadeToken is Script {
    using stdJson for string;

    //Constants
    uint256 constant INITIAL_LIVE_SUPPLY = 20_000_000 ether;
    uint256 constant INITIAL_TEST_SUPPLY = 1000 ether;
    string constant DEPLOYMENT_PATH = "./Deployments.json";

    address ownerOverride;

    function setOwnerOverride(address _address) external {
        require(block.chainid == 31337, "Can only be used in Local Test Environment");
        ownerOverride = _address;
    }

    function deployForTest(address owner) public returns (SelfmadeToken myToken, HelperConfig hConfig) {
        uint256 initialSupply = INITIAL_TEST_SUPPLY;
        vm.startPrank(owner);
        hConfig = new HelperConfig();
        myToken = new SelfmadeToken(initialSupply);
        vm.stopPrank();
    }

    function run() external returns (SelfmadeToken myToken, HelperConfig hConfig) {
        if (block.chainid == 1 && ownerOverride != address(0)) {
            revert DeploySelfMadeToken___OwnerOverrideIsDisabledOnMainnet();
        }

        address actualOwner = ownerOverride != address(0) ? ownerOverride : msg.sender; // will be usefull in test environtment for more controlled test checks!
        //setting the supply of the token
        uint256 initialSupply = block.chainid == 1 ? INITIAL_LIVE_SUPPLY : INITIAL_TEST_SUPPLY;

        //Read exiting deployments info if exists and if not then deploy
        string memory deployments = "{}";
        string memory chainIdStr = vm.toString(block.chainid);

        try vm.readFile(DEPLOYMENT_PATH) returns (string memory pathContent) {
            deployments = pathContent;
        } catch {
            console.log("No Deployments Found. Preparing  the Contract for Deployment");
        }

        //building the path keys
        string memory tokenPath = string.concat(".", chainIdStr, ".SelfmadeToken");
        string memory hConfigPath = string.concat(".", chainIdStr, ".HelperConfig");

        //check for mainnet deployment. It can only be deployed once in mainnet
        if (block.chainid == 1 && deployments.keyExists(tokenPath)) {
            console.log("SelfmadeToken Contract already deployed on mainnet, skipping deployment.");
            revert DeploySelfMadeToken___TokenContractAlreadyDeployedOnMainnet();
        }
        if (block.chainid == 1 && deployments.keyExists(hConfigPath)) {
            console.log(
                "HelperConfig Contract for the token contarct is already deployed on mainnet, skipping deployment."
            );
            revert DeploySelfMadeToken___HelperContractAlreadyDeployedOnMainnet();
        }

        // Broadcasting the Deployment
        console.log("Deploying the SelfmadeToken and HelperConfig contracts...");
        vm.startBroadcast(actualOwner);
        hConfig = new HelperConfig();
        myToken = new SelfmadeToken(initialSupply);
        vm.stopBroadcast();
        console.log("HelperConfig deployed at:", address(hConfig));
        console.log("SelfmadeToken deployed at:", address(myToken));
        console.log("Initial Supply is set at:", initialSupply);

        // Preapring the json entry deployment info to add the deployments in it, thus writing to the file

        string memory innerJsonOutput = vm.serializeAddress(chainIdStr, "HelperConfig", address(hConfig));
        innerJsonOutput = vm.serializeAddress(chainIdStr, "SelfmadeToken", address(myToken));
        // attaching the chain id with the innerjson
        string memory outerJsonOuput = vm.serializeString("root", chainIdStr, innerJsonOutput);
        if (!vm.envOr("CI", false) && block.chainid == 1) {
            vm.writeFile(DEPLOYMENT_PATH, outerJsonOuput);
        }
        console.log("Deployments written to file for chain ID:", chainIdStr);
        console.log("Deployment complete.");
        console.log(" JSON written to:", DEPLOYMENT_PATH);
    }
}
