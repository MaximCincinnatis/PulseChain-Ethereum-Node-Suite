#!/bin/bash

# ===============================================================================
# PulseChain Node Global Configuration File
# ===============================================================================
# This file serves as the central configuration for all PulseChain node scripts.
# All paths, client selections, and other configurable parameters are defined here.
# ===============================================================================

# Version tracking
CONFIG_VERSION="0.1.1"

# ===============================================================================
# Configuration File Location
# ===============================================================================

# Primary configuration file path
# This is the single source of truth for all configuration
NODE_CONFIG_FILE="${NODE_CONFIG_FILE:-/blockchain/node_config.json}"

# Directory for additional configuration overrides (advanced usage)
CONFIG_DIR="${CONFIG_DIR:-/blockchain/config}"

# ===============================================================================
# DEFAULT CONFIGURATION VALUES
# ===============================================================================
# These values are used when no configuration file exists or when values are missing

# Base installation path - this is the root directory for all PulseChain files
CUSTOM_PATH="${CUSTOM_PATH:-/blockchain}"

# Subdirectory paths derived from CUSTOM_PATH
HELPER_PATH="${CUSTOM_PATH}/helper"
EXECUTION_PATH="${CUSTOM_PATH}/execution"
CONSENSUS_PATH="${CUSTOM_PATH}/consensus"
BACKUP_PATH="${CUSTOM_PATH}/backups"
LOG_PATH="${CUSTOM_PATH}/logs"
JWT_FILE="${CUSTOM_PATH}/jwt.hex"

# Client selection defaults
ETH_CLIENT="${ETH_CLIENT:-geth}"  # Options: geth, erigon
CONSENSUS_CLIENT="${CONSENSUS_CLIENT:-lighthouse}"  # Options: lighthouse, prysm

# Network selection
NETWORK="${NETWORK:-mainnet}"  # Options: mainnet, testnet

# Docker container names
EXECUTION_CONTAINER="execution"
CONSENSUS_CONTAINER="beacon"

# Docker image references
GETH_IMAGE="registry.gitlab.com/pulsechaincom/go-pulse:latest"
ERIGON_IMAGE="registry.gitlab.com/pulsechaincom/erigon-pulse:latest"
LIGHTHOUSE_IMAGE="registry.gitlab.com/pulsechaincom/lighthouse-pulse:latest"
PRYSM_IMAGE="registry.gitlab.com/pulsechaincom/prysm-pulse/beacon-chain:latest"
PRYSM_TOOL_IMAGE="registry.gitlab.com/pulsechaincom/prysm-pulse/prysmctl:latest"

# Monitoring settings
PROMETHEUS_ENABLED="true"
GRAFANA_ENABLED="true"

# Network checkpoints
MAINNET_CHECKPOINT="https://checkpoint.v4.testnet.pulsechain.com"
TESTNET_CHECKPOINT="https://checkpoint.v4.testnet.pulsechain.com"

# Health check settings
HEALTH_CHECK_INTERVAL=300  # seconds
DISK_SPACE_THRESHOLD=90    # percentage
CPU_THRESHOLD=95           # percentage
MEMORY_THRESHOLD=90        # percentage

# Update settings
AUTO_UPDATE_ENABLED="false"
BACKUP_BEFORE_UPDATE="true"
KEEP_BACKUPS=5             # number of backups to keep

# Logging configuration
LOG_LEVEL="info"  # Options: debug, info, warning, error
LOG_ROTATION_DAYS=14  # Number of days to keep logs

# ===============================================================================
# ADVANCED CONFIGURATION DEFAULTS
# ===============================================================================

# Execution client configuration
EXECUTION_CACHE_SIZE=2048  # MB
EXECUTION_MAX_PEERS=50
EXECUTION_API_ENABLED="true"
EXECUTION_API_METHODS="eth,net,web3,txpool"

# Consensus client configuration
CONSENSUS_METRICS_ENABLED="true"
CONSENSUS_API_ENABLED="true"

# API configuration
API_CORS_DOMAINS="*"
API_VHOSTS="*"
API_ADDR="127.0.0.1"  # Use 0.0.0.0 for remote access

# ===============================================================================
# FUNCTIONS TO MANAGE CONFIGURATION
# ===============================================================================

# Check if jq is installed, required for JSON manipulation
check_jq_installed() {
    if ! command -v jq &> /dev/null; then
        echo "Warning: jq is not installed. This is required for configuration management."
        echo "Attempting to install jq..."
        
        # Try to install jq using apt
        if command -v apt &> /dev/null; then
            sudo apt update && sudo apt install -y jq
            if ! command -v jq &> /dev/null; then
                echo "Error: Failed to install jq. Using fallback configuration."
                return 1
            fi
        else
            echo "Error: Cannot install jq automatically. Please install it manually."
            return 1
        fi
    fi
    return 0
}

# Create default configuration file if it doesn't exist
create_default_config() {
    local config_file="$1"
    local config_dir=$(dirname "$config_file")
    
    # Ensure the directory exists
    mkdir -p "$config_dir"
    
    # Create a default configuration file
    cat > "$config_file" << EOL
{
  "version": "${CONFIG_VERSION}",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "paths": {
    "base": "${CUSTOM_PATH}",
    "helper": "${HELPER_PATH}",
    "execution": "${EXECUTION_PATH}",
    "consensus": "${CONSENSUS_PATH}",
    "backup": "${BACKUP_PATH}",
    "logs": "${LOG_PATH}",
    "jwt": "${JWT_FILE}"
  },
  "network": "${NETWORK}",
  "clients": {
    "execution": {
      "name": "${ETH_CLIENT}",
      "image": "$([ "$ETH_CLIENT" = "geth" ] && echo "$GETH_IMAGE" || echo "$ERIGON_IMAGE")",
      "container": "${EXECUTION_CONTAINER}",
      "cache_size": ${EXECUTION_CACHE_SIZE},
      "max_peers": ${EXECUTION_MAX_PEERS},
      "api_enabled": ${EXECUTION_API_ENABLED},
      "api_methods": "${EXECUTION_API_METHODS}"
    },
    "consensus": {
      "name": "${CONSENSUS_CLIENT}",
      "image": "$([ "$CONSENSUS_CLIENT" = "lighthouse" ] && echo "$LIGHTHOUSE_IMAGE" || echo "$PRYSM_IMAGE")",
      "container": "${CONSENSUS_CONTAINER}",
      "metrics_enabled": ${CONSENSUS_METRICS_ENABLED},
      "api_enabled": ${CONSENSUS_API_ENABLED}
    }
  },
  "api": {
    "cors_domains": "${API_CORS_DOMAINS}",
    "vhosts": "${API_VHOSTS}",
    "addr": "${API_ADDR}"
  },
  "monitoring": {
    "prometheus_enabled": ${PROMETHEUS_ENABLED},
    "grafana_enabled": ${GRAFANA_ENABLED}
  },
  "health": {
    "check_interval": ${HEALTH_CHECK_INTERVAL},
    "disk_threshold": ${DISK_SPACE_THRESHOLD},
    "cpu_threshold": ${CPU_THRESHOLD},
    "memory_threshold": ${MEMORY_THRESHOLD}
  },
  "updates": {
    "auto_update": ${AUTO_UPDATE_ENABLED},
    "backup_before_update": ${BACKUP_BEFORE_UPDATE},
    "keep_backups": ${KEEP_BACKUPS}
  },
  "logging": {
    "level": "${LOG_LEVEL}",
    "rotation_days": ${LOG_ROTATION_DAYS}
  }
}
EOL

    echo "Created default configuration at: $config_file"
    return 0
}

# Validate the configuration file structure
validate_config() {
    local config_file="$1"
    
    # Check if the file exists
    if [ ! -f "$config_file" ]; then
        return 1
    fi
    
    # Check if the file is valid JSON
    if ! jq . "$config_file" > /dev/null 2>&1; then
        echo "Error: Configuration file is not valid JSON"
        return 1
    fi
    
    # Check if required sections exist (version, paths, clients)
    if ! jq -e '.version and .paths and .clients' "$config_file" > /dev/null 2>&1; then
        echo "Error: Configuration file is missing required sections"
        return 1
    }
    
    return 0
}

# Get a value from the configuration file
get_config_value() {
    local config_file="$1"
    local json_path="$2"
    local default_value="$3"
    
    if [ ! -f "$config_file" ] || ! check_jq_installed; then
        echo "$default_value"
        return
    fi
    
    local value=$(jq -r "$json_path" "$config_file" 2>/dev/null)
    
    if [ -z "$value" ] || [ "$value" = "null" ]; then
        echo "$default_value"
    else
        echo "$value"
    fi
}

# Load configuration from file
load_config() {
    local config_file="${NODE_CONFIG_FILE}"
    
    # Check if jq is installed
    if ! check_jq_installed; then
        echo "Warning: Using default configuration values"
        return 1
    }
    
    # Check if config file exists, create if not
    if [ ! -f "$config_file" ]; then
        echo "Configuration file not found at $config_file, creating default"
        create_default_config "$config_file"
    fi
    
    # Validate configuration
    if ! validate_config "$config_file"; then
        echo "Warning: Configuration file is not valid, using fallback values"
        return 1
    }
    
    # Load main paths
    CUSTOM_PATH=$(get_config_value "$config_file" '.paths.base' "$CUSTOM_PATH")
    HELPER_PATH=$(get_config_value "$config_file" '.paths.helper' "${CUSTOM_PATH}/helper")
    EXECUTION_PATH=$(get_config_value "$config_file" '.paths.execution' "${CUSTOM_PATH}/execution")
    CONSENSUS_PATH=$(get_config_value "$config_file" '.paths.consensus' "${CUSTOM_PATH}/consensus")
    BACKUP_PATH=$(get_config_value "$config_file" '.paths.backup' "${CUSTOM_PATH}/backups")
    LOG_PATH=$(get_config_value "$config_file" '.paths.logs' "${CUSTOM_PATH}/logs")
    JWT_FILE=$(get_config_value "$config_file" '.paths.jwt' "${CUSTOM_PATH}/jwt.hex")
    
    # Load network configuration
    NETWORK=$(get_config_value "$config_file" '.network' "$NETWORK")
    
    # Load client configuration
    ETH_CLIENT=$(get_config_value "$config_file" '.clients.execution.name' "$ETH_CLIENT")
    CONSENSUS_CLIENT=$(get_config_value "$config_file" '.clients.consensus.name' "$CONSENSUS_CLIENT")
    EXECUTION_CONTAINER=$(get_config_value "$config_file" '.clients.execution.container' "$EXECUTION_CONTAINER")
    CONSENSUS_CONTAINER=$(get_config_value "$config_file" '.clients.consensus.container' "$CONSENSUS_CONTAINER")
    
    # Load docker images
    GETH_IMAGE=$(get_config_value "$config_file" '.clients.execution.image' "$GETH_IMAGE")
    ERIGON_IMAGE=$(get_config_value "$config_file" '.clients.execution.image' "$ERIGON_IMAGE")
    LIGHTHOUSE_IMAGE=$(get_config_value "$config_file" '.clients.consensus.image' "$LIGHTHOUSE_IMAGE")
    PRYSM_IMAGE=$(get_config_value "$config_file" '.clients.consensus.image' "$PRYSM_IMAGE")
    
    # Load advanced client configuration
    EXECUTION_CACHE_SIZE=$(get_config_value "$config_file" '.clients.execution.cache_size' "$EXECUTION_CACHE_SIZE")
    EXECUTION_MAX_PEERS=$(get_config_value "$config_file" '.clients.execution.max_peers' "$EXECUTION_MAX_PEERS")
    EXECUTION_API_ENABLED=$(get_config_value "$config_file" '.clients.execution.api_enabled' "$EXECUTION_API_ENABLED")
    EXECUTION_API_METHODS=$(get_config_value "$config_file" '.clients.execution.api_methods' "$EXECUTION_API_METHODS")
    
    # Load API configuration
    API_CORS_DOMAINS=$(get_config_value "$config_file" '.api.cors_domains' "$API_CORS_DOMAINS")
    API_VHOSTS=$(get_config_value "$config_file" '.api.vhosts' "$API_VHOSTS")
    API_ADDR=$(get_config_value "$config_file" '.api.addr' "$API_ADDR")
    
    # Load monitoring configuration
    PROMETHEUS_ENABLED=$(get_config_value "$config_file" '.monitoring.prometheus_enabled' "$PROMETHEUS_ENABLED")
    GRAFANA_ENABLED=$(get_config_value "$config_file" '.monitoring.grafana_enabled' "$GRAFANA_ENABLED")
    
    # Load health check settings
    HEALTH_CHECK_INTERVAL=$(get_config_value "$config_file" '.health.check_interval' "$HEALTH_CHECK_INTERVAL")
    DISK_SPACE_THRESHOLD=$(get_config_value "$config_file" '.health.disk_threshold' "$DISK_SPACE_THRESHOLD")
    CPU_THRESHOLD=$(get_config_value "$config_file" '.health.cpu_threshold' "$CPU_THRESHOLD")
    MEMORY_THRESHOLD=$(get_config_value "$config_file" '.health.memory_threshold' "$MEMORY_THRESHOLD")
    
    # Load update settings
    AUTO_UPDATE_ENABLED=$(get_config_value "$config_file" '.updates.auto_update' "$AUTO_UPDATE_ENABLED")
    BACKUP_BEFORE_UPDATE=$(get_config_value "$config_file" '.updates.backup_before_update' "$BACKUP_BEFORE_UPDATE")
    KEEP_BACKUPS=$(get_config_value "$config_file" '.updates.keep_backups' "$KEEP_BACKUPS")
    
    # Load logging configuration
    LOG_LEVEL=$(get_config_value "$config_file" '.logging.level' "$LOG_LEVEL")
    LOG_ROTATION_DAYS=$(get_config_value "$config_file" '.logging.rotation_days' "$LOG_ROTATION_DAYS")
    
    # Set network-specific variables based on the network
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
    
    echo "Configuration loaded successfully from $config_file"
    return 0
}

# Save configuration to file
save_config() {
    local config_file="${NODE_CONFIG_FILE}"
    local config_dir=$(dirname "$config_file")
    
    # Ensure the directory exists
    mkdir -p "$config_dir"
    
    # Check if jq is installed
    if ! check_jq_installed; then
        echo "Warning: jq not installed, using basic JSON format"
        # Fallback to simple format if jq is not available
        cat > "$config_file" << EOL
{
  "version": "${CONFIG_VERSION}",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "paths": {
    "base": "${CUSTOM_PATH}",
    "helper": "${HELPER_PATH}",
    "execution": "${EXECUTION_PATH}",
    "consensus": "${CONSENSUS_PATH}",
    "backup": "${BACKUP_PATH}",
    "logs": "${LOG_PATH}",
    "jwt": "${JWT_FILE}"
  },
  "network": "${NETWORK}",
  "clients": {
    "execution": {
      "name": "${ETH_CLIENT}",
      "image": "$([ "$ETH_CLIENT" = "geth" ] && echo "$GETH_IMAGE" || echo "$ERIGON_IMAGE")",
      "container": "${EXECUTION_CONTAINER}",
      "cache_size": ${EXECUTION_CACHE_SIZE},
      "max_peers": ${EXECUTION_MAX_PEERS},
      "api_enabled": ${EXECUTION_API_ENABLED},
      "api_methods": "${EXECUTION_API_METHODS}"
    },
    "consensus": {
      "name": "${CONSENSUS_CLIENT}",
      "image": "$([ "$CONSENSUS_CLIENT" = "lighthouse" ] && echo "$LIGHTHOUSE_IMAGE" || echo "$PRYSM_IMAGE")",
      "container": "${CONSENSUS_CONTAINER}",
      "metrics_enabled": ${CONSENSUS_METRICS_ENABLED},
      "api_enabled": ${CONSENSUS_API_ENABLED}
    }
  },
  "api": {
    "cors_domains": "${API_CORS_DOMAINS}",
    "vhosts": "${API_VHOSTS}",
    "addr": "${API_ADDR}"
  },
  "monitoring": {
    "prometheus_enabled": ${PROMETHEUS_ENABLED},
    "grafana_enabled": ${GRAFANA_ENABLED}
  },
  "health": {
    "check_interval": ${HEALTH_CHECK_INTERVAL},
    "disk_threshold": ${DISK_SPACE_THRESHOLD},
    "cpu_threshold": ${CPU_THRESHOLD},
    "memory_threshold": ${MEMORY_THRESHOLD}
  },
  "updates": {
    "auto_update": ${AUTO_UPDATE_ENABLED},
    "backup_before_update": ${BACKUP_BEFORE_UPDATE},
    "keep_backups": ${KEEP_BACKUPS}
  },
  "logging": {
    "level": "${LOG_LEVEL}",
    "rotation_days": ${LOG_ROTATION_DAYS}
  }
}
EOL
    else
        # Use jq to create a nicely formatted JSON file
        jq -n \
          --arg version "$CONFIG_VERSION" \
          --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
          --arg custom_path "$CUSTOM_PATH" \
          --arg helper_path "$HELPER_PATH" \
          --arg execution_path "$EXECUTION_PATH" \
          --arg consensus_path "$CONSENSUS_PATH" \
          --arg backup_path "$BACKUP_PATH" \
          --arg log_path "$LOG_PATH" \
          --arg jwt_file "$JWT_FILE" \
          --arg network "$NETWORK" \
          --arg eth_client "$ETH_CLIENT" \
          --arg consensus_client "$CONSENSUS_CLIENT" \
          --arg execution_container "$EXECUTION_CONTAINER" \
          --arg consensus_container "$CONSENSUS_CONTAINER" \
          --arg geth_image "$GETH_IMAGE" \
          --arg erigon_image "$ERIGON_IMAGE" \
          --arg lighthouse_image "$LIGHTHOUSE_IMAGE" \
          --arg prysm_image "$PRYSM_IMAGE" \
          --argjson execution_cache_size "$EXECUTION_CACHE_SIZE" \
          --argjson execution_max_peers "$EXECUTION_MAX_PEERS" \
          --arg execution_api_enabled "$EXECUTION_API_ENABLED" \
          --arg execution_api_methods "$EXECUTION_API_METHODS" \
          --arg consensus_metrics_enabled "$CONSENSUS_METRICS_ENABLED" \
          --arg consensus_api_enabled "$CONSENSUS_API_ENABLED" \
          --arg api_cors_domains "$API_CORS_DOMAINS" \
          --arg api_vhosts "$API_VHOSTS" \
          --arg api_addr "$API_ADDR" \
          --arg prometheus_enabled "$PROMETHEUS_ENABLED" \
          --arg grafana_enabled "$GRAFANA_ENABLED" \
          --argjson health_check_interval "$HEALTH_CHECK_INTERVAL" \
          --argjson disk_space_threshold "$DISK_SPACE_THRESHOLD" \
          --argjson cpu_threshold "$CPU_THRESHOLD" \
          --argjson memory_threshold "$MEMORY_THRESHOLD" \
          --arg auto_update_enabled "$AUTO_UPDATE_ENABLED" \
          --arg backup_before_update "$BACKUP_BEFORE_UPDATE" \
          --argjson keep_backups "$KEEP_BACKUPS" \
          --arg log_level "$LOG_LEVEL" \
          --argjson log_rotation_days "$LOG_ROTATION_DAYS" \
          '{
            "version": $version,
            "timestamp": $timestamp,
            "paths": {
              "base": $custom_path,
              "helper": $helper_path,
              "execution": $execution_path,
              "consensus": $consensus_path,
              "backup": $backup_path,
              "logs": $log_path,
              "jwt": $jwt_file
            },
            "network": $network,
            "clients": {
              "execution": {
                "name": $eth_client,
                "image": (if $eth_client == "geth" then $geth_image else $erigon_image end),
                "container": $execution_container,
                "cache_size": $execution_cache_size,
                "max_peers": $execution_max_peers,
                "api_enabled": $execution_api_enabled,
                "api_methods": $execution_api_methods
              },
              "consensus": {
                "name": $consensus_client,
                "image": (if $consensus_client == "lighthouse" then $lighthouse_image else $prysm_image end),
                "container": $consensus_container,
                "metrics_enabled": $consensus_metrics_enabled,
                "api_enabled": $consensus_api_enabled
              }
            },
            "api": {
              "cors_domains": $api_cors_domains,
              "vhosts": $api_vhosts,
              "addr": $api_addr
            },
            "monitoring": {
              "prometheus_enabled": $prometheus_enabled,
              "grafana_enabled": $grafana_enabled
            },
            "health": {
              "check_interval": $health_check_interval,
              "disk_threshold": $disk_space_threshold,
              "cpu_threshold": $cpu_threshold,
              "memory_threshold": $memory_threshold
            },
            "updates": {
              "auto_update": $auto_update_enabled,
              "backup_before_update": $backup_before_update,
              "keep_backups": $keep_backups
            },
            "logging": {
              "level": $log_level,
              "rotation_days": $log_rotation_days
            }
          }' > "$config_file"
    fi
    
    # Set appropriate permissions
    chmod 644 "$config_file"
    
    echo "Configuration saved to $config_file"
    return 0
}

# Update a single configuration value
update_config_value() {
    local config_file="${NODE_CONFIG_FILE}"
    local json_path="$1"
    local new_value="$2"
    
    # Check if jq is installed
    if ! check_jq_installed; then
        echo "Error: jq is required for updating configuration values"
        return 1
    }
    
    # Check if the file exists
    if [ ! -f "$config_file" ]; then
        echo "Configuration file not found, creating with default values first"
        create_default_config "$config_file"
    }
    
    # Create a temporary file
    local temp_file=$(mktemp)
    
    # Update the value using jq
    jq "$json_path = $new_value" "$config_file" > "$temp_file"
    
    # Check if jq succeeded
    if [ $? -ne 0 ]; then
        echo "Error: Failed to update configuration value"
        rm -f "$temp_file"
        return 1
    }
    
    # Move the temporary file to the original file
    mv "$temp_file" "$config_file"
    chmod 644 "$config_file"
    
    echo "Updated configuration value at $json_path"
    return 0
}

# Initialize configuration
initialize_config() {
    # Try to load existing configuration, if it fails, create a new one
    if ! load_config; then
        echo "Creating new configuration file"
        create_default_config "${NODE_CONFIG_FILE}"
        load_config
    fi
}

# Display the current configuration in a user-friendly format
show_config() {
    echo "PulseChain Node Configuration:"
    echo "=============================="
    echo ""
    echo "Version: $CONFIG_VERSION"
    echo ""
    echo "Paths:"
    echo "  Base directory: $CUSTOM_PATH"
    echo "  Helper scripts: $HELPER_PATH"
    echo "  Execution data: $EXECUTION_PATH"
    echo "  Consensus data: $CONSENSUS_PATH"
    echo "  Backup storage: $BACKUP_PATH"
    echo "  Log directory : $LOG_PATH"
    echo "  JWT token file: $JWT_FILE"
    echo ""
    echo "Network:"
    echo "  Selected network: $NETWORK"
    echo "  Checkpoint URL  : $CHECKPOINT"
    echo ""
    echo "Clients:"
    echo "  Execution client: $ETH_CLIENT"
    echo "    Container name: $EXECUTION_CONTAINER"
    echo "    Image         : $([ "$ETH_CLIENT" = "geth" ] && echo "$GETH_IMAGE" || echo "$ERIGON_IMAGE")"
    echo "    Cache size    : $EXECUTION_CACHE_SIZE MB"
    echo "    Max peers     : $EXECUTION_MAX_PEERS"
    echo "    API enabled   : $EXECUTION_API_ENABLED"
    echo "    API methods   : $EXECUTION_API_METHODS"
    echo ""
    echo "  Consensus client: $CONSENSUS_CLIENT"
    echo "    Container name: $CONSENSUS_CONTAINER"
    echo "    Image         : $([ "$CONSENSUS_CLIENT" = "lighthouse" ] && echo "$LIGHTHOUSE_IMAGE" || echo "$PRYSM_IMAGE")"
    echo "    Metrics       : $CONSENSUS_METRICS_ENABLED"
    echo "    API enabled   : $CONSENSUS_API_ENABLED"
    echo ""
    echo "API Configuration:"
    echo "  CORS domains    : $API_CORS_DOMAINS"
    echo "  Virtual hosts   : $API_VHOSTS"
    echo "  Listen address  : $API_ADDR"
    echo ""
    echo "Monitoring:"
    echo "  Prometheus      : $PROMETHEUS_ENABLED"
    echo "  Grafana         : $GRAFANA_ENABLED"
    echo ""
    echo "Health Checks:"
    echo "  Check interval  : $HEALTH_CHECK_INTERVAL seconds"
    echo "  Disk threshold  : $DISK_SPACE_THRESHOLD%"
    echo "  CPU threshold   : $CPU_THRESHOLD%"
    echo "  Memory threshold: $MEMORY_THRESHOLD%"
    echo ""
    echo "Updates:"
    echo "  Auto-update     : $AUTO_UPDATE_ENABLED"
    echo "  Backup first    : $BACKUP_BEFORE_UPDATE"
    echo "  Keep backups    : $KEEP_BACKUPS"
    echo ""
    echo "Logging:"
    echo "  Log level       : $LOG_LEVEL"
    echo "  Log rotation    : $LOG_ROTATION_DAYS days"
    echo ""
}

# Add configuration validation function
validate_configuration() {
    local config_file="/blockchain/node_config.json"
    echo -e "${GREEN}Validating configuration...${NC}"
    echo "================================"
    
    # Check if config file exists
    if [ ! -f "$config_file" ]; then
        echo -e "${RED}Error: Configuration file not found: $config_file${NC}"
        return 1
    fi
    
    # Check if file is valid JSON
    if ! jq empty "$config_file" 2>/dev/null; then
        echo -e "${RED}Error: Invalid JSON format in configuration file${NC}"
        return 1
    }
    
    # Required fields and their types
    declare -A required_fields=(
        ["network"]="string"
        ["execution_client"]="string"
        ["consensus_client"]="string"
        ["data_directory"]="string"
        ["monitoring_enabled"]="boolean"
        ["network_mode"]="string"
        ["log_level"]="string"
    )
    
    # Validate required fields and their types
    for field in "${!required_fields[@]}"; do
        expected_type="${required_fields[$field]}"
        
        # Check if field exists
        if ! jq -e ".$field" "$config_file" >/dev/null 2>&1; then
            echo -e "${RED}Error: Missing required field: $field${NC}"
            return 1
        fi
        
        # Validate field type
        value_type=$(jq -r "type.$field" "$config_file")
        if [ "$value_type" != "$expected_type" ]; then
            echo -e "${RED}Error: Field $field should be $expected_type, found $value_type${NC}"
            return 1
        fi
    done
    
    # Validate specific field values
    network=$(jq -r '.network' "$config_file")
    if [[ "$network" != "mainnet" && "$network" != "testnet" ]]; then
        echo -e "${RED}Error: Invalid network value. Must be 'mainnet' or 'testnet'${NC}"
        return 1
    fi
    
    execution_client=$(jq -r '.execution_client' "$config_file")
    if [[ "$execution_client" != "geth" && "$execution_client" != "erigon" ]]; then
        echo -e "${RED}Error: Invalid execution client. Must be 'geth' or 'erigon'${NC}"
        return 1
    fi
    
    consensus_client=$(jq -r '.consensus_client' "$config_file")
    if [[ "$consensus_client" != "lighthouse" && "$consensus_client" != "prysm" ]]; then
        echo -e "${RED}Error: Invalid consensus client. Must be 'lighthouse' or 'prysm'${NC}"
        return 1
    }
    
    # Validate data directory
    data_dir=$(jq -r '.data_directory' "$config_file")
    if [ ! -d "$data_dir" ]; then
        echo -e "${YELLOW}Warning: Data directory does not exist: $data_dir${NC}"
        echo "Directory will be created during setup"
    fi
    
    # Validate network ports
    if ! command -v nc >/dev/null 2>&1; then
        echo -e "${YELLOW}Warning: 'nc' command not found, skipping port checks${NC}"
    else
        # Check execution client port
        execution_port=$(jq -r '.execution_port // 8545' "$config_file")
        if nc -z localhost "$execution_port" 2>/dev/null; then
            echo -e "${YELLOW}Warning: Port $execution_port is already in use${NC}"
        fi
        
        # Check consensus client port
        consensus_port=$(jq -r '.consensus_port // 5052' "$config_file")
        if nc -z localhost "$consensus_port" 2>/dev/null; then
            echo -e "${YELLOW}Warning: Port $consensus_port is already in use${NC}"
        fi
    fi
    
    # Validate monitoring settings if enabled
    monitoring_enabled=$(jq -r '.monitoring_enabled' "$config_file")
    if [ "$monitoring_enabled" = "true" ]; then
        grafana_port=$(jq -r '.grafana_port // 3000' "$config_file")
        prometheus_port=$(jq -r '.prometheus_port // 9090' "$config_file")
        
        if nc -z localhost "$grafana_port" 2>/dev/null; then
            echo -e "${YELLOW}Warning: Grafana port $grafana_port is already in use${NC}"
        fi
        
        if nc -z localhost "$prometheus_port" 2>/dev/null; then
            echo -e "${YELLOW}Warning: Prometheus port $prometheus_port is already in use${NC}"
        fi
    fi
    
    echo -e "${GREEN}Configuration validation completed successfully${NC}"
    return 0
}

# Function to fix common configuration issues
fix_configuration() {
    local config_file="/blockchain/node_config.json"
    
    # Create backup
    cp "$config_file" "${config_file}.backup"
    
    # Fix missing fields with defaults
    if ! jq -e '.monitoring_enabled' "$config_file" >/dev/null 2>&1; then
        jq '. + {"monitoring_enabled": true}' "$config_file" > "${config_file}.tmp"
        mv "${config_file}.tmp" "$config_file"
    fi
    
    if ! jq -e '.network_mode' "$config_file" >/dev/null 2>&1; then
        jq '. + {"network_mode": "local"}' "$config_file" > "${config_file}.tmp"
        mv "${config_file}.tmp" "$config_file"
    fi
    
    if ! jq -e '.log_level' "$config_file" >/dev/null 2>&1; then
        jq '. + {"log_level": "info"}' "$config_file" > "${config_file}.tmp"
        mv "${config_file}.tmp" "$config_file"
    fi
    
    # Ensure data directory exists
    data_dir=$(jq -r '.data_directory' "$config_file")
    mkdir -p "$data_dir"
    
    echo -e "${GREEN}Configuration has been fixed with default values${NC}"
    echo "A backup of the original configuration has been saved to ${config_file}.backup"
}

# Add validation to the main configuration menu
show_config_menu() {
    while true; do
        clear
        echo -e "${GREEN}Node Configuration Menu${NC}"
        echo "======================="
        echo "1. Show current configuration"
        echo "2. Validate configuration"
        echo "3. Fix configuration issues"
        echo "4. Edit configuration"
        echo "5. Save configuration"
        echo "6. Create default configuration"
        echo "7. Back to main menu"
        echo
        read -p "Please select an option (1-7): " choice
        
        case $choice in
            1)
                show_current_config
                ;;
            2)
                if validate_configuration; then
                    echo -e "${GREEN}Configuration is valid${NC}"
                else
                    echo -e "${RED}Configuration validation failed${NC}"
                fi
                read -p "Press Enter to continue..."
                ;;
            3)
                if ! validate_configuration; then
                    echo -e "${YELLOW}Attempting to fix configuration issues...${NC}"
                    fix_configuration
                fi
                read -p "Press Enter to continue..."
                ;;
            4)
                edit_config
                ;;
            5)
                save_config
                ;;
            6)
                create_default_config
                ;;
            7)
                return 0
                ;;
            *)
                echo -e "${RED}Invalid option${NC}"
                sleep 2
                ;;
        esac
    done
}

# Initialize config if this script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "PulseChain Node Configuration Utility"
    echo "====================================="
    echo ""
    
    # If run directly, offer to show or save the configuration
    PS3="Select an option: "
    options=("Show current configuration" "Save configuration" "Create default configuration" "Exit")
    select opt in "${options[@]}"
    do
        case $opt in
            "Show current configuration")
                initialize_config
                show_config
                echo ""
                ;;
            "Save configuration")
                initialize_config
                save_config
                echo "Configuration saved. You can edit it manually at ${NODE_CONFIG_FILE}"
                ;;
            "Create default configuration")
                create_default_config "${NODE_CONFIG_FILE}"
                echo "Default configuration created at ${NODE_CONFIG_FILE}"
                ;;
            "Exit")
                break
                ;;
            *) 
                echo "Invalid option $REPLY"
                ;;
        esac
    done
else
    # When sourced, just initialize the configuration
    initialize_config
fi 