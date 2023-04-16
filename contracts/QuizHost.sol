// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2;

contract Quiz {
    address owner;
    mapping(address => bytes32) public submission;
    mapping(address => uint) public bet;
    address payable[] public winner;
    bytes32 public correctAnswer;

    enum Status {
        Submitting,
        Judging,
        Announcing
    }
    Status public status = Status.Submitting;

    constructor(){
        owner = msg.sender;
    }

    function submitAnswer(bytes32 answer) payable external  {
        require(status == Status.Submitting);
        require(msg.value > 0);
        submission[msg.sender] = answer;
        bet[msg.sender] = msg.value;
    }

    function verifyAnswer(bytes32 salt) external {
        require(status == Status.Judging);
        bytes32 expected = keccak256(abi.encodePacked(correctAnswer, salt, msg.sender));
        require(expected == submission[msg.sender]);
        winner.push(payable(msg.sender));
    }

    function _judgeAnswer(bytes32 _correctAnswer) external {
        require(msg.sender == owner);
        correctAnswer = _correctAnswer;
        status = Status.Judging;
    }

    function _announcePrize() external {
        require(msg.sender==owner);
        status=Status.Announcing;

        // uint winnersBet=0;


        for (uint i=0; i<winner.length; i++) {
            uint money = bet[winner[i]];
            winner[i].call{value: money}("");
        }
    }


}
