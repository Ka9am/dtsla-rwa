// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/PropertyMarketplace.sol";

/**
 * @title SeedProperty
 * @notice Lists additional properties on an already deployed marketplace.
 * Useful for adding more properties after initial deployment.
 * Run with:
 * forge script script/SeedProperty.s.sol --rpc-url sepolia --broadcast
 */
contract SeedProperty is Script {
    // Paste your deployed marketplace address here after running Deploy.s.sol
    address constant MARKETPLACE_ADDRESS = address(0);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        PropertyMarketplace marketplace = PropertyMarketplace(MARKETPLACE_ADDRESS);

        // List a second property
        marketplace.listProperty(
            "Astana Office",
            "Astana, Kazakhstan",
            200 ether,
            0.02 ether,
            500
        );
        console.log("Astana Office listed, property ID:", marketplace.propertyCount() - 1);

        vm.stopBroadcast();
    }
}