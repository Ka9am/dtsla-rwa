// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title MockUSDC
 * @notice Fake USDC for testing purposes on Sepolia
 */
contract MockUSDC is ERC20 {
    constructor() ERC20("Mock USDC", "mUSDC") {}

    // Anyone can mint test USDC (only for testing!)
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    // USDC has 6 decimals
    function decimals() public pure override returns (uint8) {
        return 6;
    }
}