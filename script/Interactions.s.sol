// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig, CodeConstants} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from
    "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";

// This script is used to create a subscription for Chainlink VRF
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

// subscription id , amount
contract FundSubscription is Script, CodeConstants {
    uint256 public constant FUND_AMOUNT = 5 ether;

    function run() external {
        fundSubscriptionUsingConfig();
    }

    //need to fund the subscription with LINK
    //so it's needed to build LINK token
    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        address vrfCoordinator = config.vrfCoordinator;
        // after Subscription, so we can use the subscriptionId
        uint256 subscriptionId = config.subscriptionId;
        address linkToken = config.linkToken;
        fundSubscription(vrfCoordinator, subscriptionId, linkToken);
    }

    function fundSubscription(address vrfCoordinator, uint256 subscriptionId, address linkToken) public {
        console.log("Funding subscription on ChainID:", block.chainid);
        console.log("Subscription ID:", subscriptionId);
        console.log("VRF Coordinator:", vrfCoordinator);
        console.log("Funding amount:", FUND_AMOUNT);

        if (block.chainid == ANVIL_CHAIN_ID) {
            vm.startBroadcast();
            // Transfer LINK tokens to the VRF Coordinator to fund the subscription
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionId, FUND_AMOUNT);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            LinkToken(linkToken).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subscriptionId));
            vm.stopBroadcast();
        }
    }
}
