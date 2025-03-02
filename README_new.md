# PulseChain Full Node Suite - Non-Validator Edition

## ⚠️ ALPHA RELEASE WARNING (v0.1.0) ⚠️

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

## 🛠️ What This Package Does

* **System Preparation**: Installs dependencies (Docker, system packages) and optimizes performance
* **Node Deployment**: Sets up execution and consensus clients as Docker containers
* **Configuration Management**: Manages node settings through a centralized system
* **Monitoring**: Deploys Prometheus and Grafana for performance monitoring
* **Health Management**: Checks node health with protection mechanisms for disk space, CPU, and memory
* **Failure Recovery**: Implements smart restart functionality for high availability
* **User Interface**: Provides intuitive menu system for all operations

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

## 📥 Simple Installation

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

### Node Management via `plsmenu`

The `plsmenu` command provides a central interface for all node operations:

```bash
plsmenu
```

This menu system allows you to:
* Start/stop/restart nodes
* View logs
* Update Docker images
* Monitor node status
* Configure client settings
* Manage system resources

### Docker Container Management

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

### Monitoring with Prometheus & Grafana

After setup, access Grafana at:
```
http://YOUR_SERVER_IP:3000
```

Default login:
* Username: `admin`
* Password: `admin`

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

## 🔧 Troubleshooting

* **Container not starting**: Check disk space and logs
* **Sync issues**: Verify internet connection and firewall settings
* **High resource usage**: Monitor with Grafana dashboards
* **Menu not working**: Ensure all helper scripts have execution permissions

## 📚 Additional Resources

* PulseChain website: https://pulsechain.com/
* PulseChain GitLab: https://gitlab.com/pulsechaincom
* Checkpoint: https://checkpoint.pulsechain.com/
* Pulsedev Telegram: https://t.me/PulseDEV

## 📝 Release Notes

This alpha release (v0.1.0) represents the initial development version with:
* Core node functionality
* Monitoring capabilities
* Management tools
* Non-validator configuration

##  Feedback and Contributions

Feedback on this alpha release is welcome. Please report issues or suggestions through GitHub issues.
