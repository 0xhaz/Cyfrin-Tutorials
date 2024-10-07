// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.25;

import { Test } from "forge-std/Test.sol";
import { DeployBox } from "script/DeployBox.s.sol";
import { UpgradeBox } from "script/UpgradeBox.s.sol";
import { BoxV1 } from "src/Intermediate/Advanced/UUPS/BoxV1.sol";
import { BoxV2 } from "src/Intermediate/Advanced/UUPS/BoxV2.sol";

contract DeployAndUpgradeTest is Test {
    DeployBox public deployer;
    UpgradeBox public upgrader;
    address public OWNER = makeAddr("owner");

    address public proxy;

    function setUp() public {
        deployer = new DeployBox();
        upgrader = new UpgradeBox();
        proxy = deployer.run();
    }

    function testProxyStartsAsBoxV1() public {
        vm.expectRevert();
        BoxV2(proxy).setNumber(4);
    }

    function testUpgrades() public {
        BoxV2 boxV2 = new BoxV2();

        upgrader.upgradeBox(proxy, address(boxV2));

        uint256 expectedValue = 1;
        assertEq(expectedValue, BoxV2(proxy).version());

        BoxV2(proxy).setNumber(42);
        assertEq(42, BoxV2(proxy).getNumber());
    }
}
