#!/bin/bash

# ===============================================================================
# PulseChain Node Global Configuration File
# ===============================================================================
# This file serves as the central configuration for all PulseChain node scripts.
# All paths, client selections, and other configurable parameters are defined here.
# ===============================================================================

# Version tracking
CONFIG_VERSION="0.1.2"

# ===============================================================================
# Security Configuration
# ===============================================================================

# JWT configuration
JWT_FILE="${CUSTOM_PATH}/.secrets/jwt.hex"
JWT_PERMISSIONS="600"
JWT_LENGTH=32

# API Security
API_CORS_DOMAINS="${API_CORS_DOMAINS:-localhost,*.pulsechain.com}"
API_VHOSTS="${API_VHOSTS:-localhost,node.pulsechain.com}"
API_ADDR="${API_ADDR:-127.0.0.1}"  # Default to localhost only
API_PORT="${API_PORT:-8545}"
API_WS_PORT="${API_WS_PORT:-8546}"

# Authentication
AUTH_ENABLED="true"
AUTH_JWT_SECRET_FILE="${CUSTOM_PATH}/.secrets/auth.jwt"
AUTH_RATE_LIMIT="100"  # Requests per minute
AUTH_ALLOWED_IPS="${AUTH_ALLOWED_IPS:-127.0.0.1}"

# ===============================================================================
# Node Operation Mode
# ===============================================================================

# Node operation modes:
# - LOCAL_INTENSIVE: Optimized for unrestricted local access, maximum performance
# - LOCAL_STANDARD: Standard local node with basic restrictions
# - PUBLIC_SECURE: Public node with security measures
# - PUBLIC_ARCHIVE: Public archive node with rate limiting
NODE_OPERATION_MODE="${NODE_OPERATION_MODE:-LOCAL_INTENSIVE}"

# ===============================================================================
# Multi-Machine Configuration
# ===============================================================================

# Cross-machine access settings
ALLOW_LOCAL_NETWORK="${ALLOW_LOCAL_NETWORK:-true}"
LOCAL_NETWORK_RANGE="${LOCAL_NETWORK_RANGE:-192.168.0.0/16}"
LOCAL_MACHINE_IPS="${LOCAL_MACHINE_IPS:-}"  # Comma-separated list of allowed IPs

# RPC access configuration for local network
RPC_LOCAL_NETWORK="${RPC_LOCAL_NETWORK:-true}"
RPC_ALLOWED_METHODS="admin,debug,eth,net,web3,txpool,trace,parity"
RPC_MAX_CONNECTIONS_LOCAL=1000
WS_MAX_CONNECTIONS_LOCAL=1000

# ===============================================================================
# Mempool Monitoring Configuration
# ===============================================================================

# Mempool monitoring settings
MEMPOOL_MONITORING="${MEMPOOL_MONITORING:-detailed}"  # Options: basic, detailed
MEMPOOL_METRICS_INTERVAL=15  # Seconds between mempool metrics collection
MEMPOOL_MAX_SLOTS=5000      # Maximum number of pending transactions to track
MEMPOOL_HISTORY_HOURS=24    # Hours of mempool history to maintain

# Mempool metrics configuration
MEMPOOL_METRICS_ENABLED="true"
MEMPOOL_ALERT_THRESHOLD=1000  # Alert if pending transactions exceed this
MEMPOOL_GAS_PRICE_TRACKING="true"
MEMPOOL_REORG_TRACKING="true"

# ===============================================================================
# Indexing Support Configuration
# ===============================================================================

# Indexing optimization
INDEXING_MODE="${INDEXING_MODE:-true}"
INDEX_BATCH_SIZE=10000
INDEX_CACHE_SIZE_GB=$((total_memory * 30 / 100))  # 30% of memory for indexing
ARCHIVE_PRUNING_DISABLED=true  # Ensure no pruning for archive nodes

# Database optimization for indexing
DB_WRITE_BUFFER_SIZE=$((INDEX_CACHE_SIZE_GB * 64))  # MB
DB_BLOCK_CACHE_SIZE=$((INDEX_CACHE_SIZE_GB * 512))  # MB
DB_MAX_OPEN_FILES=500000

# Index specific features
INDEX_TRACES="true"
INDEX_LOGS="true"
INDEX_TRANSACTIONS="true"
INDEX_STATE="true"

# Performance tuning for indexing
PARALLEL_BLOCK_PROCESSING=true
MAX_INDEXING_THREADS=$((total_cores - 2))  # Reserve 2 cores for system

# Mode-specific configurations
configure_operation_mode() {
    case "$NODE_OPERATION_MODE" in
        "LOCAL_INTENSIVE")
            # Unrestricted local access configuration
            API_CORS_DOMAINS="*"
            API_VHOSTS="*"
            API_ADDR="0.0.0.0"
            AUTH_ENABLED="false"
            AUTH_RATE_LIMIT="0"  # No rate limiting
            RPC_MAX_CONNECTIONS=1000
            WS_MAX_CONNECTIONS=1000
            EXECUTION_API_METHODS="admin,debug,eth,net,web3,txpool,trace,parity"
            CACHE_SIZE_GB=$((total_memory * 70 / 100))  # 70% of total memory
            MAX_PEERS=100
            ALLOW_UNPROTECTED_TXS="true"
            DB_CACHE_MB=$((CACHE_SIZE_GB * 1024))
            PREIMAGES_ENABLED="true"
            STATE_CACHE_MB=$((CACHE_SIZE_GB * 512))  # Half of cache for state
            SNAPSHOT_CACHE_MB=$((CACHE_SIZE_GB * 256))  # Quarter of cache for snapshots
            
            # Performance tuning
            GOMAXPROCS=$((total_cores - 2))  # Reserve 2 cores for system
            GETH_OPTS="--cache.preimages --cache.noprefetch=false --txlookuplimit=0"
            ;;
            
        "LOCAL_STANDARD")
            # Standard local node configuration
            API_CORS_DOMAINS="localhost,127.0.0.1"
            API_VHOSTS="localhost"
            API_ADDR="127.0.0.1"
            AUTH_ENABLED="true"
            AUTH_RATE_LIMIT="1000"
            RPC_MAX_CONNECTIONS=100
            WS_MAX_CONNECTIONS=50
            EXECUTION_API_METHODS="eth,net,web3,txpool"
            CACHE_SIZE_GB=$((total_memory * 50 / 100))
            MAX_PEERS=50
            ;;
            
        "PUBLIC_SECURE")
            # Public node with security measures
            API_CORS_DOMAINS="${PUBLIC_CORS_DOMAINS:-*}"
            API_VHOSTS="${PUBLIC_VHOSTS:-*}"
            API_ADDR="0.0.0.0"
            AUTH_ENABLED="true"
            AUTH_RATE_LIMIT="100"
            RPC_MAX_CONNECTIONS=50
            WS_MAX_CONNECTIONS=25
            EXECUTION_API_METHODS="eth,net,web3"
            CACHE_SIZE_GB=$((total_memory * 40 / 100))
            MAX_PEERS=25
            ;;
            
        "PUBLIC_ARCHIVE")
            # Public archive node configuration
            API_CORS_DOMAINS="${PUBLIC_CORS_DOMAINS:-*}"
            API_VHOSTS="${PUBLIC_VHOSTS:-*}"
            API_ADDR="0.0.0.0"
            AUTH_ENABLED="true"
            AUTH_RATE_LIMIT="50"
            RPC_MAX_CONNECTIONS=25
            WS_MAX_CONNECTIONS=10
            EXECUTION_API_METHODS="eth,net,web3"
            CACHE_SIZE_GB=$((total_memory * 60 / 100))
            MAX_PEERS=25
            ;;
    esac
}

# System tuning for intensive local access
tune_system_for_intensive_local() {
    if [ "$NODE_OPERATION_MODE" = "LOCAL_INTENSIVE" ]; then
        # Increase system limits
        ulimit -n 1000000
        sysctl -w fs.file-max=1000000
        sysctl -w net.core.somaxconn=65535
        sysctl -w net.ipv4.tcp_max_syn_backlog=65536
        sysctl -w net.core.netdev_max_backlog=65536
        sysctl -w net.ipv4.tcp_tw_reuse=1
        
        # Increase TCP buffer sizes
        sysctl -w net.core.rmem_max=16777216
        sysctl -w net.core.wmem_max=16777216
        sysctl -w net.ipv4.tcp_rmem="4096 87380 16777216"
        sysctl -w net.ipv4.tcp_wmem="4096 87380 16777216"
        
        # Optimize disk I/O
        if command -v hdparm >/dev/null; then
            for disk in $(lsblk -d -o name | grep -v NAME); do
                hdparm -W1 /dev/$disk  # Enable write caching
            done
        fi
        
        # Set I/O scheduler to deadline for SSDs
        for disk in $(lsblk -d -o name | grep -v NAME); do
            echo deadline > /sys/block/$disk/queue/scheduler
            echo 4096 > /sys/block/$disk/queue/read_ahead_kb
        done
    fi
}

# ===============================================================================
# Resource Management
# ===============================================================================

# Dynamic resource calculation
calculate_resources() {
    local total_memory=$(free -g | awk '/^Mem:/{print $2}')
    local total_cores=$(nproc)
    
    # Calculate execution client resources (50% of available)
    EXECUTION_MEMORY_LIMIT=$((total_memory / 2))
    EXECUTION_CPU_LIMIT=$((total_cores / 2))
    EXECUTION_CACHE_SIZE=$((EXECUTION_MEMORY_LIMIT * 1024 / 2))  # Half of allocated memory in MB
    
    # Calculate consensus client resources (30% of available)
    CONSENSUS_MEMORY_LIMIT=$((total_memory * 3 / 10))
    CONSENSUS_CPU_LIMIT=$((total_cores * 3 / 10))
    
    # Reserve remaining 20% for system and monitoring
}

# Call resource calculation
calculate_resources

# ===============================================================================
# Enhanced Monitoring Configuration
# ===============================================================================

# Health check settings
HEALTH_CHECK_INTERVAL=60    # Check every minute
HEALTH_CHECK_RETRIES=3      # Number of retries before alerting

# Resource thresholds
DISK_SPACE_THRESHOLD=85     # Alert at 85% usage
CPU_THRESHOLD=90            # Alert at 90% usage
MEMORY_THRESHOLD=85        # Alert at 85% usage
IOPS_THRESHOLD=5000        # Minimum IOPS required
FILE_DESCRIPTOR_MIN=65535   # Minimum required file descriptors

# Chain-specific monitoring
SYNC_MAX_BLOCKS_BEHIND=50   # Maximum blocks behind
MIN_PEER_COUNT=20          # Minimum required peers
MAX_TX_POOL_SIZE=5000      # Maximum transaction pool size

# Metrics retention
METRICS_RETENTION_DAYS=30
METRICS_SCRAPE_INTERVAL="15s"

# ===============================================================================
# Backup Configuration
# ===============================================================================

# Backup settings
BACKUP_ENABLED="true"
BACKUP_TYPE="incremental"  # Options: full, incremental
BACKUP_ENCRYPTION="true"
BACKUP_COMPRESSION="true"
BACKUP_RETENTION_DAYS=30
BACKUP_MAX_SIZE_GB=500
BACKUP_VERIFICATION="true"

# Backup schedule
BACKUP_SCHEDULE="0 2 * * *"  # Daily at 2 AM
BACKUP_LOCATION="${CUSTOM_PATH}/backups"
BACKUP_REMOTE_ENABLED="false"
BACKUP_REMOTE_URL=""
BACKUP_REMOTE_KEY=""

# ===============================================================================
# Error Recovery Configuration
# ===============================================================================

# Auto-recovery settings
AUTO_RECOVERY_ENABLED="true"
MAX_AUTO_RECOVERY_ATTEMPTS=3
RECOVERY_WAIT_TIME=300  # 5 minutes between attempts

# Service dependencies
declare -A SERVICE_DEPENDENCIES=(
    ["consensus"]="execution"
    ["prometheus"]="execution consensus"
    ["grafana"]="prometheus"
)

# Recovery priorities
declare -A SERVICE_PRIORITIES=(
    ["execution"]="1"
    ["consensus"]="2"
    ["prometheus"]="3"
    ["grafana"]="4"
)

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
EXECUTION_MAX_PEERS=50
EXECUTION_API_ENABLED="true"
EXECUTION_API_METHODS="eth,net,web3,txpool"

# Consensus client configuration
CONSENSUS_METRICS_ENABLED="true"
CONSENSUS_API_ENABLED="true"

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
    local validation_errors=0
    
    # Function to log validation errors
    log_validation_error() {
        local error_message=$1
        echo -e "${RED}Configuration Error: ${error_message}${NC}" >&2
        ((validation_errors++))
    }

    # Validate memory settings
    validate_memory_settings() {
        local total_memory=$(free -g | awk '/^Mem:/{print $2}')
        
        # Validate cache sizes don't exceed available memory
        if [ "$CACHE_SIZE_GB" -gt "$total_memory" ]; then
            log_validation_error "CACHE_SIZE_GB ($CACHE_SIZE_GB) exceeds total system memory ($total_memory GB)"
        fi
        
        # Validate memory limits
        if [ "$EXECUTION_MEMORY_LIMIT" -gt "$total_memory" ]; then
            log_validation_error "EXECUTION_MEMORY_LIMIT ($EXECUTION_MEMORY_LIMIT) exceeds total system memory"
        fi
        
        if [ "$CONSENSUS_MEMORY_LIMIT" -gt "$total_memory" ]; then
            log_validation_error "CONSENSUS_MEMORY_LIMIT ($CONSENSUS_MEMORY_LIMIT) exceeds total system memory"
        fi
        
        # Validate total allocated memory doesn't exceed 90% of system memory
        local total_allocated=$((EXECUTION_MEMORY_LIMIT + CONSENSUS_MEMORY_LIMIT))
        if [ "$total_allocated" -gt "$((total_memory * 90 / 100))" ]; then
            log_validation_error "Total allocated memory ($total_allocated GB) exceeds 90% of system memory"
        fi
    }

    # Validate network settings
    validate_network_settings() {
        # Validate API address format
        if ! echo "$API_ADDR" | grep -E '^([0-9]{1,3}\.){3}[0-9]{1,3}$|^localhost$' >/dev/null; then
            log_validation_error "Invalid API_ADDR format: $API_ADDR"
        fi
        
        # Validate ports are within valid range
        if ! [[ "$API_PORT" =~ ^[0-9]+$ ]] || [ "$API_PORT" -lt 1024 ] || [ "$API_PORT" -gt 65535 ]; then
            log_validation_error "Invalid API_PORT: $API_PORT (must be between 1024-65535)"
        fi
        
        if ! [[ "$API_WS_PORT" =~ ^[0-9]+$ ]] || [ "$API_WS_PORT" -lt 1024 ] || [ "$API_WS_PORT" -gt 65535 ]; then
            log_validation_error "Invalid API_WS_PORT: $API_WS_PORT (must be between 1024-65535)"
        fi
    }

    # Validate security settings
    validate_security_settings() {
        # Validate JWT configuration
        if [ ! -f "$JWT_FILE" ] && [ "$AUTH_ENABLED" = "true" ]; then
            log_validation_error "JWT file not found at $JWT_FILE but authentication is enabled"
        fi
        
        # Validate JWT permissions if file exists
        if [ -f "$JWT_FILE" ]; then
            local jwt_perms=$(stat -c %a "$JWT_FILE")
            if [ "$jwt_perms" != "$JWT_PERMISSIONS" ]; then
                log_validation_error "JWT file has incorrect permissions: $jwt_perms (should be $JWT_PERMISSIONS)"
            fi
        fi
        
        # Validate rate limiting
        if ! [[ "$AUTH_RATE_LIMIT" =~ ^[0-9]+$ ]]; then
            log_validation_error "Invalid AUTH_RATE_LIMIT: $AUTH_RATE_LIMIT (must be a number)"
        fi
    }

    # Validate monitoring settings
    validate_monitoring_settings() {
        if ! [[ "$HEALTH_CHECK_INTERVAL" =~ ^[0-9]+$ ]] || [ "$HEALTH_CHECK_INTERVAL" -lt 10 ]; then
            log_validation_error "Invalid HEALTH_CHECK_INTERVAL: $HEALTH_CHECK_INTERVAL (must be ≥ 10 seconds)"
        fi
        
        if ! [[ "$METRICS_RETENTION_DAYS" =~ ^[0-9]+$ ]] || [ "$METRICS_RETENTION_DAYS" -lt 1 ]; then
            log_validation_error "Invalid METRICS_RETENTION_DAYS: $METRICS_RETENTION_DAYS (must be ≥ 1)"
        }
    }

    # Validate operation mode settings
    validate_operation_mode() {
        case "$NODE_OPERATION_MODE" in
            "LOCAL_INTENSIVE"|"LOCAL_STANDARD"|"PUBLIC_SECURE"|"PUBLIC_ARCHIVE")
                ;;
            *)
                log_validation_error "Invalid NODE_OPERATION_MODE: $NODE_OPERATION_MODE"
                ;;
        esac
    }

    # Run all validations
    validate_memory_settings
    validate_network_settings
    validate_security_settings
    validate_monitoring_settings
    validate_operation_mode

    # Return validation status
    if [ $validation_errors -gt 0 ]; then
        echo -e "${RED}Configuration validation failed with $validation_errors error(s)${NC}" >&2
        return 1
    fi
    echo -e "${GREEN}Configuration validation passed successfully${NC}"
    return 0
}

# Run configuration validation
if ! validate_config; then
    echo "Please fix configuration errors before continuing."
    exit 1
fi

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

# Display local machine connection settings
show_local_connection_settings() {
    echo "========================================================="
    echo "     Local Machine Connection Settings"
    echo "========================================================="
    echo
    echo "Network Type: ${NETWORK} (${NETWORK_TYPE:-pulsechain})"
    echo
    echo "RPC Endpoints:"
    echo "-------------"
    echo "HTTP RPC URL : http://${API_ADDR}:${API_PORT}"
    echo "WebSocket URL: ws://${API_ADDR}:${API_WS_PORT}"
    echo
    echo "Available API Methods:"
    echo "-------------------"
    echo "${RPC_ALLOWED_METHODS}" | tr ',' '\n' | while read -r method; do
        echo "  - ${method}"
    done
    echo
    echo "Access Settings:"
    echo "---------------"
    if [[ "$NODE_OPERATION_MODE" == "LOCAL_INTENSIVE" ]]; then
        echo "Mode          : LOCAL_INTENSIVE (Unrestricted local access)"
        echo "Rate Limiting : Disabled"
        echo "Authentication: Disabled"
    else
        echo "Mode          : ${NODE_OPERATION_MODE}"
        echo "Rate Limiting : ${AUTH_RATE_LIMIT} requests/minute"
        echo "Authentication: ${AUTH_ENABLED}"
    fi
    echo
    echo "Local Network Access:"
    echo "-------------------"
    if [[ "$ALLOW_LOCAL_NETWORK" == "true" ]]; then
        echo "Status        : Enabled"
        echo "Network Range : ${LOCAL_NETWORK_RANGE}"
        if [[ -n "$LOCAL_MACHINE_IPS" ]]; then
            echo "Allowed IPs   : ${LOCAL_MACHINE_IPS}"
        else
            echo "Allowed IPs   : All IPs in network range"
        fi
    else
        echo "Status        : Disabled (localhost only)"
    fi
    echo
    echo "Connection Example Commands:"
    echo "-------------------------"
    echo "1. Check connection (using curl):"
    echo "   curl -X POST -H \"Content-Type: application/json\" \\"
    echo "        --data '{\"jsonrpc\":\"2.0\",\"method\":\"eth_blockNumber\",\"params\":[],\"id\":1}' \\"
    echo "        http://${API_ADDR}:${API_PORT}"
    echo
    echo "2. Web3.js connection:"
    echo "   const Web3 = require('web3');"
    echo "   const web3 = new Web3('http://${API_ADDR}:${API_PORT}');"
    echo
    echo "3. Ethers.js connection:"
    echo "   const provider = new ethers.JsonRpcProvider('http://${API_ADDR}:${API_PORT}');"
    echo
    echo "4. WebSocket connection:"
    echo "   const web3 = new Web3('ws://${API_ADDR}:${API_WS_PORT}');"
    echo
    echo "Performance Settings:"
    echo "-------------------"
    echo "Max Connections : ${RPC_MAX_CONNECTIONS_LOCAL} (HTTP), ${WS_MAX_CONNECTIONS_LOCAL} (WebSocket)"
    echo "Cache Size      : ${CACHE_SIZE_GB}GB"
    echo "Indexing Mode   : ${INDEXING_MODE}"
    echo
    echo "Mempool Monitoring:"
    echo "------------------"
    echo "Mode           : ${MEMPOOL_MONITORING}"
    echo "Max Slots      : ${MEMPOOL_MAX_SLOTS}"
    echo "Metrics Interval: ${MEMPOOL_METRICS_INTERVAL} seconds"
    echo
    echo "========================================================="
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

# Update show_config_menu to include the new option
show_config_menu() {
    while true; do
        clear
        echo -e "${GREEN}Node Configuration Menu${NC}"
        echo "======================="
        echo "1. Show current configuration"
        echo "2. Show local machine connection settings"
        echo "3. Validate configuration"
        echo "4. Fix configuration issues"
        echo "5. Edit configuration"
        echo "6. Save configuration"
        echo "7. Create default configuration"
        echo "8. Back to main menu"
        echo
        read -p "Please select an option (1-8): " choice
        
        case $choice in
            1)
                show_config
                read -p "Press Enter to continue..."
                ;;
            2)
                show_local_connection_settings
                read -p "Press Enter to continue..."
                ;;
            3)
                if validate_configuration; then
                    echo -e "${GREEN}Configuration is valid${NC}"
                else
                    echo -e "${RED}Configuration validation failed${NC}"
                fi
                read -p "Press Enter to continue..."
                ;;
            4)
                if ! validate_configuration; then
                    echo -e "${YELLOW}Attempting to fix configuration issues...${NC}"
                    fix_configuration
                fi
                read -p "Press Enter to continue..."
                ;;
            5)
                edit_config
                ;;
            6)
                save_config
                ;;
            7)
                create_default_config
                ;;
            8)
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

# Call configuration functions
calculate_resources
configure_operation_mode
[ "$(id -u)" = "0" ] && tune_system_for_intensive_local 