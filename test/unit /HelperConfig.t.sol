// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "script/helperConfig.s.sol";

error HelperConfigTest__UnsupportedChainIdForTest();

contract HelperConfigTest is Test {
    HelperConfig hConfig;

    address randomCaller = address(2);
    address deployer = address(1);
    address zeroAddress = address(0);

    event OwnershipSet(address indexed Owner);

    function setUp() public {
        vm.startPrank(deployer);
        hConfig = new HelperConfig();
        vm.stopPrank();
    }
    //////////////////////////////////////////////////////////////////
    ////////////////   constructor  tests   /////////////////////////
    /////////////////////////////////////////////////////////////////

    function testConstrctorSetsOwner() public view {
        assertEq(hConfig.i_owner(), deployer);
    }

    function testConstructorEmitsEvent() public {
        vm.expectEmit(true, false, false, false);
        emit OwnershipSet(deployer);
        vm.prank(deployer);
        new HelperConfig();
    }

    function testConstructorGetActiveNetworkConfig() public {
        (HelperConfig.NetworkChainName networkName, uint256 chainId) = hConfig.getCurrentNetworkInfo();
        assertEq(chainId, block.chainid);
        assertEq(uint256(networkName), uint256(HelperConfig.NetworkChainName.AnvilFoundry));
        // can write sepeated test for each id by forking and better to do that
        /*if (block.chainid == 11155111) {
            assertEq(uint256(networkName), uint256(HelperConfig.NetworkChainName.Sepolia));
        }
        if (block.chainid == 1) {
            assertEq(uint256(networkName), uint256(HelperConfig.NetworkChainName.Mainnet));
        } else {
            revert HelperConfigTest__UnsupportedChainIdForTest();
        }*/
    }

    // We will be concluding the HelperConfig.s.sol test here as we will be needing to write test for each diff chains, if need we can do the test but at the moemnt I don't see the need!
}
