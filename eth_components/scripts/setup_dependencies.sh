#!/bin/bash

# ===============================================================================
# Ethereum Node Dependencies Setup Script
# ===============================================================================
# Version: 0.1.0
# Description: Installs and configures all dependencies required for Ethereum node
# ===============================================================================

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config/eth_config.sh"

# Colors for better formatting
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display section headers
section() {
    echo ""
    echo -e "${BLUE}===== $1 =====${NC}"
    echo ""
}

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to check system requirements
check_system_requirements() {
    section "Checking System Requirements"
    
    # Check RAM
    local total_ram=$(grep MemTotal /proc/meminfo | awk '{print $2/1024/1024}')
    if (( $(echo "$total_ram < $ETH_MIN_RAM_GB" | bc -l) )); then
        echo -e "${RED}Error: Insufficient RAM. ${ETH_MIN_RAM_GB}GB required, ${total_ram}GB available.${NC}"
        exit 1
    fi
    
    # Check Storage
    local free_storage=$(df -BG "${ETH_BASE_DIR%/*}" | awk 'NR==2 {print $4}' | sed 's/G//')
    if (( free_storage < ETH_MIN_STORAGE_GB )); then
        echo -e "${RED}Error: Insufficient storage. ${ETH_MIN_STORAGE_GB}GB required, ${free_storage}GB available.${NC}"
        exit 1
    fi
    
    # Check CPU cores
    local cpu_cores=$(nproc)
    if (( cpu_cores < ETH_MIN_CPU_CORES )); then
        echo -e "${RED}Error: Insufficient CPU cores. ${ETH_MIN_CPU_CORES} required, ${cpu_cores} available.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}System requirements met.${NC}"
}

# Function to install system packages
install_system_packages() {
    section "Installing System Packages"
    
    # Update package lists
    sudo apt-get update
    
    # Install required packages
    sudo apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        git \
        ufw \
        tmux \
        dialog \
        rhash \
        openssl \
        jq \
        lsb-release \
        python3.8 \
        python3.8-venv \
        python3.8-dev \
        python3-pip \
        chrony
        
    echo -e "${GREEN}System packages installed successfully.${NC}"
}

# Function to install and configure Docker
setup_docker() {
    section "Setting up Docker"
    
    if ! command_exists docker; then
        # Add Docker's official GPG key
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        
        # Add Docker repository
        echo \
        "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        # Install Docker
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose
        
        # Start and enable Docker service
        sudo systemctl start docker
        sudo systemctl enable docker
        
        # Add current user to docker group
        sudo usermod -aG docker "$USER"
        
        echo -e "${GREEN}Docker installed successfully.${NC}"
    else
        echo -e "${YELLOW}Docker is already installed.${NC}"
    fi
}

# Function to configure time synchronization
setup_time_sync() {
    section "Configuring Time Synchronization"
    
    # Install and configure chrony
    sudo systemctl start chrony
    sudo systemctl enable chrony
    
    # Add Ethereum time servers
    echo "server time.google.com iburst" | sudo tee -a /etc/chrony/chrony.conf
    echo "server time.cloudflare.com iburst" | sudo tee -a /etc/chrony/chrony.conf
    
    # Restart chrony
    sudo systemctl restart chrony
    
    echo -e "${GREEN}Time synchronization configured.${NC}"
}

# Function to optimize system settings
optimize_system() {
    section "Optimizing System Settings"
    
    # Increase file descriptor limits
    echo "* soft nofile 1048576" | sudo tee -a /etc/security/limits.conf
    echo "* hard nofile 1048576" | sudo tee -a /etc/security/limits.conf
    
    # Optimize network settings
    cat > /etc/sysctl.d/99-ethereum-node.conf << EOL
# Increase system IP port limits
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_tw_reuse = 1

# Increase Linux autotuning TCP buffer limits
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216

# Increase the maximum amount of option memory buffers
net.core.optmem_max = 40960

# Increase the TCP receive buffer size
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216

# Increase number of incoming connections backlog
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 65536

# Increase TCP max sync backlog
net.ipv4.tcp_max_syn_backlog = 65536

# Increase memory thresholds to prevent packet dropping
net.ipv4.tcp_mem = 65536 131072 262144
EOL
    
    # Apply sysctl settings
    sudo sysctl -p /etc/sysctl.d/99-ethereum-node.conf
    
    echo -e "${GREEN}System optimizations applied.${NC}"
}

# Function to create required directories
setup_directories() {
    section "Creating Required Directories"
    
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

# Main setup function
main() {
    echo -e "${GREEN}Ethereum Node Dependencies Setup${NC}"
    echo "======================================"
    
    # Run setup steps
    check_system_requirements
    install_system_packages
    setup_docker
    setup_time_sync
    optimize_system
    setup_directories
    
    echo -e "${GREEN}Dependencies setup completed successfully!${NC}"
    echo "Please log out and back in for group changes to take effect."
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi 