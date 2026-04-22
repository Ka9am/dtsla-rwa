// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/PropertyMarketplace.sol";
import "../src/PropertyToken.sol";

/**
 * @title PropertyMarketplaceTest
 * @notice Tests for the PropertyMarketplace contract.
 */
contract PropertyMarketplaceTest is Test {

    PropertyMarketplace public marketplace;

    address public owner = makeAddr("owner");
    address public student1 = makeAddr("student1");
    address public student2 = makeAddr("student2");

    // Property details we reuse across tests
    string constant NAME = "Almaty Apartment";
    string constant LOCATION = "Almaty, Kazakhstan";
    uint256 constant TOTAL_VALUE = 100 ether;
    uint256 constant TOKEN_PRICE = 0.01 ether;
    uint256 constant MAX_TOKENS = 1000;

    function setUp() public {
        vm.prank(owner);
        marketplace = new PropertyMarketplace();

        vm.deal(student1, 10 ether);
        vm.deal(student2, 10 ether);
    }

    // ─────────────────────────────────────────────
    // listProperty tests
    // ─────────────────────────────────────────────

    /**
     * @notice Owner can list a property successfully.
     */
    function test_ListProperty_Success() public {
        vm.prank(owner);
        marketplace.listProperty(NAME, LOCATION, TOTAL_VALUE, TOKEN_PRICE, MAX_TOKENS);

        // Property count should now be 1
        assertEq(marketplace.propertyCount(), 1);

        // Read the stored property
        (
            uint256 id,
            string memory name,
            string memory location,
            uint256 totalValue,
            uint256 tokenPrice,
            uint256 maxTokens,
            ,
            bool isActive
        ) = marketplace.properties(0);

        assertEq(id, 0);
        assertEq(name, NAME);
        assertEq(location, LOCATION);
        assertEq(totalValue, TOTAL_VALUE);
        assertEq(tokenPrice, TOKEN_PRICE);
        assertEq(maxTokens, MAX_TOKENS);
        assertTrue(isActive);
    }

    /**
     * @notice Non-owner cannot list a property.
     */
    function test_ListProperty_Reverts_WhenNotOwner() public {
        vm.prank(student1);
        vm.expectRevert();
        marketplace.listProperty(NAME, LOCATION, TOTAL_VALUE, TOKEN_PRICE, MAX_TOKENS);
    }

    /**
     * @notice Cannot list a property with empty name.
     */
    function test_ListProperty_Reverts_WhenEmptyName() public {
        vm.prank(owner);
        vm.expectRevert(bytes("Name cannot be empty"));
        marketplace.listProperty("", LOCATION, TOTAL_VALUE, TOKEN_PRICE, MAX_TOKENS);
    }

    /**
     * @notice Each listed property gets its own token contract.
     */
    function test_ListProperty_DeploysTokenContract() public {
        vm.prank(owner);
        marketplace.listProperty(NAME, LOCATION, TOTAL_VALUE, TOKEN_PRICE, MAX_TOKENS);

        // Get the token address from the property
        (,,,,,, PropertyToken token,) = marketplace.properties(0);

        // Token contract should exist at a real address
        assertTrue(address(token) != address(0));

        // Token should have correct name and symbol
        assertEq(token.name(), NAME);
        assertEq(token.symbol(), "PROP0");
    }

    /**
     * @notice Multiple properties get unique IDs and token symbols.
     */
    function test_ListProperty_MultipleProperties() public {
        vm.startPrank(owner);
        marketplace.listProperty(NAME, LOCATION, TOTAL_VALUE, TOKEN_PRICE, MAX_TOKENS);
        marketplace.listProperty("Astana Office", "Astana, Kazakhstan", 200 ether, 0.02 ether, 500);
        vm.stopPrank();

        assertEq(marketplace.propertyCount(), 2);

        (,,,,,, PropertyToken token0,) = marketplace.properties(0);
        (,,,,,, PropertyToken token1,) = marketplace.properties(1);

        assertEq(token0.symbol(), "PROP0");
        assertEq(token1.symbol(), "PROP1");
    }

    // ─────────────────────────────────────────────
    // invest tests
    // ─────────────────────────────────────────────

    /**
     * @notice Student can invest ETH and receive tokens.
     */
    function test_Invest_Success() public {
        vm.prank(owner);
        marketplace.listProperty(NAME, LOCATION, TOTAL_VALUE, TOKEN_PRICE, MAX_TOKENS);

        vm.prank(student1);
        marketplace.invest{value: 0.05 ether}(0);

        assertEq(marketplace.getInvestorBalance(0, student1), 5);
    }

    /**
     * @notice Cannot invest in inactive property.
     */
    function test_Invest_Reverts_WhenPropertyInactive() public {
        vm.prank(owner);
        marketplace.listProperty(NAME, LOCATION, TOTAL_VALUE, TOKEN_PRICE, MAX_TOKENS);

        vm.prank(owner);
        marketplace.deactivateProperty(0);

        vm.prank(student1);
        vm.expectRevert(bytes("Property is not active"));
        marketplace.invest{value: 0.05 ether}(0);
    }

    /**
     * @notice ETH sent must be exact multiple of token price.
     */
    function test_Invest_Reverts_WhenNotExactMultiple() public {
        vm.prank(owner);
        marketplace.listProperty(NAME, LOCATION, TOTAL_VALUE, TOKEN_PRICE, MAX_TOKENS);

        vm.prank(student1);
        vm.expectRevert(bytes("ETH must be exact multiple of token price"));
        marketplace.invest{value: 0.015 ether}(0);
    }

    // ─────────────────────────────────────────────
    // deactivateProperty tests
    // ─────────────────────────────────────────────

    /**
     * @notice Owner can deactivate a property.
     */
    function test_DeactivateProperty_Success() public {
        vm.prank(owner);
        marketplace.listProperty(NAME, LOCATION, TOTAL_VALUE, TOKEN_PRICE, MAX_TOKENS);

        vm.prank(owner);
        marketplace.deactivateProperty(0);

        (,,,,,,, bool isActive) = marketplace.properties(0);
        assertFalse(isActive);
    }
}