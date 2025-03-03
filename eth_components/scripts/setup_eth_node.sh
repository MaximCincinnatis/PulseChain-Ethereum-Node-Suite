#!/bin/bash

# ===============================================================================
# Ethereum Node Setup Script
# ===============================================================================
# Version: 0.1.0
# Description: Sets up an Ethereum node with execution and consensus clients
# Author: Based on PulseChain setup by Maxim Broadcast
# ===============================================================================

# Exit on error
set -e

# Define color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Store initial directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INITIAL_DIR=$(pwd)

# Source configuration
source "${SCRIPT_DIR}/../config/eth_config.sh"

# ===============================================================================
# Helper Functions
# ===============================================================================

display_welcome() {
    clear
    # Define a rich color palette for the Ethereum logo
    local PLUS='\033[38;5;147m'    # Light purple for + symbols
    local PERCENT='\033[38;5;62m'   # Darker purple for % symbols
    local AT='\033[38;5;56m'       # Deep purple for @ symbols
    local HASH='\033[38;5;98m'     # Medium purple for # symbols
    local WHITE='\033[38;5;255m'   # Pure white
    local TITLE='\033[38;5;99m'    # Title color
    
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║                          ${TITLE}Ethereum Node Setup Script${WHITE}                          ║${NC}"
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${PLUS}                                                 +${PERCENT}%                                                 "
    echo -e "${PLUS}                                                ++${PERCENT}%%                                                "
    echo -e "${PLUS}                                               +++${PERCENT}%%%                                               "
    echo -e "${PLUS}                                              ++++${PERCENT}%%%%                                              "
    echo -e "${PLUS}                                            ++++++${PERCENT}%%%%%%                                            "
    echo -e "${PLUS}                                           +++++++${PERCENT}%%%%%%%                                           "
    echo -e "${PLUS}                                          ++++++++${PERCENT}%%%%%%%%                                          "
    echo -e "${PLUS}                                         +++++++++${PERCENT}%%%%%%%%%                                         "
    echo -e "${PLUS}                                        ++++++++++${PERCENT}%%%%%%%%%%                                        "
    echo -e "${PLUS}                                       +++++++++++${PERCENT}%%%%%%%%%%%                                       "
    echo -e "${PLUS}                                      ++++++++++++${PERCENT}%%%%%%%%%%%%                                      "
    echo -e "${PLUS}                                     +++++++++++++${PERCENT}%%%%%%%%%%%%%                                     "
    echo -e "${PLUS}                                   +++++++++++++++${PERCENT}%%%%%%%%%%%%%%%                                   "
    echo -e "${PLUS}                                  ++++++++++++++++${PERCENT}%%%%%%%%%%%%%%%%                                  "
    echo -e "${PLUS}                                 +++++++++++++++++${PERCENT}%%%%%%%%%%%%%%%%%                                 "
    echo -e "${PLUS}                                ++++++++++++++++++${PERCENT}%%%%%%%%%%%%%%%%%%                                "
    echo -e "${PLUS}                               +++++++++++++++++++${PERCENT}%%%%%%%%%%%%%%%%%%%                               "
    echo -e "${PLUS}                              ++++++++++++++++++++${PERCENT}%%%%%%%%%%%%%%%%%%%%                              "
    echo -e "${PLUS}                             +++++++++++++++++++++${PERCENT}%%%%%%%%%%%%%%%%%%%%%                             "
    echo -e "${PLUS}                            ++++++++++++++++++++++${PERCENT}%%%%%%%%%%%%%%%%%%%%%%                            "
    echo -e "${PLUS}                          ++++++++++++++++++++++**${PERCENT}%%%%%%%%%%%%%%%%%%%%%%%%                          "
    echo -e "${PLUS}                         ++++++++++++++++++++*${HASH}####${AT}@@@@${PERCENT}%%%%%%%%%%%%%%%%%%%%%                         "
    echo -e "${PLUS}                        +++++++++++++++++*${HASH}########${AT}@@@@@@@@${PERCENT}%%%%%%%%%%%%%%%%%%                        "
    echo -e "${PLUS}                       ++++++++++++++*${HASH}############${AT}@@@@@@@@@@@@${PERCENT}%%%%%%%%%%%%%%%                       "
    echo -e "${PLUS}                      +++++++++++*${HASH}################${AT}@@@@@@@@@@@@@@@@${PERCENT}%%%%%%%%%%%%                      "
    echo -e "${PLUS}                     ++++++++*${HASH}####################${AT}@@@@@@@@@@@@@@@@@@@@${PERCENT}%%%%%%%%%                     "
    echo -e "${PLUS}                    +++++*${HASH}########################${AT}@@@@@@@@@@@@@@@@@@@@@@@@${PERCENT}%%%%%%                    "
    echo -e "${PLUS}                   +**${HASH}############################${AT}@@@@@@@@@@@@@@@@@@@@@@@@@@@@${PERCENT}%%%                   "
    echo -e "${PLUS}                   #${PERCENT}%${HASH}#############################${AT}@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@${NC}                   "
    echo -e "                      ${PERCENT}%%${HASH}##%#######################${AT}@@@@@@@@@@@@@@@@@@@@@@@@@@@@${NC}                      "
    echo -e "                          ${PERCENT}%%%%${HASH}####################${AT}@@@@@@@@@@@@@@@@@@@@@@@@${NC}                          "
    echo -e "${PLUS}                   ++       ${PERCENT}%%${HASH}####################${AT}@@@@@@@@@@@@@@@@@@@@@@${NC}       ${HASH}#%${NC}                   "
    echo -e "${PLUS}                    +++++      ${PERCENT}%%%${HASH}################${AT}@@@@@@@@@@@@@@@@@@@${NC}       ${HASH}###%${NC}                    "
    echo -e "${PLUS}                     +++++++      ${HASH}#%%#%###########${AT}@@@@@@@@@@@@@@@@${NC}      ${HASH}######%${NC}                     "
    echo -e "${PLUS}                      +++++++++       ${HASH}##%%########${AT}@@@@@@@@@@@@${NC}       ${HASH}########%${NC}                      "
    echo -e "${PLUS}                        ++++++++++       ${HASH}#%#######${AT}@@@@@@@@@${NC}       ${HASH}%#########${NC}                        "
    echo -e "${PLUS}                         ++++++++++++       ${HASH}%###%#${AT}@@@@@@${NC}       ${HASH}%###########${NC}                         "
    echo -e "${PLUS}                          ++++++++++++++       ${HASH}%#%${AT}@@@${NC}       ${HASH}%############%${NC}                          "
    echo -e "${PLUS}                            +++++++++++++++              ${HASH}%##############${NC}                            "
    echo -e "${PLUS}                             +++++++++++++++++        ${HASH}################%${NC}                             "
    echo -e "${PLUS}                              +++++++++++++++++++  ${HASH}##################%${NC}                              "
    echo -e "${PLUS}                               +++++++++++++++++++${HASH}###################${NC}                               "
    echo -e "${PLUS}                                 +++++++++++++++++${HASH}#################${NC}                                 "
    echo -e "${PLUS}                                  ++++++++++++++++${HASH}###############%${NC}                                  "
    echo -e "${PLUS}                                    ++++++++++++++${HASH}##############${NC}                                    "
    echo -e "${PLUS}                                     +++++++++++++${HASH}#############${NC}                                     "
    echo -e "${PLUS}                                      ++++++++++++${HASH}############${NC}                                      "
    echo -e "${PLUS}                                       +++++++++++${HASH}##########%${NC}                                       "
    echo -e "${PLUS}                                         +++++++++${HASH}#########${NC}                                         "
    echo -e "${PLUS}                                          ++++++++${HASH}########${NC}                                          "
    echo -e "${PLUS}                                           +++++++${HASH}######%${NC}                                           "
    echo -e "${PLUS}                                             +++++${HASH}#####${NC}                                             "
    echo -e "${PLUS}                                              ++++${HASH}####${NC}                                              "
    echo -e "${PLUS}                                               +++${HASH}###${NC}                                               "
    echo -e "${PLUS}                                                 +${HASH}#${NC}                                                 "
    echo ""
    echo -e "                              ${TITLE}Welcome to Ethereum Node Setup${NC}"
    echo ""
    echo -e "${WHITE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║  This script will guide you through setting up a full Ethereum node with both ║${NC}"
    echo -e "${WHITE}║  execution and consensus clients. Please ensure you meet all requirements.    ║${NC}"
    echo -e "${WHITE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    press_enter_to_continue
}

display_disclaimer() {
    echo -e "${YELLOW}"
    echo "┌─────────────────────────────────────────────────────────┐"
    echo "│                     DISCLAIMER                          │"
    echo "├─────────────────────────────────────────────────────────┤"
    echo "│ This script will set up an Ethereum node.              │"
    echo "│ Please ensure you have:                                │"
    echo "│  - At least ${ETH_MIN_RAM_GB}GB of RAM                │"
    echo "│  - At least ${ETH_MIN_STORAGE_GB}GB of free storage   │"
    echo "│  - A stable internet connection                        │"
    echo "│                                                        │"
    echo "│ The setup process may take several hours to complete.  │"
    echo "│ Archive nodes require significantly more resources.    │"
    echo "└─────────────────────────────────────────────────────────┘"
    echo -e "${NC}"
    
    read -p "Do you wish to continue? (y/n): " CONFIRM
    if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
        echo "Setup aborted."
        exit 1
    fi
}

check_system_requirements() {
    echo -e "${GREEN}Checking system requirements...${NC}"
    
    # Check RAM
    local total_ram=$(grep MemTotal /proc/meminfo | awk '{print $2/1024/1024}')
    if (( $(echo "$total_ram < $ETH_MIN_RAM_GB" | bc -l) )); then
        echo -e "${RED}Error: Insufficient RAM. ${ETH_MIN_RAM_GB}GB required, ${total_ram}GB available.${NC}"
        exit 1
    fi
    
    # Check Storage
    local free_storage=$(df -BG "${CUSTOM_PATH:-/}" | awk 'NR==2 {print $4}' | sed 's/G//')
    if (( free_storage < ETH_MIN_STORAGE_GB )); then
        echo -e "${RED}Error: Insufficient storage. ${ETH_MIN_STORAGE_GB}GB required, ${free_storage}GB available.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}System requirements met.${NC}"
}

# ===============================================================================
# Network Selection
# ===============================================================================

select_network() {
    echo -e "${GREEN}Select Ethereum Network${NC}"
    echo "======================="
    echo ""
    echo "+=================+"
    echo "| Choose Network: |"
    echo "+=================+"
    echo "| 1) Mainnet      |"
    echo "| 2) Goerli       |"
    echo "| 3) Sepolia      |"
    echo "+-----------------+"
    echo ""
    
    while true; do
        read -p "Enter your choice (1-3): " network_choice
        case $network_choice in
            1)
                NETWORK="mainnet"
                break
                ;;
            2)
                NETWORK="goerli"
                break
                ;;
            3)
                NETWORK="sepolia"
                break
                ;;
            *)
                echo "Invalid choice. Please select 1, 2, or 3."
                ;;
        esac
    done
    
    export NETWORK
    save_eth_config
}

# ===============================================================================
# Node Type Selection
# ===============================================================================

select_node_type() {
    echo -e "${GREEN}Select Node Type${NC}"
    echo "================="
    echo ""
    echo "┌────────────────────────────────────────────────────────────────┐"
    echo "│ Choose Node Type:                                              │"
    echo "├────────────────────────────────────────────────────────────────┤"
    echo "│ 1) Full Node (Default)                                         │"
    echo "│    - Stores recent state                                       │"
    echo "│    - Suitable for most users                                   │"
    echo "│    - ~1TB storage required                                     │"
    echo "│    Available Clients:                                          │"
    echo "│    • Geth (Most popular, well-maintained)                      │"
    echo "│    • Erigon (Faster sync, more resource-efficient)            │"
    echo "│                                                                │"
    echo "│ 2) Archive Node                                                │"
    echo "│    - Stores complete history                                   │"
    echo "│    - For developers/services                                   │"
    echo "│    - ~2TB+ storage required                                    │"
    echo "│    Available Clients:                                          │"
    echo "│    • Erigon (Recommended - efficient storage)                  │"
    echo "│    • Geth Archive (Traditional, higher storage needs)         │"
    echo "│                                                                │"
    echo "│ 3) Pruned Node                                                │"
    echo "│    - Minimal storage requirements                              │"
    echo "│    - Limited historical data                                   │"
    echo "│    - ~500GB storage required                                   │"
    echo "│    Available Clients:                                          │"
    echo "│    • Geth (Recommended - stable pruning)                      │"
    echo "│    • Erigon (Experimental pruning support)                    │"
    echo "└────────────────────────────────────────────────────────────────┘"
    
    while true; do
        read -p "Enter your choice (1-3): " node_type_choice
        case $node_type_choice in
            1)
                NODE_TYPE="full"
                ETH_MIN_STORAGE_GB=1000
                break
                ;;
            2)
                NODE_TYPE="archive"
                ETH_MIN_STORAGE_GB=2500
                break
                ;;
            3)
                NODE_TYPE="pruned"
                ETH_MIN_STORAGE_GB=500
                break
                ;;
            *)
                echo "Invalid choice. Please select 1, 2, or 3."
                ;;
        esac
    done
    
    export NODE_TYPE
    check_storage_requirements
}

check_storage_requirements() {
    echo -e "${GREEN}Checking storage requirements for ${NODE_TYPE} node...${NC}"
    local free_storage=$(df -BG "${CUSTOM_PATH:-/}" | awk 'NR==2 {print $4}' | sed 's/G//')
    
    if (( free_storage < ETH_MIN_STORAGE_GB )); then
        echo -e "${RED}Error: Insufficient storage for ${NODE_TYPE} node.${NC}"
        echo "Required: ${ETH_MIN_STORAGE_GB}GB"
        echo "Available: ${free_storage}GB"
        echo ""
        echo "Please free up space or choose a different node type."
        exit 1
    fi
    
    echo -e "${GREEN}Storage requirements met.${NC}"
}

# ===============================================================================
# Client Selection with Advanced Options
# ===============================================================================

select_execution_client() {
    echo -e "${GREEN}Select Execution Client${NC}"
    echo "======================="
    echo ""
    echo "┌────────────────────────────────────────────┐"
    echo "│ Choose Execution Client:                    │"
    echo "├────────────────────────────────────────────┤"
    case $NODE_TYPE in
        "full")
            echo "│ 1) Geth                                    │"
            echo "│    - Most popular client                   │"
            echo "│    - Well-maintained                       │"
            echo "│    - Good for most users                   │"
            echo "│                                            │"
            echo "│ 2) Erigon                                  │"
            echo "│    - Faster sync                           │"
            echo "│    - More resource-efficient               │"
            echo "│    - Newer but stable                      │"
            ;;
        "archive")
            echo "│ 1) Erigon (Recommended for Archive)        │"
            echo "│    - Efficient storage                     │"
            echo "│    - Fast historical queries               │"
            echo "│    - Built for archive nodes               │"
            echo "│                                            │"
            echo "│ 2) Geth Archive                           │"
            echo "│    - Traditional archive node              │"
            echo "│    - Higher storage requirements           │"
            echo "│    - Slower historical queries             │"
            ;;
        "pruned")
            echo "│ 1) Geth (Recommended for Pruned)          │"
            echo "│    - Efficient pruning                     │"
            echo "│    - Stable pruning implementation         │"
            echo "│    - Good for limited storage              │"
            echo "│                                            │"
            echo "│ 2) Erigon (Experimental Pruning)          │"
            echo "│    - Newer pruning implementation          │"
            echo "│    - May require more configuration        │"
            echo "│    - Advanced users only                   │"
            ;;
    esac
    echo "└────────────────────────────────────────────┘"
    
    while true; do
        read -p "Enter your choice (1-2): " client_choice
        case $client_choice in
            1)
                case $NODE_TYPE in
                    "full")
                        ETH_CLIENT="geth"
                        ;;
                    "archive")
                        ETH_CLIENT="erigon"
                        ;;
                    "pruned")
                        ETH_CLIENT="geth-pruned"
                        ;;
                esac
                break
                ;;
            2)
                case $NODE_TYPE in
                    "full")
                        ETH_CLIENT="erigon"
                        ;;
                    "archive")
                        ETH_CLIENT="geth-archive"
                        ;;
                    "pruned")
                        ETH_CLIENT="erigon-pruned"
                        ;;
                esac
                break
                ;;
            *)
                echo "Invalid choice. Please select 1 or 2."
                ;;
        esac
    done
    
    export ETH_CLIENT
}

select_consensus_client() {
    echo -e "${GREEN}Select Consensus Client${NC}"
    echo "========================"
    echo ""
    echo "+=================+"
    echo "| Choose Client:  |"
    echo "+=================+"
    echo "| 1) Lighthouse   |"
    echo "| 2) Prysm        |"
    echo "+-----------------+"
    
    while true; do
        read -p "Enter your choice (1-2): " consensus_choice
        case $consensus_choice in
            1)
                CONSENSUS_CLIENT="lighthouse"
                break
                ;;
            2)
                CONSENSUS_CLIENT="prysm"
                break
                ;;
            *)
                echo "Invalid choice. Please select 1 or 2."
                ;;
        esac
    done
    
    export CONSENSUS_CLIENT
}

# ===============================================================================
# Main Setup Flow
# ===============================================================================

main() {
    display_welcome
    display_disclaimer
    
    # Select node type first as it affects other choices
    select_node_type
    
    # Select network (reusing existing function)
    select_network
    
    # Select clients with new advanced options
    select_execution_client
    select_consensus_client
    
    # Setup directories and configurations
    setup_directories
    
    # Install dependencies
    install_dependencies
    
    # Configure clients based on node type
    configure_clients
    
    # Setup monitoring
    setup_monitoring
    
    # Final checks
    perform_final_checks
    
    echo -e "${GREEN}Setup completed successfully!${NC}"
    display_next_steps
}

# Run main function
main 

# ===============================================================================
# Additional Helper Functions
# ===============================================================================

press_enter_to_continue() {
    echo ""
    read -p "Press Enter to continue..."
    echo ""
}

configure_clients() {
    echo -e "${GREEN}Configuring Ethereum clients...${NC}"
    
    # Create Docker Compose files
    create_execution_compose
    create_consensus_compose
    
    # Generate JWT secret if it doesn't exist
    if [ ! -f "${ETH_JWT_FILE}" ]; then
        echo -e "${GREEN}Generating JWT secret...${NC}"
        openssl rand -hex 32 | tr -d "\n" > "${ETH_JWT_FILE}"
        chmod 640 "${ETH_JWT_FILE}"
    fi
    
    # Configure execution client
    case $ETH_CLIENT in
        "geth"|"geth-pruned")
            configure_geth
            ;;
        "erigon"|"erigon-pruned")
            configure_erigon
            ;;
        "geth-archive")
            configure_geth_archive
            ;;
    esac
    
    # Configure consensus client
    case $CONSENSUS_CLIENT in
        "lighthouse")
            configure_lighthouse
            ;;
        "prysm")
            configure_prysm
            ;;
    esac
    
    echo -e "${GREEN}Client configuration completed.${NC}"
}

configure_geth() {
    cat > "${ETH_BASE_DIR}/docker-compose.execution.yml" << EOL
version: '3.8'
services:
  geth:
    image: ${GETH_ETH_IMAGE}
    container_name: eth_geth
    restart: unless-stopped
    volumes:
      - ${ETH_EXECUTION_DIR}:/data
      - ${ETH_JWT_FILE}:/jwt.hex
    ports:
      - "${ETH_RPC_PORT}:8545"
      - "${ETH_WS_PORT}:8546"
      - "${ETH_ENGINE_PORT}:8551"
      - "${ETH_P2P_PORT}:30303/tcp"
      - "${ETH_P2P_PORT}:30303/udp"
    command:
      - --${NETWORK}
      - --datadir=/data
      - --http
      - --http.addr=0.0.0.0
      - --http.vhosts=*
      - --http.api=eth,net,engine,admin
      - --ws
      - --ws.addr=0.0.0.0
      - --ws.origins=*
      - --authrpc.addr=0.0.0.0
      - --authrpc.vhosts=*
      - --authrpc.jwtsecret=/jwt.hex
      - --metrics
      - --metrics.addr=0.0.0.0
      - --metrics.port=${ETH_METRICS_PORT}
EOL

    if [ "$ETH_CLIENT" = "geth-pruned" ]; then
        echo "      - --snapshot=false" >> "${ETH_BASE_DIR}/docker-compose.execution.yml"
    fi
}

configure_erigon() {
    cat > "${ETH_BASE_DIR}/docker-compose.execution.yml" << EOL
version: '3.8'
services:
  erigon:
    image: ${ERIGON_ETH_IMAGE}
    container_name: eth_erigon
    restart: unless-stopped
    volumes:
      - ${ETH_EXECUTION_DIR}:/data
      - ${ETH_JWT_FILE}:/jwt.hex
    ports:
      - "${ETH_RPC_PORT}:8545"
      - "${ETH_WS_PORT}:8546"
      - "${ETH_ENGINE_PORT}:8551"
      - "${ETH_P2P_PORT}:30303/tcp"
      - "${ETH_P2P_PORT}:30303/udp"
    command:
      - --chain=${NETWORK}
      - --datadir=/data
      - --http
      - --http.addr=0.0.0.0
      - --http.vhosts=*
      - --http.api=eth,erigon,net,web3,debug,trace,txpool
      - --ws
      - --ws.addr=0.0.0.0
      - --ws.origins=*
      - --authrpc.addr=0.0.0.0
      - --authrpc.vhosts=*
      - --authrpc.jwtsecret=/jwt.hex
      - --metrics
      - --metrics.addr=0.0.0.0
      - --metrics.port=${ETH_METRICS_PORT}
EOL

    if [ "$ETH_CLIENT" = "erigon-pruned" ]; then
        echo "      - --prune=htc" >> "${ETH_BASE_DIR}/docker-compose.execution.yml"
    fi
}

configure_geth_archive() {
    cat > "${ETH_BASE_DIR}/docker-compose.execution.yml" << EOL
version: '3.8'
services:
  geth:
    image: ${GETH_ETH_IMAGE}
    container_name: eth_geth_archive
    restart: unless-stopped
    volumes:
      - ${ETH_EXECUTION_DIR}:/data
      - ${ETH_JWT_FILE}:/jwt.hex
    ports:
      - "${ETH_RPC_PORT}:8545"
      - "${ETH_WS_PORT}:8546"
      - "${ETH_ENGINE_PORT}:8551"
      - "${ETH_P2P_PORT}:30303/tcp"
      - "${ETH_P2P_PORT}:30303/udp"
    command:
      - --${NETWORK}
      - --datadir=/data
      - --http
      - --http.addr=0.0.0.0
      - --http.vhosts=*
      - --http.api=eth,net,engine,admin,debug
      - --ws
      - --ws.addr=0.0.0.0
      - --ws.origins=*
      - --authrpc.addr=0.0.0.0
      - --authrpc.vhosts=*
      - --authrpc.jwtsecret=/jwt.hex
      - --metrics
      - --metrics.addr=0.0.0.0
      - --metrics.port=${ETH_METRICS_PORT}
      - --gcmode=archive
      - --txlookuplimit=0
EOL
}

configure_lighthouse() {
    cat > "${ETH_BASE_DIR}/docker-compose.consensus.yml" << EOL
version: '3.8'
services:
  lighthouse:
    image: ${LIGHTHOUSE_ETH_IMAGE}
    container_name: eth_lighthouse
    restart: unless-stopped
    volumes:
      - ${ETH_CONSENSUS_DIR}:/data
      - ${ETH_JWT_FILE}:/jwt.hex
    ports:
      - "${ETH_BEACON_P2P_PORT}:9000/tcp"
      - "${ETH_BEACON_P2P_PORT}:9000/udp"
      - "${ETH_BEACON_HTTP_PORT}:5052"
      - "${ETH_BEACON_METRICS_PORT}:5054"
    command:
      - lighthouse
      - beacon_node
      - --network=${NETWORK}
      - --datadir=/data
      - --execution-endpoint=http://localhost:${ETH_ENGINE_PORT}
      - --execution-jwt=/jwt.hex
      - --http
      - --http-address=0.0.0.0
      - --metrics
      - --metrics-address=0.0.0.0
      - --checkpoint-sync-url=https://beaconstate.${NETWORK}.ethstaker.cc
EOL
}

configure_prysm() {
    cat > "${ETH_BASE_DIR}/docker-compose.consensus.yml" << EOL
version: '3.8'
services:
  prysm:
    image: ${PRYSM_ETH_IMAGE}
    container_name: eth_prysm
    restart: unless-stopped
    volumes:
      - ${ETH_CONSENSUS_DIR}:/data
      - ${ETH_JWT_FILE}:/jwt.hex
    ports:
      - "${ETH_BEACON_P2P_PORT}:9000/tcp"
      - "${ETH_BEACON_P2P_PORT}:9000/udp"
      - "${ETH_BEACON_HTTP_PORT}:5052"
      - "${ETH_BEACON_METRICS_PORT}:5054"
    command:
      - --${NETWORK}
      - --datadir=/data
      - --execution-endpoint=http://localhost:${ETH_ENGINE_PORT}
      - --jwt-secret=/jwt.hex
      - --rpc-host=0.0.0.0
      - --monitoring-host=0.0.0.0
      - --checkpoint-sync-url=https://beaconstate.${NETWORK}.ethstaker.cc
      - --accept-terms-of-use
EOL
}

perform_final_checks() {
    echo -e "${GREEN}Performing final checks...${NC}"
    
    # Check if Docker is running
    if ! systemctl is-active --quiet docker; then
        echo -e "${RED}Error: Docker service is not running.${NC}"
        exit 1
    fi
    
    # Check if required ports are available
    check_port_availability() {
        local port=$1
        if netstat -tuln | grep -q ":${port} "; then
            echo -e "${RED}Error: Port ${port} is already in use.${NC}"
            exit 1
        fi
    }
    
    check_port_availability "${ETH_RPC_PORT}"
    check_port_availability "${ETH_WS_PORT}"
    check_port_availability "${ETH_ENGINE_PORT}"
    check_port_availability "${ETH_P2P_PORT}"
    check_port_availability "${ETH_BEACON_P2P_PORT}"
    check_port_availability "${ETH_BEACON_HTTP_PORT}"
    
    # Check if JWT file exists and has correct permissions
    if [ ! -f "${ETH_JWT_FILE}" ]; then
        echo -e "${RED}Error: JWT file not found.${NC}"
        exit 1
    fi
    
    # Check if Docker Compose files exist
    if [ ! -f "${ETH_BASE_DIR}/docker-compose.execution.yml" ] || \
       [ ! -f "${ETH_BASE_DIR}/docker-compose.consensus.yml" ]; then
        echo -e "${RED}Error: Docker Compose files not found.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}All checks passed successfully.${NC}"
}

display_next_steps() {
    echo -e "${GREEN}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                         Next Steps                             ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo "1. Start the execution client:"
    echo "   cd ${ETH_BASE_DIR} && docker-compose -f docker-compose.execution.yml up -d"
    echo ""
    echo "2. Wait for the execution client to sync (this may take several hours)"
    echo "   Monitor progress: docker logs -f eth_${ETH_CLIENT}"
    echo ""
    echo "3. Start the consensus client:"
    echo "   cd ${ETH_BASE_DIR} && docker-compose -f docker-compose.consensus.yml up -d"
    echo ""
    echo "4. Monitor the sync progress:"
    echo "   docker logs -f eth_${CONSENSUS_CLIENT}"
    echo ""
    echo "5. Access monitoring dashboard:"
    echo "   http://localhost:3000 (default credentials: admin/admin)"
    echo ""
    echo "Useful commands:"
    echo "- View logs: docker logs -f eth_${ETH_CLIENT}|eth_${CONSENSUS_CLIENT}"
    echo "- Stop clients: docker-compose -f docker-compose.*.yml down"
    echo "- Check status: docker ps"
    echo ""
    echo -e "${YELLOW}Note: Initial synchronization may take several days depending on"
    echo "your hardware and network connection.${NC}"
    echo ""
}

# ===============================================================================
# Setup Functions
# ===============================================================================

setup_directories() {
    echo -e "${GREEN}Setting up directories...${NC}"
    
    # Create base directory structure
    sudo mkdir -p "${ETH_BASE_DIR}"
    sudo mkdir -p "${ETH_EXECUTION_DIR}"
    sudo mkdir -p "${ETH_CONSENSUS_DIR}"
    sudo mkdir -p "${ETH_LOGS_DIR}"
    sudo mkdir -p "${ETH_BACKUP_DIR}"
    
    # Set appropriate permissions
    sudo chown -R "$USER:$USER" "${ETH_BASE_DIR}"
    sudo chmod -R 750 "${ETH_BASE_DIR}"
    
    echo -e "${GREEN}Directory structure created.${NC}"
}

install_dependencies() {
    echo -e "${GREEN}Installing dependencies...${NC}"
    
    # Run the dependency setup script
    bash "${SCRIPT_DIR}/setup_dependencies.sh"
    
    # Check if the dependency setup was successful
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Failed to install dependencies.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Dependencies installed successfully.${NC}"
}

save_eth_config() {
    echo -e "${GREEN}Saving configuration...${NC}"
    
    # Create config directory if it doesn't exist
    mkdir -p "$(dirname "${ETH_CONFIG_FILE}")"
    
    # Save configuration to JSON file
    cat > "${ETH_CONFIG_FILE}" << EOL
{
    "version": "${ETH_CONFIG_VERSION}",
    "network": "${NETWORK}",
    "node_type": "${NODE_TYPE}",
    "execution_client": "${ETH_CLIENT}",
    "consensus_client": "${CONSENSUS_CLIENT}",
    "base_dir": "${ETH_BASE_DIR}",
    "ports": {
        "rpc": ${ETH_RPC_PORT},
        "ws": ${ETH_WS_PORT},
        "engine": ${ETH_ENGINE_PORT},
        "p2p": ${ETH_P2P_PORT},
        "beacon_p2p": ${ETH_BEACON_P2P_PORT},
        "beacon_http": ${ETH_BEACON_HTTP_PORT},
        "metrics": ${ETH_METRICS_PORT}
    }
}
EOL
    
    echo -e "${GREEN}Configuration saved to ${ETH_CONFIG_FILE}${NC}"
}

create_execution_compose() {
    echo -e "${GREEN}Creating execution client Docker Compose file...${NC}"
    
    # The actual compose file creation is handled in the client-specific
    # configuration functions (configure_geth, configure_erigon, etc.)
    case $ETH_CLIENT in
        "geth"|"geth-pruned")
            configure_geth
            ;;
        "erigon"|"erigon-pruned")
            configure_erigon
            ;;
        "geth-archive")
            configure_geth_archive
            ;;
    esac
}

create_consensus_compose() {
    echo -e "${GREEN}Creating consensus client Docker Compose file...${NC}"
    
    # The actual compose file creation is handled in the client-specific
    # configuration functions (configure_lighthouse, configure_prysm)
    case $CONSENSUS_CLIENT in
        "lighthouse")
            configure_lighthouse
            ;;
        "prysm")
            configure_prysm
            ;;
    esac
}

setup_monitoring() {
    echo -e "${GREEN}Setting up monitoring...${NC}"
    
    # Create monitoring directory if it doesn't exist
    sudo mkdir -p "${ETH_MONITORING_DIR}"
    sudo chown -R "$USER:$USER" "${ETH_MONITORING_DIR}"
    
    echo -e "${GREEN}Monitoring setup completed.${NC}"
} 