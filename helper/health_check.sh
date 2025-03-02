#!/bin/bash

# ===============================================================================
# PulseChain Node Simple Health Check Script
# ===============================================================================
# This script performs basic health checks on the node and system
# Can be run manually or scheduled with cron
# ===============================================================================

# Source global configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODE_ROOT="$(dirname "$SCRIPT_DIR")"
source "$NODE_ROOT/config.sh"

# Set log file for health check
HEALTH_LOG="${LOG_PATH}/health_check.log"
mkdir -p "$(dirname "$HEALTH_LOG")"

# Make sure we have a timestamp in the logs
echo "===============================================================================" >> "$HEALTH_LOG"
echo "Health check started at $(date)" >> "$HEALTH_LOG"

# ===============================================================================
# Utility Functions
# ===============================================================================

# Simple logging function
log() {
    local level="$1"
    local message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$HEALTH_LOG"
    
    # Also print to console if running interactively
    if [[ -t 1 ]]; then
        if [[ "$level" == "ERROR" ]]; then
            echo -e "\033[0;31m[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message\033[0m"
        elif [[ "$level" == "WARNING" ]]; then
            echo -e "\033[0;33m[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message\033[0m"
        elif [[ "$level" == "SUCCESS" ]]; then
            echo -e "\033[0;32m[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message\033[0m"
        else
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message"
        fi
    fi
}

# Check if a container is running
is_container_running() {
    local container_name="$1"
    if sudo docker ps --format '{{.Names}}' | grep -q "^$container_name$"; then
        return 0
    else
        return 1
    fi
}

# Restart a container if it's not running
restart_container() {
    local container_name="$1"
    local start_script="$2"
    
    log "INFO" "Attempting to restart $container_name container..."
    
    # Check if container exists but is stopped
    if sudo docker ps -a --format '{{.Names}}' | grep -q "^$container_name$"; then
        log "INFO" "Container $container_name exists but is stopped, removing it..."
        sudo docker rm "$container_name"
    fi
    
    # Start the container
    if [[ -f "$start_script" ]]; then
        log "INFO" "Starting $container_name using $start_script"
        sudo bash "$start_script"
        sleep 10
        
        if is_container_running "$container_name"; then
            log "SUCCESS" "$container_name successfully restarted"
            return 0
        else
            log "ERROR" "Failed to restart $container_name"
            return 1
        fi
    else
        log "ERROR" "Start script $start_script not found"
        return 1
    fi
}

# ===============================================================================
# System Health Checks
# ===============================================================================

# Check disk space
check_disk_space() {
    log "INFO" "Checking disk space..."
    
    # Get disk usage percentage for the main partition
    local disk_usage=$(df -h "$CUSTOM_PATH" | grep -v Filesystem | awk '{print $5}' | tr -d '%')
    
    if [[ $disk_usage -ge $DISK_SPACE_THRESHOLD ]]; then
        log "WARNING" "Disk space critically low: ${disk_usage}% used (threshold: ${DISK_SPACE_THRESHOLD}%)"
        
        # Try to free up some space by pruning Docker resources
        log "INFO" "Attempting to free up space by pruning Docker resources..."
        sudo docker system prune -f
        
        # Re-check disk space after pruning
        disk_usage=$(df -h "$CUSTOM_PATH" | grep -v Filesystem | awk '{print $5}' | tr -d '%')
        log "INFO" "Disk usage after pruning: ${disk_usage}%"
    else
        log "INFO" "Disk space OK: ${disk_usage}% used"
    fi
}

# Check if Docker service is running
check_docker_service() {
    log "INFO" "Checking Docker service..."
    
    if systemctl is-active --quiet docker; then
        log "INFO" "Docker service is running"
    else
        log "ERROR" "Docker service is not running, attempting to start..."
        sudo systemctl start docker
        sleep 5
        
        if systemctl is-active --quiet docker; then
            log "SUCCESS" "Docker service successfully started"
        else
            log "ERROR" "Failed to start Docker service"
            return 1
        fi
    fi
    
    return 0
}

# ===============================================================================
# Node Health Checks
# ===============================================================================

# Check execution client
check_execution_client() {
    log "INFO" "Checking execution client (${EXECUTION_CONTAINER})..."
    
    if is_container_running "$EXECUTION_CONTAINER"; then
        log "INFO" "Execution client is running"
        
        # Optional: Check if the execution client is responding
        if curl -s -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"net_version","params":[],"id":1}' http://localhost:8545 | grep -q result; then
            log "INFO" "Execution client RPC is responding"
        else
            log "WARNING" "Execution client RPC is not responding, may need a restart"
            return 1
        fi
    else
        log "ERROR" "Execution client is not running"
        restart_container "$EXECUTION_CONTAINER" "$CUSTOM_PATH/start_execution.sh"
        return $?
    fi
    
    return 0
}

# Check consensus client
check_consensus_client() {
    log "INFO" "Checking consensus client (${CONSENSUS_CONTAINER})..."
    
    if is_container_running "$CONSENSUS_CONTAINER"; then
        log "INFO" "Consensus client is running"
        
        # For now, just check if it's running
        # Could add more sophisticated checks later
    else
        log "ERROR" "Consensus client is not running"
        restart_container "$CONSENSUS_CONTAINER" "$CUSTOM_PATH/start_consensus.sh"
        return $?
    fi
    
    return 0
}

# Check sync status
check_sync_status() {
    log "INFO" "Checking node sync status..."
    
    # Get current block height from the node
    local current_block=$(curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
        http://localhost:8545 | grep -oP '(?<="result":")0x[^"]+' | tr -d '0x' | xargs printf "%d" 2>/dev/null)
    
    if [[ -z "$current_block" ]]; then
        log "WARNING" "Couldn't get current block height"
        return 1
    fi
    
    log "INFO" "Current block height: $current_block"
    
    # Store the block height for trend analysis
    echo "$(date '+%Y-%m-%d %H:%M:%S'),$current_block" >> "${LOG_PATH}/block_height.csv"
    
    return 0
}

# ===============================================================================
# Main Health Check Routine
# ===============================================================================

# Run all checks
run_health_check() {
    local exit_code=0
    
    # System checks
    check_disk_space || exit_code=$((exit_code + 1))
    check_docker_service || exit_code=$((exit_code + 2))
    
    # Node checks
    check_execution_client || exit_code=$((exit_code + 4))
    check_consensus_client || exit_code=$((exit_code + 8))
    check_sync_status || exit_code=$((exit_code + 16))
    
    # Log result
    if [[ $exit_code -eq 0 ]]; then
        log "SUCCESS" "All health checks passed successfully"
    else
        log "WARNING" "Some health checks failed (exit code: $exit_code)"
    fi
    
    return $exit_code
}

# ===============================================================================
# Script Execution
# ===============================================================================

# Check if this script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Check if help is requested
    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        echo "PulseChain Node Health Check"
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  --cron, -c    Run in cron mode (no console output)"
        echo "  --help, -h    Show this help message"
        echo ""
        echo "When run with no options, health check results will be output to both"
        echo "the console and log file. In cron mode, output goes only to the log file."
        exit 0
    fi
    
    # Create log directory if it doesn't exist
    mkdir -p "$LOG_PATH"
    
    # Run health check
    run_health_check
    exit_code=$?
    
    # Print final status
    if [[ $exit_code -eq 0 ]]; then
        echo "Health check completed successfully."
    else
        echo "Health check completed with warnings or errors. Check the log file at:"
        echo "$HEALTH_LOG"
    fi
    
    exit $exit_code
fi 