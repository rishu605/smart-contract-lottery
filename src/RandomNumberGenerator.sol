// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract RandomNumberGenerator is VRFConsumerBaseV2Plus {
    uint256 immutable s_subscriptionId;
    address private vrfCoordinator;
    // = 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B;
    bytes32 private s_keyHash; 
    // = 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae;
    uint32 private callbackGasLimit = 40000;
    uint16 private constant requestConfirmations = 3;
    uint32 private numWords = 1;
    // address private owner;

    error Unauthorised();

    constructor(address _vrfCoordinator, bytes32 _gasLane, uint256 _subscriptionId, uint32 _callbackGasLimit) VRFConsumerBaseV2Plus(vrfCoordinator) {
        s_subscriptionId = _subscriptionId;
        vrfCoordinator = _vrfCoordinator;
        s_keyHash = _gasLane;
        callbackGasLimit = _callbackGasLimit;
        // owner = msg.sender;
    }

    event RandomNumberGenerated(uint256 indexed requestId, uint256 result);

    function generateRandomNumber()
        public
        onlyOwner
        returns (uint256 requestId)
    {
        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: s_keyHash,
                subId: s_subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
    }

    function getRecentWinner(uint256 requestId, uint256[] memory randomWords, address payable[] memory s_players) public returns(address){
        // uint256 requestId = generateRandomNumber();
        // uint256[] calldata randomWordsArray;
        // fulfillRandomWords(requestId, randomWordsArray);
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        return recentWinner;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        uint256 result = (randomWords[0] % randomWords.length) + 1;
        emit RandomNumberGenerated(requestId, result);
    }
}
