// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/dTSLA.sol";
import "../src/MockUSDC.sol";

contract DeployDTSLA is Script {
    // Chainlink Price Feed addresses on Sepolia
    // TSLA/USD feed
    address constant TSLA_FEED = 0xC32f0A9D70A34B9E7377C10FDAd88512596f61EA;
    // USDC/USD feed
    address constant USDC_USD_FEED = 0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E;

    function run() external returns (dTSLA, MockUSDC) {
        vm.startBroadcast();

        // Deploy Mock USDC first
        MockUSDC mockUsdc = new MockUSDC();

        // Deploy dTSLA with price feeds and mock USDC
        dTSLA dtSla = new dTSLA(
            TSLA_FEED,
            USDC_USD_FEED,
            address(mockUsdc)
        );

        // Mint some test USDC to the deployer
        mockUsdc.mint(msg.sender, 10000 * 1e6); // 10,000 USDC

        vm.stopBroadcast();

        return (dtSla, mockUsdc);
    }
}