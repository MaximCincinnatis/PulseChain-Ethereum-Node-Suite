#!/bin/bash

# ===============================================================================
# PulseChain Node Global Configuration File
# ===============================================================================
# This file serves as the central configuration for all PulseChain node scripts.
# All paths, client selections, and other configurable parameters are defined here.
# ===============================================================================

# Version tracking
CONFIG_VERSION="1.0.0"

# ===============================================================================
# PATH CONFIGURATION
# ===============================================================================

# Base installation path - this is the root directory for all PulseChain files
# If not set in environment, default to /blockchain
CUSTOM_PATH="${CUSTOM_PATH:-/blockchain}"

# Subdirectory paths derived from CUSTOM_PATH
HELPER_PATH="${CUSTOM_PATH}/helper"
EXECUTION_PATH="${CUSTOM_PATH}/execution"
CONSENSUS_PATH="${CUSTOM_PATH}/consensus"
BACKUP_PATH="${CUSTOM_PATH}/backups"
LOG_PATH="${CUSTOM_PATH}/logs"
JWT_FILE="${CUSTOM_PATH}/jwt.hex"

# ===============================================================================
# CLIENT CONFIGURATION
# ===============================================================================

# Client selection (saved during setup)
ETH_CLIENT="${ETH_CLIENT:-geth}"  # Options: geth, erigon
CONSENSUS_CLIENT="${CONSENSUS_CLIENT:-lighthouse}"  # Options: lighthouse, prysm

# Network selection
NETWORK="${NETWORK:-mainnet}"  # Options: mainnet, testnet

# ===============================================================================
# DOCKER CONFIGURATION
# ===============================================================================

# Container names
EXECUTION_CONTAINER="execution"
CONSENSUS_CONTAINER="beacon"

# Docker image references
GETH_IMAGE="registry.gitlab.com/pulsechaincom/go-pulse:latest"
ERIGON_IMAGE="registry.gitlab.com/pulsechaincom/erigon-pulse:latest"
LIGHTHOUSE_IMAGE="registry.gitlab.com/pulsechaincom/lighthouse-pulse:latest"
PRYSM_IMAGE="registry.gitlab.com/pulsechaincom/prysm-pulse/beacon-chain:latest"
PRYSM_TOOL_IMAGE="registry.gitlab.com/pulsechaincom/prysm-pulse/prysmctl:latest"

# ===============================================================================
# NETWORK CONFIGURATION
# ===============================================================================

# Default checkpoints for different networks
MAINNET_CHECKPOINT="https://checkpoint.v4.testnet.pulsechain.com"
TESTNET_CHECKPOINT="https://checkpoint.v4.testnet.pulsechain.com"

# Get the appropriate checkpoint URL based on the selected network
if [[ "$NETWORK" == "mainnet" ]]; then
    CHECKPOINT="$MAINNET_CHECKPOINT"
    EXECUTION_NETWORK_FLAG="pulsechain"
    LIGHTHOUSE_NETWORK_FLAG="pulsechain"
    PRYSM_NETWORK_FLAG="pulsechain"
else
    CHECKPOINT="$TESTNET_CHECKPOINT"
    EXECUTION_NETWORK_FLAG="pulsechain-testnet-v4"
    LIGHTHOUSE_NETWORK_FLAG="pulsechain_testnet_v4"
    PRYSM_NETWORK_FLAG="pulsechain-testnet-v4"
fi

# ===============================================================================
# SYSTEM CONFIGURATION
# ===============================================================================

# Log settings
LOG_LEVEL="info"  # Options: debug, info, warning, error
LOG_FILE="${LOG_PATH}/node_operation.log"

# Health check settings
HEALTH_CHECK_INTERVAL=300  # seconds
DISK_SPACE_THRESHOLD=90    # percentage
CPU_THRESHOLD=95           # percentage
MEMORY_THRESHOLD=90        # percentage

# Update settings
AUTO_UPDATE_ENABLED=false
BACKUP_BEFORE_UPDATE=true
KEEP_BACKUPS=5             # number of backups to keep

# ===============================================================================
# FUNCTIONS TO MANAGE CONFIGURATION
# ===============================================================================

# Load configuration from file
load_config() {
    local config_file="$CUSTOM_PATH/node_config.json"
    
    # Check if config file exists
    if [[ -f "$config_file" ]]; then
        # Read basic configuration (requires jq to be installed)
        if command -v jq &> /dev/null; then
            NETWORK=$(jq -r '.network // "mainnet"' "$config_file")
            ETH_CLIENT=$(jq -r '.execution_client // "geth"' "$config_file")
            CONSENSUS_CLIENT=$(jq -r '.consensus_client // "lighthouse"' "$config_file")
            CUSTOM_PATH=$(jq -r '.custom_path // "/blockchain"' "$config_file")
            AUTO_UPDATE_ENABLED=$(jq -r '.auto_update // false' "$config_file")
            LOG_LEVEL=$(jq -r '.log_level // "info"' "$config_file")
            
            # Update derived paths
            HELPER_PATH="${CUSTOM_PATH}/helper"
            EXECUTION_PATH="${CUSTOM_PATH}/execution"
            CONSENSUS_PATH="${CUSTOM_PATH}/consensus"
            BACKUP_PATH="${CUSTOM_PATH}/backups"
            LOG_PATH="${CUSTOM_PATH}/logs"
            JWT_FILE="${CUSTOM_PATH}/jwt.hex"
            
            # Log that config was loaded
            echo "Configuration loaded from $config_file"
        else
            echo "Warning: jq not installed, using default configuration"
        fi
    else
        echo "Config file not found at $config_file, using default configuration"
    fi
    
    # Update network-specific variables
    if [[ "$NETWORK" == "mainnet" ]]; then
        CHECKPOINT="$MAINNET_CHECKPOINT"
        EXECUTION_NETWORK_FLAG="pulsechain"
        LIGHTHOUSE_NETWORK_FLAG="pulsechain"
        PRYSM_NETWORK_FLAG="pulsechain"
    else
        CHECKPOINT="$TESTNET_CHECKPOINT"
        EXECUTION_NETWORK_FLAG="pulsechain-testnet-v4"
        LIGHTHOUSE_NETWORK_FLAG="pulsechain_testnet_v4"
        PRYSM_NETWORK_FLAG="pulsechain-testnet-v4"
    fi
}

# Save configuration to file
save_config() {
    local config_file="$CUSTOM_PATH/node_config.json"
    
    # Create directory if it doesn't exist
    mkdir -p $(dirname "$config_file")
    
    # Create JSON config (requires jq to be installed)
    if command -v jq &> /dev/null; then
        jq -n \
          --arg network "$NETWORK" \
          --arg execution_client "$ETH_CLIENT" \
          --arg consensus_client "$CONSENSUS_CLIENT" \
          --arg custom_path "$CUSTOM_PATH" \
          --argjson auto_update $AUTO_UPDATE_ENABLED \
          --arg log_level "$LOG_LEVEL" \
          --arg config_version "$CONFIG_VERSION" \
          '{
            network: $network,
            execution_client: $execution_client,
            consensus_client: $consensus_client,
            custom_path: $custom_path,
            auto_update: $auto_update,
            log_level: $log_level,
            config_version: $config_version,
            last_updated: (now | todate)
          }' > "$config_file"
          
        echo "Configuration saved to $config_file"
    else
        # Fallback to simple format if jq is not available
        cat > "$config_file" << EOL
{
  "network": "${NETWORK}",
  "execution_client": "${ETH_CLIENT}",
  "consensus_client": "${CONSENSUS_CLIENT}",
  "custom_path": "${CUSTOM_PATH}",
  "auto_update": ${AUTO_UPDATE_ENABLED},
  "log_level": "${LOG_LEVEL}",
  "config_version": "${CONFIG_VERSION}",
  "last_updated": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOL
        echo "Configuration saved to $config_file (basic format)"
    fi
    
    # Make sure the file has correct permissions
    chmod 644 "$config_file"
}

# Initialize config if this script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "PulseChain Node Configuration Utility"
    echo "====================================="
    echo ""
    echo "This script should not be run directly."
    echo "It should be sourced from other scripts with:"
    echo "  source $(basename ${BASH_SOURCE[0]})"
    echo ""
    
    # Still, offer to save the current configuration
    read -p "Do you want to save the current configuration? (y/N): " save_choice
    if [[ "$save_choice" =~ ^[Yy]$ ]]; then
        save_config
        echo "Configuration saved. You can edit it manually at ${CUSTOM_PATH}/node_config.json"
    fi
fi 