// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/**
 * @title dTSLA
 * @notice Directly backed Tesla stock token on Ethereum Sepolia
 * @dev 1 dTSLA = 1 TSLA share worth of USDC collateral
 */
contract dTSLA is ERC20, Ownable {
    
    // Chainlink Price Feed addresses on Sepolia
    AggregatorV3Interface internal tslaFeed;
    AggregatorV3Interface internal usdcUsdFeed;

    // Collateral token (USDC on Sepolia)
    address public usdcToken;

    // How much USDC is deposited per user
    mapping(address => uint256) public usdcDeposited;

    // Minimum collateral ratio: 200% (overcollateralized for safety)
    uint256 public constant COLLATERAL_RATIO = 200;
    uint256 public constant COLLATERAL_PRECISION = 100;
    uint256 public constant PRECISION = 1e18;
    uint256 public constant FEED_PRECISION = 1e8;

    event Minted(address indexed user, uint256 usdcDeposited, uint256 dTslaMinted);
    event Redeemed(address indexed user, uint256 dTslaBurned, uint256 usdcReturned);

    constructor(
        address _tslaFeed,
        address _usdcUsdFeed,
        address _usdcToken
    ) ERC20("dTSLA", "dTSLA") Ownable(msg.sender) {
        tslaFeed = AggregatorV3Interface(_tslaFeed);
        usdcUsdFeed = AggregatorV3Interface(_usdcUsdFeed);
        usdcToken = _usdcToken;
    }

    /**
     * @notice Deposit USDC and mint dTSLA tokens
     * @param usdcAmount Amount of USDC to deposit (6 decimals)
     */
    function mintDTsla(uint256 usdcAmount) external {
        // Get current TSLA price in USD
        uint256 tslaPrice = getTslaPrice();

        // Calculate how many dTSLA tokens to mint
        // With 200% collateral ratio: dTSLA = (usdcAmount * 100) / (tslaPrice * 200)
        uint256 dTslaToMint = (usdcAmount * COLLATERAL_PRECISION * PRECISION) 
                              / (tslaPrice * COLLATERAL_RATIO * FEED_PRECISION);

        // Transfer USDC from user to contract
        bool success = IERC20(usdcToken).transferFrom(msg.sender, address(this), usdcAmount);
        require(success, "USDC transfer failed");

        // Record deposit
        usdcDeposited[msg.sender] += usdcAmount;

        // Mint dTSLA tokens to user
        _mint(msg.sender, dTslaToMint);

        emit Minted(msg.sender, usdcAmount, dTslaToMint);
    }

    /**
     * @notice Burn dTSLA tokens and redeem USDC collateral
     * @param dTslaAmount Amount of dTSLA to burn
     */
    function redeemDTsla(uint256 dTslaAmount) external {
        // Get current TSLA price
        uint256 tslaPrice = getTslaPrice();

        // Calculate USDC to return
        uint256 usdcToReturn = (dTslaAmount * tslaPrice * COLLATERAL_RATIO * FEED_PRECISION)
                               / (COLLATERAL_PRECISION * PRECISION);

        // Check user has enough deposited
        require(usdcDeposited[msg.sender] >= usdcToReturn, "Not enough collateral");

        // Update state
        usdcDeposited[msg.sender] -= usdcToReturn;

        // Burn dTSLA tokens
        _burn(msg.sender, dTslaAmount);

        // Return USDC to user
        bool success = IERC20(usdcToken).transfer(msg.sender, usdcToReturn);
        require(success, "USDC return failed");

        emit Redeemed(msg.sender, dTslaAmount, usdcToReturn);
    }

    /**
     * @notice Get latest TSLA price in USD (8 decimals)
     */
    function getTslaPrice() public view returns (uint256) {
        (, int256 price,,,) = tslaFeed.latestRoundData();
        require(price > 0, "Invalid TSLA price");
        return uint256(price);
    }

    /**
     * @notice Get latest USDC/USD price (8 decimals)
     */
    function getUsdcPrice() public view returns (uint256) {
        (, int256 price,,,) = usdcUsdFeed.latestRoundData();
        require(price > 0, "Invalid USDC price");
        return uint256(price);
    }

    /**
     * @notice Get total collateral value in USD
     */
    function getTotalCollateralValue(address user) public view returns (uint256) {
        return usdcDeposited[user];
    }
}