#!/bin/bash

# Remote Access Management Script for PulseChain Archive Node
# This script helps manage remote access to the node for indexing purposes

VERSION="1.0"
CUSTOM_PATH=${CUSTOM_PATH:-"/blockchain"}

# Function to display current firewall rules related to RPC access
show_current_access() {
    clear
    echo "Current Remote Access Configuration:"
    echo "===================================="
    echo ""
    echo "Firewall Rules for RPC Access:"
    sudo ufw status | grep -E '8545|8546'
    echo ""
    echo "Current RPC Configuration in start_execution.sh:"
    grep -E 'http.addr|http.vhosts|http.corsdomain|ws.addr|ws.origins' "${CUSTOM_PATH}/start_execution.sh"
    echo ""
    read -p "Press Enter to continue..."
}

# Function to add a new IP address for remote access
add_remote_ip() {
    clear
    echo "Add New Remote Access IP"
    echo "========================"
    echo ""
    read -p "Enter the IP address to allow RPC access: " ip_address
    
    if [[ -z "$ip_address" ]]; then
        echo "No IP address entered. Returning to menu."
        return
    fi
    
    # Validate IP address format
    if ! [[ $ip_address =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Invalid IP address format. Please use format: xxx.xxx.xxx.xxx"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo "Adding firewall rules for $ip_address..."
    sudo ufw allow from $ip_address to any port 8545 proto tcp comment "RPC access for $ip_address"
    sudo ufw allow from $ip_address to any port 8546 proto tcp comment "WebSocket access for $ip_address"
    
    echo "Firewall rules added successfully!"
    echo ""
    read -p "Press Enter to continue..."
}

# Function to remove an IP address from remote access
remove_remote_ip() {
    clear
    echo "Remove Remote Access IP"
    echo "======================="
    echo ""
    
    # Get current rules
    rules=$(sudo ufw status numbered | grep -E '8545|8546')
    
    if [[ -z "$rules" ]]; then
        echo "No remote access rules found."
        read -p "Press Enter to continue..."
        return
    fi
    
    echo "Current remote access rules:"
    echo "$rules"
    echo ""
    read -p "Enter the rule number to remove (or press Enter to cancel): " rule_num
    
    if [[ -z "$rule_num" ]]; then
        echo "No rule selected. Returning to menu."
        return
    fi
    
    # Remove the rule
    echo "Removing rule $rule_num..."
    sudo ufw delete $rule_num
    
    echo "Rule removed successfully!"
    echo ""
    read -p "Press Enter to continue..."
}

# Function to test RPC connectivity
test_rpc_connection() {
    clear
    echo "Test RPC Connection"
    echo "=================="
    echo ""
    
    # Check if curl is installed
    if ! command -v curl &> /dev/null; then
        echo "curl is not installed. Installing..."
        sudo apt-get update && sudo apt-get install -y curl
    fi
    
    echo "Testing local RPC connection..."
    curl -s -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' http://localhost:8545
    echo ""
    echo ""
    
    read -p "Do you want to test a remote connection? (y/n): " test_remote
    if [[ "$test_remote" == "y" ]]; then
        read -p "Enter the remote IP address: " remote_ip
        echo "Testing remote RPC connection from $remote_ip..."
        echo "Note: This test will only succeed if the remote machine has access and can reach this server."
        echo "You may need to run this test from the remote machine itself."
        echo ""
        read -p "Press Enter to continue..."
    fi
}

# Function to configure RPC settings
configure_rpc_settings() {
    clear
    echo "Configure RPC Settings"
    echo "====================="
    echo ""
    
    echo "Current RPC Configuration:"
    grep -E 'http.addr|http.vhosts|http.corsdomain|ws.addr|ws.origins' "${CUSTOM_PATH}/start_execution.sh"
    echo ""
    
    echo "This will modify your start_execution.sh script to update RPC settings."
    read -p "Do you want to continue? (y/n): " confirm
    
    if [[ "$confirm" != "y" ]]; then
        echo "Operation cancelled."
        read -p "Press Enter to continue..."
        return
    fi
    
    # Backup the original file
    cp "${CUSTOM_PATH}/start_execution.sh" "${CUSTOM_PATH}/start_execution.sh.bak"
    
    # Update settings based on user input
    read -p "Allow all hosts for RPC? (recommended for remote access) (y/n): " allow_all_hosts
    if [[ "$allow_all_hosts" == "y" ]]; then
        sed -i 's/--http.addr=.*/--http.addr=0.0.0.0 \\/g' "${CUSTOM_PATH}/start_execution.sh"
        sed -i 's/--http.vhosts=.*/--http.vhosts=* \\/g' "${CUSTOM_PATH}/start_execution.sh"
        sed -i 's/--ws.addr=.*/--ws.addr=0.0.0.0 \\/g' "${CUSTOM_PATH}/start_execution.sh"
        sed -i 's/--ws.origins=.*/--ws.origins=* \\/g' "${CUSTOM_PATH}/start_execution.sh"
    fi
    
    echo "RPC settings updated successfully!"
    echo "You'll need to restart the execution client for changes to take effect."
    echo ""
    read -p "Do you want to restart the execution client now? (y/n): " restart_now
    if [[ "$restart_now" == "y" ]]; then
        echo "Restarting execution client..."
        sudo docker stop -t 300 execution
        sleep 1
        sudo docker container prune -f
        ${CUSTOM_PATH}/start_execution.sh
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

# Main menu
while true; do
    clear
    echo "Remote Access Management - v${VERSION}"
    echo "======================================"
    echo ""
    echo "1) Show Current Remote Access Configuration"
    echo "2) Add New Remote IP for Access"
    echo "3) Remove Remote IP from Access"
    echo "4) Test RPC Connection"
    echo "5) Configure RPC Settings"
    echo ""
    echo "0) Back to Main Menu"
    echo ""
    read -p "Enter your choice: " choice
    
    case $choice in
        1) show_current_access ;;
        2) add_remote_ip ;;
        3) remove_remote_ip ;;
        4) test_rpc_connection ;;
        5) configure_rpc_settings ;;
        0) exit 0 ;;
        *) echo "Invalid option. Please try again." ;;
    esac
done 