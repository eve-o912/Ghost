// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ISomniaReactivity.sol";
import "./PresenceTracker.sol";

contract GhostVault is SomniaEventHandler {
    ISomniaReactivity public constant REACTIVITY =
        ISomniaReactivity(REACTIVITY_PRECOMPILE);

    uint256 public constant CLAIM_WINDOW_BLOCKS = 30;
    uint256 public constant TRIGGER_THRESHOLD = 0.01 ether;

    PresenceTracker public immutable presenceTracker;
    address public immutable watchedProtocol;
    address public immutable owner;

    struct ClaimWindow {
        uint256 triggerBlock;
        uint256 windowEndBlock;
        uint256 rewardPerClaim;
        address triggerWallet;
        bool isOpen;
        uint256 totalClaims;
        uint256 maxClaims;
    }

    ClaimWindow public currentWindow;
    mapping(bytes32 => bool) private _claimed;

    uint256 public windowCounter;
    uint256 public vaultSubscriptionId;
    uint256 public totalPaidOut;

    event VaultTriggered(
        uint256 indexed windowId,
        address indexed triggeredBy,
        uint256 triggerBlock,
        uint256 windowEndBlock,
        uint256 rewardPerClaim,
        uint256 amountIn
    );

    event PresenceClaimed(
        uint256 indexed windowId,
        address indexed claimer,
        uint256 amount,
        uint256 claimerLastActiveBlock
    );

    event WindowClosed(uint256 indexed windowId, uint256 totalClaims, uint256 totalPaid);
    event SubscriptionRegistered(uint256 subscriptionId, address watchedContract);
    event FundsDeposited(address indexed from, uint256 amount);

    constructor(
        address _presenceTracker,
        address _watchedProtocol
    ) payable {
        presenceTracker = PresenceTracker(_presenceTracker);
        watchedProtocol = _watchedProtocol;
        owner = msg.sender;
    }

    /// @notice Call once after deployment. Send >= 32 STT.
    function registerSubscription() external payable {
        require(msg.sender == owner, "GhostVault: not owner");

        bytes32 swapEventSig = keccak256(
            "Swap(address,address,uint256,uint256,uint256)"
        );

        bytes32[] memory topics = new bytes32[](1);
        topics[0] = swapEventSig;

        ISomniaReactivity.SubscriptionConfig memory config = ISomniaReactivity
            .SubscriptionConfig({
                emitter: watchedProtocol,
                eventTopics: topics,
                isGuaranteed: true,
                maxGasLimit: 200_000
            });

        vaultSubscriptionId = REACTIVITY.subscribe{value: msg.value}(config);
        emit SubscriptionRegistered(vaultSubscriptionId, watchedProtocol);
    }

    function _onEvent(
        address emitter,
        bytes32[] calldata topics,
        bytes calldata data
    ) external override onlyPrecompile {
        require(emitter == watchedProtocol, "GhostVault: wrong emitter");

        if (currentWindow.isOpen && block.number > currentWindow.windowEndBlock) {
            _closeWindow();
        }

        if (currentWindow.isOpen) return;

        uint256 amountIn;
        if (data.length >= 32) {
            amountIn = abi.decode(data, (uint256));
        }

        if (amountIn < TRIGGER_THRESHOLD) return;

        address triggerWallet;
        if (topics.length >= 2) {
            triggerWallet = address(uint160(uint256(topics[1])));
        }

        uint256 vaultBalance = address(this).balance;
        require(vaultBalance > 0, "GhostVault: vault is empty");

        uint256 rewardPool = vaultBalance / 10;
        uint256 maxClaimers = rewardPool > 1 ether ? rewardPool / (0.1 ether) : 1;
        uint256 rewardPerClaim = rewardPool / maxClaimers;

        windowCounter++;
        currentWindow = ClaimWindow({
            triggerBlock: block.number,
            windowEndBlock: block.number + CLAIM_WINDOW_BLOCKS,
            rewardPerClaim: rewardPerClaim,
            triggerWallet: triggerWallet,
            isOpen: true,
            totalClaims: 0,
            maxClaims: maxClaimers
        });

        emit VaultTriggered(
            windowCounter,
            triggerWallet,
            block.number,
            block.number + CLAIM_WINDOW_BLOCKS,
            rewardPerClaim,
            amountIn
        );
    }

    function claim() external {
        ClaimWindow storage w = currentWindow;

        if (w.isOpen && block.number > w.windowEndBlock) {
            _closeWindow();
        }

        require(w.isOpen, "GhostVault: no open window");
        require(w.totalClaims < w.maxClaims, "GhostVault: max claims reached");

        bytes32 claimKey = keccak256(abi.encodePacked(windowCounter, msg.sender));
        require(!_claimed[claimKey], "GhostVault: already claimed this window");

        bool wasPresent = presenceTracker.wasActiveInWindow(
            msg.sender,
            w.triggerBlock,
            w.windowEndBlock
        );
        require(wasPresent, "GhostVault: no presence proof for this window");

        _claimed[claimKey] = true;
        w.totalClaims++;

        uint256 payout = w.rewardPerClaim;
        if (payout > address(this).balance) {
            payout = address(this).balance;
        }

        totalPaidOut += payout;

        if (w.totalClaims >= w.maxClaims) {
            w.isOpen = false;
            emit WindowClosed(windowCounter, w.totalClaims, totalPaidOut);
        }

        (bool success, ) = payable(msg.sender).call{value: payout}("");
        require(success, "GhostVault: transfer failed");

        emit PresenceClaimed(
            windowCounter,
            msg.sender,
            payout,
            presenceTracker.lastActiveBlock(msg.sender)
        );
    }

    function _closeWindow() internal {
        emit WindowClosed(windowCounter, currentWindow.totalClaims, totalPaidOut);
        currentWindow.isOpen = false;
    }

    struct VaultStatus {
        bool windowOpen;
        uint256 triggerBlock;
        uint256 windowEndBlock;
        uint256 blocksRemaining;
        uint256 rewardPerClaim;
        uint256 claimsRemaining;
        address triggerWallet;
        uint256 vaultBalance;
        uint256 windowCounter;
        uint256 totalPaidOut;
    }

    function getStatus() external view returns (VaultStatus memory) {
        ClaimWindow memory w = currentWindow;
        bool open = w.isOpen && block.number <= w.windowEndBlock;
        uint256 blocksLeft = open ? w.windowEndBlock - block.number : 0;

        return VaultStatus({
            windowOpen: open,
            triggerBlock: w.triggerBlock,
            windowEndBlock: w.windowEndBlock,
            blocksRemaining: blocksLeft,
            rewardPerClaim: w.rewardPerClaim,
            claimsRemaining: open ? w.maxClaims - w.totalClaims : 0,
            triggerWallet: w.triggerWallet,
            vaultBalance: address(this).balance,
            windowCounter: windowCounter,
            totalPaidOut: totalPaidOut
        });
    }

    function hasClaimed(address wallet) external view returns (bool) {
        bytes32 claimKey = keccak256(abi.encodePacked(windowCounter, wallet));
        return _claimed[claimKey];
    }

    function myPresenceBlock() external view returns (uint256) {
        return presenceTracker.lastActiveBlock(msg.sender);
    }

    receive() external payable {
        emit FundsDeposited(msg.sender, msg.value);
    }

    function drain() external {
        require(msg.sender == owner, "GhostVault: not owner");
        payable(owner).transfer(address(this).balance);
    }
}
