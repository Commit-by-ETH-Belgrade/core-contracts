// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { IChronicle, ISelfKisser } from "./interfaces/IChronicle.sol";

contract Commit {
    uint256 constant MULTIPLIER = 1e18;

    IChronicle public immutable chronicle;
    ISelfKisser public immutable selfKiss;

    uint256 public eventId;

    struct EventConfig {
        // usd price
        uint128 price;
        uint128 totalStaked;
        address eventOwner;
        bool inactive;
    }

    mapping(uint256 => EventConfig) public events;
    mapping(address => mapping(uint256 => uint128)) public userStake;

    event Created(uint256 indexed eventId);

    event Staked(address indexed user, uint256 eventId);

    event Slashed(uint256 indexed eventId, address user);

    event Unstake(uint256 indexed eventId, address user);

    constructor(IChronicle _chronicle, ISelfKisser _selfKiss) {
        // Note to add address(this) to chronicle oracle's whitelist.
        // This allows the contract to read from the chronicle oracle.

        chronicle = _chronicle;
        selfKiss = _selfKiss;

        if (address(_selfKiss) != address(0)) selfKiss.selfKiss(address(_chronicle));
    }

    function createEvent(uint128 _price) external {
        uint256 _eventId = eventId;

        EventConfig storage eventConfig = events[_eventId];
        eventConfig.eventOwner = msg.sender;
        eventConfig.price = _price;

        eventId++;

        emit Created(_eventId);
    }

    function stake(uint256 _eventId) external payable {
        if (userStake[msg.sender][_eventId] > 0) revert();

        EventConfig memory eventConfig = events[_eventId];
        if (eventConfig.inactive) revert();

        if (msg.sender == eventConfig.eventOwner) revert();

        events[_eventId].totalStaked += eventConfig.price;
        userStake[msg.sender][_eventId] = eventConfig.price;

        if (address(chronicle) != address(0)) {
            (uint256 value, uint256 age) = getETHPrice(eventConfig.price);

            if (age < block.timestamp - 86_400 /* 1 day */ ) revert();

            if (msg.value != value) revert();
        } else {
            if (msg.value != eventConfig.price) revert();
        }

        emit Staked(msg.sender, _eventId);
    }

    function slashUser(address user, uint256 _eventId) external {
        EventConfig memory eventConfig = events[_eventId];

        if (msg.sender != eventConfig.eventOwner) revert();
        uint128 stakedAmount = userStake[user][_eventId];

        if (stakedAmount == 0) revert();

        userStake[user][_eventId] = 0;

        events[_eventId].totalStaked -= stakedAmount;

        if (!eventConfig.inactive) events[_eventId].inactive = true;

        emit Slashed(_eventId, user);
    }

    function unstake(uint256 _eventId) external {
        uint128 stakedAmount = userStake[msg.sender][_eventId];

        if (stakedAmount == 0) revert();

        userStake[msg.sender][_eventId] = 0;
        events[_eventId].totalStaked -= stakedAmount;

        (uint256 ethAmount,) = address(chronicle) != address(0) ? getETHPrice(stakedAmount) : (stakedAmount, 0);

        (bool success,) = msg.sender.call{ value: ethAmount }("");
        if (!success) revert();

        emit Unstake(_eventId, msg.sender);
    }

    function getETHPrice(uint256 usdAmount) public view returns (uint256, uint256) {
        (uint256 ethPrice, uint256 age) = chronicle.readWithAge();
        uint256 value = (usdAmount * MULTIPLIER) / ethPrice;
        return (value, age);
    }

    receive() external payable { }
}
