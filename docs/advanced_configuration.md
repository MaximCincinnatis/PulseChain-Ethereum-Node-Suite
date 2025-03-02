# PulseChain Node Advanced Configuration Guide

This document provides detailed information about the advanced configuration options available for your PulseChain node. Understanding these options will help you optimize performance, customize your setup, and make the most of your node.

## Table of Contents

1. [Configuration System Overview](#configuration-system-overview)
2. [Configuration File Location](#configuration-file-location)
3. [Client Configuration Options](#client-configuration-options)
4. [Network Configuration](#network-configuration)
5. [Performance Tuning](#performance-tuning)
6. [API Configuration](#api-configuration)
7. [Monitoring Options](#monitoring-options)
8. [Health Check Parameters](#health-check-parameters)
9. [Update Settings](#update-settings)
10. [Logging Configuration](#logging-configuration)
11. [Command Line Usage](#command-line-usage)
12. [Troubleshooting Configuration Issues](#troubleshooting-configuration-issues)

## Configuration System Overview

The PulseChain Node Suite uses a centralized JSON-based configuration system. All settings are stored in a single configuration file, making it easy to back up, restore, or transfer your configuration between systems.

Key benefits of this approach:
- **Centralized management**: All settings in one place
- **Structured format**: JSON provides a well-defined structure
- **Compatibility**: Easy integration with other tools
- **Validation**: Automatic validation prevents configuration errors

## Configuration File Location

The default configuration file is located at:
```
/blockchain/node_config.json
```

You can override this location by setting the `NODE_CONFIG_FILE` environment variable before running any scripts.

Example:
```bash
export NODE_CONFIG_FILE=/path/to/my-config.json
./setup_pulse_node.sh
```

## Client Configuration Options

### Execution Client Options

The execution client (Geth or Erigon) can be customized with these settings:

| Option | Description | Default Value | Acceptable Values |
|--------|-------------|---------------|-------------------|
| `clients.execution.name` | The execution client to use | `geth` | `geth`, `erigon` |
| `clients.execution.cache_size` | Memory allocated to the client cache (MB) | `2048` | Integer value |
| `clients.execution.max_peers` | Maximum number of peers to connect to | `50` | Integer value |
| `clients.execution.api_enabled` | Whether to enable the JSON-RPC API | `true` | `true`, `false` |
| `clients.execution.api_methods` | Comma-separated list of enabled API methods | `eth,net,web3,txpool` | Varies by client |

#### Geth-Specific Options

If you're using Geth as your execution client, the following options apply:

- **Cache Size**: Higher values improve performance but require more RAM. For systems with 16GB+ RAM, values of 4096 or higher are recommended.
- **Max Peers**: Higher values may improve sync speed but increase bandwidth usage. Values between 25-100 are recommended.

#### Erigon-Specific Options

For Erigon users, consider these guidelines:

- **Cache Size**: Erigon has different memory management - values between 1024-4096 are usually sufficient.
- **Database Options**: Erigon uses a different database structure and has special parameters for database management.

### Consensus Client Options

The consensus client (Lighthouse or Prysm) can be customized with these settings:

| Option | Description | Default Value | Acceptable Values |
|--------|-------------|---------------|-------------------|
| `clients.consensus.name` | The consensus client to use | `lighthouse` | `lighthouse`, `prysm` |
| `clients.consensus.metrics_enabled` | Enable Prometheus metrics | `true` | `true`, `false` |
| `clients.consensus.api_enabled` | Enable the client API | `true` | `true`, `false` |

#### Lighthouse-Specific Options

Lighthouse has these specific configuration options:

- **Target Peers**: Controls how many peers to maintain connections with.
- **Execution Endpoints**: Multiple endpoints can be specified for redundancy.

#### Prysm-Specific Options

Prysm has these unique options:

- **RPC Port**: The port to use for the RPC server.
- **Monitoring Host**: The host address for the monitoring endpoint.

## Network Configuration

The network configuration determines which PulseChain network your node connects to:

| Option | Description | Default Value | Acceptable Values |
|--------|-------------|---------------|-------------------|
| `network` | The PulseChain network to connect to | `mainnet` | `mainnet`, `testnet` |

This setting affects:
- Network ID and Chain ID
- Genesis block
- Bootnodes
- Checkpoint URL

## Performance Tuning

For optimal performance, consider adjusting these parameters:

### System Resource Allocation

| Option | Description | Impact |
|--------|-------------|--------|
| `clients.execution.cache_size` | Memory cache size | Higher values improve performance but require more RAM |
| `clients.execution.max_peers` | Maximum peer connections | Higher values may improve sync speed but increase bandwidth usage |

### Recommended Values By System Specification

| System RAM | Recommended Cache Size | Recommended Max Peers |
|------------|------------------------|------------------------|
| 8GB | 1024MB | 25 |
| 16GB | 2048MB | 50 |
| 32GB+ | 4096MB+ | 50-100 |

## API Configuration

The API configuration controls how external applications can interact with your node:

| Option | Description | Default Value | Security Impact |
|--------|-------------|---------------|----------------|
| `api.cors_domains` | Allowed CORS domains | `*` | Restrict to specific domains for production |
| `api.vhosts` | Allowed virtual hosts | `*` | Restrict for production |
| `api.addr` | Listen address | `127.0.0.1` | Use `0.0.0.0` to allow external connections |

### Security Recommendations

- For personal/local use, the defaults are fine
- For production environments:
  - Set specific CORS domains
  - Limit vhosts to your domain
  - Consider using a reverse proxy with SSL
  - Implement IP-based restrictions

## Monitoring Options

PulseChain nodes can integrate with monitoring tools:

| Option | Description | Default Value |
|--------|-------------|---------------|
| `monitoring.prometheus_enabled` | Enable Prometheus metrics | `true` |
| `monitoring.grafana_enabled` | Enable Grafana dashboards | `true` |

### Accessing Monitoring Dashboards

When enabled, monitoring dashboards are available at:
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000

Default Grafana credentials:
- Username: `admin`
- Password: `admin`

## Health Check Parameters

Health checks monitor your node's status:

| Option | Description | Default Value |
|--------|-------------|---------------|
| `health.check_interval` | Time between checks (seconds) | `300` |
| `health.disk_threshold` | Disk usage warning threshold (%) | `90` |
| `health.cpu_threshold` | CPU usage warning threshold (%) | `95` |
| `health.memory_threshold` | Memory usage warning threshold (%) | `90` |

Adjusting these thresholds affects when warnings appear in logs and the web interface.

## Update Settings

These options control the automatic update behavior:

| Option | Description | Default Value |
|--------|-------------|---------------|
| `updates.auto_update` | Enable automatic updates | `false` |
| `updates.backup_before_update` | Create backup before updating | `true` |
| `updates.keep_backups` | Number of backups to retain | `5` |

### Auto-Update Considerations

- **Pros**: Always running the latest version
- **Cons**: Updates might introduce changes that require attention
- **Recommendation**: Enable backup_before_update if using auto_update

## Logging Configuration

Control the verbosity and retention of logs:

| Option | Description | Default Value | Acceptable Values |
|--------|-------------|---------------|-------------------|
| `logging.level` | Log verbosity level | `info` | `debug`, `info`, `warning`, `error` |
| `logging.rotation_days` | Days to keep logs | `14` | Integer value |

### Log Levels Explained

- **debug**: Very detailed information, useful for development
- **info**: General operational information
- **warning**: Potential issues that don't affect operation
- **error**: Significant problems that affect normal operation

## Command Line Usage

The configuration system can be managed through the command line:

```bash
# View current configuration
./config.sh

# Select from menu options to view or edit configuration
# The menu provides options to:
# 1. Show current configuration
# 2. Save configuration
# 3. Create default configuration
```

For scripts or automation, you can use these commands:

```bash
# Load configuration into your environment
source ./config.sh

# Update a single value
update_config_value '.clients.execution.cache_size' '4096'

# Save current configuration
save_config
```

## Troubleshooting Configuration Issues

Common configuration issues and their solutions:

### Invalid JSON Format

**Symptom**: Scripts fail with JSON parsing errors.
**Solution**: Run `validate_config /blockchain/node_config.json` to check for syntax errors.

### Missing Configuration File

**Symptom**: Scripts use default values instead of your customizations.
**Solution**: Check the file path and permissions, or run `create_default_config /blockchain/node_config.json`.

### Performance Issues

**Symptom**: Node syncs slowly or has high resource usage.
**Solution**: Adjust cache size and peer count based on your system resources.

### API Access Issues

**Symptom**: Cannot connect to node API from external applications.
**Solution**: Check `api.addr` setting - make sure it's set to `0.0.0.0` for external access.

## Example Configuration

Here's a complete example configuration for a high-performance node:

```json
{
  "version": "0.1.1",
  "timestamp": "2023-07-01T12:00:00Z",
  "paths": {
    "base": "/blockchain",
    "helper": "/blockchain/helper",
    "execution": "/blockchain/execution",
    "consensus": "/blockchain/consensus",
    "backup": "/blockchain/backups",
    "logs": "/blockchain/logs",
    "jwt": "/blockchain/jwt.hex"
  },
  "network": "mainnet",
  "clients": {
    "execution": {
      "name": "geth",
      "image": "registry.gitlab.com/pulsechaincom/go-pulse:latest",
      "container": "execution",
      "cache_size": 4096,
      "max_peers": 75,
      "api_enabled": true,
      "api_methods": "eth,net,web3,txpool,debug"
    },
    "consensus": {
      "name": "lighthouse",
      "image": "registry.gitlab.com/pulsechaincom/lighthouse-pulse:latest",
      "container": "beacon",
      "metrics_enabled": true,
      "api_enabled": true
    }
  },
  "api": {
    "cors_domains": "*",
    "vhosts": "*",
    "addr": "0.0.0.0"
  },
  "monitoring": {
    "prometheus_enabled": true,
    "grafana_enabled": true
  },
  "health": {
    "check_interval": 300,
    "disk_threshold": 90,
    "cpu_threshold": 95,
    "memory_threshold": 90
  },
  "updates": {
    "auto_update": false,
    "backup_before_update": true,
    "keep_backups": 5
  },
  "logging": {
    "level": "info",
    "rotation_days": 14
  }
}
``` 