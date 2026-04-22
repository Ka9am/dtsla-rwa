// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/PropertyToken.sol";

/**
 * @title PropertyTokenTest
 * @notice Tests for the PropertyToken contract.
 * We test every function and every require statement.
 */
contract PropertyTokenTest is Test {

    // The contract we are testing
    PropertyToken public token;

    // Test wallets — Foundry gives us fake addresses to work with
    address public owner = makeAddr("owner");
    address public treasury = makeAddr("treasury");
    address public student1 = makeAddr("student1");
    address public student2 = makeAddr("student2");

    // Token settings
    uint256 public constant MAX_SUPPLY = 1000;
    uint256 public constant TOKEN_PRICE = 0.01 ether;

    /**
     * @notice setUp runs before EVERY test automatically.
     * Like a beforeEach in JavaScript testing frameworks.
     */
    function setUp() public {
        // Deploy PropertyToken as the owner
        vm.prank(owner);
        token = new PropertyToken(
            "Almaty Apartment Token",
            "AAT",
            MAX_SUPPLY,
            TOKEN_PRICE,
            treasury
        );

        // Give test students some fake ETH to spend
        vm.deal(student1, 10 ether);
        vm.deal(student2, 10 ether);
    }

    // ─────────────────────────────────────────────
    // Deployment tests
    // ─────────────────────────────────────────────

    /**
     * @notice Check that constructor set everything correctly.
     */
    function test_DeploymentValues() public view {
        assertEq(token.name(), "Almaty Apartment Token");
        assertEq(token.symbol(), "AAT");
        assertEq(token.maxSupply(), MAX_SUPPLY);
        assertEq(token.tokenPrice(), TOKEN_PRICE);
        assertEq(token.treasury(), treasury);
        assertTrue(token.fundingOpen());
        assertEq(token.totalSupply(), 0);
    }

    // ─────────────────────────────────────────────
    // buyTokens tests
    // ─────────────────────────────────────────────

    /**
     * @notice Student sends ETH and receives correct number of tokens.
     */
    function test_BuyTokens_Success() public {
        // student1 sends 0.05 ETH → should get 5 tokens
        vm.prank(student1);
        token.buyTokens{value: 0.05 ether}();

        assertEq(token.balanceOf(student1), 5);
        assertEq(token.totalSupply(), 5);
    }

    /**
     * @notice Treasury receives the ETH when tokens are bought.
     */
    function test_BuyTokens_TreasuryReceivesETH() public {
        uint256 treasuryBefore = treasury.balance;

        vm.prank(student1);
        token.buyTokens{value: 0.05 ether}();

        assertEq(treasury.balance, treasuryBefore + 0.05 ether);
    }

    /**
     * @notice Buying tokens emits the correct event.
     */
    function test_BuyTokens_EmitsEvent() public {
        vm.expectEmit(true, false, false, true);
        emit PropertyToken.TokensPurchased(student1, 5, 0.05 ether);

        vm.prank(student1);
        token.buyTokens{value: 0.05 ether}();
    }

    /**
     * @notice Cannot buy tokens if funding is closed.
     */
    function test_BuyTokens_Reverts_WhenFundingClosed() public {
        vm.prank(owner);
        token.closeFunding();

        vm.prank(student1);
        vm.expectRevert(bytes("Funding is closed"));
        token.buyTokens{value: 0.05 ether}();
    }

    /**
     * @notice Cannot buy tokens without sending ETH.
     */
    function test_BuyTokens_Reverts_WhenNoETH() public {
        vm.prank(student1);
        vm.expectRevert(bytes("Send ETH to buy tokens"));
        token.buyTokens{value: 0}();
    }

    /**
     * @notice Cannot buy more tokens than max supply allows.
     */
    function test_BuyTokens_Reverts_WhenExceedsMaxSupply() public {
        // MAX_SUPPLY is 1000 tokens, each costs 0.01 ETH
        // Try to buy 1001 tokens = 10.01 ETH
        vm.deal(student1, 20 ether);
        vm.prank(student1);
        vm.expectRevert(bytes("Exceeds max supply"));
        token.buyTokens{value: 10.01 ether}();
    }

    /**
     * @notice Funding closes automatically when max supply is reached.
     */
    function test_BuyTokens_AutoClosesFunding() public {
        // Buy all 1000 tokens = 10 ETH
        vm.deal(student1, 20 ether);
        vm.prank(student1);
        token.buyTokens{value: 10 ether}();

        assertFalse(token.fundingOpen());
        assertEq(token.totalSupply(), MAX_SUPPLY);
    }

    // ─────────────────────────────────────────────
    // closeFunding tests
    // ─────────────────────────────────────────────

    /**
     * @notice Owner can close funding manually.
     */
    function test_CloseFunding_Success() public {
        vm.prank(owner);
        token.closeFunding();

        assertFalse(token.fundingOpen());
    }

    /**
     * @notice Non-owner cannot close funding.
     */
    function test_CloseFunding_Reverts_WhenNotOwner() public {
        vm.prank(student1);
        vm.expectRevert();
        token.closeFunding();
    }
}