// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";

contract TestRaffle is Test {
    //what's the purpose of raffle and helperConfig?
    Raffle public raffle;
    HelperConfig public helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator; //can aquire from link back-end
    bytes32 gaslane;
    uint256 subscriptionId; //can aquire from link back-end
    uint32 callbackGasLimit;

    address public PLAYER = makeAddr(name("player"));
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

    function setUp() external {
        // Deploy the Raffle contract using the DeployRaffle script
        DeployRaffle deployRaffle = new DeployRaffle();
        (raffle, helperConfig) = deployRaffle.depolyContract();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        gaslane = config.gaslane;
        subscriptionId = config.subscriptionId;
        callbackGasLimit = config.callbackGasLimit;
    }

    function testRaffleInitializeInOpenState() public view {}
}
