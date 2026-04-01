// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title MockUSDC
 * @author Aibar (NU'26)
 * @notice Fake USDC token for testing the dTSLA RWA system on Sepolia testnet
 * @dev In production, this would be replaced with the real USDC contract
 *
 * Key differences from real USDC:
 * - Anyone can mint tokens (no restrictions)
 * - Used only for testing purposes
 * - 6 decimals (same as real USDC)
 */
contract MockUSDC is ERC20 {

    /**
     * @notice Deploys the MockUSDC token with name and symbol
     */
    constructor() ERC20("Mock USDC", "mUSDC") {}

    /**
     * @notice Mint any amount of MockUSDC to any address
     * @dev Only for testing! Real USDC has strict minting controls
     * @param to Address to receive the minted tokens
     * @param amount Amount to mint (6 decimals, e.g. 1000000 = 1 USDC)
     */
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    /**
     * @notice Returns 6 decimals to match real USDC standard
     * @dev Overrides ERC20 default of 18 decimals
     */
    function decimals() public pure override returns (uint8) {
        return 6;
    }
}