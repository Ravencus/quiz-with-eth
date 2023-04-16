// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2;

contract Quiz {
    address owner;
    mapping(address => bytes32) submission;
    mapping(address => uint256) bet;
    mapping(address => bool) verified;
    address payable[] winner;
    bytes32 correctAnswer;

    enum Status {
        Submitting,
        Judging,
        Announcing
    }
    Status public status = Status.Submitting;

    constructor() {
        owner = msg.sender;
    }

    function submitAnswer(bytes32 answer) external payable {
        require(status == Status.Submitting);
        require(msg.value > 0);
        submission[msg.sender] = answer;
        bet[msg.sender] = msg.value;
        verified[msg.sender] = false;
    }

    function verifyAnswer(bytes32 salt) external {
        require(status == Status.Judging);
        require(verified[msg.sender] == false);

        bytes32 expected = keccak256(
            abi.encodePacked(correctAnswer, salt, msg.sender)
        );
        require(expected == submission[msg.sender]);

        winner.push(payable(msg.sender));
        verified[msg.sender] = true;
    }

    function _judgeAnswer(bytes32 _correctAnswer) external {
        require(status == Status.Submitting);
        require(msg.sender == owner);
        correctAnswer = _correctAnswer;
        status = Status.Judging;
    }

    function _announcePrize() external {
        require(msg.sender == owner);
        require(status == Status.Judging);
        status = Status.Announcing;

        uint256 allMoney = (address(this).balance / 10) * 9;
        uint256 winnersMoney = 0;
        for (uint256 i = 0; i < winner.length; i++) {
            winnersMoney += bet[winner[i]];
        }

        for (uint256 i = 0; i < winner.length; i++) {
            uint256 money = (allMoney * bet[winner[i]]) / winnersMoney;
            if (money > 0) winner[i].call{value: money}("");
        }
    }
}
