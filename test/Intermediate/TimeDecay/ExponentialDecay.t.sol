// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {ExponentialDecay} from "src/Intermediate/TimeDecay/ExponentialDecay.sol";

contract ExponentialDecayTest is Test {
    ExponentialDecay timeDecay;
    uint256 public initialValue = 1000;
    uint256 public startTime;

    function setUp() public {
        timeDecay = new ExponentialDecay(initialValue);
        startTime = block.timestamp;
    }

    function testInitialValue() public view {
        uint256 decayedValue = timeDecay.getDecayedValue();
        assertEq(decayedValue, initialValue);
    }

    function testDecayAfter10Seconds() public {
        vm.warp(block.timestamp + 10);

        uint256 decayedValue = timeDecay.getDecayedValue();
        assertTrue(decayedValue < initialValue);
    }

    function testDecayAfterLongTime() public {
        vm.warp(block.timestamp + 1_000_000);

        uint256 decayedValue = timeDecay.getDecayedValue();

        assertApproxEqAbs(decayedValue, 0, 1);
    }
}
