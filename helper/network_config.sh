#!/bin/bash

# ===============================================================================
# PulseChain Node Network Configuration Switcher
# ===============================================================================
# This script manages network configuration parameters for optimizing your node
# It allows switching between local mode (for personal use) and public mode (for RPC endpoints)
# Version: 0.1.0
# ===============================================================================

# Colors for better formatting
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Determine installation path
if [ -z "$INSTALL_PATH" ]; then
    # Try to detect it
    if [ -d "/blockchain" ]; then
        INSTALL_PATH="/blockchain"
    else
        # Check if we can source the config file
        if [ -f "$(dirname $(dirname $0))/config.sh" ]; then
            source "$(dirname $(dirname $0))/config.sh"
            INSTALL_PATH="$CUSTOM_PATH"
        else
            echo -e "${RED}Error: Installation path could not be determined.${NC}"
            echo "Please set the INSTALL_PATH variable or run this from the node directory."
            exit 1
        fi
    fi
fi

# Configuration file paths
NET_CONFIG_DIR="$INSTALL_PATH/network_config"
LOCAL_CONFIG="$NET_CONFIG_DIR/local_network.conf"
PUBLIC_CONFIG="$NET_CONFIG_DIR/public_network.conf"
ACTIVE_CONFIG="$NET_CONFIG_DIR/active_network.conf"
MODE_INDICATOR="$NET_CONFIG_DIR/current_mode"

# Create config directory if it doesn't exist
mkdir -p "$NET_CONFIG_DIR"

# Function to display section headers
section() {
    echo ""
    echo -e "${BLUE}===== $1 =====${NC}"
    echo ""
}

# Create default local configuration (optimized for high-throughput local/VM access)
create_local_config() {
    cat > "$LOCAL_CONFIG" << EOF
# PulseChain Node - Local/VM Mode Network Configuration
# Optimized for high-throughput between local machine and VMs
# Last updated: $(date)

# Increase TCP buffer sizes for high throughput
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216

# Increase the maximum connections
net.core.somaxconn = 1024

# Improve handling of busy connections
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_fastopen = 3

# Optimize for throughput rather than latency
net.ipv4.tcp_congestion_control = cubic
EOF
}

# Create default public configuration (optimized for many external connections)
create_public_config() {
    cat > "$PUBLIC_CONFIG" << EOF
# PulseChain Node - Public Mode Network Configuration
# Optimized for handling many external connections (public RPC endpoint)
# Last updated: $(date)

# Increase TCP buffer sizes for high throughput
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216

# Optimize for many simultaneous connections
net.core.somaxconn = 4096
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_max_syn_backlog = 8096
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.ip_local_port_range = 1024 65535

# Improve handling of busy connections
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_fastopen = 3

# Congestion control for busy networks
net.ipv4.tcp_congestion_control = cubic

# Connection protection
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syncookies = 1
EOF
}

# Function to apply network configuration
apply_network_config() {
    local config_file="$1"
    if [ -f "$config_file" ]; then
        echo "Applying network configuration..."
        
        # Copy to sysctl.d directory for persistence
        sudo cp "$config_file" /etc/sysctl.d/99-pulsechain-network.conf
        
        # Apply settings
        sudo sysctl -p /etc/sysctl.d/99-pulsechain-network.conf
        
        # Create a symlink to active config
        ln -sf "$config_file" "$ACTIVE_CONFIG"
        
        echo -e "${GREEN}Network configuration applied successfully.${NC}"
        return 0
    else
        echo -e "${RED}Error: Configuration file not found.${NC}"
        return 1
    fi
}

# Function to switch network mode
switch_network_mode() {
    local mode="$1"
    
    case "$mode" in
        local)
            if [ ! -f "$LOCAL_CONFIG" ]; then
                create_local_config
            fi
            
            if apply_network_config "$LOCAL_CONFIG"; then
                echo "local" > "$MODE_INDICATOR"
                echo -e "${GREEN}Switched to LOCAL mode${NC}"
                echo "Network optimized for high-throughput local/VM access"
            fi
            ;;
        public)
            if [ ! -f "$PUBLIC_CONFIG" ]; then
                create_public_config
            fi
            
            if apply_network_config "$PUBLIC_CONFIG"; then
                echo "public" > "$MODE_INDICATOR"
                echo -e "${GREEN}Switched to PUBLIC mode${NC}"
                echo "Network optimized for handling many external connections"
            fi
            ;;
        *)
            echo -e "${RED}Invalid mode. Use 'local' or 'public'.${NC}"
            return 1
            ;;
    esac
}

# Function to show current network mode and configuration
show_network_mode() {
    if [ -f "$MODE_INDICATOR" ]; then
        local current_mode=$(cat "$MODE_INDICATOR")
        echo -e "Current network mode: ${GREEN}${current_mode^^}${NC}"
        
        if [ -f "$ACTIVE_CONFIG" ]; then
            echo ""
            echo "Active network configuration:"
            echo "-------------------------"
            cat "$ACTIVE_CONFIG" | grep -v "^#" | grep -v "^$"
        fi
    else
        echo "Network mode not set. Please run 'network_config.sh local' or 'network_config.sh public'"
    fi
}

# Display help information
show_help() {
    echo "PulseChain Node Network Configuration Switcher"
    echo "Usage: $0 [local|public|status|edit-local|edit-public]"
    echo ""
    echo "Options:"
    echo "  local       - Switch to local mode (optimized for high-throughput between your machine and VMs)"
    echo "  public      - Switch to public mode (optimized for handling many external connections)"
    echo "  status      - Show current network mode and configuration"
    echo "  edit-local  - Edit local mode configuration"
    echo "  edit-public - Edit public mode configuration"
    echo ""
    echo "Example: $0 local"
}

# Main function
main() {
    # Create configuration files if they don't exist
    if [ ! -f "$LOCAL_CONFIG" ]; then
        create_local_config
    fi
    
    if [ ! -f "$PUBLIC_CONFIG" ]; then
        create_public_config
    fi
    
    # Process command-line arguments
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi
    
    case "$1" in
        local|public)
            switch_network_mode "$1"
            ;;
        status)
            show_network_mode
            ;;
        edit-local)
            if command -v nano > /dev/null; then
                nano "$LOCAL_CONFIG"
            else
                vi "$LOCAL_CONFIG"
            fi
            ;;
        edit-public)
            if command -v nano > /dev/null; then
                nano "$PUBLIC_CONFIG"
            else
                vi "$PUBLIC_CONFIG"
            fi
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo -e "${RED}Invalid option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
}

# Run the main function with all arguments
main "$@" 