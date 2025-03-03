#!/bin/bash

# Colors for better readability
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to run basic system checks
run_system_checks() {
    echo -e "${GREEN}Running System Checks...${NC}"
    echo "----------------------------"
    
    # Check CPU Usage
    if command_exists mpstat; then
        cpu_usage=$(mpstat 1 1 | awk '$12 ~ /[0-9.]/ {print 100 - $12}' | tail -1)
        echo -e "CPU Usage: ${YELLOW}${cpu_usage}%${NC}"
    else
        cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}')
        echo -e "CPU Usage: ${YELLOW}${cpu_usage}%${NC}"
    fi
    
    # Check Memory Usage
    mem_info=$(free -h)
    echo -e "\nMemory Usage:"
    echo "$mem_info"
    
    # Check Disk Space
    echo -e "\nDisk Space Usage:"
    df -h /
    
    # Check Network Connectivity
    echo -e "\nNetwork Connectivity:"
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        echo -e "${GREEN}Internet Connection: OK${NC}"
    else
        echo -e "${RED}Internet Connection: FAILED${NC}"
    fi
}

# Function to display the troubleshooting guide
show_troubleshooting_guide() {
    cat << EOL
Common Issues and Solutions:
--------------------------
1. Node Not Syncing
   - Check internet connection
   - Verify port forwarding (30303 TCP/UDP)
   - Check disk space (minimum 2TB recommended)
   - Verify peer connections (minimum 10 peers)
   
2. High Memory Usage
   - Reduce client cache size in config
   - Check for memory leaks using 'top' or 'htop'
   - Consider upgrading RAM (minimum 16GB recommended)
   - Monitor swap usage
   
3. Slow Performance
   - Check CPU usage and temperature
   - Verify SSD health using 'smartctl'
   - Optimize network settings
   - Consider reducing logging level
   
4. Connection Issues
   - Check firewall rules (UFW status)
   - Verify peer count
   - Test network speed
   - Check DNS resolution
   
5. Client-Specific Issues
   Execution Client:
   - Check logs for errors: docker logs execution
   - Verify RPC endpoint functionality
   - Monitor sync progress
   
   Consensus Client:
   - Check logs for errors: docker logs beacon
   - Verify API endpoint functionality
   - Monitor peer count and sync status

6. Monitoring Issues
   - Check Prometheus connectivity
   - Verify Grafana login and dashboards
   - Check metric collection
   - Verify alert configurations

Quick Commands:
-------------
1. Check node status:
   $ docker ps
   
2. View logs:
   $ docker logs -f --tail=100 execution
   $ docker logs -f --tail=100 beacon
   
3. Check sync status:
   $ curl -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' http://localhost:8545
   
4. Check peer count:
   $ curl -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' http://localhost:8545

5. Restart services:
   $ cd /blockchain
   $ ./smart_restart.sh

For additional support:
- Visit our GitHub repository
- Join our Discord community
- Check the official documentation
EOL
}

# Function to check node health
check_node_health() {
    echo -e "${GREEN}Checking Node Health...${NC}"
    echo "-------------------------"
    
    # Check Docker status
    echo -e "\nDocker Container Status:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.State}}"
    
    # Check client sync status
    echo -e "\nSync Status:"
    curl -s -X POST -H "Content-Type: application/json" \
         --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
         http://localhost:8545 | jq
         
    # Check peer count
    echo -e "\nPeer Count:"
    curl -s -X POST -H "Content-Type: application/json" \
         --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' \
         http://localhost:8545 | jq
}

# Main menu
main_menu() {
    while true; do
        clear
        echo -e "${GREEN}PulseChain Node Troubleshooting Tool${NC}"
        echo "=================================="
        echo "1. Show Troubleshooting Guide"
        echo "2. Run System Checks"
        echo "3. Check Node Health"
        echo "4. View Recent Logs"
        echo "5. Exit"
        echo
        read -p "Please select an option (1-5): " choice
        
        case $choice in
            1)
                clear
                show_troubleshooting_guide
                read -p "Press Enter to continue..."
                ;;
            2)
                clear
                run_system_checks
                read -p "Press Enter to continue..."
                ;;
            3)
                clear
                check_node_health
                read -p "Press Enter to continue..."
                ;;
            4)
                clear
                echo -e "${GREEN}Execution Client Logs:${NC}"
                docker logs --tail 50 execution
                echo -e "\n${GREEN}Consensus Client Logs:${NC}"
                docker logs --tail 50 beacon
                read -p "Press Enter to continue..."
                ;;
            5)
                echo "Exiting..."
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please try again.${NC}"
                sleep 2
                ;;
        esac
    done
}

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root or with sudo${NC}"
    exit 1
fi

# Start the main menu
main_menu 