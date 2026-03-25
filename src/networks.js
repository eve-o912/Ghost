// Somnia Network Configuration
// https://docs.somnia.network/developer/network-info

export const somniaTestnet = {
  id: 50312,
  name: 'Somnia Shannon Testnet',
  network: 'somnia-testnet',
  nativeCurrency: {
    name: 'Somnia Test Token',
    symbol: 'STT',
    decimals: 18,
  },
  rpcUrls: {
    default: {
      http: ['https://dream-rpc.somnia.network'],
    },
    public: {
      http: [
        'https://dream-rpc.somnia.network',
        'https://vsf-rpc.somnia.network',
      ],
    },
  },
  blockExplorers: {
    default: {
      name: 'Somnia Shannon Explorer',
      url: 'https://shannon-explorer.somnia.network',
    },
    socialscan: {
      name: 'SocialScan',
      url: 'https://somnia-testnet.socialscan.io',
    },
  },
  contracts: {
    multicall3: {
      address: '0x841b8199E6d3Db3C6f264f6C2bd8848b3cA64223',
      blockCreated: 1,
    },
    entryPointV07: {
      address: '0x0000000071727De22E5E9d8BAf0edAc6f37da032',
    },
    // Reactivity Precompile (Somnia native)
    reactivityPrecompile: {
      address: '0x0000000000000000000000000000000000000100',
    },
  },
  testnet: true,
};

export const somniaMainnet = {
  id: 5031,
  name: 'Somnia Mainnet',
  network: 'somnia',
  nativeCurrency: {
    name: 'Somnia',
    symbol: 'SOMI',
    decimals: 18,
  },
  rpcUrls: {
    default: {
      http: ['https://api.infra.mainnet.somnia.network'],
    },
    public: {
      http: [
        'https://api.infra.mainnet.somnia.network',
        'https://somnia.publicnode.com',
        'https://somnia-json-rpc.stakely.io',
      ],
    },
  },
  blockExplorers: {
    default: {
      name: 'Somnia Explorer',
      url: 'https://explorer.somnia.network',
    },
  },
  contracts: {
    multicall3: {
      address: '0x5e44F178E8cF9B2F5409B6f18ce936aB817C5a11',
      blockCreated: 1,
    },
    reactivityPrecompile: {
      address: '0x0000000000000000000000000000000000000100',
    },
  },
};

// Contract addresses (to be updated after deployment)
export const contractAddresses = {
  testnet: {
    ghostVault: null,       // Deploy then paste address
    presenceTracker: null,  // Deploy then paste address
    watchedProtocol: null,  // Deploy then paste address
  },
  mainnet: {
    ghostVault: null,
    presenceTracker: null,
    watchedProtocol: null,
  },
};

// Faucet URLs
export const faucets = {
  stakely: 'https://stakely.io/faucet/somnia-testnet-stt',
  thirdweb: 'https://thirdweb.com/somnia-shannon-testnet',
  googleCloud: 'https://cloud.google.com/application/web3/faucet/somnia/shannon',
  official: 'https://testnet.somnia.network',
};

// Export for use with viem/wagmi
export const supportedChains = [somniaTestnet, somniaMainnet];
