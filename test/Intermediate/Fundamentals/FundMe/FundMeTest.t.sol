// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "src/Intermediate/Fundamentals/FundMe/FundMe.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    function setUp() external {
        fundMe = new FundMe();
    }

    function testMinimumrDollaIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }
}
