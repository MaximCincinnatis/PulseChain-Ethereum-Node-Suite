# Blockchain Node Setup

This project provides a unified setup system for running either a PulseChain or Ethereum node. The setup process is designed to be user-friendly while maintaining high reliability and security standards.

## Overview

The system allows you to set up either:
- A PulseChain node (mainnet or testnet)
- An Ethereum node (mainnet, Goerli, or Sepolia)

**Important:** It is recommended to run only one type of node per machine unless you have significant hardware resources available.

## System Requirements

### PulseChain Node
- Minimum 16GB RAM
- 1TB+ storage space
- 4+ CPU cores
- Stable internet connection

### Ethereum Node
- Minimum 16GB RAM
- 1TB+ storage space (2TB+ recommended for archive nodes)
- 4+ CPU cores
- Stable internet connection

## Getting Started

1. Run the setup script:
```bash
./menu_new.sh
```

2. Choose your preferred blockchain:
   - Option 1: PulseChain Node
   - Option 2: Ethereum Node

3. Follow the setup wizard for your chosen blockchain

## Features

### PulseChain Node
- Full node setup
- Archive node options
- Built-in monitoring
- Automatic updates
- Health checks

### Ethereum Node
- Multiple client options:
  - Execution: Geth or Erigon
  - Consensus: Lighthouse or Prysm
- Full sync options
- Built-in monitoring
- Health checks

## Directory Structure

```
/blockchain/
├── pulsechain/        # PulseChain node data (if installed)
│   ├── execution/
│   └── consensus/
├── ethereum/          # Ethereum node data (if installed)
│   ├── execution/
│   └── consensus/
└── monitoring/        # Shared monitoring data
```

## Configuration

Each node type maintains its own configuration files:
- PulseChain: `/blockchain/node_config.json`
- Ethereum: `/blockchain/ethereum/eth_node_config.json`

## Safety Features

The setup system includes several safety measures:
1. Checks for existing installations
2. Verifies system requirements
3. Validates network connectivity
4. Ensures proper permissions
5. Prevents port conflicts

## Troubleshooting

If you encounter issues:
1. Check the logs in the respective node's log directory
2. Verify system requirements are met
3. Ensure no port conflicts exist
4. Check disk space availability

## Support

For support:
1. Check the documentation in the `docs/` directory
2. Review the troubleshooting guide
3. Check the GitHub issues

## License

This project is licensed under the MIT License - see the LICENSE file for details. 