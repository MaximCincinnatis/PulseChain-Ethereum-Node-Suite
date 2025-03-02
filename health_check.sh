#!/bin/bash

# ===============================================================================
# PulseChain Node Health Check Script
# ===============================================================================
# This script performs health checks on the PulseChain node
# Version: 0.1.0 (Enhanced with automatic disk protection)
# ===============================================================================

# Source global configuration
if [ -f "$(dirname "$(dirname "$0")")/config.sh" ]; then
    source "$(dirname "$(dirname "$0")")/config.sh"
else
    # Set defaults if config not found
    CUSTOM_PATH="/blockchain"
    LOG_PATH="$CUSTOM_PATH/logs"
    EXECUTION_CONTAINER="execution-client"
    CONSENSUS_CONTAINER="consensus-client"
    DISK_WARN_THRESHOLD=80
    DISK_CRITICAL_THRESHOLD=90
    DISK_PROTECTION_THRESHOLD=95
fi

# Create log directory if it doesn't exist
mkdir -p "$LOG_PATH"

# Log file path
LOG_FILE="$LOG_PATH/health_check.log"
BLOCK_HEIGHT_CSV="$LOG_PATH/block_height.csv"

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Status indicator file for disk protection
DISK_PROTECTION_ACTIVE="$LOG_PATH/disk_protection_active"

# ===============================================================================
# Helper Functions
# ===============================================================================

# Function to log messages with timestamps
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    # Log to file
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    # Also print to console
    case "$level" in
        "INFO")
            echo -e "${GREEN}[$level]${NC} $message"
            ;;
        "WARNING")
            echo -e "${YELLOW}[$level]${NC} $message"
            ;;
        "ERROR")
            echo -e "${RED}[$level]${NC} $message"
            ;;
        *)
            echo "[$level] $message"
            ;;
    esac
}

# Function to check if a Docker container is running
check_container_running() {
    local container_name="$1"
    
    if sudo docker ps | grep -q "$container_name"; then
        return 0 # Container is running
    else
        return 1 # Container is not running
    fi
}

# Function to activate disk protection mode
activate_disk_protection() {
    local disk_usage="$1"
    local mount_point="$2"
    
    # Only activate if not already active
    if [ ! -f "$DISK_PROTECTION_ACTIVE" ]; then
        log_message "ERROR" "DISK PROTECTION ACTIVATED: Disk usage at $disk_usage% on $mount_point has reached critical level."
        log_message "ERROR" "Automatically stopping node containers to prevent data corruption."
        
        # Create the protection active file
        echo "Activated at: $(date)" > "$DISK_PROTECTION_ACTIVE"
        echo "Disk usage: $disk_usage% on $mount_point" >> "$DISK_PROTECTION_ACTIVE"
        
        # Stop containers with generous timeouts
        log_message "INFO" "Stopping consensus client container with 3-minute timeout..."
        sudo docker stop -t 180 $CONSENSUS_CONTAINER
        
        log_message "INFO" "Stopping execution client container with 5-minute timeout..."
        sudo docker stop -t 300 $EXECUTION_CONTAINER
        
        log_message "INFO" "Node containers stopped. Please free up disk space and run the menu.sh script to restart services."
        
        # Create desktop notification if possible
        if command -v notify-send &> /dev/null; then
            notify-send -u critical "DISK SPACE CRITICAL" "Node containers have been stopped to prevent data corruption. Please free up disk space immediately."
        fi
        
        return 0
    else
        log_message "ERROR" "Disk protection already active. Node containers should be stopped."
        return 1
    fi
}

# Function to check if disk protection can be deactivated
check_disk_protection_status() {
    # If protection is active, check if disk space is now below critical threshold
    if [ -f "$DISK_PROTECTION_ACTIVE" ]; then
        log_message "WARNING" "Disk protection mode is active. Checking if disk space has been freed..."
        
        # Check all mount points
        local all_below_threshold=true
        
        # Get disk usage for filesystem containing the blockchain data
        local blockchain_df=$(df -h "$CUSTOM_PATH" | grep -v "Filesystem")
        local blockchain_usage=$(echo "$blockchain_df" | awk '{print $5}' | tr -d '%')
        local blockchain_mount=$(echo "$blockchain_df" | awk '{print $6}')
        
        if [ "$blockchain_usage" -lt "$DISK_PROTECTION_THRESHOLD" ]; then
            log_message "INFO" "Disk usage now at $blockchain_usage% on $blockchain_mount - below protection threshold."
        else
            all_below_threshold=false
            log_message "WARNING" "Disk usage still at $blockchain_usage% on $blockchain_mount - above protection threshold."
        fi
        
        # If all checked disks are below threshold, deactivate protection
        if [ "$all_below_threshold" = true ]; then
            log_message "INFO" "Disk space freed. Removing disk protection. You can restart the node containers now."
            rm "$DISK_PROTECTION_ACTIVE"
            
            # Create desktop notification if possible
            if command -v notify-send &> /dev/null; then
                notify-send "Disk Space Recovered" "Disk protection deactivated. You can restart the node containers now."
            fi
        fi
        
        return 0
    fi
    
    return 1 # Protection not active
}

# ===============================================================================
# Health Check Functions
# ===============================================================================

# Check disk space
check_disk_space() {
    log_message "INFO" "Checking disk space..."
    
    # Get disk usage for filesystem containing the blockchain data
    local blockchain_df=$(df -h "$CUSTOM_PATH" | grep -v "Filesystem")
    local blockchain_usage=$(echo "$blockchain_df" | awk '{print $5}' | tr -d '%')
    local blockchain_mount=$(echo "$blockchain_df" | awk '{print $6}')
    
    if [ "$blockchain_usage" -ge "$DISK_PROTECTION_THRESHOLD" ]; then
        # Critical threshold - activate disk protection
        log_message "ERROR" "CRITICAL: Disk usage at $blockchain_usage% on $blockchain_mount has reached protection threshold ($DISK_PROTECTION_THRESHOLD%)."
        activate_disk_protection "$blockchain_usage" "$blockchain_mount"
    elif [ "$blockchain_usage" -ge "$DISK_CRITICAL_THRESHOLD" ]; then
        # Critical warning
        log_message "ERROR" "CRITICAL: Disk usage at $blockchain_usage% on $blockchain_mount has reached critical threshold ($DISK_CRITICAL_THRESHOLD%)."
        log_message "ERROR" "Action required: Free up space immediately to prevent automatic shutdown at $DISK_PROTECTION_THRESHOLD%."
    elif [ "$blockchain_usage" -ge "$DISK_WARN_THRESHOLD" ]; then
        # Warning
        log_message "WARNING" "Disk usage at $blockchain_usage% on $blockchain_mount has reached warning threshold ($DISK_WARN_THRESHOLD%)."
    else
        # OK
        log_message "INFO" "Disk usage at $blockchain_usage% on $blockchain_mount (OK)."
    fi
}

# Check Docker service
check_docker_service() {
    log_message "INFO" "Checking Docker service..."
    
    if systemctl is-active --quiet docker; then
        log_message "INFO" "Docker service is running (OK)."
    else
        log_message "ERROR" "Docker service is not running!"
    fi
}

# Check containers status
check_containers_status() {
    log_message "INFO" "Checking container status..."
    
    if check_container_running "$EXECUTION_CONTAINER"; then
        log_message "INFO" "Execution client container is running (OK)."
    else
        log_message "ERROR" "Execution client container is not running!"
    fi
    
    if check_container_running "$CONSENSUS_CONTAINER"; then
        log_message "INFO" "Consensus client container is running (OK)."
    else
        log_message "ERROR" "Consensus client container is not running!"
    fi
}

# Check client sync status
check_client_sync() {
    log_message "INFO" "Checking client sync status..."
    
    # Check execution client sync status
    if check_container_running "$EXECUTION_CONTAINER"; then
        local exec_syncing=$(curl -s -X POST -H "Content-Type: application/json" \
            --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
            http://localhost:8545)
        
        if echo "$exec_syncing" | grep -q "false"; then
            log_message "INFO" "Execution client is fully synced!"
        else
            local current_block=$(curl -s -X POST -H "Content-Type: application/json" \
                --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
                http://localhost:8545 | grep -oP '(?<="result":")0x[^"]+' | tr -d '0x' | xargs printf "%d" 2>/dev/null)
            
            local highest_block=$(echo "$exec_syncing" | grep -o '"highestBlock":"0x[^"]*' | grep -o '0x[^"]*' | tr -d '0x' | xargs printf "%d" 2>/dev/null)
            
            if [[ -n "$current_block" && -n "$highest_block" ]]; then
                log_message "INFO" "Execution client syncing: Block $current_block of $highest_block"
                
                # Record block height for historical tracking
                if [ -n "$current_block" ]; then
                    echo "$(date +%s),$current_block" >> "$BLOCK_HEIGHT_CSV"
                fi
                
                # Check for sync progress
                if [[ $highest_block -gt 0 ]]; then
                    local progress=$(awk "BEGIN {printf \"%.2f\", ($current_block/$highest_block)*100}")
                    log_message "INFO" "Sync progress: $progress%"
                fi
            else
                log_message "WARNING" "Could not determine execution client sync status."
            fi
        fi
    else
        log_message "WARNING" "Cannot check execution client sync status - container not running."
    fi
}

# Get system resource usage
check_system_resources() {
    log_message "INFO" "Checking system resources..."
    
    # Check memory usage
    local mem_info=$(free -m)
    local mem_total=$(echo "$mem_info" | grep "Mem:" | awk '{print $2}')
    local mem_used=$(echo "$mem_info" | grep "Mem:" | awk '{print $3}')
    local mem_usage_pct=$(awk "BEGIN {printf \"%.1f\", ($mem_used/$mem_total)*100}")
    
    log_message "INFO" "Memory usage: $mem_used MB / $mem_total MB ($mem_usage_pct%)"
    
    # Check CPU load
    local cpu_load=$(uptime | awk -F'[a-z]:' '{print $2}' | awk -F',' '{print $1,$2,$3}')
    log_message "INFO" "CPU load averages: $cpu_load"
}

# ===============================================================================
# Main Function
# ===============================================================================

main() {
    log_message "INFO" "==== PulseChain Node Health Check Started ===="
    
    # Check if disk protection is active and if it can be deactivated
    check_disk_protection_status
    
    # Only proceed with other checks if disk protection is not active
    if [ ! -f "$DISK_PROTECTION_ACTIVE" ]; then
        check_disk_space
        check_docker_service
        check_containers_status
        check_client_sync
        check_system_resources
    else
        log_message "WARNING" "Disk protection mode is active. Health checks skipped."
        log_message "WARNING" "Free up disk space and restart the node containers."
        echo "Current disk protection status:"
        cat "$DISK_PROTECTION_ACTIVE"
    fi
    
    log_message "INFO" "==== Health Check Completed ===="
}

# Run the main function
main

exit 0 