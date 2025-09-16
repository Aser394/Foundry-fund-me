//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundme;
    address USER = makeAddr("user");  // testing new user
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARING_BALANCE = 10 ether;

    uint256 constant GAS_PRICE = 1;
    function setUp() external { 
       // fundme = new FundMe(0x694AA1769357215DE4FAC001bf1f309aDC325306);   //delpoy
        DeployFundMe deployFundMe = new DeployFundMe();
        fundme = deployFundMe.run();
        vm.deal(USER, STARING_BALANCE);  // user with 10 ether
    }

    function testMinimumDollarIsFive() public view {
        console.log(msg.sender);
        console.log(fundme.getOwner());
        assertEq(fundme.getOwner(),msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundme.getVersion();
        if(version == 4) {
            assertEq(version,4);
            }else{
            assertEq(version,6);   
        }
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert(); // the next line should revert
        fundme.fund{value:1e10}();  // has 0 value
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER);  // the next TX will be sent by USER
        fundme.fund{value: SEND_VALUE}();

        uint256 amountFunded = fundme.getAddressToAmountFunded(USER);
        assertEq(amountFunded,SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER); 
        fundme.fund{value: SEND_VALUE}();

        vm.prank(USER);
        address funder = fundme.getFunder(0);
        assertEq(funder,USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundme.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
    
        vm.expectRevert();  // next line for revert
        fundme.withdraw();  // check th withdraw 
    }

    function testWithdrawWithAsingleFunder() public funded {
        //Arange
        uint256 startingOwnerBalance = fundme.getOwner().balance; //owner
        uint256 startingFundmeBalance = address(fundme).balance; //funder
         
        //Act
        vm.prank(fundme.getOwner());
        fundme.withdraw();
             
        //Assert
        uint256 endingOwnerBalance = fundme.getOwner().balance;
        uint256 endingFundmeBalance = address(fundme).balance;
        assertEq(endingFundmeBalance,0);
        assertEq(startingFundmeBalance + startingOwnerBalance, endingOwnerBalance);
    }

    function testWithdrawWithAmultiFunder() public funded {
        //Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for(uint160 i = startingFunderIndex; i < numberOfFunders; i++){
            hoax(address(i), SEND_VALUE);
            fundme.fund{value: SEND_VALUE}();
        }

        uint256 startingFundmeBalance = fundme.getOwner().balance;
        uint256 startingOwnerBalance = address(fundme).balance;
        
        //Act
        uint256 startGas = gasleft(); //1000
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundme.getOwner()); //c: 200
        fundme.withdraw();

        uint256 endGas = gasleft(); //800
        uint256 gasTotal = (startGas - endGas) * tx.gasprice; 

        console.log(gasTotal);

        //Assert
        assert(address(fundme).balance == 0);
        assert(startingFundmeBalance + startingOwnerBalance == fundme.getOwner().balance);
    }

    function testCheaperWithdrawWithAmultiFunder() public {
        //Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for(uint160 i = startingFunderIndex; i < numberOfFunders; i++){
            hoax(address(i), SEND_VALUE);
            fundme.fund{value: SEND_VALUE}();
        }

        uint256 startingFundmeBalance = fundme.getOwner().balance;
        uint256 startingOwnerBalance = address(fundme).balance;
        
        //Act
        uint256 startGas = gasleft(); //1000
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundme.getOwner()); //c: 200
        fundme.CheaperWithdraw();

        uint256 endGas = gasleft(); //800
        uint256 gasTotal = (startGas - endGas) * tx.gasprice; 

        console.log(gasTotal);

        //Assert
        assert(address(fundme).balance == 0);
        assert(startingFundmeBalance + startingOwnerBalance == fundme.getOwner().balance);
    }
}