// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2;

import "QuizHost.sol";

contract UnpayablePlayerUtils {

    Quiz quiz;

    bytes32 mySalt;

    constructor(Quiz _quiz) payable { 
        require(msg.value>0);
        quiz = _quiz; 
    }

    function submitAnswer(bytes32 rawAnswer, bytes32 salt) external {
        mySalt = salt;
        bytes32 encodedAnswer = keccak256(abi.encodePacked(rawAnswer, salt, address(this)));
        quiz.submitAnswer{value: 1 gwei}(encodedAnswer);
    }



    function verify() external {
        quiz.verifyAnswer(mySalt);
    }

}

contract PayablePlayerUtils {

    Quiz quiz;
    bytes32 mySalt;

    constructor(Quiz _quiz) payable { 
        require(msg.value>0);
        quiz = _quiz; 
    }

    function submitAnswer(bytes32 rawAnswer, bytes32 salt) external {
        mySalt = salt;
        bytes32 encodedAnswer = keccak256(abi.encodePacked(rawAnswer, salt, address(this)));
        quiz.submitAnswer{value: 1 gwei}(encodedAnswer);
    }

    function verify() external {
        quiz.verifyAnswer(mySalt);
    }

    receive() external payable {}

}