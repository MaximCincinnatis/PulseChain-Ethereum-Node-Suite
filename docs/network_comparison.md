# Network Comparison Guide

This guide helps you choose between PulseChain and Ethereum for your node installation.

## ⚠️ Important Note

**You must choose EITHER PulseChain OR Ethereum for your node. This is a one-time choice made during installation and cannot be changed without a complete reinstallation.**

## Choosing Your Network

This comparison will help you decide which network best suits your needs. Consider these factors carefully before installation, as you cannot switch networks without a complete reinstallation.

## Overview

| Feature | PulseChain | Ethereum |
|---------|------------|----------|
| Network Types | Mainnet, Testnet | Mainnet, Goerli, Sepolia |
| Chain ID | 369 (Mainnet) | 1 (Mainnet) |
| Block Time | ~2 seconds | ~12 seconds |
| Storage Requirements | 2TB minimum | 4TB minimum |
| Sync Time | Faster | Longer due to chain size |

## Client Support

### Execution Clients

| Client | PulseChain Support | Ethereum Support | Notes |
|--------|-------------------|------------------|--------|
| Geth | ✅ | ✅ | Recommended for both networks |
| Erigon | ✅ | ✅ | Better for archive nodes |

### Consensus Clients

| Client | PulseChain Support | Ethereum Support | Notes |
|--------|-------------------|------------------|--------|
| Lighthouse | ✅ | ✅ | Recommended for both networks |
| Prysm | ✅ | ✅ | Alternative option |

## Network-Specific Features

### PulseChain

* **Advantages**:
  - Faster block times
  - Lower storage requirements
  - Quicker initial sync
  - Lower system requirements
  - Compatible with Ethereum tooling

* **Considerations**:
  - Newer network, less historical data
  - Smaller peer network
  - Network-specific configurations needed

### Ethereum

* **Advantages**:
  - Established network
  - Larger peer network
  - More tooling available
  - Better documentation

* **Considerations**:
  - Larger storage requirements
  - Longer sync times
  - Higher system requirements
  - More network congestion

## System Requirements Comparison

### Minimum Requirements

| Resource | PulseChain | Ethereum |
|----------|------------|----------|
| CPU | 4+ cores | 4+ cores |
| RAM | 16GB | 16GB |
| Storage | 2TB SSD | 4TB SSD |
| Network | 10Mbps | 10Mbps |

### Recommended Requirements

| Resource | PulseChain | Ethereum |
|----------|------------|----------|
| CPU | 8+ cores | 8+ cores |
| RAM | 32GB | 32GB |
| Storage | 4TB NVMe SSD | 8TB NVMe SSD |
| Network | 25Mbps | 25Mbps |

## Installation Choice

Once you've decided which network to use:

### If Choosing PulseChain:
```bash
./setup_pulse_node.sh
```

### If Choosing Ethereum:
```bash
./setup_eth_node.sh
```

⚠️ Remember: This choice cannot be changed without completely reinstalling the system.

## Setup Differences

### Initial Setup

1. **PulseChain**:
```bash
./setup_pulse_node.sh
```
- Faster initial sync
- Network-specific bootstrapping
- PulseChain-specific genesis block

2. **Ethereum**:
```bash
./setup_eth_node.sh
```
- Longer initial sync
- Standard Ethereum bootstrapping
- Ethereum mainnet genesis

### Configuration Differences

#### PulseChain Config
```json
{
    "network": {
        "type": "pulsechain",
        "chain": "mainnet",
        "network_id": 369,
        "chain_id": 369
    }
}
```

#### Ethereum Config
```json
{
    "network": {
        "type": "ethereum",
        "chain": "mainnet",
        "network_id": 1,
        "chain_id": 1
    }
}
```

## Monitoring & Maintenance

### Common Features
- Prometheus metrics
- Grafana dashboards
- Health checks
- Automatic updates
- Backup systems

### Network-Specific Monitoring

#### PulseChain
- PulseChain-specific metrics
- Network health indicators
- Block production monitoring

#### Ethereum
- Ethereum network metrics
- Gas price monitoring
- Network congestion tracking

## Troubleshooting Network-Specific Issues

### PulseChain Issues

1. **Sync Issues**
   - Check PulseChain-specific endpoints
   - Verify network ID (369)
   - Check bootstrap nodes

2. **Network Connection**
   - Verify PulseChain RPC endpoints
   - Check peer connections
   - Validate chain ID

### Ethereum Issues

1. **Sync Issues**
   - Check disk space (needs more)
   - Verify Ethereum endpoints
   - Check peer connections

2. **Performance Issues**
   - Monitor gas prices
   - Check network congestion
   - Optimize for larger chain

## Best Practices

### PulseChain
1. Regular pruning recommended
2. Monitor block production
3. Keep bootstrap nodes updated
4. Regular backups

### Ethereum
1. More frequent pruning needed
2. Monitor storage usage
3. Gas price monitoring
4. Regular state cleanup

## Additional Resources

### PulseChain
- [PulseChain Documentation](https://docs.pulsechain.com)
- [Network Status](https://scan.pulsechain.com)
- Community Discord

### Ethereum
- [Ethereum Documentation](https://ethereum.org/docs)
- [Network Status](https://etherscan.io)
- [Client Documentation](https://geth.ethereum.org) 