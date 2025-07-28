// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployRaffle is Script {
    function run() public {}

    /* 
        variables needed to construt the Raffle

        uint256 _entranceFee,
        uint256 _interval,
        address _vrfCoordinator, //can aquire from link back-end
        bytes32 _gaslane,
        uint256 _subscriptionId, //can aquire from link back-end
        uint32 _callbackGasLimit
         */
    function depolyContract() public returns (Raffle, HelperConfig) {
        //what helperconfig do is generate the configuration needed to deploy the raffle
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
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

        return (raffle, helperConfig);
    }
}
