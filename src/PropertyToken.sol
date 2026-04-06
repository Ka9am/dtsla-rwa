// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title PropertyToken
 * @notice ERC-20 token representing fractional ownership of a real estate property.
 * Each token = 1 share of the property. Students buy tokens to become fractional owners.
 */
contract PropertyToken is ERC20, Ownable {
    // Maximum number of tokens that can ever exist (= total property shares)
    uint256 public immutable maxSupply;

    // Price of one token in ETH (set at deployment, cannot change)
    uint256 public immutable tokenPrice;

    // Address that receives the raised ETH (the property owner/admin)
    address public immutable treasury;

    // Tracks whether the property is still open for investment
    bool public fundingOpen;

    // Events — emitted when something important happens on-chain
    event TokensPurchased(address indexed buyer, uint256 amount, uint256 ethPaid);
    event FundingClosed();

    constructor(
        string memory name,        // e.g. "Almaty Apartment Token"
        string memory symbol,      // e.g. "AAT"
        uint256 _maxSupply,        // e.g. 1000 tokens = 1000 shares
        uint256 _tokenPrice,       // e.g. 0.01 ETH per token
        address _treasury          // wallet that receives the ETH
    ) ERC20(name, symbol) Ownable(msg.sender) {
        maxSupply = _maxSupply;
        tokenPrice = _tokenPrice;
        treasury = _treasury;
        fundingOpen = true;
    }

    /**
     * @notice Buy tokens by sending ETH.
     * The amount of tokens you get = ETH sent / token price.
     */
    function buyTokens() external payable {
        require(fundingOpen, "Funding is closed");
        require(msg.value > 0, "Send ETH to buy tokens");

        // Calculate how many tokens the buyer gets
        uint256 amount = msg.value / tokenPrice;
        require(amount > 0, "Not enough ETH for one token");

        // Make sure we don't exceed the max supply
        require(totalSupply() + amount <= maxSupply, "Exceeds max supply");

        // Mint tokens to the buyer
        _mint(msg.sender, amount);

        // Send the ETH to the treasury
        (bool success, ) = treasury.call{value: msg.value}("");
        require(success, "ETH transfer failed");

        emit TokensPurchased(msg.sender, amount, msg.value);

        // Auto-close funding if fully sold out
        if (totalSupply() == maxSupply) {
            fundingOpen = false;
            emit FundingClosed();
        }
    }

    /**
     * @notice Owner can manually close funding early.
     */
    function closeFunding() external onlyOwner {
        fundingOpen = false;
        emit FundingClosed();
    }
}