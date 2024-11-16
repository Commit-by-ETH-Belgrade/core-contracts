// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Commit {
    uint256 public eventId;

    struct EventConfig {
        uint128 price;
        uint128 totalStaked;
        IERC20 token;
        address slashRecipient;
        bool inactive;
    }

    mapping(uint256 => EventConfig) public events;
    mapping(address => mapping(uint256 => uint128)) public userStake;

    event Created(uint256 indexed eventId);

    event Staked(address indexed user, uint256 eventId);

    event Slashed(uint256 indexed eventId, address user);

    event Unstake(uint256 indexed eventId, address user);

    function createEvent(IERC20 token) external {
        uint256 _eventId = eventId;

        EventConfig storage eventConfig = events[_eventId];
        eventConfig.token = token;
        eventConfig.slashRecipient = msg.sender;

        emit Created(_eventId);
    }

    function stake(uint256 _eventId) external payable {
        if (userStake[msg.sender][_eventId] > 0) revert();

        EventConfig memory eventConfig = events[_eventId];
        if (eventConfig.inactive) revert();

        if (msg.sender == eventConfig.slashRecipient) revert();

        events[_eventId].totalStaked += eventConfig.price;
        userStake[msg.sender][_eventId] = eventConfig.price;

        if (address(eventConfig.token) == address(0) && msg.value != eventConfig.price) {
            revert();
        } else {
            bool success = eventConfig.token.transferFrom(msg.sender, address(this), eventConfig.price);
            if (!success) revert();
        }

        emit Staked(msg.sender, _eventId);
    }

    function slashUser(address user) external {
        uint256 _eventId = eventId;
        EventConfig memory eventConfig = events[_eventId];

        if (msg.sender != eventConfig.slashRecipient) revert();
        uint128 stakedAmount = userStake[user][_eventId];

        userStake[user][_eventId] = 0;

        events[_eventId].totalStaked -= stakedAmount;

        if (!eventConfig.inactive) events[_eventId].inactive = true;

        if (address(eventConfig.token) == address(0)) {
            (bool success,) = eventConfig.slashRecipient.call{ value: stakedAmount }("");
            if (!success) revert();
        } else {
            bool success = eventConfig.token.transfer(eventConfig.slashRecipient, stakedAmount);
            if (!success) revert();
        }

        emit Slashed(_eventId, user);
    }

    function unstake(uint256 _eventId) external {
        EventConfig memory eventConfig = events[_eventId];
        if (!eventConfig.inactive) revert();

        uint128 stakedAmount = userStake[msg.sender][_eventId];

        userStake[msg.sender][_eventId] = 0;
        events[_eventId].totalStaked -= stakedAmount;

        if (address(eventConfig.token) == address(0)) {
            (bool success,) = eventConfig.slashRecipient.call{ value: stakedAmount }("");
            if (!success) revert();
        } else {
            bool success = eventConfig.token.transfer(eventConfig.slashRecipient, stakedAmount);
            if (!success) revert();
        }

        emit Unstake(_eventId, msg.sender);
    }
}
