// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {DSCEngine} from "src/Intermediate/Advanced/Stablecoins/DSCEngine.sol";
import {DecentralizedStableCoin} from "src/Intermediate/Advanced/Stablecoins/DecentralizedStableCoin.sol";

import {HelperConfig} from "script/HelperConfig.s.sol";

contract DeployDSC is Script {
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    function run() external returns (DecentralizedStableCoin, DSCEngine, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();

        (address wethUsdPriceFeed, address wbtcUsdPriceFeed, address weth, address wbtc, uint256 deployerKey) =
            helperConfig.activeNetworkConfigDSC();

        tokenAddresses = [weth, wbtc];
        priceFeedAddresses = [wethUsdPriceFeed, wbtcUsdPriceFeed];

        vm.startBroadcast();
        DecentralizedStableCoin dsc = new DecentralizedStableCoin();
        DSCEngine dscEngine = new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));

        dsc.transferOwnership(address(dscEngine));

        vm.stopBroadcast();

        return (dsc, dscEngine, helperConfig);
    }
}
