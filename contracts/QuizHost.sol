// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.11;

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

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.8.3/contracts/token/ERC20/ERC20.sol";

// import "hardhat/console.sol";

contract QuizWithERC20 is ERC20 {
    address owner;
    uint256 public registerToken = 10**decimals();
    // uint256 blkNumOnConstructed;
    mapping(address => bytes32) submission;
    mapping(address => uint256) bet;
    mapping(address => bool) verified;
    address payable[] winner;
    bytes32 correctAnswer;

    enum Status {
        Registering,
        Submitting,
        Judging,
        Announcing
    }
    Status public status = Status.Registering;

    // erc20 override
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        owner = msg.sender;
        // blkNumOnConstructed = block.number;
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    { 
        require(msg.sender == owner || to == owner);
        return super.transfer(to, amount);
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        require(false);
        return super.approve(spender, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        require(false);
    }

    // original contract
    function register() public {
        require(status == Status.Registering);
        require(balanceOf(msg.sender) == 0);
        _mint(msg.sender, registerToken);
    }

    function submitAnswer(bytes32 answer, uint256 playerBet) external {
        require(status == Status.Submitting);
        require(playerBet > 0);
        transfer(owner, playerBet);

        submission[msg.sender] = answer;
        bet[msg.sender] = playerBet;
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

    function _startQuiz() external {
        require(status == Status.Registering);
        require(msg.sender == owner);
        status = Status.Submitting;
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

        uint256 allMoney = balanceOf(owner); 
        uint256 winnersMoney = 0;
        for (uint256 i = 0; i < winner.length; i++) {
            winnersMoney += bet[winner[i]];
        } 

        for (uint256 i = 0; i < winner.length; i++) {
            uint256 money = (allMoney * bet[winner[i]]) / winnersMoney; 
            if (money > 0) {
                transfer(winner[i], money);
            }
        }
    }
}
