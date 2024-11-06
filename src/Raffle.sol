// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

/**
* @title A sample Raffle Contract
* @author Rishabh Gupta
* @notice This contract is used for creating a sample Raffle
* @dev Implements Chainlink VRFv2.5
*/

import {RandomNumberGenerator} from "./RandomNumberGenerator.sol";

contract Raffle {

    error Raffle__NotEnoughEth();
    error Raffle__NotTimeToPickWinner();
    error Raffle__TransferFailed();
    error Raffle__NotOpen();
    error Raffle__UpkeepNotNeeded(uint256 balance, uint256 playersLength, uint256 raffleState);

    enum RaffleState {
        OPEN,
        CALCULATING
    }

    uint256 private immutable ENTRANCE_FEE;
    // Duration of the lottery in seconds
    uint256 private immutable INTERVAL;
    address payable[] internal s_players;
    uint256 private s_raffleStartTime;
    address private recentWiner;
    RaffleState private s_raffleState;
    address private s_vrfCoordinator;
    bytes32 private s_gasLane;
    uint32 private s_callbackGasLimit;
    uint256 immutable s_subscriptionId;

    event Raffle__RaffleEntered(address indexed player);
    event Raffle__WinnerPicked(address indexed winner);
    modifier minimumEthNeeded() {
        // Method 1:
        // require(msg.value >= ENTRANCE_FEE, "Not enough ETH sent");
        // Method 2:
        if(msg.value < ENTRANCE_FEE) {
            revert Raffle__NotEnoughEth();
        }
        // Method 3:
        // require(msg.value >= ENTRANCE_FEE, NotEnoughEth());
        _;
    }

    modifier intervalNotComplete() {
        uint256 currentTimeStamp = block.timestamp;
        require(currentTimeStamp > s_raffleStartTime + INTERVAL, Raffle__NotTimeToPickWinner());
        _;
    }

    constructor(uint256 _entranceFee, uint256 _interval, address _vrfCoordinator, bytes32 _gasLane, uint256 _subscriptionId, uint32 _callbackGasLimit) {
        ENTRANCE_FEE = _entranceFee;
        INTERVAL = _interval;
        s_vrfCoordinator = _vrfCoordinator;
        s_gasLane = _gasLane;
        s_callbackGasLimit = _callbackGasLimit;
        s_subscriptionId = _subscriptionId;
        s_raffleStartTime = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable minimumEthNeeded {
        if(s_raffleState != RaffleState.OPEN) {
            revert Raffle__NotOpen();
        }
        s_players.push(payable(msg.sender));
        emit Raffle__RaffleEntered(msg.sender);
    }

    // Will be called to check if lottery is ready to pick winner
    function checkUpkeep(bytes memory) public view returns(bool upkeepNeeded, bytes memory /*performData */) {
        bool timePassed = ((block.timestamp - s_raffleStartTime) >= INTERVAL);
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = timePassed && isOpen && hasBalance && hasPlayers;
    }

    function performUpkeep( bytes calldata /* performData */) external intervalNotComplete returns(uint256) {
        // TODO:
        // Get a random number
        // 1. Request Random Number Generator
        // 2. Get Random Number Generated by RNG
        // User the random number to pick a player
        // Be automatically called after a certain time frame
        (bool upkeepNeeded, ) = checkUpkeep("");
        if(!upkeepNeeded ) {
            revert Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
        }
        s_raffleState = RaffleState.CALCULATING;
        RandomNumberGenerator rng = new RandomNumberGenerator(s_vrfCoordinator, s_gasLane, s_subscriptionId, s_callbackGasLimit);
        uint256 requestId = rng.generateRandomNumber();
        uint256[] memory randomWords;
        randomWords[0] = 123456789012345678901234567890;
        address recentWinner = rng.getRecentWinner(requestId, randomWords, s_players);
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_raffleStartTime = block.timestamp;
        (bool success,) = recentWinner.call{value: address(this).balance}("");
        if(!success) {
            revert Raffle__TransferFailed();
        }

        emit Raffle__WinnerPicked(recentWinner);
    }

    function getEntranceFee() external view returns(uint256) {
        return ENTRANCE_FEE;
    }

    function getRaffleState() external view returns(RaffleState) {
        return s_raffleState;
    }

    function getPlayer(uint256 indexOfPlayer) external view returns (address) {
        return s_players[indexOfPlayer];
    }

}