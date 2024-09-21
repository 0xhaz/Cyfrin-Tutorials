// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {DSCEngine, DecentralizedStableCoin} from "src/Intermediate/Advanced/Stablecoins/DSCEngine.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {DeployDSC, HelperConfig} from "script/DeployDSC.s.sol";

contract DSCEngineTest is Test {
    DeployDSC deployer;
    DecentralizedStableCoin dsc;
    DSCEngine dscEngine;
    HelperConfig config;
    address ethUsdPriceFeed;
    address weth;

    address public USER = makeAddr("user");
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 20 ether;

    function setUp() public {
        deployer = new DeployDSC();
        (dsc, dscEngine, config) = deployer.run();
        (ethUsdPriceFeed,, weth,,) = config.activeNetworkConfigDSC();

        ERC20Mock(weth).mint(USER, STARTING_ERC20_BALANCE);
    }

    /*//////////////////////////////////////////////////////////////
                            PRICE TESTS
    //////////////////////////////////////////////////////////////*/
    function testGetUsdcValue() public view {
        uint256 ethAmount = 15 ether;
        // 15 ETH * 2000 USD = 30000 USD
        uint256 expectedUsdValue = 30000e18;
        uint256 actualUsd = dscEngine.getUsdValue(weth, ethAmount);
        assertEq(expectedUsdValue, actualUsd);
    }

    /*//////////////////////////////////////////////////////////////
                           depositCollateral TESTS
    //////////////////////////////////////////////////////////////*/

    function testRevertsIfCollateralZero() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscEngine), AMOUNT_COLLATERAL);

        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        dscEngine.depositCollateral(weth, 0);
        vm.stopPrank();
    }
}
