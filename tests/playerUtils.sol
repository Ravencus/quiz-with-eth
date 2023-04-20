// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2;

import "QuizHost.sol";

contract PlayerCannotReceiveFunds {
    Quiz quiz;

    constructor(Quiz _quiz) payable {
        require(msg.value > 0);
        quiz = _quiz;
    }

    function submitAnswer(bytes32 rawAnswer, bytes32 salt) external payable {
        require(msg.value > 0);
        bytes32 encodedAnswer = keccak256(
            abi.encodePacked(rawAnswer, salt, address(this))
        );
        quiz.submitAnswer{value: msg.value}(encodedAnswer);
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

    function submitAnswer(bytes32 rawAnswer, bytes32 salt) external payable {
        submitEncodedAnswer(getEncodedAnswer(rawAnswer, salt));
    }

    function getEncodedAnswer(bytes32 rawAnswer, bytes32 salt)
        public
        view
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(rawAnswer, salt, address(this)));
    }

    function submitEncodedAnswer(bytes32 encodedAnswer) public payable {
        require(msg.value > 0);
        quiz.submitAnswer{value: msg.value}(encodedAnswer);
    }

    function verify(bytes32 mySalt) external {
        quiz.verifyAnswer(mySalt);
    }

    receive() external payable {}
}

contract PlayerERC20 {
    QuizWithERC20 quiz;

    constructor(QuizWithERC20 _quiz) {
        quiz = _quiz;
    }

    function register() external {
        quiz.register();
    }

    function balanceOf() external view returns (uint256) {
        return quiz.balanceOf(address(this));
    }

    function submitAnswer(bytes32 rawAnswer, bytes32 salt) external {
        submitEncodedAnswer(getEncodedAnswer(rawAnswer, salt));
    }

    function getEncodedAnswer(bytes32 rawAnswer, bytes32 salt)
        public
        view
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(rawAnswer, salt, address(this)));
    }

    function submitEncodedAnswer(bytes32 encodedAnswer) public {
        uint256 amount = quiz.registerToken();

        quiz.submitAnswer(encodedAnswer, amount);
    }

    function verify(bytes32 mySalt) external {
        quiz.verifyAnswer(mySalt);
    }

    /**
     * This shoud revert!
     */
    function transfer(address dst, uint256 amount) public {
        quiz.transfer(dst, amount);
    }
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
        Quiz quiz = new Quiz();
        PlayerCannotReceiveFunds player1 = new PlayerCannotReceiveFunds{
            value: 1 gwei
        }(quiz);
        Player player2 = new Player{value: 1 gwei}(quiz);
        // submitting
        bytes32 answer = 0;
        bytes32 salt = 0;
        player1.submitAnswer{value: .5 gwei}(answer, salt);
        player2.submitAnswer{value: .5 gwei}(answer, salt);
        // judging
        quiz._judgeAnswer(answer);
        player1.verify(salt);
        player2.verify(salt);
        // announcing
        quiz._announcePrize();
    }
}

contract TestNoWinnerNoSubmission {
    constructor() payable {
        Quiz quiz = new Quiz();
        // submitting
        // judging
        quiz._judgeAnswer(0);
        // announcing
        quiz._announcePrize();
    }
}

contract TestNoWinnerNobodyRight {
    constructor() payable {
        Quiz quiz = new Quiz();
        Player player1 = new Player{value: 1 gwei}(quiz);
        Player player2 = new Player{value: 1 gwei}(quiz);
        // submitting
        bytes32 answer = 0;
        bytes32 salt1 = 0;
        bytes32 salt2 = 0;
        player1.submitAnswer{value: .5 gwei}(answer, salt1);
        player2.submitAnswer{value: .5 gwei}(answer, salt2);
        // judging
        bytes32 correctAns = bytes32(uint256(1));
        require(answer != correctAns);
        quiz._judgeAnswer(correctAns);
        try player1.verify(salt1) {
            require(false, "Incorrect answer should be reverted!");
        } catch (bytes memory) {}
        try player2.verify(salt2) {
            require(false, "Incorrect answer should be reverted!");
        } catch (bytes memory) {}
        // announcing
        quiz._announcePrize();
    }
}

contract TestReplay {
    constructor() payable {
        Quiz quiz = new Quiz();
        Player player1 = new Player{value: 1 gwei}(quiz);
        Player player2 = new Player{value: 1 gwei}(quiz);
        // submitting
        bytes32 answer = 0;
        bytes32 salt1 = 0;
        bytes32 encodedAns = player1.getEncodedAnswer(answer, salt1);
        player1.submitEncodedAnswer{value: .5 gwei}(encodedAns);
        player2.submitEncodedAnswer{value: .5 gwei}(
            encodedAns /* player 2 saw player 1's transaction and stole its hashed answer */
        );
        // judging
        quiz._judgeAnswer(answer);
        player1.verify(salt1);
        try
            player2.verify(
                salt1 /* player 2 saw player 1's transaction and stole its salt */
            )
        {
            require(false, "Replay attack should be reverted!");
        } catch (bytes memory) {}
        // announcing
        quiz._announcePrize();
    }
}

contract TestQuizWithERC20 {
    QuizWithERC20 public quiz;
    PlayerERC20 public player1;
    PlayerERC20 public player2;
    bytes32 answer1 = 0;
    bytes32 answer2 = bytes32(uint256(1));
    bytes32 salt = 0;

    constructor() payable {
        quiz = new QuizWithERC20("Quiz", "QZ");
        player1 = new PlayerERC20(quiz);
        player2 = new PlayerERC20(quiz);
        // registering
        player1.register();
        player2.register();
        // submitting
        quiz._startQuiz(); 
        require(answer1 != answer2); 
        player1.submitAnswer(answer1, salt);
        player2.submitAnswer(answer2, salt);
        // judging
        quiz._judgeAnswer(answer1);
        player1.verify(salt);
        try player2.verify(salt) {
            require(false, "Incorrect answer should be reverted!");
        } catch (bytes memory) {}
        //  announcing
        quiz._announcePrize();
        require(quiz.balanceOf(address(player1)) == 2 * quiz.registerToken());
        require(quiz.balanceOf(address(player2)) == 0);
    }
}

contract TestDenyPlayerTransferBetween {
    QuizWithERC20 public quiz;
    PlayerERC20 public player1;
    PlayerERC20 public player2; 

    constructor() payable {
        quiz = new QuizWithERC20("Quiz", "QZ");
        player1 = new PlayerERC20(quiz);
        player2 = new PlayerERC20(quiz);
        // registering
        player1.register();
        player2.register();
        // transfer
        try player1.transfer(address(player2), 1) {
            require(
                false,
                "Players should not be able to transfer between players!"
            );
        } catch (bytes memory) {}
        try player2.transfer(address(player1), 1) {
            require(
                false,
                "Players should not be able to transfer between players!"
            );
        } catch (bytes memory) {}
    }
}
