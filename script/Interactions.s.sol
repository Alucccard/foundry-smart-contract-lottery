// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from
    "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract CreateSubscription is Script {
    // This script is used to create a subscription for Chainlink VRF
    // It can be run with `forge script CreateSubscription --rpc-url <RPC_URL> --broadcast`

    function CreateSubscriptionUsingConfig() public returns (uint256) {
        //the logic to create a subscription using the HelperConfig
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        address vrfCoordinator = config.vrfCoordinator;

        return createSubscription(vrfCoordinator);
    }

    function createSubscription(address vrfCoordinator) internal returns (uint256) {
        console.log("Creating subscription on ChainID:", block.chainid);
        vm.startBroadcast();
        uint256 subscriptionId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console.log("Subscription created with ID:", subscriptionId);
        console.log("Please update subscriptionId in HelperConfig with this ID.");
        return subscriptionId;
    }

    function run() external returns (uint256) {
        return CreateSubscriptionUsingConfig();
    }
}
