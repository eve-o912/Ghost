// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ISomniaReactivity.sol";

contract PresenceTracker is SomniaEventHandler {
    ISomniaReactivity public constant REACTIVITY =
        ISomniaReactivity(REACTIVITY_PRECOMPILE);

    mapping(address => uint256) public lastActiveBlock;
    uint256 public totalTracked;
    mapping(uint256 => address[]) private _blockActivity;

    uint256 public wildcardSubscriptionId;
    address public immutable owner;

    event PresenceRecorded(address indexed wallet, uint256 indexed blockNumber);
    event SubscriptionCreated(uint256 subscriptionId);

    constructor() payable {
        owner = msg.sender;
    }

    /// @notice Call once after deployment. Send >= 32 STT.
    function registerWildcardSubscription() external payable {
        require(msg.sender == owner, "PresenceTracker: not owner");

        bytes32[] memory emptyTopics = new bytes32[](0);

        ISomniaReactivity.SubscriptionConfig memory config = ISomniaReactivity
            .SubscriptionConfig({
                emitter: address(0),      // WILDCARD — every contract
                eventTopics: emptyTopics, // WILDCARD — every event
                isGuaranteed: true,
                maxGasLimit: 100_000
            });

        wildcardSubscriptionId = REACTIVITY.subscribe{value: msg.value}(config);
        emit SubscriptionCreated(wildcardSubscriptionId);
    }

    function _onEvent(
        address emitter,
        bytes32[] calldata topics,
        bytes calldata data
    ) external override onlyPrecompile {
        uint256 blockNum = block.number;

        _recordActivity(emitter, blockNum);

        if (topics.length >= 2) {
            address fromWallet = address(uint160(uint256(topics[1])));
            if (fromWallet != address(0)) {
                _recordActivity(fromWallet, blockNum);
            }
        }

        if (topics.length >= 3) {
            address toWallet = address(uint160(uint256(topics[2])));
            if (toWallet != address(0) && toWallet != emitter) {
                _recordActivity(toWallet, blockNum);
            }
        }
    }

    function _recordActivity(address wallet, uint256 blockNum) internal {
        if (wallet == address(0)) return;
        bool isNew = lastActiveBlock[wallet] == 0;
        lastActiveBlock[wallet] = blockNum;
        _blockActivity[blockNum].push(wallet);
        if (isNew) totalTracked++;
        emit PresenceRecorded(wallet, blockNum);
    }

    function wasActiveInWindow(
        address wallet,
        uint256 startBlock,
        uint256 endBlock
    ) external view returns (bool) {
        uint256 last = lastActiveBlock[wallet];
        return last >= startBlock && last <= endBlock;
    }

    function getBlockActivity(uint256 blockNum)
        external
        view
        returns (address[] memory wallets, uint256 total)
    {
        address[] storage all = _blockActivity[blockNum];
        uint256 len = all.length > 50 ? 50 : all.length;
        wallets = new address[](len);
        for (uint256 i = 0; i < len; i++) {
            wallets[i] = all[i];
        }
        total = all.length;
    }

    receive() external payable {}
}
