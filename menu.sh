#!/bin/bash

# ===============================================================================
# PulseChain Node Management Menu System
# ===============================================================================
# Version 0.1.0
# This menu system provides a user-friendly interface to manage a PulseChain node
# ===============================================================================

# Source global configuration if it exists
if [ -f "$(dirname "$0")/config.sh" ]; then
    source "$(dirname "$0")/config.sh"
else
    echo "Configuration file not found. Some features may not work correctly."
    # Set some default values
    CUSTOM_PATH="/blockchain"
    HELPER_PATH="$CUSTOM_PATH/helper"
    LOG_PATH="$CUSTOM_PATH/logs"
    EXECUTION_CONTAINER="execution-client"
    CONSENSUS_CONTAINER="consensus-client"
fi

VERSION="0.1.0"
    
# Handle Ctrl+C gracefully
trap cleanup SIGINT

function cleanup() {
    clear
    echo "Exiting menu system..."
    exit
}

# Function to pause and wait for user input
pause() {
    echo ""
    read -p "Press Enter to continue..." dummy
}

# Function to display a header for each section
show_header() {
    clear
    echo -e "\033[1;36m========================================\033[0m"
    echo -e "\033[1;36m    PulseChain Node Management - $1    \033[0m"
    echo -e "\033[1;36m========================================\033[0m"
    echo ""
}

# ===============================================================================
# Main Menu
# ===============================================================================

main_menu() {
    while true; do
        main_opt=$(dialog --stdout --title "PulseChain Node Menu $VERSION" --backtitle "PulseChain Node Management" --menu "Choose an option:" 0 0 0 \
                          "Logviewer" "View logs from various components" \
                          "Clients Menu" "Manage execution and consensus clients" \
                          "Health" "Run health checks and monitoring" \
                          "Info and Management" "View node information and status" \
                          "System" "System maintenance and updates" \
                          "exit" "Exit the menu system")

        case $? in
          0)
            case $main_opt in
                "Logviewer")
                    logviewer_submenu
                    ;;
                "Clients Menu")
                    client_actions_submenu
                    ;;
                "Health")
                    health_submenu
                    ;;
                "Info and Management")
                    node_info_submenu
                    ;;
                "System")
                    system_submenu
                    ;;
                "exit")
                    clear
                    echo "Thank you for using PulseChain Node Management System!"
                    break
                    ;;
            esac
            ;;
          1)
            clear
            echo "Thank you for using PulseChain Node Management System!"
            break
            ;;
        esac
    done
}

# ===============================================================================
# Log Viewer Submenu
# ===============================================================================

logviewer_submenu() {
    while true; do
        log_opt=$(dialog --stdout --title "Log Viewer Menu $VERSION" --backtitle "PulseChain Node Management" --menu "Which logs would you like to view?" 0 0 0 \
                      "Execution Client" "View execution client logs ($EXECUTION_CONTAINER)" \
                      "Consensus Client" "View consensus client logs ($CONSENSUS_CONTAINER)" \
                      "Health Logs" "View health check logs" \
                      "System Logs" "View system journal logs" \
                      "Docker Events" "View Docker events log" \
                      "BACK" "Return to the Main Menu")

        case $? in
          0)
            case $log_opt in
                "Execution Client")
                    show_header "Execution Client Logs"
                    echo "Showing most recent logs for $EXECUTION_CONTAINER container..."
                    echo "Press Ctrl+C to exit log view."
                    sudo docker logs --tail=100 -f $EXECUTION_CONTAINER
                    pause
                    ;;
                "Consensus Client")
                    show_header "Consensus Client Logs"
                    echo "Showing most recent logs for $CONSENSUS_CONTAINER container..."
                    echo "Press Ctrl+C to exit log view."
                    sudo docker logs --tail=100 -f $CONSENSUS_CONTAINER
                    pause
                    ;;
                "Health Logs")
                    show_header "Health Check Logs"
                    echo "Showing health check logs..."
                    if [ -f "$LOG_PATH/health_check.log" ]; then
                        less "$LOG_PATH/health_check.log"
                    else
                        echo "Health check log file not found."
                        pause
                    fi
                    ;;
                "System Logs")
                    show_header "System Journal Logs"
                    echo "Showing recent system journal entries..."
                    sudo journalctl -n 100
                    pause
                    ;;
                "Docker Events")
                    show_header "Docker Events"
                    echo "Showing recent Docker events (press Ctrl+C to exit)..."
                    sudo docker events --since 30m
                    pause
                    ;;
                "BACK")
                    break
                    ;;
            esac
            ;;
          1)
            break
            ;;
        esac
    done
}

# ===============================================================================
# Client Actions Submenu
# ===============================================================================

client_actions_submenu() {
    while true; do
        client_opt=$(dialog --stdout --title "Clients Menu $VERSION" --backtitle "PulseChain Node Management" --menu "Manage node clients:" 0 0 0 \
                        "Restart Execution" "Restart execution client with visual feedback" \
                        "Restart Consensus" "Restart consensus client with visual feedback" \
                        "Restart All" "Restart both execution and consensus clients" \
                        "View Execution Logs" "Show logs from execution client" \
                        "View Consensus Logs" "Show logs from consensus client" \
                        "Check Sync Status" "View current blockchain synchronization status" \
                        "BACK" "Return to the Main Menu")
        
        case $? in
          0)
            case $client_opt in
                "Restart Execution")
                    show_header "Restart Execution Client"
                    echo "Using smart restart with visual feedback..."
                    if [ -f "$HELPER_PATH/smart_restart.sh" ]; then
                        bash "$HELPER_PATH/smart_restart.sh" --restart-execution
                    else
                        echo "Smart restart script not found. Falling back to standard restart."
                        echo "Restarting execution client ($EXECUTION_CONTAINER)..."
                        sudo docker restart $EXECUTION_CONTAINER
                        echo "Execution client restarted. Waiting a moment to stabilize..."
                        sleep 5
                        if sudo docker ps | grep -q "$EXECUTION_CONTAINER"; then
                            echo "Execution client is running."
                        else
                            echo "Warning: Execution client is not running after restart."
                            echo "Try starting it manually: sudo $CUSTOM_PATH/start_execution.sh"
                        fi
                    fi
                    pause
                    ;;
                "Restart Consensus")
                    show_header "Restart Consensus Client"
                    echo "Using smart restart with visual feedback..."
                    if [ -f "$HELPER_PATH/smart_restart.sh" ]; then
                        bash "$HELPER_PATH/smart_restart.sh" --restart-consensus
                    else
                        echo "Smart restart script not found. Falling back to standard restart."
                        echo "Restarting consensus client ($CONSENSUS_CONTAINER)..."
                        sudo docker restart $CONSENSUS_CONTAINER
                        echo "Consensus client restarted. Waiting a moment to stabilize..."
                        sleep 5
                        if sudo docker ps | grep -q "$CONSENSUS_CONTAINER"; then
                            echo "Consensus client is running."
                        else
                            echo "Warning: Consensus client is not running after restart."
                            echo "Try starting it manually: sudo $CUSTOM_PATH/start_consensus.sh"
                        fi
                    fi
                    pause
                    ;;
                "Restart All")
                    show_header "Restart All Clients"
                    echo "This will restart BOTH execution and consensus clients."
                    echo "The node will be temporarily offline during restart."
                    read -p "Are you sure you want to continue? (y/N): " confirm
                    if [[ "$confirm" =~ ^[Yy]$ ]]; then
                        if [ -f "$HELPER_PATH/smart_restart.sh" ]; then
                            echo "Using smart restart with visual feedback..."
                            bash "$HELPER_PATH/smart_restart.sh" --restart-all
                        else
                            echo "Smart restart script not found. Falling back to standard restart."
                            echo "Running restart script..."
                            bash "$HELPER_PATH/restart_docker.sh"
                            echo "All clients have been restarted."
                        fi
                    else
                        echo "Restart cancelled."
                    fi
                    pause
                    ;;
                "View Execution Logs")
                    show_header "Execution Client Logs"
                    echo "Showing most recent logs for $EXECUTION_CONTAINER container..."
                    echo "Press Ctrl+C to exit log view."
                    sudo docker logs --tail=100 -f $EXECUTION_CONTAINER
                    pause
                    ;;
                "View Consensus Logs")
                    show_header "Consensus Client Logs"
                    echo "Showing most recent logs for $CONSENSUS_CONTAINER container..."
                    echo "Press Ctrl+C to exit log view."
                    sudo docker logs --tail=100 -f $CONSENSUS_CONTAINER
                    pause
                    ;;
                "Check Sync Status")
                    show_header "Blockchain Sync Status"
                    echo "Checking execution client sync status..."
                    
                    # Get current block height from the node
                    exec_syncing=$(curl -s -X POST -H "Content-Type: application/json" \
                        --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
                        http://localhost:8545)
                    
                    if echo "$exec_syncing" | grep -q "false"; then
                        echo "Execution client is fully synced!"
                    else
                        current_block=$(curl -s -X POST -H "Content-Type: application/json" \
                            --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
                            http://localhost:8545 | grep -oP '(?<="result":")0x[^"]+' | tr -d '0x' | xargs printf "%d" 2>/dev/null)
                        
                        highest_block=$(echo "$exec_syncing" | grep -o '"highestBlock":"0x[^"]*' | grep -o '0x[^"]*' | tr -d '0x' | xargs printf "%d" 2>/dev/null)
                        
                        if [[ -n "$current_block" && -n "$highest_block" ]]; then
                            echo "Current block: $current_block"
                            echo "Highest known block: $highest_block"
                            
                            if [[ $highest_block -gt 0 ]]; then
                                progress=$(awk "BEGIN {printf \"%.2f\", ($current_block/$highest_block)*100}")
                                echo "Sync progress: $progress%"
                            else
                                echo "Sync just started, progress calculation not yet available."
                            fi
                        else
                            echo "Could not determine sync status details."
                        fi
                    fi
                    
                    echo ""
                    echo "Checking consensus client status..."
                    if [[ "$CONSENSUS_CLIENT" == "lighthouse" ]]; then
                        # For Lighthouse
                        echo "Lighthouse status check not yet implemented in this menu version."
                        echo "You can check the logs to monitor sync progress."
                    elif [[ "$CONSENSUS_CLIENT" == "prysm" ]]; then
                        # For Prysm
                        echo "Prysm status check not yet implemented in this menu version."
                        echo "You can check the logs to monitor sync progress."
                    fi
                    
                    pause
                    ;;
                "BACK")
                    break
                    ;;
            esac
            ;;
          1)
            break
            ;;
        esac
    done
}

# ===============================================================================
# Health Check Submenu
# ===============================================================================

health_submenu() {
    while true; do
        health_opt=$(dialog --stdout --title "Health Menu $VERSION" --backtitle "PulseChain Node Management" --menu "Monitor node health:" 0 0 0 \
                        "Run Health Check" "Run a comprehensive health check now" \
                        "View Health Logs" "View historical health check logs" \
                        "Setup Automatic Checks" "Configure automated health monitoring" \
                        "System Resources" "View CPU, memory, and disk usage" \
                        "Container Status" "Check status of all Docker containers" \
                        "BACK" "Return to the Main Menu")

        case $? in
          0)
            case $health_opt in
                "Run Health Check")
                    show_header "Node Health Check"
                    echo "Running complete health check..."
                    $HELPER_PATH/health_check.sh
                    pause
                    ;;
                "View Health Logs")
                    show_header "Health Check Logs"
                    if [ -f "$LOG_PATH/health_check.log" ]; then
                        less "$LOG_PATH/health_check.log"
                    else
                        echo "Health check log file not found."
                        pause
                    fi
                    ;;
                "Setup Automatic Checks")
                    show_header "Setup Automatic Health Checks"
                    $HELPER_PATH/setup_health_check.sh
                    pause
                    ;;
                "System Resources")
                    show_header "System Resource Usage"
                    echo "CPU and Memory Usage:"
                    top -b -n 1 | head -n 20
                    
                    echo ""
                    echo "Disk Usage:"
                    df -h
                    
                    echo ""
                    echo "Docker Disk Usage:"
                    sudo docker system df
                    pause
                    ;;
                "Container Status")
                    show_header "Docker Container Status"
                    echo "All running containers:"
                    sudo docker ps
                    
                    echo ""
                    echo "Container resource usage:"
                    sudo docker stats --no-stream
                    pause
                    ;;
                "BACK")
                    break
                    ;;
            esac
            ;;
          1)
            break
            ;;
        esac
    done
}

# ===============================================================================
# Node Info Submenu
# ===============================================================================

node_info_submenu() {
    while true; do
        info_opt=$(dialog --stdout --title "Info and Management $VERSION" --backtitle "PulseChain Node Management" --menu "View information about your node:" 0 0 0 \
                       "Node Configuration" "View current node configuration" \
                       "Network Information" "View network and peer information" \
                       "Client Versions" "Check versions of running clients" \
                       "Blockchain Status" "View blockchain height and sync status" \
                       "BACK" "Return to the Main Menu")

        case $? in
          0)
            case $info_opt in
                "Node Configuration")
                    show_header "Node Configuration"
                    echo "Current configuration:"
                    echo "  • Installation path: $CUSTOM_PATH"
                    echo "  • Network: $NETWORK"
                    echo "  • Execution client: $ETH_CLIENT"
                    echo "  • Consensus client: $CONSENSUS_CLIENT"
                    
                    if [ -f "$CUSTOM_PATH/node_config.json" ]; then
                        echo ""
                        echo "Configuration file contents:"
                        cat "$CUSTOM_PATH/node_config.json" | jq
                    fi
                    pause
                    ;;
                "Network Information")
                    show_header "Network Information"
                    echo "Execution client peer information:"
                    curl -s -X POST -H "Content-Type: application/json" \
                        --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' \
                        http://localhost:8545 | jq
                    
                    echo ""
                    echo "Node listening ports:"
                    sudo netstat -tulpn | grep -E 'docker|geth|erigon|lighthouse|prysm'
                    pause
                    ;;
                "Client Versions")
                    show_header "Client Versions"
                    echo "Checking execution client version..."
                    version=$(curl -s -X POST -H "Content-Type: application/json" \
                        --data '{"jsonrpc":"2.0","method":"web3_clientVersion","params":[],"id":1}' \
                        http://localhost:8545 | jq -r '.result')
                    echo "Execution client version: $version"
                    
                    echo ""
                    echo "Docker images:"
                    sudo docker images | grep -E 'geth|erigon|lighthouse|prysm'
                    pause
                    ;;
                "Blockchain Status")
                    show_header "Blockchain Status"
                    echo "Current blockchain information:"
                    
                    # Get current block
                    current_block=$(curl -s -X POST -H "Content-Type: application/json" \
                        --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
                        http://localhost:8545 | grep -oP '(?<="result":")0x[^"]+' | tr -d '0x' | xargs printf "%d" 2>/dev/null)
                    
                    if [[ -n "$current_block" ]]; then
                        echo "Current block height: $current_block"
                        
                        # Get chain ID
                        chain_id=$(curl -s -X POST -H "Content-Type: application/json" \
                            --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
                            http://localhost:8545 | grep -oP '(?<="result":")0x[^"]+' | tr -d '0x' | xargs printf "%d" 2>/dev/null)
                        
                        if [[ -n "$chain_id" ]]; then
                            echo "Chain ID: $chain_id"
                            
                            # Resolve chain name
                            chain_name="Unknown"
                            if [[ "$chain_id" == "369" ]]; then
                                chain_name="PulseChain Mainnet"
                            elif [[ "$chain_id" == "943" ]]; then
                                chain_name="PulseChain Testnet v4"
                            fi
                            echo "Network: $chain_name"
                        fi
                        
                        # Block time of latest block
                        latest_block_info=$(curl -s -X POST -H "Content-Type: application/json" \
                            --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_getBlockByNumber\",\"params\":[\"latest\", false],\"id\":1}" \
                            http://localhost:8545)
                        
                        block_time=$(echo "$latest_block_info" | grep -oP '(?<="timestamp":")0x[^"]+' | tr -d '0x' | xargs printf "%d" 2>/dev/null)
                        
                        if [[ -n "$block_time" ]]; then
                            # Convert hex timestamp to date
                            block_date=$(date -d @$block_time)
                            echo "Latest block time: $block_date"
                            
                            # Calculate age
                            now=$(date +%s)
                            age=$(($now - $block_time))
                            
                            if [[ $age -lt 60 ]]; then
                                echo "Block age: $age seconds (healthy)"
                            elif [[ $age -lt 300 ]]; then
                                echo "Block age: $age seconds (normal)"
                            else
                                echo "Block age: $age seconds (potential sync issues)"
                            fi
                        fi
                    else
                        echo "Could not retrieve current block information."
                    fi
                    pause
                    ;;
                "BACK")
                    break
                    ;;
            esac
            ;;
          1)
            break
            ;;
        esac
    done
}

# ===============================================================================
# System Submenu
# ===============================================================================

system_submenu() {
    while true; do
        system_opt=$(dialog --stdout --title "System Menu $VERSION" --backtitle "PulseChain Node Management" --menu "System maintenance options:" 0 0 0 \
                         "Update System" "Update Ubuntu packages" \
                         "Docker Maintenance" "Prune unused Docker resources" \
                         "Backup Configuration" "Create backup of node configuration" \
                         "Reboot System" "Safely reboot the server" \
                         "Shutdown System" "Safely shut down the server" \
                         "BACK" "Return to the Main Menu")

        case $? in
          0)
            case $system_opt in
                "Update System")
                    show_header "System Updates"
                    echo "Running system updates..."
                    echo "Updating package lists..."
                    sudo apt-get update
                    
                    echo ""
                    read -p "Do you want to upgrade packages? (y/N): " confirm
                    if [[ "$confirm" =~ ^[Yy]$ ]]; then
                        echo "Upgrading packages (this may take some time)..."
                        sudo apt-get upgrade -y
                        echo "System has been updated."
                    else
                        echo "Package upgrade skipped."
                    fi
                    pause
                    ;;
                "Docker Maintenance")
                    show_header "Docker Maintenance"
                    echo "Checking Docker disk usage..."
                    sudo docker system df
                    
                    echo ""
                    read -p "Do you want to prune unused Docker resources? (y/N): " confirm
                    if [[ "$confirm" =~ ^[Yy]$ ]]; then
                        echo "Pruning unused Docker resources..."
                        sudo docker system prune -f
                        echo "Docker cleanup completed."
                    else
                        echo "Docker pruning skipped."
                    fi
                    pause
                    ;;
                "Backup Configuration")
                    show_header "Backup Configuration"
                    backup_dir="$BACKUP_PATH/config_backup_$(date +%Y%m%d_%H%M%S)"
                    
                    echo "Creating backup at: $backup_dir"
                    mkdir -p "$backup_dir"
                    
                    # Backup configuration files
                    cp "$CUSTOM_PATH/config.sh" "$backup_dir/" 2>/dev/null || echo "config.sh not found"
                    cp "$CUSTOM_PATH/node_config.json" "$backup_dir/" 2>/dev/null || echo "node_config.json not found"
                    cp "$CUSTOM_PATH/start_execution.sh" "$backup_dir/" 2>/dev/null || echo "start_execution.sh not found"
                    cp "$CUSTOM_PATH/start_consensus.sh" "$backup_dir/" 2>/dev/null || echo "start_consensus.sh not found"
                    
                    # Backup helper scripts
                    mkdir -p "$backup_dir/helper"
                    cp -r "$HELPER_PATH/"* "$backup_dir/helper/" 2>/dev/null
                    
                    echo "Backup completed successfully!"
                    echo "Backup location: $backup_dir"
                    pause
                    ;;
                "Reboot System")
                    show_header "System Reboot"
                    echo "WARNING: This will reboot the entire system."
                    echo "All services will be temporarily offline during reboot."
                    read -p "Are you sure you want to reboot now? (y/N): " confirm
                    if [[ "$confirm" =~ ^[Yy]$ ]]; then
                        echo "Rebooting system now..."
                        # Give some time for user to read message
                        sleep 2
                        sudo reboot
                    else
                        echo "Reboot cancelled."
                        pause
                    fi
                    ;;
                "Shutdown System")
                    show_header "System Shutdown"
                    echo "WARNING: This will shut down the entire system."
                    echo "All services will be offline until manual restart."
                    read -p "Are you sure you want to shut down now? (y/N): " confirm
                    if [[ "$confirm" =~ ^[Yy]$ ]]; then
                        echo "Shutting down system now..."
                        # Give some time for user to read message
                        sleep 2
                        sudo shutdown -h now
                    else
                        echo "Shutdown cancelled."
                        pause
                    fi
                    ;;
                "BACK")
                    break
                    ;;
            esac
            ;;
          1)
            break
            ;;
        esac
    done
}

# ===============================================================================
# Start Main Menu
# ===============================================================================

# Call the main menu function
main_menu 