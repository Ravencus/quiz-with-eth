// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2;

import "QuizHost.sol";

contract PlayerCannotReceiveFunds {
    Quiz quiz;

    constructor(Quiz _quiz) payable {
        require(msg.value > 0);
        quiz = _quiz;
    }

    function submitAnswer(bytes32 rawAnswer, bytes32 salt) external {
        bytes32 encodedAnswer = keccak256(
            abi.encodePacked(rawAnswer, salt, address(this))
        );
        quiz.submitAnswer{value: 1 gwei}(encodedAnswer);
    }

    function verify(bytes32 mySalt) external {
        quiz.verifyAnswer(mySalt);
    }
}

contract Player {
    Quiz quiz;

    constructor(Quiz _quiz) payable {
        require(msg.value > 0);
        quiz = _quiz;
    }

    function submitAnswer(bytes32 rawAnswer, bytes32 salt) external {
        submitEncodedAnswer(getEncodedAnswer(rawAnswer, salt));
    }

    function getEncodedAnswer(bytes32 rawAnswer, bytes32 salt)
        public
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(rawAnswer, salt, address(this)));
    }

    function submitEncodedAnswer(bytes32 encodedAnswer) public {
        quiz.submitAnswer{value: 1 gwei}(encodedAnswer);
    }

    function verify(bytes32 mySalt) external {
        quiz.verifyAnswer(mySalt);
    }

    receive() external payable {}
}

//
//
//
//
//
//
//
//
//
//
//

contract TestSendFundToUnpayableAddr {
    constructor() payable {
        Quiz quiz;
        PlayerCannotReceiveFunds player = new PlayerCannotReceiveFunds(quiz);
        // submitting
        bytes32 salt = 0;
        player.submitAnswer(0, salt);
        // judging
        quiz._judgeAnswer(0);
        player.verify(salt);
        // announcing
        quiz._announcePrize();
    }
}

contract TestNoWinnerNoSubmission {
    constructor() payable {
        Quiz quiz;
        // submitting
        // judging
        quiz._judgeAnswer(0);
        // announcing
        quiz._announcePrize();
    }
}

contract TestNoWinnerNobodyRight {
    constructor() payable {
        Quiz quiz;
        Player player1 = new Player(quiz);
        Player player2 = new Player(quiz);
        // submitting
        bytes32 salt1 = 0;
        bytes32 salt2 = 0;
        player1.submitAnswer(0, salt1);
        player2.submitAnswer(0, salt2);
        // judging
        quiz._judgeAnswer(bytes32(uint256(1)));
        player1.verify(salt1);
        player2.verify(salt2);
        // announcing
        quiz._announcePrize();
    }
}

contract TestReplay {
    constructor() payable {
        Quiz quiz;
        Player player1 = new Player(quiz);
        Player player2 = new Player(quiz);
        // submitting
        bytes32 salt1 = 0;
        bytes32 encodedAns = player1.getEncodedAnswer(0, salt1);
        player2.submitEncodedAnswer(encodedAns /* player 2 saw player 1's transaction and stole its hashed answer */);
        // judging 
        quiz._judgeAnswer(0);
        player1.verify(salt1);
        try player2.verify(salt1 /* player 2 saw player 1's transaction and stole its salt */) {
            require(false, "Replay attack should be reverted!");
        } catch (bytes memory) {}
        // announcing 
        quiz._announcePrize();
    }
}

