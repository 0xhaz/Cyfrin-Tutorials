// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.25;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title DSC Engine
 * @dev This contract is designed to be as minimal as possible and have the tokens mantain a 1 token to 1 USD ratio.
 *  The stable coin has the properties
 * - Exogenous Collateral
 * - Dollar Pegged
 * - Algorithmic Stable
 * It is similar to DAI if DAI had no governance, no fees and was ony backed by WETH and WBTC.
 *
 * Our DSC system should always be "overcollateralized". At no point, should the value of all collateral be less than the value of all DSC.
 *
 * @notice This contract is the the core of the DSC system. It handles all the logic for mining
 * and redeeming DSC, as well as depositing & withdrawing collateral.
 * @notice This contract is VERY loosely based on the MakerDAO DSS (Dai Stablecoin System) system.
 */
contract DSCEngine is ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error DSCEngine__NeedsMoreThanZero();
    error DSCEngine__TokenAddressesAndPriceAddressesMustBeSameLength();
    error DSCEngine__NotAllowedToken();
    error DSCEngine__TransferFailed();

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    uint256 private constant ADDITIONAL_FEE_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;

    mapping(address token => address priceFeed) private s_priceFeeds;
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited;
    mapping(address user => uint256 amountDscMinted) private s_DSCMinted;

    address[] private s_collateralTokens;

    DecentralizedStableCoin private immutable i_dsc;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert DSCEngine__NeedsMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (s_priceFeeds[token] == address(0)) {
            revert DSCEngine__NotAllowedToken();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddresses, address dscAddress) {
        uint256 tokenLen = tokenAddresses.length;
        uint256 priceFeedLen = priceFeedAddresses.length;

        // USD Price Feeds
        if (tokenLen != priceFeedLen) {
            revert DSCEngine__TokenAddressesAndPriceAddressesMustBeSameLength();
        }

        for (uint256 i; i < tokenLen; ++i) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
            s_collateralTokens.push(tokenAddresses[i]);
        }

        i_dsc = DecentralizedStableCoin(dscAddress);
    }

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function depositCollateralAndMintDsc() external {}

    /**
     * @notice Deposit collateral to mint DSC
     * @param tokenCollateralAddress  The address of the token to be deposited as collateral
     * @param amountCollateral The amount of collateral to be deposited
     */
    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        external
        moreThanZero(amountCollateral)
        isAllowedToken(tokenCollateralAddress)
        nonReentrant
    {
        s_collateralDeposited[msg.sender][tokenCollateralAddress] += amountCollateral;
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
    }

    function redeemCollateralForDsc() external {}

    function redeemCollateral() external {}

    /**
     * @notice Mint DSC
     * @param amountDscToMint The amount of DSC to mint
     * @notice they must have more collateral value than the minimum threshold
     */
    function mintDsc(uint256 amountDscToMint) external moreThanZero(amountDscToMint) nonReentrant {
        s_DSCMinted[msg.sender] += amountDscToMint;
        // if they minted too much
        _revertIfHealthFactorIsBroken(msg.sender);
        i_dsc.mint(msg.sender, amountDscToMint);
    }

    function burnDsc() external {}

    function liquidate() external {}

    function getHealthFactor() external view {}

    /*//////////////////////////////////////////////////////////////
                    INTERNAL & PRIVATE VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function _getAccountInformation(address user)
        private
        view
        returns (uint256 totalDscMinted, uint256 collateralValueInUsd)
    {
        totalDscMinted = s_DSCMinted[user];
        collateralValueInUsd = getAccountCollateralValue(user);
    }

    /**
     * @notice Return how close to liquiditation the user is
     * @notice If the health factor is below 1, the user is insolvent
     * @param user The address of the user
     */
    function _healthFactor(address user) private view returns (uint256) {
        // total DSC minted
        // total collateral value
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = _getAccountInformation(user);
    }

    function _revertIfHealthFactorIsBroken(address user) internal view {
        // 1. Check health factor
        // 2. Revert if health factor is broken
    }

    /*//////////////////////////////////////////////////////////////
                    PUBLIC & EXTERNAL VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function getAccountCollateralValue(address user) public view returns (uint256 totalCollateralValueInUsd) {
        // loop through all the collateral, get the amount of deposited collateral
        // and map it to the price to get the USD value
        uint256 collateralTokenslen = s_collateralTokens.length;

        for (uint256 i; i < collateralTokenslen; ++i) {
            address token = s_collateralTokens[i];
            uint256 amount = s_collateralDeposited[user][token];
            totalCollateralValueInUsd += getUsdValue(token, amount);
        }

        return totalCollateralValueInUsd;
    }

    function getUsdValue(address token, uint256 amount) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (, int256 price,,,) = priceFeed.latestRoundData();
        return ((uint256(price) * ADDITIONAL_FEE_PRECISION) * amount) / PRECISION;
    }
}
