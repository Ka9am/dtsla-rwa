// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/PropertyMarketplace.sol";
import "../src/RentalYield.sol";

/**
 * @title Deploy
 * @notice Deploys PropertyMarketplace and RentalYield to Sepolia.
 * Run with:
 * forge script script/Deploy.s.sol --rpc-url sepolia --broadcast --verify
 */
contract Deploy is Script {
    function run() external {
        // Load private key from .env and start broadcasting transactions
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy the marketplace
        PropertyMarketplace marketplace = new PropertyMarketplace();
        console.log("PropertyMarketplace deployed at:", address(marketplace));

        // 2. List a sample property so the frontend has something to show
        marketplace.listProperty(
            "Almaty Apartment",          // name
            "Almaty, Kazakhstan",         // location
            100 ether,                    // total property value
            0.01 ether,                   // price per token
            1000                          // max tokens (shares)
        );
        console.log("Sample property listed with ID: 0");

        // 3. Get the token address for property 0
        (,,,,,, PropertyToken token,) = marketplace.properties(0);
        console.log("PropertyToken for property 0:", address(token));

        // 4. Deploy RentalYield linked to property 0's token
        RentalYield rentalYield = new RentalYield(address(token));
        console.log("RentalYield deployed at:", address(rentalYield));

        vm.stopBroadcast();

        // Print summary for easy copy-paste into frontend
        console.log("\n---- DEPLOYMENT SUMMARY ----");
        console.log("Marketplace:", address(marketplace));
        console.log("PropertyToken (prop 0):", address(token));
        console.log("RentalYield:", address(rentalYield));
        console.log("----------------------------");
    }
}