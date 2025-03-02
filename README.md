# PulseChain Full Node Suite - Non-Validator Edition

## ⚠️ ALPHA RELEASE WARNING (v0.1.1) ⚠️

**This is an ALPHA release intended for testing and development purposes only.**

> This software is provided "as is" without warranty of any kind. Use at your own risk and always back up important data before testing.

This package has been specifically modified to **remove all validator functionality**. It cannot be used for validation or staking.

## 📋 Quick Summary

* **Purpose**: Setup and manage a PulseChain full node (without validator functionality)
* **Status**: Alpha release - may contain bugs or incomplete features
* **Recommended for**: Testing, development, and RPC endpoint provisioning
* **Not recommended for**: Production environments without thorough testing
* **Key components**: Execution client (Geth/Erigon), Consensus client (Lighthouse/Prysm), Monitoring (Prometheus/Grafana)
* **Management**: Interactive menu system (`plsmenu`) for all node operations
* **Network Optimization**: Switchable modes for local or public RPC usage
* **Robust Configuration**: JSON-based central configuration system for easy customization
* **Sync Recovery**: Advanced recovery mechanisms for blockchain synchronization issues

## 🏗️ System Architecture

The PulseChain Full Node Suite follows a modular design with these key components:

1. **Main Setup Script**: `setup_pulse_node.sh` handles the initial installation and configuration
2. **Helper Scripts**: Various scripts in the `helper/` directory provide specialized functionality
3. **Centralized Configuration**: JSON-based config system for easy management
4. **Menu Interface**: The `plsmenu` command provides a user-friendly management UI
5. **Monitoring Stack**: Prometheus and Grafana with custom dashboards
6. **Recovery Subsystems**: Smart restart and sync recovery mechanisms
7. **Health Management**: Automated resource monitoring with protective actions

This architecture ensures reliability through error detection, recovery mechanisms, and comprehensive logging throughout all operations.

## 🛠️ What This Package Does

* **System Preparation**: Installs dependencies (Docker, system packages) and optimizes performance
* **Node Deployment**: Sets up execution and consensus clients as Docker containers
* **Configuration Management**: Manages node settings through a centralized system
* **Monitoring**: Deploys Prometheus and Grafana for performance monitoring
* **Health Management**: Checks node health with protection mechanisms for disk space, CPU, and memory
* **Failure Recovery**: Implements smart restart functionality for high availability
* **Sync Recovery**: Automatically detects and repairs blockchain synchronization issues
* **User Interface**: Provides intuitive menu system for all operations
* **Network Tuning**: Automatically optimizes network settings based on your usage scenario

## ❌ What This Package Does NOT Do

* **No Validator Functionality**: Cannot be used for staking or validation
* **No Key Management**: Does not handle validator keys or deposits
* **No Staking Rewards**: Cannot earn rewards from validating blocks
* **No Validator Monitoring**: No validator performance metrics

## 💻 System Requirements

* Ubuntu 20.04 LTS or newer
* At least 16GB RAM (32GB recommended)
* Minimum 2TB SSD (NVMe SSD recommended)
* Stable internet connection (10Mbps+ upload/download)
* Modern CPU with 4+ cores

## 📥 Installation Options

### One-Command Installation

```bash
sudo apt update && sudo apt install git -y && git clone https://github.com/MaximCincinnatis/PulseChain-Full-Node-Suite && cd PulseChain-Full-Node-Suite && chmod +x setup_pulse_node.sh && ./setup_pulse_node.sh
```

### Manual Installation Steps

1. **Install Git**:
   ```bash
   sudo apt update && sudo apt install git -y
   ```

2. **Clone the repository**:
   ```bash
   git clone https://github.com/MaximCincinnatis/PulseChain-Full-Node-Suite
   ```

3. **Enter the directory**:
   ```bash
   cd PulseChain-Full-Node-Suite
   ```

4. **Make the setup script executable**:
   ```bash
   chmod +x setup_pulse_node.sh
   ```

5. **Run the setup script**:
   ```bash
   ./setup_pulse_node.sh
   ```

6. **Follow the interactive prompts** to complete your installation

## 🔍 Key Features Explained

### 🧰 Node Management via `plsmenu`

The `plsmenu` command provides a central interface for all node operations:

```bash
plsmenu
```

This comprehensive menu system allows you to:
* Start/stop/restart nodes
* View detailed logs
* Update Docker images
* Monitor node status
* Configure client settings
* Manage system resources
* Recover from synchronization issues

### 🐳 Docker Container Management

#### Viewing Running Containers
```bash
docker ps
```

#### Viewing Logs
```bash
# View logs for execution client
docker logs -f --tail=50 execution

# View logs for consensus client
docker logs -f --tail=50 beacon
```

#### Stopping Containers Safely
```bash
cd /blockchain/helper
./stop_docker.sh
```

#### Starting Containers
```bash
cd /blockchain
./start_execution.sh
./start_consensus.sh
```

### ⚙️ Configuration Management

The node uses a centralized JSON configuration system that makes customization easy and consistent:

```bash
# View current configuration
cd /blockchain
./config.sh
```

This will show a menu that allows you to:
1. Show current configuration
2. Save configuration
3. Create default configuration

All settings are stored in `/blockchain/node_config.json` and can be manually edited or updated through the provided functions.

See the [Advanced Configuration Guide](docs/advanced_configuration.md) for detailed information about all available options.

### 🔄 Recovery Mechanisms

#### Smart Restart System

The smart restart system (`smart_restart.sh`) provides:
* Intelligent container management with proper shutdown sequences
* Visual progress indicators during operations
* Automatic detection of container status
* Proper error handling and logging

#### Sync Recovery Tool

The sync recovery system automatically detects and fixes blockchain synchronization issues:

```bash
# Run sync recovery tool
cd /blockchain/helper
./sync_recovery.sh --recover
```

This sophisticated tool:
- Detects synchronization problems using multiple indicators
- Diagnoses common issues (corrupt database, network problems)
- Performs appropriate recovery steps based on specific conditions
- Creates detailed logs of the recovery process
- Implements protections against repeated recovery attempts

You can also access this feature through the Info & Management menu in `plsmenu`.

### 📊 Monitoring with Prometheus & Grafana

After setup, access Grafana at:
```
http://YOUR_SERVER_IP:3000
```

Default login:
* Username: `admin`
* Password: `admin`

The monitoring system includes:
* Node performance metrics
* Blockchain synchronization status
* System resource utilization (CPU, memory, disk)
* Network connection statistics
* Customizable dashboards and alerts

### 🌐 Network Configuration

The node includes specialized network optimization with two modes:

#### Local Mode (Default)
```bash
# Switch to local mode
cd /blockchain/helper
./network_config.sh local
```
* Optimized for high-throughput between your machine and VMs
* Perfect for personal use, development, and testing
* Configured for maximum data transfer performance

#### Public Mode
```bash
# Switch to public mode
cd /blockchain/helper
./network_config.sh public
```
* Optimized for handling many external connections
* Ideal when exposing your node as a public RPC endpoint
* Includes protections against connection floods

You can also access network configuration through the menu:
```bash
plsmenu
# Navigate to: System Menu > Network Configuration
```

### 💽 VirtualBox Integration

The node includes enhanced VirtualBox Guest Additions support for better VM integration:

#### Automatic Installation

During setup, the script will:
- Detect if running in VirtualBox
- Download and install the correct Guest Additions version
- Configure clipboard sharing between host and VM
- Set up persistent clipboard service that survives reboots

#### Clipboard Management

Manage clipboard functionality through the menu:
```bash
plsmenu
# Navigate to: System Menu > VirtualBox Clipboard
```

This menu provides options to:
- Check clipboard functionality status
- Restart clipboard sharing if not working
- Test clipboard with sample text
- Install/update clipboard service

If copy-paste stops working after a reboot, use this menu to quickly restore functionality.

## 🔄 Updating the Node

Update Docker images using:
```bash
cd /blockchain/helper
sudo ./update_docker.sh
```

Or via the menu:
```bash
plsmenu
# Navigate to: Clients-Menu > Update all Clients
```

## 🚑 Troubleshooting Guide

### Common Issues and Solutions

| Issue | Possible Causes | Solution |
|-------|-----------------|----------|
| **Container not starting** | Disk space, port conflicts, database corruption | Check logs with `docker logs execution`, verify disk space, use recovery tool |
| **Sync issues** | Network problems, outdated software, database corruption | Run `./sync_recovery.sh --diagnose`, check firewall settings |
| **High resource usage** | Normal during initial sync, inefficient configuration | Monitor with Grafana, adjust client parameters in configuration |
| **Menu not working** | Permission issues, missing dependencies | Ensure helper scripts have execution permissions (`chmod +x`) |
| **Out of disk space** | Chain growth, logs accumulation | Use disk cleanup tools, consider pruned node option |
| **Poor performance** | Hardware limitations, network congestion | Check system resources, switch network configuration mode |

For additional troubleshooting assistance, check the `plsmenu` > Info & Management section, which includes diagnostic tools.

## 📚 Additional Resources

* PulseChain website: https://pulsechain.com/
* PulseChain GitLab: https://gitlab.com/pulsechaincom
* Checkpoint: https://checkpoint.pulsechain.com/
* Pulsedev Telegram: https://t.me/PulseDEV

## 📝 Release Notes

This alpha release (v0.1.1) represents the initial development version with:
* Core node functionality
* Monitoring capabilities
* Management tools
* Non-validator configuration
* Robust configuration and sync recovery

Expect future updates to improve stability, performance, and add features.

## ⚠️ Known Limitations

* Limited testing in production environments
* Some features may be incomplete
* Documentation is still developing
* Performance optimizations pending

## 📣 Feedback and Contributions

Feedback on this alpha release is welcome. Please report issues or suggestions through GitHub issues.
