// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/WatchedProtocol.sol";
import "../src/PresenceTracker.sol";
import "../src/GhostVault.sol";

/// @title GhostVault Deployment Script
/// @notice Deploys the full GhostVault system to Somnia Network
/// @dev Requires PRIVATE_KEY env var and sufficient STT for:
///      - Gas for 3 contract deployments
///      - 1 STT initial vault funding
///      - 32+ STT for subscription registration (post-deployment)
///
/// Somnia Shannon Testnet:
///   - Chain ID: 50312
///   - RPC: https://dream-rpc.somnia.network
///   - Explorer: https://shannon-explorer.somnia.network
///
/// Somnia Mainnet:
///   - Chain ID: 5031
///   - RPC: https://api.infra.mainnet.somnia.network
///   - Explorer: https://explorer.somnia.network

contract Deploy is Script {
    // Somnia Reactivity Precompile (same on all networks)
    address constant REACTIVITY_PRECOMPILE = 0x0000000000000000000000000000000000000100;

    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);

        console.log("========================================");
        console.log("GhostVault Deployment");
        console.log("========================================");
        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);
        console.log("========================================");

        vm.startBroadcast(deployerKey);

        // 1. Deploy WatchedProtocol (the contract we monitor for triggers)
        WatchedProtocol watchedProtocol = new WatchedProtocol();
        console.log("WatchedProtocol deployed at:", address(watchedProtocol));

        // 2. Deploy PresenceTracker (wildcard event subscription)
        // Note: Must call registerWildcardSubscription() post-deployment with 32+ STT
        PresenceTracker presenceTracker = new PresenceTracker{value: 0}();
        console.log("PresenceTracker deployed at:", address(presenceTracker));

        // 3. Deploy GhostVault (rewards distribution + event subscription)
        // Sends 1 STT initial balance for rewards pool
        // Note: Must call registerSubscription() post-deployment with 32+ STT
        GhostVault ghostVault = new GhostVault{value: 1 ether}(
            address(presenceTracker),
            address(watchedProtocol)
        );
        console.log("GhostVault deployed at:", address(ghostVault));

        vm.stopBroadcast();

        // Output summary
        console.log("========================================");
        console.log("DEPLOYMENT COMPLETE");
        console.log("========================================");
        console.log("Next steps:");
        console.log("1. Fund PresenceTracker with 32+ STT:");
        console.log("   cast send", address(presenceTracker), '"registerWildcardSubscription()" --value 32ether ...');
        console.log("2. Fund GhostVault with 32+ STT:");
        console.log("   cast send", address(ghostVault), '"registerSubscription()" --value 32ether ...');
        console.log("3. Add more funds to GhostVault for rewards:");
        console.log("   cast send", address(ghostVault), '--value 10ether ...');
        console.log("========================================");
    }
}
