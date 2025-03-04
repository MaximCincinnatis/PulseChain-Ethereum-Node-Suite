#!/bin/bash

# Enhanced Health Check Script for PulseChain Node
# This script implements comprehensive health monitoring for the node

# Source the main configuration
source /blockchain/config.sh

# Initialize logging for health checks
HEALTH_LOG="${LOG_PATH}/health_check.log"
mkdir -p "$(dirname "$HEALTH_LOG")"

# Logging function
log_health() {
    local level="$1"
    local message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$HEALTH_LOG"
    
    # If critical, send alert
    if [ "$level" = "CRITICAL" ]; then
        send_alert "$message"
    fi
}

# Alert function - can be configured to use various notification methods
send_alert() {
    local message="$1"
    
    # Log the alert
    echo "[ALERT] $message" >> "$HEALTH_LOG"
    
    # If webhook URL is configured, send alert
    if [ -n "$ALERT_WEBHOOK_URL" ]; then
        curl -X POST -H "Content-Type: application/json" \
             -d "{\"message\": \"$message\"}" \
             "$ALERT_WEBHOOK_URL"
    fi
}

# Check system resources
check_system_resources() {
    # Check disk space
    local disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$disk_usage" -gt "$DISK_SPACE_THRESHOLD" ]; then
        log_health "CRITICAL" "Disk usage is at ${disk_usage}% (threshold: ${DISK_SPACE_THRESHOLD}%)"
    fi
    
    # Check CPU usage
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d. -f1)
    if [ "$cpu_usage" -gt "$CPU_THRESHOLD" ]; then
        log_health "WARNING" "CPU usage is at ${cpu_usage}% (threshold: ${CPU_THRESHOLD}%)"
    fi
    
    # Check memory usage
    local mem_usage=$(free | grep Mem | awk '{print int($3/$2 * 100)}')
    if [ "$mem_usage" -gt "$MEMORY_THRESHOLD" ]; then
        log_health "WARNING" "Memory usage is at ${mem_usage}% (threshold: ${MEMORY_THRESHOLD}%)"
    fi
    
    # Check IOPS
    local iops=$(iostat -x 1 1 | awk '/sda/ {print int($4)}')
    if [ "$iops" -lt "$IOPS_THRESHOLD" ]; then
        log_health "WARNING" "IOPS is at ${iops} (minimum required: ${IOPS_THRESHOLD})"
    fi
    
    # Check file descriptors
    local fd_count=$(lsof -n | wc -l)
    if [ "$fd_count" -gt "$FILE_DESCRIPTOR_MIN" ]; then
        log_health "WARNING" "High number of file descriptors: ${fd_count} (threshold: ${FILE_DESCRIPTOR_MIN})"
    fi
}

# Check node synchronization
check_node_sync() {
    # Get current block number
    local current_block=$(curl -s -X POST -H "Content-Type: application/json" \
                         --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
                         http://localhost:8545 | jq -r '.result')
    
    # Convert hex to decimal
    current_block=$((16#${current_block#0x}))
    
    # Get latest block from network
    local latest_block=$(curl -s https://rpc.pulsechain.com \
                        -X POST -H "Content-Type: application/json" \
                        --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
                        | jq -r '.result')
    latest_block=$((16#${latest_block#0x}))
    
    # Calculate blocks behind
    local blocks_behind=$((latest_block - current_block))
    
    if [ "$blocks_behind" -gt "$SYNC_MAX_BLOCKS_BEHIND" ]; then
        log_health "CRITICAL" "Node is ${blocks_behind} blocks behind (threshold: ${SYNC_MAX_BLOCKS_BEHIND})"
    fi
}

# Check peer connections
check_peer_connections() {
    # Get peer count
    local peer_count=$(curl -s -X POST -H "Content-Type: application/json" \
                      --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' \
                      http://localhost:8545 | jq -r '.result')
    
    # Convert hex to decimal
    peer_count=$((16#${peer_count#0x}))
    
    if [ "$peer_count" -lt "$MIN_PEER_COUNT" ]; then
        log_health "WARNING" "Low peer count: ${peer_count} (minimum: ${MIN_PEER_COUNT})"
    fi
}

# Check transaction pool
check_tx_pool() {
    # Get transaction pool status
    local tx_pool_status=$(curl -s -X POST -H "Content-Type: application/json" \
                          --data '{"jsonrpc":"2.0","method":"txpool_status","params":[],"id":1}' \
                          http://localhost:8545)
    
    local pending=$(echo "$tx_pool_status" | jq -r '.result.pending')
    pending=$((16#${pending#0x}))
    
    if [ "$pending" -gt "$MAX_TX_POOL_SIZE" ]; then
        log_health "WARNING" "High transaction pool size: ${pending} (threshold: ${MAX_TX_POOL_SIZE})"
    fi
}

# Check service health
check_service_health() {
    # Check execution client
    if ! curl -s http://localhost:8545 > /dev/null; then
        log_health "CRITICAL" "Execution client is not responding"
        attempt_service_recovery "execution"
    fi
    
    # Check consensus client
    if ! curl -s http://localhost:5052/eth/v1/node/health > /dev/null; then
        log_health "CRITICAL" "Consensus client is not responding"
        attempt_service_recovery "consensus"
    fi
    
    # Check monitoring stack
    if ! curl -s http://localhost:9090/-/healthy > /dev/null; then
        log_health "WARNING" "Prometheus is not responding"
    fi
    
    if ! curl -s http://localhost:3000/api/health > /dev/null; then
        log_health "WARNING" "Grafana is not responding"
    fi
}

# Service recovery function
attempt_service_recovery() {
    local service="$1"
    local attempts=0
    
    while [ "$attempts" -lt "$MAX_AUTO_RECOVERY_ATTEMPTS" ]; do
        log_health "INFO" "Attempting recovery of $service (attempt $((attempts + 1)))"
        
        # Restart the service
        docker-compose restart "$service"
        
        # Wait for recovery
        sleep "$RECOVERY_WAIT_TIME"
        
        # Check if service is now healthy
        if docker-compose ps "$service" | grep -q "Up"; then
            log_health "INFO" "Successfully recovered $service"
            return 0
        fi
        
        attempts=$((attempts + 1))
    done
    
    log_health "CRITICAL" "Failed to recover $service after $MAX_AUTO_RECOVERY_ATTEMPTS attempts"
    return 1
}

# Main health check loop
main() {
    while true; do
        # Run all checks
        check_system_resources
        check_node_sync
        check_peer_connections
        check_tx_pool
        check_service_health
        
        # Sleep for the configured interval
        sleep "$HEALTH_CHECK_INTERVAL"
    done
}

# Start the health check loop
main 