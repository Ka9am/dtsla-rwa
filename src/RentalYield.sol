// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./PropertyToken.sol";

/**
 * @title RentalYield
 * @notice Distributes rental income (ETH) to property token holders.
 * Admin deposits ETH representing rental income.
 * Token holders claim their share proportional to how many tokens they hold.
 * Example: hold 10% of tokens = claim 10% of the deposited yield.
 */
contract RentalYield is Ownable, ReentrancyGuard {

    // The property token we are distributing yield for
    PropertyToken public immutable propertyToken;

    // Total ETH deposited as yield so far (keeps growing)
    uint256 public totalYieldDeposited;

    // Tracks how much yield per token has been accumulated at the global level
    // Multiplied by 1e18 to avoid precision loss with integer division
    uint256 public yieldPerTokenStored;

    // Tracks the yieldPerToken value at the time each user last claimed
    mapping(address => uint256) public userYieldPerTokenPaid;

    // Tracks pending (unclaimed) yield for each user in wei
    mapping(address => uint256) public pendingYield;

    // Events
    event YieldDeposited(uint256 amount, uint256 newYieldPerToken);
    event YieldClaimed(address indexed investor, uint256 amount);

    constructor(address _propertyToken) Ownable(msg.sender) {
        propertyToken = PropertyToken(_propertyToken);
    }

    /**
     * @notice Admin deposits ETH as rental yield.
     * The yield is split proportionally across all token holders.
     */
    function depositYield() external payable onlyOwner {
        require(msg.value > 0, "Must deposit some ETH");
        require(propertyToken.totalSupply() > 0, "No token holders yet");

        // Calculate how much yield each token earns from this deposit
        // Multiply by 1e18 first to preserve precision
        // Example: deposit 1 ETH, 1000 tokens exist
        // yieldPerToken increase = (1e18 * 1e18) / 1000 = 1e33 / 1000
        yieldPerTokenStored += (msg.value * 1e18) / propertyToken.totalSupply();

        totalYieldDeposited += msg.value;

        emit YieldDeposited(msg.value, yieldPerTokenStored);
    }

    /**
     * @notice Calculates how much ETH a given investor can claim right now.
     * Formula: (tokens held) * (yield per token since last claim) / 1e18
     */
    function calculatePendingYield(address investor) public view returns (uint256) {
        uint256 tokenBalance = propertyToken.balanceOf(investor);

        // How much yield per token has accumulated since this user last claimed
        uint256 yieldPerTokenDelta = yieldPerTokenStored - userYieldPerTokenPaid[investor];

        // Their share = balance * delta / 1e18
        uint256 newYield = (tokenBalance * yieldPerTokenDelta) / 1e18;

        // Add any previously accumulated but unclaimed yield
        return pendingYield[investor] + newYield;
    }

    /**
     * @notice Investor calls this to receive their accumulated yield in ETH.
     */
    function claimYield() external nonReentrant {
        // First update their pending yield before sending anything
        _updateYield(msg.sender);

        uint256 amount = pendingYield[msg.sender];
        require(amount > 0, "No yield to claim");

        // Reset pending yield before transfer (prevents reentrancy)
        pendingYield[msg.sender] = 0;

        // Send ETH to the investor
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "ETH transfer failed");

        emit YieldClaimed(msg.sender, amount);
    }

    /**
     * @notice Updates a user's pending yield to the current state.
     * Must be called before any claim to get accurate numbers.
     */
    function _updateYield(address investor) internal {
        // Calculate new yield earned since last update
        uint256 tokenBalance = propertyToken.balanceOf(investor);
        uint256 yieldPerTokenDelta = yieldPerTokenStored - userYieldPerTokenPaid[investor];
        uint256 newYield = (tokenBalance * yieldPerTokenDelta) / 1e18;

        // Add to their pending balance
        pendingYield[investor] += newYield;

        // Mark them as up to date
        userYieldPerTokenPaid[investor] = yieldPerTokenStored;
    }

    /**
     * @notice Returns the total ETH sitting in this contract available for claims.
     */
    function contractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}