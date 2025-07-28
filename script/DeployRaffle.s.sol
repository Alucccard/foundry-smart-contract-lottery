// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "src/Raffle.sol";

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
    function depolyContract() public returns (Raffle, HelperConfig) {}
}
