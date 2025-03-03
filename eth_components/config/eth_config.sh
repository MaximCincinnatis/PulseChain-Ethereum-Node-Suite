#!/bin/bash

# ===============================================================================
# Ethereum Node Configuration
# ===============================================================================

# Version Control
ETH_CONFIG_VERSION="0.1.0"

# Network Options
declare -A ETH_NETWORKS=(
    ["mainnet"]="mainnet"
    ["goerli"]="goerli"
    ["sepolia"]="sepolia"
)

# Docker Images
GETH_ETH_IMAGE="ethereum/client-go:stable"
ERIGON_ETH_IMAGE="thorax/erigon:stable"
LIGHTHOUSE_ETH_IMAGE="sigp/lighthouse:latest"
PRYSM_ETH_IMAGE="gcr.io/prysmaticlabs/prysm/beacon-chain:stable"

# Default Ports (can be overridden)
ETH_RPC_PORT=8545
ETH_WS_PORT=8546
ETH_ENGINE_PORT=8551
ETH_P2P_PORT=30303
ETH_METRICS_PORT=6060

# Beacon Chain Ports
ETH_BEACON_P2P_PORT=9000
ETH_BEACON_HTTP_PORT=5052
ETH_BEACON_METRICS_PORT=5054

# Default Paths
ETH_BASE_DIR="${CUSTOM_PATH:-/blockchain}/ethereum"
ETH_EXECUTION_DIR="${ETH_BASE_DIR}/execution"
ETH_CONSENSUS_DIR="${ETH_BASE_DIR}/consensus"
ETH_LOGS_DIR="${ETH_BASE_DIR}/logs"
ETH_BACKUP_DIR="${ETH_BASE_DIR}/backups"

# JWT Authentication
ETH_JWT_FILE="${ETH_BASE_DIR}/jwt.hex"

# Resource Management
ETH_MIN_RAM_GB=16
ETH_MIN_STORAGE_GB=1000
ETH_MIN_CPU_CORES=4

# Health Check Settings
ETH_HEALTH_CHECK_INTERVAL=300  # 5 minutes
ETH_MAX_BLOCK_AGE=60          # Maximum acceptable block age in seconds

# Monitoring Settings
ETH_MONITORING_DIR="${ETH_BASE_DIR}/monitoring"
ETH_PROMETHEUS_PORT=9090
ETH_GRAFANA_PORT=3000
ETH_GRAFANA_ADMIN_PASSWORD="admin"

# Checkpoint Sync URLs
declare -A ETH_CHECKPOINT_URLS=(
    ["mainnet"]="https://beaconstate.mainnet.ethstaker.cc"
    ["goerli"]="https://beaconstate.goerli.ethstaker.cc"
    ["sepolia"]="https://beaconstate.sepolia.ethstaker.cc"
)

# Configuration File
ETH_CONFIG_FILE="${ETH_BASE_DIR}/eth_node_config.json"

# Function to validate network selection
validate_eth_network() {
    local network=$1
    if [[ -z "${ETH_NETWORKS[$network]}" ]]; then
        echo "Invalid network selection: $network"
        echo "Valid options: ${!ETH_NETWORKS[@]}"
        return 1
    fi
    return 0
}

# Function to save ETH configuration
save_eth_config() {
    local config_file="${ETH_CONFIG_FILE}"
    cat > "$config_file" << EOL
{
    "version": "${ETH_CONFIG_VERSION}",
    "network": "${NETWORK}",
    "node_type": "${NODE_TYPE}",
    "execution_client": "${ETH_CLIENT}",
    "consensus_client": "${CONSENSUS_CLIENT}",
    "base_dir": "${ETH_BASE_DIR}",
    "monitoring": {
        "prometheus_port": ${ETH_PROMETHEUS_PORT},
        "grafana_port": ${ETH_GRAFANA_PORT}
    },
    "ports": {
        "rpc": ${ETH_RPC_PORT},
        "ws": ${ETH_WS_PORT},
        "engine": ${ETH_ENGINE_PORT},
        "p2p": ${ETH_P2P_PORT},
        "beacon_p2p": ${ETH_BEACON_P2P_PORT},
        "beacon_http": ${ETH_BEACON_HTTP_PORT},
        "beacon_metrics": ${ETH_BEACON_METRICS_PORT},
        "metrics": ${ETH_METRICS_PORT}
    },
    "resources": {
        "min_ram_gb": ${ETH_MIN_RAM_GB},
        "min_storage_gb": ${ETH_MIN_STORAGE_GB},
        "min_cpu_cores": ${ETH_MIN_CPU_CORES}
    },
    "health_check": {
        "interval": ${ETH_HEALTH_CHECK_INTERVAL},
        "max_block_age": ${ETH_MAX_BLOCK_AGE}
    }
}
EOL
}

# Function to load ETH configuration
load_eth_config() {
    local config_file="${ETH_CONFIG_FILE}"
    if [[ -f "$config_file" ]]; then
        # Load configuration using jq
        if command -v jq >/dev/null 2>&1; then
            NETWORK=$(jq -r '.network' "$config_file")
            NODE_TYPE=$(jq -r '.node_type' "$config_file")
            ETH_CLIENT=$(jq -r '.execution_client' "$config_file")
            CONSENSUS_CLIENT=$(jq -r '.consensus_client' "$config_file")
            ETH_BASE_DIR=$(jq -r '.base_dir' "$config_file")
            
            # Load ports
            ETH_RPC_PORT=$(jq -r '.ports.rpc' "$config_file")
            ETH_WS_PORT=$(jq -r '.ports.ws' "$config_file")
            ETH_ENGINE_PORT=$(jq -r '.ports.engine' "$config_file")
            ETH_P2P_PORT=$(jq -r '.ports.p2p' "$config_file")
            ETH_BEACON_P2P_PORT=$(jq -r '.ports.beacon_p2p' "$config_file")
            ETH_BEACON_HTTP_PORT=$(jq -r '.ports.beacon_http' "$config_file")
            ETH_BEACON_METRICS_PORT=$(jq -r '.ports.beacon_metrics' "$config_file")
            ETH_METRICS_PORT=$(jq -r '.ports.metrics' "$config_file")
            
            # Load monitoring settings
            ETH_PROMETHEUS_PORT=$(jq -r '.monitoring.prometheus_port' "$config_file")
            ETH_GRAFANA_PORT=$(jq -r '.monitoring.grafana_port' "$config_file")
            
            echo "Configuration loaded from $config_file"
        else
            echo "Error: jq is required for loading configuration"
            return 1
        fi
    else
        echo "No existing configuration found"
    fi
}

# Export variables
export ETH_CONFIG_VERSION
export ETH_NETWORKS
export ETH_BASE_DIR
export ETH_JWT_FILE

# Export additional variables
export ETH_MONITORING_DIR
export ETH_PROMETHEUS_PORT
export ETH_GRAFANA_PORT
export ETH_GRAFANA_ADMIN_PASSWORD
export ETH_CHECKPOINT_URLS
export ETH_CONFIG_FILE 