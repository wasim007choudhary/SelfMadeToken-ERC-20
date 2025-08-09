//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {DeploySelfMadeToken} from "script/deploy.s.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {HelperConfig} from "script/helperConfig.s.sol";
import {SelfmadeToken} from "src/SelfToken.sol";

contract SelfMadeTokenTest is Test {
    SelfmadeToken smToken;
    HelperConfig configHelper;

    uint256 constant USER_BALANCE = 100 ether;
    address user = makeAddr("user");

    address deployer = makeAddr("deployer");

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function setUp() public {
        DeploySelfMadeToken deployScript = new DeploySelfMadeToken();
        deployScript.setOwnerOverride(deployer);
        (smToken, configHelper) = deployScript.deployForTest(deployer);

        vm.deal(user, USER_BALANCE);
    }

    //////////////////////////////////////////////////////////////////
    ////////////////   Constructor and deploy tests   ////////////////
    /////////////////////////////////////////////////////////////////

    function testBasicDeployIsCorrect() public view {
        assert(address(smToken) != address(0));
        console.log("Owner", smToken.i_owner());
        console.log("deployer", deployer);
        assertTrue(smToken.i_owner() == deployer);
        console.log("SUPPLY", smToken.totalSupply());
        assertTrue(smToken.totalSupply() == 1000 ether);
    }

    function testDeployerOwnsInitialSupply() public view {
        assertEq(smToken.balanceOf(deployer), smToken.totalSupply());
    }

    function testBasicTokenContractFunctions() public view {
        assertEq(smToken.name(), "SelfMade Token");
        assertEq(smToken.symbol(), "$MT");
        assertEq(smToken.decimals(), 18);
    }

    function testOwnerBalanceAfterDeploymet() public view {
        uint256 expectedBalance = 1000 ether;
        uint256 actualBalance = smToken.balanceOf(deployer);
        assertEq(actualBalance, expectedBalance);
    }

    // event test inside constructor\\

    function testEventTransferInContructor() public {
        address expectedOwner = deployer;
        uint256 initialSupply = 1000 ether;

        assertEq(smToken.s_balance(deployer), 1000 ether);

        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), expectedOwner, initialSupply);
        vm.prank(expectedOwner);
        new SelfmadeToken(initialSupply);
    }

    //////////////////////////////////////////////////////////////////
    //////////////////   balanceOf function  ////////////////////////
    /////////////////////////////////////////////////////////////////

    //  zero balance for user who hasn't received any $MT tokens
    function testBalanceOfFunction() public view {
        uint256 actualBalance = smToken.balanceOf(user);
        console.log("actualBalance:", actualBalance);
        uint256 expectedBalance = 0 ether;
        assertEq(actualBalance, expectedBalance);
    }

    //blance of Zero address should be zero
    function testBalanceOfZeroAddress() public view {
        uint256 expectedBalance = 0 ether;
        uint256 actualBalance = smToken.balanceOf(address(0));
        assertEq(expectedBalance, actualBalance);
    }

    //////////////////////////////////////////////////////////////////
    //////////////////   allowance function  ////////////////////////
    /////////////////////////////////////////////////////////////////

    function testAllowanceFunction() public view {
        address spender = user;
        address owner = deployer;

        uint256 expectedAllowance = 0 ether;
        uint256 actualAllowance = smToken.allowance(owner, spender);
        assertEq(actualAllowance, expectedAllowance);
    }

    //////////////////////////////////////////////////////////////////
    //////////////////   transfer function  /////////////////////////
    /////////////////////////////////////////////////////////////////
    function testTransferFunctionRevertIfAmountSentGreaterThanBalance() public {
        uint256 amountToSend = 1001 ether;
        address to = user;

        vm.expectRevert(SelfmadeToken.SelfmadeToken___transfer_NotEnoughBalance.selector);
        vm.prank(deployer);
        smToken.transfer(to, amountToSend);
    }

    function testTransferFunctionAfterTransferBalance() public {
        uint256 amount = 100 ether;

        uint256 deployerBalanceBeforeTransfer = smToken.balanceOf(deployer);
        uint256 userBalanceBeforeTransfer = smToken.balanceOf(user);
        vm.prank(deployer);
        bool success = smToken.transfer(user, amount);
        uint256 deployerBalanceAfterTransfer = smToken.balanceOf(deployer);
        uint256 userBalanceAfterTransfer = smToken.balanceOf(user);
        assertTrue(success);
        assertEq(deployerBalanceBeforeTransfer, deployerBalanceAfterTransfer + amount);
        assertEq(userBalanceAfterTransfer, userBalanceBeforeTransfer + amount);
    }

    function testTransferFunctionEmitsTransferEventAfterTransfer() public {
        uint256 amount = 10 ether;
        vm.expectEmit(true, true, false, true);
        emit Transfer(deployer, user, amount);
        vm.prank(deployer);
        smToken.transfer(user, amount);
    }

    //////////////////////////////////////////////////////////////////
    //////////////////   approve function  ///////////////////////////
    /////////////////////////////////////////////////////////////////
    function testApproveFunctionWillRevertIfSpenderIsZeroAddress() public {
        address spender = address(0);
        uint256 amount = 10 ether;

        vm.expectRevert(SelfmadeToken.SelfmadeToken___approve_ApproveToZeroAddressNotAllowed.selector);
        vm.prank(deployer);
        smToken.approve(spender, amount);
    }

    function testApproveFunctionAfterValidapproval() public {
        address spender = user;
        uint256 approveAmount = 10 ether;
        uint256 totalSupplyBeforeApproval = smToken.totalSupply();
        uint256 balanceOfuser = smToken.balanceOf(user);
        uint256 balanceOfDeployer = smToken.balanceOf(deployer);

        vm.prank(deployer);
        bool success = smToken.approve(spender, approveAmount);

        uint256 allowanceAmount = smToken.allowance(deployer, spender);

        uint256 totalSupplyAfterApproval = smToken.totalSupply();
        uint256 balanceOfuserAfter = smToken.balanceOf(user);
        uint256 balanceOfDeployerAfter = smToken.balanceOf(deployer);

        assertTrue(success);
        assertEq(allowanceAmount, approveAmount);
        assertEq(totalSupplyBeforeApproval, totalSupplyAfterApproval);
        assertEq(balanceOfuser, balanceOfuserAfter);
        assertEq(balanceOfDeployer, balanceOfDeployerAfter);
    }

    function testApproveFunctionEmitsEventsAfterApprove() public {
        uint256 approveAmount = 10 ether;
        vm.expectEmit(true, true, false, true);
        emit Approval(deployer, user, approveAmount);
        vm.prank(deployer);
        smToken.approve(user, approveAmount);
    }

    //////////////////////////////////////////////////////////////////
    //////////////////   safeApprove function  ///////////////////////
    //////////////////////////////////////////////////////////////////
    function testSafeApproveFunctionWillRevertIfNotCurrentAllowance() public {
        uint256 currentAllowance = 10 ether;
        uint256 falseCurrentAllowance = 5 ether;
        uint256 newAllowance = 20 ether;
        address spender = user;
        vm.prank(deployer);
        smToken.approve(spender, currentAllowance);

        vm.prank(deployer);
        vm.expectRevert(SelfmadeToken.SelfmadeToken___safeApprove_CurrentAllowanceNotMatching.selector);
        smToken.safeApprove(spender, falseCurrentAllowance, newAllowance);
    }

    function testSafeApproveFunctionWithCorrectCurrentAllowance() public {
        uint256 currentAllowance = 1 ether;
        uint256 newAllowance = 2 ether;
        address spender = user;
        vm.prank(deployer);
        bool successInApprove = smToken.approve(spender, currentAllowance);
        assertTrue(successInApprove);
        vm.prank(deployer);
        bool successInSafeApprove = smToken.safeApprove(spender, currentAllowance, newAllowance);
        assertTrue(successInSafeApprove);
        assertEq(smToken.allowance(deployer, spender), newAllowance);
    }

    function testSafeApproveFunctionEmitsApprovalEvent() public {
        uint256 currentAllowance = 4 ether;
        uint256 newAllowance = 3 ether;
        address spender = user;
        vm.prank(deployer);
        smToken.approve(spender, currentAllowance);
        vm.expectEmit(true, true, false, true);
        emit Approval(deployer, spender, newAllowance);
        vm.prank(deployer);
        smToken.safeApprove(spender, currentAllowance, newAllowance);
    }

    ///////////////////////////////////////////////////////////////////
    //////////////////   transferFrom function  ///////////////////////
    ///////////////////////////////////////////////////////////////////
    function testTransferFromWillRevertIfAmountGreaterThanSenderBalance() public {
        address tokenOwner = deployer; // the account from which tokens will be transfered from
        address tokenRecepient = address(3); // address account which will receive the  transfered tokens
        address spender = user; // the spender who will call the function
        uint256 amountApprovedForTransfer = 10001 ether;

        vm.prank(tokenOwner);
        smToken.approve(spender, amountApprovedForTransfer);

        vm.expectRevert(SelfmadeToken.SelfmadeToken___transferFrom_NotEnoughBalance.selector);
        vm.prank(spender);
        smToken.transferFrom(tokenOwner, tokenRecepient, amountApprovedForTransfer);
    }

    function testTransferFromWillRevertIfTransferAmountGreaterThanAllowance() public {
        address tokenOwner = deployer; // the account from which tokens will be transfered from
        address tokenRecepient = address(3); // address account which will receive the  transfered tokens
        address spender = user; // the spender who will call the function

        uint256 approvedAmount = 20 ether;
        uint256 transferAmount = 30 ether;

        vm.prank(tokenOwner);
        smToken.approve(spender, approvedAmount);

        vm.expectRevert(SelfmadeToken.SelfmadeToken___transferFrom_AllowanceNotEnough.selector);
        vm.prank(spender);
        smToken.transferFrom(tokenOwner, tokenRecepient, transferAmount);
    }

    function testTransferFromIfDoesnotRevert() public {
        address tokenOwner = deployer; // the account from which tokens will be transfered from
        address tokenRecepient = address(3); // address account which will receive the  transfered tokens
        address spender = user; // the spender who will call the function

        uint256 amountApprovedForTransfer = 50 ether;

        vm.prank(tokenOwner);
        smToken.approve(spender, amountApprovedForTransfer);
        console.log("allowance check ", smToken.allowance(tokenOwner, spender));

        vm.prank(spender);
        bool success = smToken.transferFrom(tokenOwner, tokenRecepient, amountApprovedForTransfer);
        console.log("allowance check after transfer ", smToken.allowance(tokenOwner, spender));
        assertTrue(success);
        assertEq(smToken.balanceOf(tokenOwner), smToken.totalSupply() - amountApprovedForTransfer);
        assertEq(smToken.balanceOf(tokenRecepient), amountApprovedForTransfer);
        assertEq(smToken.allowance(tokenOwner, spender), 0);
    }

    function testTransferFromEmitsTransferEvent() public {
        address tokenOwner = deployer; // the account from which tokens will be transfered from
        address tokenRecepient = address(3); // address account which will receive the  transfered tokens
        address spender = user; // the spender who will call the function

        uint256 amountApprovedForTransfer = 50 ether;
        vm.prank(tokenOwner);
        smToken.approve(spender, amountApprovedForTransfer);
        vm.expectEmit(true, true, false, true);
        emit Transfer(tokenOwner, tokenRecepient, amountApprovedForTransfer);
        vm.prank(spender);
        smToken.transferFrom(tokenOwner, tokenRecepient, amountApprovedForTransfer);
    }

    ///////////////////////////////////////////////////////////////////
    //////////////////   increaseAllowance function   /////////////////
    ///////////////////////////////////////////////////////////////////

    function testIncreaseAllowanceCompleteScenarios() public {
        address spender = user;
        //1st scene

        uint256 increaseAllowanceAmount = 1000 ether;
        uint256 allowanceAmount = 10 ether;
        vm.prank(deployer);
        smToken.approve(spender, allowanceAmount);
        uint256 firstCurrentAllowance = smToken.allowance(deployer, spender);
        console.log(firstCurrentAllowance);
        vm.expectEmit(true, true, false, true);
        emit Approval(deployer, spender, firstCurrentAllowance + increaseAllowanceAmount);
        vm.prank(deployer);
        smToken.increaseAllowance(spender, increaseAllowanceAmount, firstCurrentAllowance);
        assertEq(firstCurrentAllowance + increaseAllowanceAmount, smToken.allowance(deployer, spender));

        //2nd Scene

        uint256 increasSecondAllowance = 0 ether;
        uint256 secondAllowance = 0 ether;
        vm.prank(spender);
        smToken.approve(deployer, secondAllowance);
        uint256 secondCurrentAllowance = smToken.allowance(spender, deployer);
        vm.expectEmit(true, true, false, true);
        emit Approval(spender, deployer, secondCurrentAllowance + increasSecondAllowance);
        vm.prank(spender);
        smToken.increaseAllowance(deployer, increasSecondAllowance, secondCurrentAllowance);
        assertEq(smToken.allowance(spender, deployer), secondCurrentAllowance + increasSecondAllowance);
        // assertEq(smToken.allowance(spender, deployer), 0);

        //3rd Scene
        uint256 thirdIncreaseAllowance = 5 ether;
        vm.prank(deployer);
        //smToken.approve(spender, thirdIncreaseAllowance);
        uint256 thirdCurrentAllowance = smToken.allowance(deployer, spender);
        console.log("third current ", thirdCurrentAllowance);
        vm.expectEmit(true, true, false, true);
        emit Approval(deployer, spender, thirdCurrentAllowance + thirdIncreaseAllowance);
        vm.prank(deployer);
        smToken.increaseAllowance(spender, thirdIncreaseAllowance, thirdCurrentAllowance);

        assertEq(smToken.allowance(deployer, spender), thirdIncreaseAllowance + thirdCurrentAllowance);

        // the revert scene
        uint256 wrongExpectedCurrent = 7 ether;
        uint256 increaseAllowance = 30 ether;
        vm.prank(deployer);
        uint256 legitCurrentAllowance = smToken.allowance(deployer, spender);
        console.log("Legit current Allowance : ", legitCurrentAllowance);
        vm.expectRevert(SelfmadeToken.SelfmadeToken___increaseAllowance_AllowanceChangedUnexpectedly.selector);
        vm.prank(deployer);
        smToken.increaseAllowance(spender, increaseAllowance, wrongExpectedCurrent);
    }

    ///////////////////////////////////////////////////////////////////
    //////////////////   decreaseAllowance function   /////////////////
    ///////////////////////////////////////////////////////////////////

    function testDecreaseAllowanceRevertsIfCurrentDoesNotMatchExpected() public {
        address spender = user;
        uint256 initialAllowance = 100 ether;
        uint256 decreaseAmount = 5 ether;
        uint256 wrongExpectedAllowance = 90 ether; // should be 100 ether, but intentionally wrong

        // Arrange: approve spender
        vm.prank(deployer);
        smToken.approve(spender, initialAllowance);

        uint256 currentAllowance = smToken.allowance(deployer, spender);
        console.log("Current Allowance:", currentAllowance);

        // Act & Assert: expect revert due to allowance mismatch
        vm.expectRevert(SelfmadeToken.SelfmadeToken___decreaseAllowance_AllowanceChangedUnexpectedly.selector);
        vm.prank(deployer);
        smToken.decreaseAllowance(spender, decreaseAmount, wrongExpectedAllowance);
    }

    function testRevertIfDecreaseExceedsAllowance() public {
        address spender = user;
        uint256 allowance = 10 ether;
        uint256 decreaseAllowance = 11 ether;
        vm.prank(deployer);
        smToken.approve(spender, allowance);
        uint256 currentAllowance = smToken.allowance(deployer, spender);
        assertEq(currentAllowance, allowance);
        vm.expectRevert(SelfmadeToken.SelfmadeToken___decreaseAllowance_AllowanceDecreasedBelowZero.selector);
        vm.prank(deployer);
        smToken.decreaseAllowance(spender, decreaseAllowance, currentAllowance);
    }

    function testDecreaseAllowanceSucceedsWhenExpectedMatches() public {
        vm.prank(deployer);
        smToken.approve(user, 100 ether);
        vm.prank(deployer);
        bool success = smToken.decreaseAllowance(user, 40 ether, 100 ether);
        uint256 currentAllowance = smToken.allowance(deployer, user);
        console.log(currentAllowance);
        uint256 expectedCurrentAllowance = 100 ether - 40 ether;
        console.log(expectedCurrentAllowance);
        assertTrue(success);
        assertEq(currentAllowance, expectedCurrentAllowance);
    }

    function testDecreaseAllowanceFunctionFullCall() public {
        address spender = user;
        uint256 decreaseAllowance = 5 ether;
        uint256 approvedAllowance = 6 ether;
        vm.prank(deployer);
        smToken.approve(spender, approvedAllowance);
        uint256 currentAllowance = smToken.allowance(deployer, spender);
        vm.expectEmit(true, true, false, true);
        emit Approval(deployer, spender, currentAllowance - decreaseAllowance);
        vm.prank(deployer);
        bool success = smToken.decreaseAllowance(spender, decreaseAllowance, currentAllowance);
        console.log("Current Allowance After Decrease : ", smToken.allowance(deployer, spender));
        assertTrue(success);
    }

    ///////////////////////////////////////////////////////////////////
    //////////////////////      mint function     /////////////////////
    ///////////////////////////////////////////////////////////////////

    function testMintFunctionOnlyOwnerRevertCheck() public {
        address recipient = address(3);
        uint256 mintAmount = 10 ether;
        vm.expectRevert(SelfmadeToken.SelfmadeToken___mint_NotOwner.selector);
        vm.prank(user);
        smToken.mint(recipient, mintAmount);
    }

    function testMintFunctionRevertsIfZeroAmountMint() public {
        uint256 mintAmount = 0 ether;
        vm.expectRevert(SelfmadeToken.SelfmadeToken___mint_MintAmountCannotBeZero.selector);
        vm.prank(deployer);
        smToken.mint(user, mintAmount);
    }

    function testMintFunctionRevertsIfSentToZeroAddress() public {
        address zeroAddress = address(0);
        uint256 mintAmount = 5 ether;
        vm.expectRevert(SelfmadeToken.SelfmadeToken___mint_ToZeroAddressNotAllowed.selector);
        vm.prank(deployer);
        smToken.mint(zeroAddress, mintAmount);
    }

    function testMintFunctionIfCalledByOnlyOwner() public {
        // address recipient = address(3);
        uint256 mintAmount = 10 ether;
        //console.log("balance of the deployer:", smToken.balanceOf(deployer));
        // uint256 totalSupplyBefore = smToken.totalSupply();
        uint256 deployerBlanceBefore = smToken.balanceOf(deployer);
        vm.startPrank(deployer);
        bool firstSuccess = smToken.mint(user, mintAmount);
        uint256 balanceAfterFirstMint = smToken.totalSupply();
        bool secondSuccess = smToken.mint(deployer, mintAmount);
        vm.stopPrank();
        uint256 totalSupplyAfter = smToken.totalSupply();
        assertTrue(firstSuccess);
        assertTrue(secondSuccess);
        assertEq(smToken.balanceOf(user), mintAmount);
        assertEq(smToken.balanceOf(deployer), deployerBlanceBefore + mintAmount);
        assertEq(totalSupplyAfter, balanceAfterFirstMint + mintAmount);
    }

    function testMintFunctionEmitsEvent() public {
        uint256 mintAmount = 5 ether;
        address recipient = user;
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), recipient, mintAmount);
        vm.prank(deployer);
        smToken.mint(recipient, mintAmount);
    }

    ///////////////////////////////////////////////////////////////////
    //////////////////////      burn function     /////////////////////
    ///////////////////////////////////////////////////////////////////

    function testBurnFunctionRevertsIfBurnAmountIsZero() public {
        uint256 burnAmount = 0 ether;
        vm.prank(deployer);
        smToken.transfer(user, 5 ether);
        // uint256 userBalance = smToken.balanceOf(user);
        vm.expectRevert(SelfmadeToken.SelfmadeToken___burn_BurnAmountCannotBeZero.selector);
        vm.prank(user);
        //console.log("User Balance After the transfer :-", userBalance);
        smToken.burn(burnAmount);
    }

    function testBurnFunctionRevertsIfBurnAmountGreaterThanUserBalance() public {
        // uint256 burnAmount = 0 ether;
        vm.prank(deployer);
        smToken.transfer(user, 5 ether);
        uint256 userBalance = smToken.balanceOf(user);
        vm.expectRevert(SelfmadeToken.SelfmadeToken___burn_BurnAmountExceedsBalance.selector);
        vm.prank(user);
        console.log("User balance :- ", userBalance);
        smToken.burn(10 ether);
    }

    function testBurnFunctionOwnerCaseRevertsIfBurnAmountGreaterThanBalance() public {
        uint256 burnAmount = smToken.balanceOf(deployer) + 1 ether;
        console.log("Burn amount is :-", burnAmount);
        uint256 balanceDeployer = smToken.balanceOf(deployer);
        // console.log("Owner/deployer balance :- ", smToken.balanceOf(deployer));
        vm.expectRevert(SelfmadeToken.SelfmadeToken___burn_BurnAmountExceedsBalance.selector);
        vm.prank(deployer);
        console.log("Owner/deployer balance :- ", balanceDeployer);
        smToken.burn(burnAmount);
    }

    function testBurnFunctionOnSuccessfullCall() public {
        uint256 burnAmount = 5 ether;
        uint256 balanceBeforeBurn = smToken.balanceOf(deployer);
        uint256 totalSupplyBeforeBurn = smToken.totalSupply();

        vm.expectEmit(true, true, false, true);
        emit Transfer(deployer, address(0), burnAmount);
        vm.prank(deployer);
        bool success = smToken.burn(burnAmount);
        uint256 balanceAfterBurn = smToken.balanceOf(deployer);
        uint256 totalSupplyAfterBurn = smToken.totalSupply();

        assertTrue(success);
        assertEq(balanceBeforeBurn - burnAmount, balanceAfterBurn);
        assertEq(totalSupplyBeforeBurn - burnAmount, totalSupplyAfterBurn);
    }
}
