// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ArcInfoAgent {
    address public owner;
    uint256 public queryFee = 0.001 ether;
    uint256 public totalQueries;

    // Points per query: random between 2-5
    mapping(address => uint256) public userPoints;
    mapping(address => uint256) public userQueryCount;

    // Leaderboard: top users array (max 100)
    address[] public leaderboardUsers;
    mapping(address => bool) public isInLeaderboard;

    event QuerySubmitted(address indexed user, string question, uint256 queryId, uint256 pointsEarned);
    event PointsEarned(address indexed user, uint256 points, uint256 totalPoints);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    // Pseudo-random points between 2-5
    function _getRandomPoints(address user, uint256 queryId) internal view returns (uint256) {
        uint256 rand = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            user,
            queryId
        ))) % 4; // 0-3
        return rand + 2; // 2-5
    }

    function askQuestion(string memory question) public payable {
        require(msg.value >= queryFee, "Insufficient fee");
        require(bytes(question).length > 0, "Question cannot be empty");
        require(bytes(question).length <= 500, "Question too long");

        totalQueries++;
        uint256 queryId = totalQueries;

        // Award points
        uint256 points = _getRandomPoints(msg.sender, queryId);
        userPoints[msg.sender] += points;
        userQueryCount[msg.sender]++;

        // Add to leaderboard if new user
        if (!isInLeaderboard[msg.sender]) {
            isInLeaderboard[msg.sender] = true;
            leaderboardUsers.push(msg.sender);
        }

        emit QuerySubmitted(msg.sender, question, queryId, points);
        emit PointsEarned(msg.sender, points, userPoints[msg.sender]);

        // Refund excess
        if (msg.value > queryFee) {
            payable(msg.sender).transfer(msg.value - queryFee);
        }
    }

    // Get top N leaderboard entries (sorted off-chain)
    function getLeaderboard(uint256 limit) public view returns (
        address[] memory users,
        uint256[] memory points,
        uint256[] memory queryCounts
    ) {
        uint256 total = leaderboardUsers.length;
        uint256 size = limit < total ? limit : total;

        users = new address[](size);
        points = new uint256[](size);
        queryCounts = new uint256[](size);

        // Simple copy (sorting done on frontend)
        for (uint256 i = 0; i < size; i++) {
            users[i] = leaderboardUsers[i];
            points[i] = userPoints[leaderboardUsers[i]];
            queryCounts[i] = userQueryCount[leaderboardUsers[i]];
        }
    }

    function getTotalUsers() public view returns (uint256) {
        return leaderboardUsers.length;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function setQueryFee(uint256 newFee) public onlyOwner {
        queryFee = newFee;
    }

    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}
