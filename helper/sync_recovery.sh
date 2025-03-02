#!/bin/bash

# ===============================================================================
# PulseChain Node Sync Recovery Script
# ===============================================================================
# This script provides enhanced error detection and recovery for blockchain sync issues
# Version: 0.1.0
# ===============================================================================

# Source global configuration if it exists
if [ -f "$(dirname "$(dirname "$0")")/config.sh" ]; then
    source "$(dirname "$(dirname "$0")")/config.sh"
else
    # Set defaults if config not found
    CUSTOM_PATH="/blockchain"
    HELPER_PATH="$CUSTOM_PATH/helper"
    LOG_PATH="$CUSTOM_PATH/logs"
    EXECUTION_CONTAINER="execution"
    CONSENSUS_CONTAINER="beacon"
fi

# Create log directory if it doesn't exist
mkdir -p "$LOG_PATH"

# Log file path
SYNC_LOG="$LOG_PATH/sync_recovery.log"

# Status tracking file
SYNC_STATUS_FILE="$LOG_PATH/sync_status.json"

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ===============================================================================
# Helper Functions
# ===============================================================================

# Function to log messages with timestamps
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    # Log to file
    echo "[$timestamp] [$level] $message" >> "$SYNC_LOG"
    
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
        "ACTION")
            echo -e "${BLUE}[$level]${NC} $message"
            ;;
        *)
            echo "[$level] $message"
            ;;
    esac
}

# Convert epoch to timestamp
epoch_to_time() {
    expr 1683785555 + \( $1 \* 320 \)
}

# Update sync status file
update_sync_status() {
    local execution_syncing="$1"
    local consensus_syncing="$2"
    local finalized_epoch="$3"
    local current_epoch="$4"
    local sync_gap="$5"
    local status="$6"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    cat > "$SYNC_STATUS_FILE" << EOL
{
  "timestamp": "$timestamp",
  "execution_syncing": $execution_syncing,
  "consensus_syncing": $consensus_syncing,
  "finalized_epoch": $finalized_epoch,
  "current_epoch": $current_epoch,
  "sync_gap": $sync_gap,
  "status": "$status",
  "last_recovery_attempt": "$(grep "last_recovery_attempt" "$SYNC_STATUS_FILE" 2>/dev/null | cut -d'"' -f4 || echo "never")"
}
EOL
}

# Record recovery attempt
record_recovery_attempt() {
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local current_data=$(cat "$SYNC_STATUS_FILE" 2>/dev/null)
    
    if [ -n "$current_data" ]; then
        # Update the existing file
        sed -i "s/\"last_recovery_attempt\": \"[^\"]*\"/\"last_recovery_attempt\": \"$timestamp\"/g" "$SYNC_STATUS_FILE"
    else
        # Create a new file with minimal info
        cat > "$SYNC_STATUS_FILE" << EOL
{
  "timestamp": "$timestamp",
  "execution_syncing": null,
  "consensus_syncing": null,
  "finalized_epoch": null,
  "current_epoch": null,
  "sync_gap": null,
  "status": "unknown",
  "last_recovery_attempt": "$timestamp"
}
EOL
    fi
}

# Check if a recovery was attempted recently (within the last hour)
recent_recovery_attempt() {
    local last_attempt=$(grep "last_recovery_attempt" "$SYNC_STATUS_FILE" 2>/dev/null | cut -d'"' -f4)
    
    if [ "$last_attempt" = "never" ] || [ -z "$last_attempt" ]; then
        return 1  # No recent attempt
    fi
    
    local last_timestamp=$(date -d "$last_attempt" +%s)
    local current_timestamp=$(date +%s)
    local time_diff=$((current_timestamp - last_timestamp))
    
    if [ $time_diff -lt 3600 ]; then  # Less than 1 hour
        return 0  # Recent attempt
    else
        return 1  # No recent attempt
    fi
}

# Get beacon client port based on client type
get_beacon_port() {
    if docker logs $CONSENSUS_CONTAINER 2>&1 | grep -q "Lighthouse"; then
        echo "5052"  # Lighthouse API port
    elif docker logs $CONSENSUS_CONTAINER 2>&1 | grep -q "Prysm"; then
        echo "3500"  # Prysm API port
    else
        echo "5052"  # Default to Lighthouse port
    fi
}

# ===============================================================================
# Diagnosis Functions
# ===============================================================================

# Check execution client sync status
check_execution_sync() {
    log_message "INFO" "Checking execution client sync status..."
    
    if ! docker ps | grep -q "$EXECUTION_CONTAINER"; then
        log_message "ERROR" "Execution client container is not running"
        return 2  # Error
    fi
    
    # Check if the execution API is responding
    local response=$(curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
        http://localhost:8545)
    
    if [ -z "$response" ]; then
        log_message "ERROR" "Execution client API not responding"
        return 2  # Error
    fi
    
    local sync_status=$(echo $response | jq -r '.result')
    
    if [ "$sync_status" = "false" ]; then
        log_message "INFO" "Execution client is fully synced"
        return 0  # Synced
    else
        # Get detailed sync info
        local current_block=$(echo $response | jq -r '.result.currentBlock')
        local highest_block=$(echo $response | jq -r '.result.highestBlock')
        
        if [ "$current_block" != "null" ] && [ "$highest_block" != "null" ]; then
            local blocks_behind=$((highest_block - current_block))
            log_message "INFO" "Execution client is syncing - $blocks_behind blocks behind (current: $current_block, highest: $highest_block)"
        else
            log_message "INFO" "Execution client is syncing - detailed status not available"
        fi
        
        return 1  # Syncing
    fi
}

# Check consensus client sync status
check_consensus_sync() {
    log_message "INFO" "Checking consensus client sync status..."
    
    if ! docker ps | grep -q "$CONSENSUS_CONTAINER"; then
        log_message "ERROR" "Consensus client container is not running"
        return 2  # Error
    fi
    
    local beacon_port=$(get_beacon_port)
    local beacon_node="http://localhost:$beacon_port"
    
    # Check if finalized checkpoint is accessible
    local finalized_data=$(curl -s -X GET "$beacon_node/eth/v1/beacon/states/finalized/finality_checkpoints")
    local finalized_epoch=$(echo $finalized_data | jq -r '.data.finalized.epoch')
    
    if [ -z "$finalized_epoch" ] || [ "$finalized_epoch" = "null" ]; then
        log_message "ERROR" "Unable to get finalized epoch from beacon node"
        return 2  # Error
    fi
    
    # Get current head
    local head_data=$(curl -s -X GET "$beacon_node/eth/v1/beacon/headers/head")
    local current_slot=$(echo $head_data | jq -r '.data.header.message.slot')
    
    if [ -z "$current_slot" ] || [ "$current_slot" = "null" ]; then
        log_message "ERROR" "Unable to get current slot from beacon node"
        return 2  # Error
    fi
    
    local current_epoch=$((current_slot / 32))
    local sync_gap=$((current_epoch - finalized_epoch))
    
    log_message "INFO" "Finalized epoch: $finalized_epoch, Current epoch: $current_epoch, Gap: $sync_gap"
    
    # Update sync status file
    local execution_syncing=$(check_execution_sync > /dev/null && echo "false" || echo "true")
    update_sync_status "$execution_syncing" "$([ $sync_gap -le 2 ] && echo "false" || echo "true")" \
        "$finalized_epoch" "$current_epoch" "$sync_gap" "$([ $sync_gap -le 2 ] && echo "synced" || echo "syncing")"
    
    if [ $sync_gap -le 2 ]; then
        log_message "INFO" "Consensus client is fully synced (normal gap between finality and head)"
        return 0  # Synced
    else
        log_message "WARNING" "Consensus client is $sync_gap epochs behind finality"
        return 1  # Syncing
    fi
}

# ===============================================================================
# Recovery Functions
# ===============================================================================

# Safe restart of execution client
restart_execution_client() {
    log_message "ACTION" "Attempting to safely restart execution client..."
    
    # Record the recovery attempt
    record_recovery_attempt
    
    # Stop the container with an extended timeout
    log_message "INFO" "Stopping execution client with 5-minute timeout..."
    sudo docker stop -t 300 $EXECUTION_CONTAINER
    
    # Wait a moment to ensure clean shutdown
    sleep 10
    
    # Start the client using the standard script
    log_message "INFO" "Starting execution client..."
    if [ -f "$CUSTOM_PATH/start_execution.sh" ]; then
        sudo bash "$CUSTOM_PATH/start_execution.sh"
        
        # Wait for it to initialize
        log_message "INFO" "Waiting for execution client to initialize..."
        sleep 30
        
        if docker ps | grep -q "$EXECUTION_CONTAINER"; then
            log_message "INFO" "Execution client restarted successfully"
            return 0
        else
            log_message "ERROR" "Failed to restart execution client"
            return 1
        fi
    else
        log_message "ERROR" "Start script not found at $CUSTOM_PATH/start_execution.sh"
        return 1
    fi
}

# Safe restart of consensus client
restart_consensus_client() {
    log_message "ACTION" "Attempting to safely restart consensus client..."
    
    # Record the recovery attempt
    record_recovery_attempt
    
    # Stop the container with an extended timeout
    log_message "INFO" "Stopping consensus client with 3-minute timeout..."
    sudo docker stop -t 180 $CONSENSUS_CONTAINER
    
    # Wait a moment to ensure clean shutdown
    sleep 10
    
    # Start the client using the standard script
    log_message "INFO" "Starting consensus client..."
    if [ -f "$CUSTOM_PATH/start_consensus.sh" ]; then
        sudo bash "$CUSTOM_PATH/start_consensus.sh"
        
        # Wait for it to initialize
        log_message "INFO" "Waiting for consensus client to initialize..."
        sleep 30
        
        if docker ps | grep -q "$CONSENSUS_CONTAINER"; then
            log_message "INFO" "Consensus client restarted successfully"
            return 0
        else
            log_message "ERROR" "Failed to restart consensus client"
            return 1
        fi
    else
        log_message "ERROR" "Start script not found at $CUSTOM_PATH/start_consensus.sh"
        return 1
    fi
}

# Check for and clear corrupt or problematic database files
check_database_integrity() {
    local client_type="$1"
    log_message "ACTION" "Checking $client_type database integrity..."
    
    case "$client_type" in
        "execution")
            # Check if execution client is Geth or Erigon
            if docker logs $EXECUTION_CONTAINER 2>&1 | grep -q "Geth"; then
                log_message "INFO" "Detected Geth execution client"
                
                # Check for known error patterns in logs
                if docker logs $EXECUTION_CONTAINER 2>&1 | grep -q "leveldb: corruption"; then
                    log_message "WARNING" "Detected database corruption in Geth"
                    return 1  # Indicates corruption
                fi
                
                if docker logs $EXECUTION_CONTAINER 2>&1 | grep -q "Fatal: Failed to register the Ethereum service"; then
                    log_message "WARNING" "Detected fatal Ethereum service error in Geth"
                    return 1  # Indicates corruption
                fi
                
            elif docker logs $EXECUTION_CONTAINER 2>&1 | grep -q "Erigon"; then
                log_message "INFO" "Detected Erigon execution client"
                
                # Check for known error patterns in logs
                if docker logs $EXECUTION_CONTAINER 2>&1 | grep -q "Error: failed to repair database"; then
                    log_message "WARNING" "Detected database corruption in Erigon"
                    return 1  # Indicates corruption
                fi
            fi
            ;;
            
        "consensus")
            # Check if consensus client is Lighthouse or Prysm
            if docker logs $CONSENSUS_CONTAINER 2>&1 | grep -q "Lighthouse"; then
                log_message "INFO" "Detected Lighthouse consensus client"
                
                # Check for known error patterns in logs
                if docker logs $CONSENSUS_CONTAINER 2>&1 | grep -q "Database error"; then
                    log_message "WARNING" "Detected database error in Lighthouse"
                    return 1  # Indicates corruption
                fi
                
            elif docker logs $CONSENSUS_CONTAINER 2>&1 | grep -q "Prysm"; then
                log_message "INFO" "Detected Prysm consensus client"
                
                # Check for known error patterns in logs
                if docker logs $CONSENSUS_CONTAINER 2>&1 | grep -q "could not get or create bolt bucket"; then
                    log_message "WARNING" "Detected database error in Prysm"
                    return 1  # Indicates corruption
                fi
            fi
            ;;
    esac
    
    return 0  # No corruption detected
}

# ===============================================================================
# Main Recovery Logic
# ===============================================================================

# Main function for sync recovery
recover_sync() {
    log_message "INFO" "Starting sync recovery process..."
    
    # Check if recovery was attempted recently
    if recent_recovery_attempt; then
        log_message "WARNING" "Recovery was attempted within the last hour, skipping to prevent recovery loops"
        return 1
    fi
    
    # First diagnose the issue
    local execution_status=$(check_execution_sync; echo $?)
    local consensus_status=$(check_consensus_sync; echo $?)
    
    log_message "INFO" "Diagnosis complete: Execution status=$execution_status, Consensus status=$consensus_status"
    
    if [ $execution_status -eq 0 ] && [ $consensus_status -eq 0 ]; then
        log_message "INFO" "Both clients are synced correctly, no recovery needed"
        return 0
    fi
    
    # Check for database corruption before attempting restart
    if [ $execution_status -eq 2 ]; then
        if ! check_database_integrity "execution"; then
            log_message "ERROR" "Execution client database corruption detected"
            log_message "ACTION" "Please run a database repair or consider resetting the node for a clean sync"
            return 2
        fi
    fi
    
    if [ $consensus_status -eq 2 ]; then
        if ! check_database_integrity "consensus"; then
            log_message "ERROR" "Consensus client database corruption detected"
            log_message "ACTION" "Please run a database repair or consider resetting the node for a clean sync"
            return 2
        fi
    fi
    
    # Recovery strategy based on diagnosis
    if [ $execution_status -eq 2 ]; then
        log_message "WARNING" "Execution client has critical errors, attempting recovery..."
        if ! restart_execution_client; then
            log_message "ERROR" "Failed to recover execution client"
            return 2
        fi
    elif [ $execution_status -eq 1 ]; then
        log_message "INFO" "Execution client is still syncing, monitoring..."
    fi
    
    if [ $consensus_status -eq 2 ]; then
        log_message "WARNING" "Consensus client has critical errors, attempting recovery..."
        if ! restart_consensus_client; then
            log_message "ERROR" "Failed to recover consensus client"
            return 2
        fi
    elif [ $consensus_status -eq 1 ]; then
        log_message "INFO" "Consensus client is still syncing, monitoring..."
    fi
    
    # Re-check after recovery attempts
    local execution_status_after=$(check_execution_sync; echo $?)
    local consensus_status_after=$(check_consensus_sync; echo $?)
    
    log_message "INFO" "Post-recovery status: Execution=$execution_status_after, Consensus=$consensus_status_after"
    
    if [ $execution_status_after -eq 2 ] || [ $consensus_status_after -eq 2 ]; then
        log_message "ERROR" "Recovery was unsuccessful, manual intervention may be required"
        return 2
    else
        log_message "SUCCESS" "Recovery process completed successfully"
        return 0
    fi
}

# ===============================================================================
# Script Execution
# ===============================================================================

# Display header
echo "================================================================="
echo "PulseChain Node Sync Recovery Tool"
echo "Version: 0.1.0"
echo "================================================================="
echo ""

# Process command line arguments
MODE="check"
if [ $# -gt 0 ]; then
    case "$1" in
        "--recover")
            MODE="recover"
            ;;
        "--monitor")
            MODE="monitor"
            ;;
        "--help")
            echo "Usage: $0 [--recover|--monitor|--help]"
            echo ""
            echo "Options:"
            echo "  --recover    Run the recovery process for sync issues"
            echo "  --monitor    Run continuous monitoring and automatic recovery"
            echo "  --help       Display this help message"
            echo ""
            echo "Running without options will check sync status without recovery."
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
fi

# Run in the appropriate mode
case "$MODE" in
    "check")
        log_message "INFO" "Checking sync status only (no recovery)"
        check_execution_sync
        check_consensus_sync
        log_message "INFO" "Sync status check complete"
        echo ""
        echo "Sync status saved to: $SYNC_STATUS_FILE"
        ;;
        
    "recover")
        log_message "INFO" "Running recovery process"
        if recover_sync; then
            log_message "SUCCESS" "Recovery completed successfully"
        else
            log_message "WARNING" "Recovery process completed with warnings or errors"
            echo "Check the log file for details: $SYNC_LOG"
        fi
        ;;
        
    "monitor")
        log_message "INFO" "Starting continuous monitoring (press Ctrl+C to stop)"
        while true; do
            # Check sync status
            check_execution_sync > /dev/null
            check_consensus_sync > /dev/null
            
            # Read current status
            if [ -f "$SYNC_STATUS_FILE" ]; then
                local execution_syncing=$(grep "execution_syncing" "$SYNC_STATUS_FILE" | grep -o "true\|false")
                local consensus_syncing=$(grep "consensus_syncing" "$SYNC_STATUS_FILE" | grep -o "true\|false")
                local status=$(grep "status" "$SYNC_STATUS_FILE" | cut -d'"' -f4)
                
                echo -n "Status: "
                if [ "$status" = "synced" ]; then
                    echo -e "${GREEN}SYNCED${NC}"
                else
                    echo -e "${YELLOW}SYNCING${NC}"
                fi
                
                # Check for issues requiring recovery
                if [ "$execution_syncing" = "true" ] || [ "$consensus_syncing" = "true" ]; then
                    if ! check_execution_sync > /dev/null || ! check_consensus_sync > /dev/null; then
                        log_message "WARNING" "Sync issues detected, initiating recovery..."
                        recover_sync
                    fi
                fi
            fi
            
            # Sleep for 15 minutes before next check
            echo "Next check in 15 minutes. Press Ctrl+C to stop monitoring."
            sleep 900
        done
        ;;
esac

echo ""
echo "================================================================="
echo "Process complete. Check $SYNC_LOG for detailed information."
echo "=================================================================" 