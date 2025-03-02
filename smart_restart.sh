#!/bin/bash

# ===============================================================================
# PulseChain Node Smart Restart Script
# ===============================================================================
# This script provides intelligent container management with visual feedback
# Version: 0.1.0
# ===============================================================================

# Source global configuration
if [ -f "$(dirname "$0")/../config.sh" ]; then
    source "$(dirname "$0")/../config.sh"
else
    # Set defaults if config not found
    CUSTOM_PATH="/blockchain"
    EXECUTION_CONTAINER="execution"
    CONSENSUS_CONTAINER="beacon"
    LOG_PATH="$CUSTOM_PATH/logs"
fi

# Create log directory if it doesn't exist
mkdir -p "$LOG_PATH"

# Log file
RESTART_LOG="$LOG_PATH/restart.log"

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Log messages
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    # Log to file
    echo "[$timestamp] [$level] $message" >> "$RESTART_LOG"
    
    # Format for console output
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
        "SUCCESS")
            echo -e "${PURPLE}[$level]${NC} $message"
            ;;
        *)
            echo "[$level] $message"
            ;;
    esac
}

# Display progress bar
show_progress() {
    local duration=$1
    local size=40
    local remaining=$duration
    local start_time=$(date +%s)
    local end_time=$((start_time + duration))
    local container=$2
    local operation=$3
    
    # Initial status check
    local status="running"
    if [[ "$operation" == "stopping" ]]; then
        if ! sudo docker ps | grep -q "$container"; then
            status="stopped"
            log_message "INFO" "$container is already stopped."
            return 0
        fi
    fi
    
    echo ""
    log_message "ACTION" "⏱️ $operation $container (timeout: ${duration}s)"
    echo -e "${YELLOW}Press Ctrl+C to hide progress bar (container will continue in background)${NC}"
    echo ""
    
    while [ $remaining -gt 0 ] && [ "$status" == "running" ]; do
        # Calculate progress
        local elapsed=$((duration - remaining))
        local percent=$((elapsed * 100 / duration))
        local filled=$((elapsed * size / duration))
        local empty=$((size - filled))
        
        # Build the progress bar
        bar="["
        for ((i=0; i<filled; i++)); do
            bar+="█"
        done
        for ((i=0; i<empty; i++)); do
            bar+="░"
        done
        bar+="] ${percent}%"
        
        # Check container status
        if [[ "$operation" == "stopping" ]] && ! sudo docker ps | grep -q "$container"; then
            status="stopped"
        fi
        
        # Display the progress bar and time remaining
        printf "\r%-80s" "$bar - $remaining seconds remaining"
        
        # Early completion message
        if [ "$status" != "running" ]; then
            printf "\r%-80s\n" "$bar - Completed early! Container is now $status"
            log_message "SUCCESS" "$container $operation completed successfully (early completion)"
            break
        fi
        
        # Wait 1 second
        sleep 1
        remaining=$((end_time - $(date +%s)))
        if [ $remaining -lt 0 ]; then
            remaining=0
        fi
    done
    
    # Final status check if we timed out
    if [ "$status" == "running" ] && [ "$operation" == "stopping" ]; then
        if ! sudo docker ps | grep -q "$container"; then
            status="stopped"
        else
            status="still running"
        fi
    fi
    
    # Final message
    if [ "$status" == "stopped" ] || [ "$operation" != "stopping" ]; then
        printf "\r%-80s\n" "[$(printf '█%.0s' $(seq 1 $size))] 100% - Complete!"
        log_message "SUCCESS" "$container $operation completed successfully"
    else
        printf "\r%-80s\n" "[$(printf '█%.0s' $(seq 1 $filled))$(printf '░%.0s' $(seq 1 $empty))] TIMEOUT"
        log_message "WARNING" "$container $operation timed out, container is $status"
    fi
    
    echo ""
    return 0
}

# Check if a container exists
check_container_exists() {
    local container="$1"
    if sudo docker ps -a | grep -q "$container"; then
        return 0
    else
        return 1
    fi
}

# Check if a container is running
check_container_running() {
    local container="$1"
    if sudo docker ps | grep -q "$container"; then
        return 0
    else
        return 1
    fi
}

# Stop a container with visual feedback
smart_stop_container() {
    local container="$1"
    local timeout="$2"
    
    # Check if container exists
    if ! check_container_exists "$container"; then
        log_message "INFO" "$container does not exist, no need to stop"
        return 0
    fi
    
    # Check if container is already stopped
    if ! check_container_running "$container"; then
        log_message "INFO" "$container is already stopped"
        return 0
    fi
    
    # Stop the container
    log_message "ACTION" "Stopping $container with ${timeout}s timeout"
    
    # Run the docker stop command in the background
    sudo docker stop -t "$timeout" "$container" &
    local docker_pid=$!
    
    # Show progress while the container is stopping
    show_progress "$timeout" "$container" "stopping"
    
    # Check the status after stopping
    if check_container_running "$container"; then
        log_message "ERROR" "$container failed to stop gracefully within timeout"
        read -p "Force stop container? (y/N): " force_stop
        if [[ "$force_stop" =~ ^[Yy]$ ]]; then
            log_message "WARNING" "Force stopping $container"
            sudo docker kill "$container"
            if ! check_container_running "$container"; then
                log_message "SUCCESS" "$container force stopped successfully"
            else
                log_message "ERROR" "Failed to force stop $container"
                return 1
            fi
        else
            log_message "WARNING" "Container $container left running as requested"
            return 1
        fi
    else
        log_message "SUCCESS" "$container stopped successfully"
    fi
    
    return 0
}

# Start a container with visual feedback
smart_start_container() {
    local container="$1"
    local start_script="$2"
    local startup_time="$3"
    
    # Check if container is already running
    if check_container_running "$container"; then
        log_message "INFO" "$container is already running"
        return 0
    fi
    
    # Start the container
    log_message "ACTION" "Starting $container using $start_script"
    
    # Run the start script
    bash "$start_script" &
    local start_pid=$!
    
    # Allow some time for container to initialize
    sleep 3
    
    # Check if container started
    if check_container_running "$container"; then
        log_message "SUCCESS" "$container started successfully"
        
        # Show startup progress for monitoring
        show_progress "$startup_time" "$container" "starting"
        
        # Final status check
        if check_container_running "$container"; then
            log_message "SUCCESS" "$container is running normally"
            return 0
        else
            log_message "ERROR" "$container stopped unexpectedly after starting"
            return 1
        fi
    else
        log_message "ERROR" "Failed to start $container"
        return 1
    fi
}

# Restart a specific container
restart_container() {
    local container="$1"
    local start_script="$2"
    local stop_timeout="$3"
    local startup_monitor_time="$4"
    
    # Display header
    echo ""
    echo "========================================================"
    echo "   Smart Restart: $container"
    echo "========================================================"
    echo ""
    
    # Warn about risks
    log_message "WARNING" "⚠️ Restarting $container may cause temporary service interruption"
    echo ""
    
    # Stop the container
    if ! smart_stop_container "$container" "$stop_timeout"; then
        log_message "ERROR" "Failed to properly stop $container"
        read -p "Continue with start attempt anyway? (y/N): " continue_anyway
        if ! [[ "$continue_anyway" =~ ^[Yy]$ ]]; then
            log_message "INFO" "Restart abandoned at user request"
            return 1
        fi
    fi
    
    # Give a small pause between stop and start
    sleep 2
    
    # Start the container
    if ! smart_start_container "$container" "$start_script" "$startup_monitor_time"; then
        log_message "ERROR" "Failed to start $container"
        echo ""
        log_message "ACTION" "Please check logs for errors: sudo docker logs $container"
        return 1
    fi
    
    log_message "SUCCESS" "✅ $container has been successfully restarted"
    return 0
}

# Restart all containers
restart_all() {
    echo ""
    echo "========================================================"
    echo "   Smart Restart: All Node Containers"
    echo "========================================================"
    echo ""
    
    # Warn about risks
    log_message "WARNING" "⚠️ This will restart all node components"
    log_message "WARNING" "⚠️ Your node will be temporarily offline during this process"
    echo ""
    
    # Confirmation
    read -p "Are you sure you want to restart all containers? (y/N): " confirm
    if ! [[ "$confirm" =~ ^[Yy]$ ]]; then
        log_message "INFO" "Restart cancelled by user"
        return 0
    fi
    
    echo ""
    log_message "ACTION" "Beginning restart sequence"
    echo ""
    
    # Stop containers in reverse order
    log_message "INFO" "Phase 1: Stopping containers in safe order"
    smart_stop_container "$CONSENSUS_CONTAINER" 180
    smart_stop_container "$EXECUTION_CONTAINER" 300
    
    # Brief pause
    sleep 3
    
    # Start containers in correct order
    log_message "INFO" "Phase 2: Starting containers in proper order"
    smart_start_container "$EXECUTION_CONTAINER" "$CUSTOM_PATH/start_execution.sh" 30
    
    # Give the execution client time to initialize before starting consensus
    sleep 10
    
    smart_start_container "$CONSENSUS_CONTAINER" "$CUSTOM_PATH/start_consensus.sh" 30
    
    # Final status
    echo ""
    log_message "INFO" "Checking final status of all containers:"
    
    if check_container_running "$EXECUTION_CONTAINER"; then
        log_message "SUCCESS" "✅ $EXECUTION_CONTAINER is running"
    else
        log_message "ERROR" "❌ $EXECUTION_CONTAINER is not running"
    fi
    
    if check_container_running "$CONSENSUS_CONTAINER"; then
        log_message "SUCCESS" "✅ $CONSENSUS_CONTAINER is running"
    else
        log_message "ERROR" "❌ $CONSENSUS_CONTAINER is not running"
    fi
    
    echo ""
    log_message "ACTION" "It may take some time for clients to fully synchronize again"
    log_message "ACTION" "Check health status in a few minutes: bash $CUSTOM_PATH/helper/health_check.sh"
    
    return 0
}

# Main menu
main_menu() {
    echo ""
    echo "========================================================"
    echo "   PulseChain Node Smart Restart Tool"
    echo "========================================================"
    echo ""
    echo "Please select an option:"
    echo ""
    echo "  1) Restart execution client ($EXECUTION_CONTAINER)"
    echo "  2) Restart consensus client ($CONSENSUS_CONTAINER)"
    echo "  3) Restart all containers"
    echo "  4) Exit"
    echo ""
    
    read -p "Enter your choice (1-4): " choice
    
    case $choice in
        1)
            restart_container "$EXECUTION_CONTAINER" "$CUSTOM_PATH/start_execution.sh" 300 30
            ;;
        2)
            restart_container "$CONSENSUS_CONTAINER" "$CUSTOM_PATH/start_consensus.sh" 180 30
            ;;
        3)
            restart_all
            ;;
        4)
            echo "Exiting."
            return 0
            ;;
        *)
            echo "Invalid option. Please try again."
            main_menu
            ;;
    esac
    
    return 0
}

# Check if this script is being run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # If arguments are provided, handle them
    if [[ $# -gt 0 ]]; then
        case "$1" in
            --restart-execution)
                restart_container "$EXECUTION_CONTAINER" "$CUSTOM_PATH/start_execution.sh" 300 30
                ;;
            --restart-consensus)
                restart_container "$CONSENSUS_CONTAINER" "$CUSTOM_PATH/start_consensus.sh" 180 30
                ;;
            --restart-all)
                restart_all
                ;;
            *)
                echo "Unknown argument: $1"
                echo "Usage: $0 [--restart-execution|--restart-consensus|--restart-all]"
                exit 1
                ;;
        esac
    else
        # No arguments, show menu
        main_menu
    fi
fi 