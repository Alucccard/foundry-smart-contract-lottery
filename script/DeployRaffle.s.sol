// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    function run() public {
        // Deploy the Raffle contract using the DeployRaffle script
        (Raffle raffle, HelperConfig helperConfig) = deployContract();
        console.log("DeployRaffle-run::Raffle contract deployed at:", address(raffle));
        console.log("DeployRaffle-run::HelperConfig contract deployed at:", address(helperConfig));
    }

    /* 
        variables needed to construt the Raffle

        uint256 _entranceFee,
        uint256 _interval,
        address _vrfCoordinator, //can aquire from link back-end
        bytes32 _gaslane,
        uint256 _subscriptionId, //can aquire from link back-end
        uint32 _callbackGasLimit
         */
    function deployContract() public returns (Raffle, HelperConfig) {
        //what helperconfig do is generate the configuration needed to deploy the raffle
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        //no subscriptionId in config, so we need to create one
        if (config.subscriptionId == 0) {
            //create a subscription
            CreateSubscription createSubscription = new CreateSubscription();
            config.subscriptionId = createSubscription.createSubscription(config.vrfCoordinator);

            //fund the subscription
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(config.vrfCoordinator, config.subscriptionId, config.linkToken);
        }

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.gaslane,
            config.subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();

        //need the raffle address, so it is run after the raffle is deployed
        console.log("DeployRaffle-run::Raffle contract deployed at:", address(raffle));
        //add the consumer to the subscription
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(config.subscriptionId, address(raffle), config.vrfCoordinator);

        return (raffle, helperConfig);
    }
}
