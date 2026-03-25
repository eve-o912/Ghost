// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ISomniaReactivity {
    struct SubscriptionConfig {
        address emitter;          // address(0) = wildcard (any contract)
        bytes32[] eventTopics;    // topic[0] = event sig, [] = all events
        bool isGuaranteed;        // true = chain retries on revert
        uint256 maxGasLimit;      // gas cap per callback
    }

    function subscribe(SubscriptionConfig calldata config)
        external
        payable
        returns (uint256 subscriptionId);

    function unsubscribe(uint256 subscriptionId) external;
}

abstract contract SomniaEventHandler {
    address internal constant REACTIVITY_PRECOMPILE = address(0x0100);

    modifier onlyPrecompile() {
        require(
            msg.sender == REACTIVITY_PRECOMPILE,
            "GhostVault: caller is not the Reactivity precompile"
        );
        _;
    }

    function _onEvent(
        address emitter,
        bytes32[] calldata topics,
        bytes calldata data
    ) external virtual onlyPrecompile {}
}
