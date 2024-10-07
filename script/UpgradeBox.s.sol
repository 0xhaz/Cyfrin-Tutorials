// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.25;

import { Script, console } from "forge-std/Script.sol";
import { DevOpsTools } from "foundry-devops/src/DevOpsTools.sol";
import { BoxV2 } from "src/Intermediate/Advanced/UUPS/BoxV2.sol";
import { BoxV1 } from "src/Intermediate/Advanced/UUPS/BoxV1.sol";

contract UpgradeBox is Script {
    function run() external returns (address) {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("ERC1967Proxy", block.chainid);

        vm.startBroadcast();

        BoxV2 newBox = new BoxV2();

        vm.stopBroadcast();

        address proxy = upgradeBox(mostRecentlyDeployed, address(newBox));
        return proxy;
    }

    function upgradeBox(address proxyAddress, address newBox) public returns (address) {
        vm.startBroadcast();
        BoxV1 proxy = BoxV1(proxyAddress);
        proxy.upgradeToAndCall(address(newBox), "");
        vm.stopBroadcast();
        return address(proxy);
    }
}
