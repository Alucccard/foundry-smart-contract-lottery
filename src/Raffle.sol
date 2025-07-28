// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {VRFConsumerBaseV2Plus} from
    "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
/* 
@Order of Contract
Pragma statements
Import statements
Events
Errors
Interfaces
Libraries
Type declarations
State variables
Modifiers
Functions


@Order of Functions
constructor
receive function (if exists)
fallback function (if exists)
external
public
internal
private
view & pure functions

 */

/**
 * @title Raffle Contract
 * @author Your Name
 * @notice This contract allows users to participate in a raffle
 */
contract Raffle is VRFConsumerBaseV2Plus {
    event Raffle_Entered(address indexed player);
    event Raffle_WinnerPicked(address winner);

    error Raffle_SendMoreToEnterRaffle(uint256 sent, uint256 required);
    //add Raffle_ prefix to indicate it's a Raffle-specific error
    error Raffle_NotEnoughTimePassedSinceLastWinnerPicked(uint256 lastTimeStamp, uint256 interval);
    error Raffle_TransferFailed(address winner, uint256 amount);
    error Raffle_NotActing(RaffleState currentState);
    error Raffle_UpkeepNotNeeded(uint256 addressBalance, uint256 numberOfPlayers, uint256 currentState);

    /* State Type Declarations */
    enum RaffleState {
        ACTING, //0
        COMPUTING, //1
        COOLING //2

    }

    // State variables and functions will be added here
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval; // Example interval for picking a winner
    uint256 private s_lastTimeStamp; // Timestamp of the last winner picked
    RaffleState private s_raffleState;

    // Chainlink VRF variables
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable i_callbackGasLimit = 40000;
    uint32 private constant NUM_WORDS = 1;

    //players and winner
    address payable[] private s_players;
    address payable private s_recentWinner;

    // mapping(address => uint256) private s_addressToIndex;
    // mapping(address => uint256) private s_addressToAmount;

    //needs a vrfCoordinator address, is it the subscription ID?
    constructor(
        uint256 _entranceFee,
        uint256 _interval,
        address _vrfCoordinator, //can aquire from link back-end
        bytes32 _gaslane,
        uint256 _subscriptionId, //can aquire from link back-end
        uint32 _callbackGasLimit
    ) VRFConsumerBaseV2Plus(_vrfCoordinator) {
        i_entranceFee = _entranceFee;
        i_interval = _interval;
        s_lastTimeStamp = block.timestamp;

        i_keyHash = _gaslane;
        i_subscriptionId = _subscriptionId;
        i_callbackGasLimit = _callbackGasLimit;

        s_raffleState = RaffleState.ACTING;
    }

    function enterRaffle() public payable {
        // if solidity version is low, use this
        // if (msg.value < i_entranceFee) {
        //     revert Raffle_SendMoreToEnterRaffle(msg.value, i_entranceFee);
        // }
        require(s_raffleState == RaffleState.ACTING, Raffle_NotActing(s_raffleState));
        require(msg.value >= i_entranceFee, Raffle_SendMoreToEnterRaffle(msg.value, i_entranceFee));
        // Add player to the raffle
        s_players.push(payable(msg.sender));

        // Update the mapping for address to index
        emit Raffle_Entered(msg.sender);
    }

    /**
     * @notice 3
     * @dev 4
     * @param 5
     * @return upKeepNeeded
     */
    //function to check time

    function checkUpkeep(bytes memory) public view returns (bool upKeepNeeded, bytes memory) {
        bool timeHasPassed = ((block.timestamp - s_lastTimeStamp) >= i_interval);
        bool isOpen = s_raffleState == RaffleState.ACTING;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;

        if (timeHasPassed && isOpen && hasBalance && hasPlayers) {
            upKeepNeeded = true;
            return (upKeepNeeded, "");
            //how does chainlink know it's time to trigger performUpkeep?
        }
    }

    // @notice This function picks a winner from the raffle participants
    // @dev This function uses a random number generator to select a winner
    function performUpkeep(bytes calldata) external returns (address winner) {
        (bool upKeepNeeded,) = checkUpkeep("");
        require(upKeepNeeded, Raffle_UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState)));
        s_raffleState = RaffleState.COMPUTING;
        // pickWinner periodically, e.g., every 10 minutes

        //we need to get a random number from chainlink api
        //the process:
        //1. Request RNG
        //2. Get RNG
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
    }

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal virtual override {
        //the randomWords array contains the random number
        //use it to pick a winner
        //but it will be a very long number, so we will use modulo to get a winner
        //since we only need one random number, we can use the first element
        // require(randomWords.length > 0, "No random words returned");

        // Pick a winner from the players array using the random number
        uint256 index = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[index];
        s_recentWinner = recentWinner;

        //set Raffle state to cooling`
        s_raffleState = RaffleState.COOLING;

        //emit a event to notice the players about the lottery result
        emit Raffle_WinnerPicked(s_recentWinner);

        //reset the player array for next round
        s_players = new address payable[](0);

        //refresh the lastTimeStamp
        s_lastTimeStamp = block.timestamp;

        // Transfer the prize to the winner
        (bool success,) = s_recentWinner.call{value: address(this).balance}("");
        require(success, Raffle_TransferFailed(s_recentWinner, address(this).balance));

        //after balance succefully transfered to winner, raffle state will be reset to acting
        s_raffleState = RaffleState.ACTING;
    }

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
