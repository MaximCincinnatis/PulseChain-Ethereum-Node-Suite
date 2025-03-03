#!/bin/bash

# ===============================================================================
# Node Setup Menu Script
# ===============================================================================
# Version: 0.1.0
# Description: Unified menu for choosing between PulseChain and Ethereum node setup
# ===============================================================================

# Define color codes for better readability
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Store script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ===============================================================================
# Helper Functions
# ===============================================================================

display_header() {
    clear
    echo "╔════════════════════════════════════════════╗"
    echo "║          Blockchain Node Setup             ║"
    echo "╚════════════════════════════════════════════╝"
    echo ""
}

display_main_menu() {
    echo "Please choose which blockchain node to set up:"
    echo ""
    echo "┌────────────────────────────────────┐"
    echo "│ 1) PulseChain Node                 │"
    echo "│    - Full node setup               │"
    echo "│    - Archive node options          │"
    echo "│    - Monitoring included           │"
    echo "│                                    │"
    echo "│ 2) Ethereum Node                   │"
    echo "│    - Full node setup               │"
    echo "│    - Multiple client options       │"
    echo "│    - Monitoring included           │"
    echo "│                                    │"
    echo "│ 3) Quick Start (Advanced)          │"
    echo "│    - Default configuration         │"
    echo "│    - Minimal interaction           │"
    echo "│    - For experienced users         │"
    echo "│                                    │"
    echo "│ 4) View Documentation             │"
    echo "│                                    │"
    echo "│ 5) Exit                           │"
    echo "└────────────────────────────────────┘"
    echo ""
}

display_warning() {
    echo -e "${YELLOW}"
    echo "┌─────────────────────────────────────────────────────────┐"
    echo "│                      WARNING                            │"
    echo "├─────────────────────────────────────────────────────────┤"
    echo "│ Running multiple blockchain nodes on the same machine   │"
    echo "│ is not recommended unless you have significant          │"
    echo "│ hardware resources available.                          │"
    echo "│                                                        │"
    echo "│ Please ensure you run only one node setup at a time    │"
    echo "│ unless you know what you're doing.                     │"
    echo "└─────────────────────────────────────────────────────────┘"
    echo -e "${NC}"
    echo ""
    read -p "Press Enter to continue..."
}

check_existing_installation() {
    local node_type=$1
    local config_file=""
    
    case $node_type in
        "pulse")
            config_file="${CUSTOM_PATH:-/blockchain}/node_config.json"
            ;;
        "eth")
            config_file="${CUSTOM_PATH:-/blockchain}/ethereum/eth_node_config.json"
            ;;
    esac
    
    if [[ -f "$config_file" ]]; then
        echo -e "${YELLOW}Warning: Existing $node_type node configuration detected.${NC}"
        echo "Running another node setup might conflict with the existing installation."
        echo ""
        read -p "Do you want to continue anyway? (y/n): " continue_setup
        if [[ "$continue_setup" != "y" && "$continue_setup" != "Y" ]]; then
            echo "Setup aborted."
            exit 1
        fi
    fi
}

# ===============================================================================
# Main Menu Logic
# ===============================================================================

# Add quick start function
quick_start_setup() {
    echo -e "${YELLOW}Quick Start Setup - Advanced Mode${NC}"
    echo "This will set up a node with default configuration."
    echo "Only use this if you're familiar with the setup process."
    echo
    
    # Create default configuration
    cat > /blockchain/node_config.json << EOL
{
    "network": "mainnet",
    "execution_client": "geth",
    "consensus_client": "lighthouse",
    "monitoring_enabled": true,
    "auto_update": true,
    "network_mode": "local",
    "data_directory": "/blockchain/data",
    "log_level": "info",
    "execution_port": 8545,
    "consensus_port": 5052,
    "grafana_port": 3000,
    "prometheus_port": 9090,
    "metrics_enabled": true,
    "p2p_port": 30303,
    "max_peers": 50,
    "cache_size": 4096
}
EOL
    
    # Validate configuration
    if ! validate_configuration; then
        echo -e "${RED}Configuration validation failed. Aborting quick start.${NC}"
        return 1
    fi
    
    # Run setup with minimal interaction
    ./setup_pulse_node.sh --quick-start
}

# Update main menu logic
main() {
    while true; do
        display_header
        display_main_menu
        
        read -p "Enter your choice (1-5): " choice
        
        case $choice in
            1)
                check_existing_installation "pulse"
                display_warning
                echo "Starting PulseChain node setup..."
                bash "${SCRIPT_DIR}/setup_pulse_node_improved.sh"
                exit 0
                ;;
            2)
                check_existing_installation "eth"
                display_warning
                echo "Starting Ethereum node setup..."
                bash "${SCRIPT_DIR}/eth_components/scripts/setup_eth_node.sh"
                exit 0
                ;;
            3)
                echo -e "${YELLOW}Warning: Quick Start mode is for advanced users only.${NC}"
                read -p "Are you sure you want to continue? (y/n): " confirm
                if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                    quick_start_setup
                    exit 0
                fi
                ;;
            4)
                echo "Opening documentation..."
                if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
                    start "${SCRIPT_DIR}/docs/README.md"
                elif [[ "$OSTYPE" == "darwin"* ]]; then
                    open "${SCRIPT_DIR}/docs/README.md"
                else
                    xdg-open "${SCRIPT_DIR}/docs/README.md"
                fi
                ;;
            5)
                echo "Exiting..."
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice. Please select 1-5.${NC}"
                sleep 2
                ;;
        esac
    done
}

# Run main function
main 