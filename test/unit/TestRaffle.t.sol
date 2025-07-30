// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from
    "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

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

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

    //define events for testing,it's a bit redundant
    event Raffle_Entered(address indexed player);
    event Raffle_WinnerPicked(address winner);

    modifier raffleEntered() {
        vm.startPrank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1); // Move time forward to trigger upkeep
        vm.roll(block.number + 1); // Move to the next block
        _;
    }

    function setUp() external {
        // Deploy the Raffle contract using the DeployRaffle script
        vm.deal(PLAYER, STARTING_PLAYER_BALANCE); // Give the player some ether
        DeployRaffle deployRaffle = new DeployRaffle();
        (raffle, helperConfig) = deployRaffle.deployContract();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        gaslane = config.gaslane;
        subscriptionId = config.subscriptionId;
        callbackGasLimit = config.callbackGasLimit;
    }

    function testRaffleInitializeInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.ACTING);
    }

    function testRaffleRevertsWhenYouDontPayEnough() public {
        vm.startPrank(PLAYER);
        vm.expectRevert(abi.encodeWithSelector(Raffle.Raffle_SendMoreToEnterRaffle.selector, 0, entranceFee));
        raffle.enterRaffle();
        vm.stopPrank();
    }

    function testRaffleRecordsPlayersWhenTheyEnter() public {
        vm.startPrank(PLAYER);
        // vm.deal(PLAYER, STARTING_PLAYER_BALANCE); // Give the player some ether
        raffle.enterRaffle{value: entranceFee}();
        assertEq(raffle.getPlayer(0), PLAYER);
        assertEq(raffle.getNumberOfPlayers(), 1);
        vm.stopPrank();
    }
    /* function expectEmit(
    bool checkTopic1,
    bool checkTopic2,
    bool checkTopic3,
    bool checkData,
    address emitter
    ) external; */

    function testEmitsEventOnEntrance() public {
        vm.startPrank(PLAYER);
        // vm.deal(PLAYER, STARTING_PLAYER_BALANCE); // Give the player some ether
        vm.expectEmit(true, false, false, false, address(raffle));
        emit Raffle_Entered(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.stopPrank();
    }

    //test whether player can enter the raffle when the raffle isn't in ACTING state
    function testDontAllowPlayersToEnterWhenNotActing() public {
        vm.startPrank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1); // Move time forward to trigger upkeep
        vm.roll(block.number + 1); // Move to the next block
        raffle.performUpkeep(""); // Perform upkeep to change state

        //act
        vm.expectRevert(abi.encodeWithSelector(Raffle.Raffle_NotActing.selector, Raffle.RaffleState.COMPUTING));
        raffle.enterRaffle{value: entranceFee}();
        vm.stopPrank();
    }

    function testCheckUpkeepReturnsFalseIfItHasNoBalance() public {
        vm.warp(block.timestamp + interval + 1); // Move time forward to trigger upkeep
        vm.roll(block.number + 1); // Move to the next block

        (bool upkeepNeeded,) = raffle.checkUpkeep("");

        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfRaffleIsntActing() public raffleEntered {
        raffle.performUpkeep(""); // Perform upkeep to change state

        (bool upkeepNeeded,) = raffle.checkUpkeep("");

        assert(!upkeepNeeded);
    }

    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public raffleEntered {
        raffle.performUpkeep("");
    }

    function testPerformUpKeepRevertsIfCheckUpkeepIsFalse() public {
        uint256 currentBalance = 0;
        uint256 numPlayers = 0;
        Raffle.RaffleState rState = raffle.getRaffleState();

        vm.startPrank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        currentBalance += entranceFee;
        numPlayers = 1;
        vm.expectRevert(
            abi.encodeWithSelector(Raffle.Raffle_UpkeepNotNeeded.selector, currentBalance, numPlayers, rState)
        );
        raffle.performUpkeep("");
    }

    //gonna test a event
    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId() public raffleEntered {
        //arrange

        //action
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        Raffle.RaffleState raffleState = raffle.getRaffleState();
        assert(uint256(requestId) > 0);
        assert(uint256(raffleState) == 1);
    }

    // /* FULLFIL RANDOM WORDS  */ //
    function testFullfilRandomWordsCanOnlyBeCalledAfterPerformUpkeep(uint256 randomRequestId) public raffleEntered {
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(randomRequestId, address(raffle));
    }
}
