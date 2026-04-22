// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./PropertyToken.sol";

/**
 * @title PropertyMarketplace
 * @notice Central hub for listing real estate properties and managing investments.
 * Admin lists properties, each property gets its own PropertyToken contract.
 * Students invest ETH and receive property tokens in return.
 */
contract PropertyMarketplace is Ownable, ReentrancyGuard {

    // Represents a single listed property
    struct Property {
        uint256 id;               // Unique property ID
        string name;              // e.g. "Almaty Apartment"
        string location;          // e.g. "Almaty, Kazakhstan"
        uint256 totalValue;       // Total property value in ETH
        uint256 tokenPrice;       // Price per token in ETH
        uint256 maxTokens;        // Total tokens = total shares
        PropertyToken token;      // The ERC-20 token for this property
        bool isActive;            // Whether investment is open
    }

    // Counter for property IDs — starts at 0, increments each time
    uint256 public propertyCount;

    // Maps property ID → Property struct
    mapping(uint256 => Property) public properties;

    // Events
    event PropertyListed(
        uint256 indexed propertyId,
        string name,
        address tokenAddress,
        uint256 totalValue
    );
    event Invested(
        uint256 indexed propertyId,
        address indexed investor,
        uint256 ethAmount,
        uint256 tokensReceived
    );
    event PropertyDeactivated(uint256 indexed propertyId);

    constructor() Ownable(msg.sender) {}

    /**
     * @notice Admin lists a new property on the marketplace.
     * Deploys a fresh PropertyToken contract for each property.
     */
    function listProperty(
        string memory name,
        string memory location,
        uint256 totalValue,    // in wei (1 ETH = 1e18 wei)
        uint256 tokenPrice,    // price per token in wei
        uint256 maxTokens      // total number of tokens/shares
    ) external onlyOwner {
        require(bytes(name).length > 0, "Name cannot be empty");
        require(totalValue > 0, "Total value must be greater than zero");
        require(tokenPrice > 0, "Token price must be greater than zero");
        require(maxTokens > 0, "Max tokens must be greater than zero");

        // Generate a short token symbol from the property count
        // e.g. property 0 = "PROP0", property 1 = "PROP1"
        string memory symbol = string(abi.encodePacked("PROP", _toString(propertyCount)));

        // Deploy a new PropertyToken contract for this property
        // msg.sender (admin) becomes the treasury — receives the ETH
        PropertyToken token = new PropertyToken(
            name,
            symbol,
            maxTokens,
            tokenPrice,
            msg.sender
        );

        // Store the property in our mapping
        properties[propertyCount] = Property({
            id: propertyCount,
            name: name,
            location: location,
            totalValue: totalValue,
            tokenPrice: tokenPrice,
            maxTokens: maxTokens,
            token: token,
            isActive: true
        });

        emit PropertyListed(propertyCount, name, address(token), totalValue);

        // Increment counter for next property
        propertyCount++;
    }

        /**
    * @notice Student invests ETH into a property and receives tokens.
    * nonReentrant prevents reentrancy attacks.
    */
    function invest(uint256 propertyId) external payable nonReentrant {
        Property storage property = properties[propertyId];

        require(property.isActive, "Property is not active");
        require(msg.value > 0, "Send ETH to invest");
        require(
            msg.value % property.tokenPrice == 0,
            "ETH must be exact multiple of token price"
        );

        // Calculate tokens to receive
        uint256 tokensToMint = msg.value / property.tokenPrice;

        // Make sure we don't exceed max supply
        require(
            property.token.totalSupply() + tokensToMint <= property.maxTokens,
            "Exceeds max supply"
        );

        // Send ETH to treasury directly
        (bool success, ) = property.token.treasury().call{value: msg.value}("");
        require(success, "ETH transfer failed");

        // Mint tokens directly to the investor (msg.sender)
        property.token.mintTo(msg.sender, tokensToMint);

        emit Invested(propertyId, msg.sender, msg.value, tokensToMint);
    }
    /**
     * @notice Admin can deactivate a property listing.
     */
    function deactivateProperty(uint256 propertyId) external onlyOwner {
        require(properties[propertyId].isActive, "Already inactive");
        properties[propertyId].isActive = false;
        properties[propertyId].token.closeFunding();
        emit PropertyDeactivated(propertyId);
    }

    /**
     * @notice Returns token balance of an investor for a specific property.
     */
    function getInvestorBalance(
        uint256 propertyId,
        address investor
    ) external view returns (uint256) {
        return properties[propertyId].token.balanceOf(investor);
    }

    /**
     * @notice Converts a uint256 to its string representation.
     * Used to generate token symbols like "PROP0", "PROP1".
     */
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}