// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// OpenZeppelin: standard ERC20 token implementation
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// OpenZeppelin: ownership control (only owner can call certain functions)
import "@openzeppelin/contracts/access/Ownable.sol";
// Chainlink: interface to read real-world price data on-chain
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/**
 * @title dTSLA
 * @author Aibar (NU'26)
 * @notice This contract tokenizes Tesla (TSLA) stock as an ERC20 token on Ethereum Sepolia
 * @dev Real World Asset (RWA) tokenization using Chainlink Price Feeds
 *
 * How it works:
 * 1. User deposits MockUSDC as collateral
 * 2. Contract fetches real TSLA price from Chainlink
 * 3. Contract mints dTSLA tokens proportional to deposited collateral
 * 4. User can burn dTSLA tokens to redeem their USDC back
 *
 * Collateral Ratio: 200% (overcollateralized for safety)
 * Example: To mint $100 worth of dTSLA, user must deposit $200 of USDC
 */
contract dTSLA is ERC20, Ownable {

    // ========================
    // STATE VARIABLES
    // ========================

    /// @notice Chainlink price feed for TSLA/USD on Sepolia
    AggregatorV3Interface internal tslaFeed;

    /// @notice Chainlink price feed for USDC/USD on Sepolia
    AggregatorV3Interface internal usdcUsdFeed;

    /// @notice Address of the USDC token used as collateral
    address public usdcToken;

    /// @notice Tracks how much USDC each user has deposited
    mapping(address => uint256) public usdcDeposited;

    // ========================
    // CONSTANTS
    // ========================

    /// @notice 200% collateral ratio - user must deposit 2x the value they want to mint
    uint256 public constant COLLATERAL_RATIO = 200;

    /// @notice Used to calculate percentage (divide by 100)
    uint256 public constant COLLATERAL_PRECISION = 100;

    /// @notice Standard precision for ERC20 tokens (18 decimals)
    uint256 public constant PRECISION = 1e18;

    /// @notice Chainlink price feeds return prices with 8 decimals
    uint256 public constant FEED_PRECISION = 1e8;

    // ========================
    // EVENTS
    // ========================

    /// @notice Emitted when a user mints dTSLA tokens
    event Minted(address indexed user, uint256 usdcDeposited, uint256 dTslaMinted);

    /// @notice Emitted when a user redeems dTSLA tokens for USDC
    event Redeemed(address indexed user, uint256 dTslaBurned, uint256 usdcReturned);

    // ========================
    // CONSTRUCTOR
    // ========================

    /**
     * @notice Initializes the dTSLA contract with price feeds and collateral token
     * @param _tslaFeed Address of the Chainlink TSLA/USD price feed on Sepolia
     * @param _usdcUsdFeed Address of the Chainlink USDC/USD price feed on Sepolia
     * @param _usdcToken Address of the USDC token contract used as collateral
     */
    constructor(
        address _tslaFeed,
        address _usdcUsdFeed,
        address _usdcToken
    ) ERC20("dTSLA", "dTSLA") Ownable(msg.sender) {
        tslaFeed = AggregatorV3Interface(_tslaFeed);
        usdcUsdFeed = AggregatorV3Interface(_usdcUsdFeed);
        usdcToken = _usdcToken;
    }

    // ========================
    // MAIN FUNCTIONS
    // ========================

    /**
     * @notice Deposit USDC and receive dTSLA tokens
     * @dev Uses Chainlink price feed to calculate how many dTSLA to mint
     * @param usdcAmount Amount of USDC to deposit (6 decimals, e.g. 1000000 = 1 USDC)
     *
     * Formula: dTSLA = (usdcAmount * 100) / (tslaPrice * 200)
     * Example: deposit $200 USDC, TSLA = $250 → mint 0.4 dTSLA
     */
    function mintDTsla(uint256 usdcAmount) external {
        // Step 1: Get current TSLA price from Chainlink (8 decimals)
        uint256 tslaPrice = getTslaPrice();

        // Step 2: Calculate dTSLA tokens to mint based on collateral ratio
        // With 200% ratio: user gets half the value they deposit
        uint256 dTslaToMint = (usdcAmount * COLLATERAL_PRECISION * PRECISION)
                              / (tslaPrice * COLLATERAL_RATIO * FEED_PRECISION);

        // Step 3: Pull USDC from user's wallet into this contract
        bool success = IERC20(usdcToken).transferFrom(msg.sender, address(this), usdcAmount);
        require(success, "USDC transfer failed");

        // Step 4: Record the deposit for later redemption
        usdcDeposited[msg.sender] += usdcAmount;

        // Step 5: Mint dTSLA tokens to the user
        _mint(msg.sender, dTslaToMint);

        emit Minted(msg.sender, usdcAmount, dTslaToMint);
    }

    /**
     * @notice Burn dTSLA tokens and get USDC collateral back
     * @dev Uses current TSLA price to calculate USDC to return
     * @param dTslaAmount Amount of dTSLA tokens to burn
     */
    function redeemDTsla(uint256 dTslaAmount) external {
        // Step 1: Get current TSLA price from Chainlink
        uint256 tslaPrice = getTslaPrice();

        // Step 2: Calculate how much USDC to return
        uint256 usdcToReturn = (dTslaAmount * tslaPrice * COLLATERAL_RATIO * FEED_PRECISION)
                               / (COLLATERAL_PRECISION * PRECISION);

        // Step 3: Ensure user has enough collateral recorded
        require(usdcDeposited[msg.sender] >= usdcToReturn, "Not enough collateral");

        // Step 4: Update user's deposit record
        usdcDeposited[msg.sender] -= usdcToReturn;

        // Step 5: Burn the dTSLA tokens
        _burn(msg.sender, dTslaAmount);

        // Step 6: Return USDC to the user
        bool success = IERC20(usdcToken).transfer(msg.sender, usdcToReturn);
        require(success, "USDC return failed");

        emit Redeemed(msg.sender, dTslaAmount, usdcToReturn);
    }

    // ========================
    // VIEW FUNCTIONS
    // ========================

    /**
     * @notice Fetches the latest TSLA/USD price from Chainlink
     * @return price Current TSLA price in USD with 8 decimals
     * Example: 25000000000 = $250.00
     */
    function getTslaPrice() public view returns (uint256) {
        (, int256 price,,,) = tslaFeed.latestRoundData();
        require(price > 0, "Invalid TSLA price");
        return uint256(price);
    }

    /**
     * @notice Fetches the latest USDC/USD price from Chainlink
     * @return price Current USDC price in USD with 8 decimals
     * Example: 100000000 = $1.00
     */
    function getUsdcPrice() public view returns (uint256) {
        (, int256 price,,,) = usdcUsdFeed.latestRoundData();
        require(price > 0, "Invalid USDC price");
        return uint256(price);
    }

    /**
     * @notice Returns total USDC deposited by a specific user
     * @param user Wallet address of the user
     * @return Total USDC deposited in 6 decimal format
     */
    function getTotalCollateralValue(address user) public view returns (uint256) {
        return usdcDeposited[user];
    }
}