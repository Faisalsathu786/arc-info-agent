// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract ArcInfoAgent {
    address public owner;
    uint256 public queryFee;
    uint256 public totalQueries;
    
    event QuerySubmitted(address indexed user, string question, uint256 queryId);
    event FeeUpdated(uint256 newFee);
    event Withdrawn(uint256 amount);

    constructor(uint256 _queryFee) {
        owner = msg.sender;
        queryFee = _queryFee;
    }

    function askQuestion(string memory question) public payable {
        require(msg.value >= queryFee, "insufficient fee");
        totalQueries++;
        emit QuerySubmitted(msg.sender, question, totalQueries);
        if (msg.value > queryFee) {
            payable(msg.sender).transfer(msg.value - queryFee);
        }
    }

    function setFee(uint256 _newFee) public {
        require(msg.sender == owner, "not owner");
        queryFee = _newFee;
        emit FeeUpdated(_newFee);
    }

    function withdraw() public {
        require(msg.sender == owner, "not owner");
        uint256 bal = address(this).balance;
        require(bal > 0, "nothing to withdraw");
        payable(owner).transfer(bal);
        emit Withdrawn(bal);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
