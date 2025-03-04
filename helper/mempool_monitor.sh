#!/bin/bash

# Source the main configuration
source /blockchain/config.sh

# ===============================================================================
# Mempool Monitoring Script
# This script provides detailed monitoring of the transaction mempool
# for both PulseChain and Ethereum networks
# ===============================================================================

# Initialize logging
LOG_FILE="${LOG_PATH}/mempool.log"
METRICS_FILE="${LOG_PATH}/mempool_metrics.json"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Logging function
log_mempool() {
    local level="$1"
    local message="$2"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    # If it's a metric, also save to metrics file
    if [[ "$level" == "METRIC" ]]; then
        echo "{\"timestamp\":\"$timestamp\",\"data\":$message}" >> "$METRICS_FILE"
    fi
}

# Function to get detailed mempool statistics
get_mempool_stats() {
    local response=$(curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"txpool_status","params":[],"id":1}' \
        http://localhost:8545)
    
    if [[ $? -ne 0 ]]; then
        log_mempool "ERROR" "Failed to fetch mempool status"
        return 1
    fi
    
    echo "$response"
}

# Function to analyze transaction types and gas prices
analyze_mempool_transactions() {
    local content=$(curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"txpool_content","params":[],"id":1}' \
        http://localhost:8545)
    
    if [[ $? -ne 0 ]]; then
        log_mempool "ERROR" "Failed to fetch mempool content"
        return 1
    fi
    
    # Process and analyze transactions
    local pending_count=$(echo "$content" | jq -r '.result.pending | keys | length')
    local queued_count=$(echo "$content" | jq -r '.result.queued | keys | length')
    local total_count=$((pending_count + queued_count))
    
    # Calculate average gas price
    local avg_gas_price=$(echo "$content" | jq -r '
        [.result.pending[][] | .gasPrice | tonumber] | 
        if length > 0 then (add / length) else 0 end
    ')
    
    # Create metrics JSON
    local metrics=$(cat << EOF
{
    "pending_count": $pending_count,
    "queued_count": $queued_count,
    "total_count": $total_count,
    "avg_gas_price": $avg_gas_price
}
EOF
    )
    
    log_mempool "METRIC" "$metrics"
    
    # Check alert threshold
    if [[ $total_count -gt $MEMPOOL_ALERT_THRESHOLD ]]; then
        log_mempool "ALERT" "Mempool size ($total_count) exceeds threshold ($MEMPOOL_ALERT_THRESHOLD)"
    fi
}

# Function to track reorgs
track_reorgs() {
    local current_block=$(curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
        http://localhost:8545 | jq -r '.result')
    
    if [[ -f "/tmp/last_block" ]]; then
        local last_block=$(cat "/tmp/last_block")
        if [[ "$((16#${current_block:2}))" -lt "$((16#${last_block:2}))" ]]; then
            log_mempool "ALERT" "Potential reorg detected: Current block $current_block, Last block $last_block"
        fi
    fi
    
    echo "$current_block" > "/tmp/last_block"
}

# Main monitoring loop
monitor_mempool() {
    while true; do
        if [[ "$MEMPOOL_MONITORING" == "detailed" ]]; then
            analyze_mempool_transactions
            [[ "$MEMPOOL_REORG_TRACKING" == "true" ]] && track_reorgs
        else
            get_mempool_stats
        fi
        
        sleep "$MEMPOOL_METRICS_INTERVAL"
    done
}

# Cleanup old metrics
cleanup_old_metrics() {
    find "$LOG_PATH" -name "mempool_metrics.json" -mtime +"$MEMPOOL_HISTORY_HOURS" -delete
}

# Start monitoring
log_mempool "INFO" "Starting mempool monitoring (Mode: $MEMPOOL_MONITORING)"
cleanup_old_metrics
monitor_mempool 