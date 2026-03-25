# GhostVault // Somnia Reactivity

> No oracle. No keeper. No whitelist. No permission from the watched contract.

GhostVault is a **trustless rewards system** built on [Somnia Network](https://somnia.network/) that uses the native **Reactivity Precompile** to watch for on-chain events and reward active participants without any external infrastructure.

---

## Quick Links

| Resource | URL |
|----------|-----|
| **Somnia Docs** | https://docs.somnia.network |
| **Network Info** | https://docs.somnia.network/developer/network-info |
| **Testnet Faucet** | https://testnet.somnia.network |
| **Testnet Explorer** | https://shannon-explorer.somnia.network |
| **Mainnet Explorer** | https://explorer.somnia.network |

---

## Somnia Network Configuration

### Shannon Testnet (Recommended for Development)

```yaml
Chain ID: 50312
Symbol: STT (Somnia Test Token)
RPC: https://dream-rpc.somnia.network
Explorer: https://shannon-explorer.somnia.network
Alternative Explorer: https://somnia-testnet.socialscan.io

Contracts:
  Multicall3: 0x841b8199E6d3Db3C6f264f6C2bd8848b3cA64223
  EntryPoint v0.7: 0x0000000071727De22E5E9d8BAf0edAc6f37da032
  Factory: 0x4bE0ddfebcA9A5A4a617dee4DeCe99E7c862dceb
  Reactivity Precompile: 0x0000000000000000000000000000000000000100
```

### Mainnet

```yaml
Chain ID: 5031
Symbol: SOMI
RPC: https://api.infra.mainnet.somnia.network
Explorer: https://explorer.somnia.network

Contracts:
  Multicall3: 0x5e44F178E8cF9B2F5409B6f18ce936aB817C5a11
  Reactivity Precompile: 0x0000000000000000000000000000000000000100
```

### Faucets (Testnet STT)

- **Official**: https://testnet.somnia.network
- **Stakely**: https://stakely.io/faucet/somnia-testnet-stt
- **Thirdweb**: https://thirdweb.com/somnia-shannon-testnet
- **Google Cloud**: https://cloud.google.com/application/web3/faucet/somnia/shannon

---

## Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  WatchedProtocol │────▶│ Reactivity       │────▶│  GhostVault     │
│  (any contract)  │ Swap │ Precompile       │ Swap │ (rewards vault) │
└─────────────────┘     │ 0x00...0100      │     └─────────────────┘
                        └──────────────────┘              │
                               │                        │
                               │ Wildcard               │ Verify
                               ▼                        ▼
                        ┌──────────────────┐     ┌─────────────────┐
                        │  PresenceTracker │────▶│  Proof of       │
                        │ (all events)     │     │  Presence Check │
                        └──────────────────┘     └─────────────────┘
```

**Key Innovation**: Reactivity allows contracts to subscribe to events from *any* other contract without that contract's permission or modification.

---

## Deployment

### Prerequisites

1. **Install Foundry**:
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

2. **Get Testnet STT** from any faucet above

3. **Set environment**:
   ```bash
   cp .env.example .env
   # Edit .env with your PRIVATE_KEY
   ```

### Deploy Commands

```bash
# Deploy to Somnia Shannon Testnet
forge script script/Deploy.s.sol:Deploy \
  --rpc-url https://dream-rpc.somnia.network \
  --private-key $PRIVATE_KEY \
  --broadcast -vvvv

# Or use foundry.toml alias
forge script script/Deploy.s.sol:Deploy \
  --rpc-url somnia-testnet \
  --broadcast -vvvv
```

### Post-Deployment Setup

After deployment, you must fund subscriptions (32+ STT each):

```bash
export PRESENCE_TRACKER=<address from output>
export GHOST_VAULT=<address from output>

# 1. Fund PresenceTracker wildcard subscription
cast send $PRESENCE_TRACKER "registerWildcardSubscription()" \
  --value 32ether \
  --rpc-url https://dream-rpc.somnia.network \
  --private-key $PRIVATE_KEY

# 2. Fund GhostVault subscription to WatchedProtocol
cast send $GHOST_VAULT "registerSubscription()" \
  --value 32ether \
  --rpc-url https://dream-rpc.somnia.network \
  --private-key $PRIVATE_KEY

# 3. Add rewards pool to GhostVault
cast send $GHOST_VAULT \
  --value 10ether \
  --rpc-url https://dream-rpc.somnia.network \
  --private-key $PRIVATE_KEY
```

---

## Frontend Integration

The frontend (`index.html`) includes:
- Real-time radar visualization
- Wallet connection (MetaMask compatible)
- Proof of presence verification
- Live event feed from Somnia testnet

### Wallet Configuration

Add Somnia Testnet to MetaMask:

| Field | Value |
|-------|-------|
| Network Name | Somnia Shannon Testnet |
| RPC URL | https://dream-rpc.somnia.network |
| Chain ID | 50312 |
| Currency Symbol | STT |
| Block Explorer | https://shannon-explorer.somnia.network |

### Network Config (src/networks.js)

```javascript
import { somniaTestnet, somniaMainnet } from './networks.js';

// Use with wagmi/viem
const config = createConfig({
  chains: [somniaTestnet, somniaMainnet],
  // ...
});
```

---

## How It Works

1. **PresenceTracker** subscribes to **all events** from **all contracts** (wildcard)
2. **GhostVault** subscribes only to `Swap` events from **WatchedProtocol**
3. When a large swap (≥0.01 STT) occurs:
   - GhostVault opens a **30-block claim window**
   - Reward pool = 10% of vault balance
   - Max claimants = rewardPool / 0.1 STT
4. Users can **claim** if their wallet was recorded active by PresenceTracker during the window

**Key Property**: No oracle, no keeper, no off-chain computation required. All verification happens on-chain via the Reactivity precompile.

---

## Contract Addresses

Fill this in after deployment:

| Contract | Testnet | Mainnet |
|----------|---------|---------|
| GhostVault | `0x...` | `0x...` |
| PresenceTracker | `0x...` | `0x...` |
| WatchedProtocol | `0x...` | `0x...` |

---

## Resources

- [Somnia Network Docs](https://docs.somnia.network)
- [Foundry Book](https://book.getfoundry.sh/)
- [Solidity by Example](https://solidity-by-example.org/)
- [Somnia Discord](https://discord.com/invite/Somnia)

---

## License

MIT
