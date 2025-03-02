#!/bin/bash

# ===============================================================================
# PulseChain Node Dependencies Setup Script
# ===============================================================================
# This script installs and configures all dependencies required for a PulseChain node
# Including system updates, required packages, and VirtualBox integration
# Version: 0.1.0
# ===============================================================================

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

# Default to non-interactive mode if running in a script
INTERACTIVE=true
if [[ ! -t 0 ]]; then
    INTERACTIVE=false
fi

# Check for --yes flag
if [[ "$1" == "--yes" || "$1" == "-y" ]]; then
    AUTO_YES=true
else
    AUTO_YES=false
fi

# Function to prompt for yes/no confirmation
confirm() {
    if [[ "$AUTO_YES" == true ]]; then
        return 0
    fi
    
    if [[ "$INTERACTIVE" == false ]]; then
        echo "Non-interactive mode detected. Skipping confirmation."
        return 0
    fi
    
    local prompt="$1 (y/N): "
    local response
    
    read -p "$prompt" response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# Display script header
echo -e "${GREEN}PulseChain Node Dependencies Setup${NC}"
echo "======================================"
echo ""
echo "This script will install and configure all dependencies"
echo "required for running a PulseChain node on your system."
echo ""
echo "The following will be installed/configured:"
echo "1. System updates and essential packages"
echo "2. Docker and Docker Compose"
echo "3. VirtualBox Guest Additions (if running in VirtualBox)"
echo "4. Time synchronization"
echo "5. Performance optimizations"
echo "6. Network optimizations"
echo ""

if ! confirm "Do you want to continue?"; then
    echo "Setup cancelled."
    exit 0
fi

# ===============================================================================
# System Updates
# ===============================================================================
section "System Updates"

echo "Checking for and installing system updates..."
if confirm "Do you want to update system packages?"; then
    sudo apt-get update
    if confirm "Do you want to upgrade all packages? (This may take some time)"; then
        sudo apt-get upgrade -y
    fi
fi

# ===============================================================================
# Essential Packages
# ===============================================================================
section "Essential Packages"

ESSENTIAL_PACKAGES=(
    apt-transport-https
    ca-certificates
    curl
    gnupg
    lsb-release
    software-properties-common
    git
    jq
    htop
    ufw
    tmux
    vim
    net-tools
    ntp
    ntpdate
    dialog
    python3
    python3-pip
)

echo "Checking for essential packages..."
MISSING_PACKAGES=()

for pkg in "${ESSENTIAL_PACKAGES[@]}"; do
    if ! dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "ok installed"; then
        MISSING_PACKAGES+=("$pkg")
    fi
done

if [[ ${#MISSING_PACKAGES[@]} -gt 0 ]]; then
    echo "The following packages need to be installed:"
    printf "  %s\n" "${MISSING_PACKAGES[@]}"
    
    if confirm "Install these packages?"; then
        sudo apt-get install -y "${MISSING_PACKAGES[@]}"
        echo -e "${GREEN}Essential packages installed.${NC}"
    else
        echo -e "${YELLOW}Skipping package installation. This may cause issues later.${NC}"
    fi
else
    echo -e "${GREEN}All essential packages are already installed.${NC}"
fi

# ===============================================================================
# Docker Installation
# ===============================================================================
section "Docker Installation"

if command_exists docker && command_exists docker-compose; then
    echo -e "${GREEN}Docker and Docker Compose are already installed.${NC}"
    
    # Check Docker version
    DOCKER_VERSION=$(docker --version | awk '{print $3}' | sed 's/,//')
    echo "Docker version: $DOCKER_VERSION"
    
    if [[ "$(echo "$DOCKER_VERSION" | awk -F'.' '{print $1}')" -lt 20 ]]; then
        echo -e "${YELLOW}Warning: Docker version is older than recommended (20.0+).${NC}"
        if confirm "Would you like to update Docker?"; then
            echo "Removing old Docker version..."
            sudo apt-get remove docker docker-engine docker.io containerd runc -y
            
            echo "Installing latest Docker version..."
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose
            
            echo -e "${GREEN}Docker has been updated.${NC}"
        fi
    fi
else
    echo "Docker and/or Docker Compose not found. Installing..."
    
    # Remove old versions
    sudo apt-get remove docker docker-engine docker.io containerd runc -y
    
    # Set up repository
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker Engine
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose
    
    # Enable and start Docker
    sudo systemctl enable docker
    sudo systemctl start docker
    
    # Add current user to Docker group
    CURRENT_USER=$(whoami)
    if confirm "Add user $CURRENT_USER to the docker group? (Recommended)"; then
        sudo usermod -aG docker "$CURRENT_USER"
        echo -e "${YELLOW}Note: You'll need to log out and back in for this change to take effect.${NC}"
    fi
    
    echo -e "${GREEN}Docker and Docker Compose have been installed.${NC}"
fi

# ===============================================================================
# VirtualBox Guest Additions
# ===============================================================================
section "VirtualBox Integration"

# Check if running in VirtualBox
if dmesg | grep -i "virtualbox" > /dev/null; then
    echo "VirtualBox detected. Checking Guest Additions..."
    
    # Check if VBoxClient exists
    if command_exists VBoxClient; then
        echo -e "${GREEN}VirtualBox Guest Additions is already installed.${NC}"
        
        # Setup systemd service for clipboard if it doesn't exist
        if [ ! -f /etc/systemd/system/vboxclient-clipboard.service ]; then
            echo "Setting up persistent clipboard service..."
            
            # Create systemd service for clipboard sharing
            sudo tee /etc/systemd/system/vboxclient-clipboard.service > /dev/null << EOF
[Unit]
Description=VirtualBox Clipboard Service
After=vboxadd.service
ConditionVirtualization=oracle

[Service]
Type=simple
ExecStart=/usr/bin/VBoxClient --clipboard
Restart=on-failure
RestartSec=5
User=$(whoami)

[Install]
WantedBy=multi-user.target
EOF
            
            # Enable and start the clipboard service
            sudo systemctl enable vboxclient-clipboard.service
            sudo systemctl start vboxclient-clipboard.service
            
            echo -e "${GREEN}Clipboard service installed and started.${NC}"
        else
            # Check if clipboard service is active
            if ! systemctl is-active --quiet vboxclient-clipboard.service; then
                echo "Clipboard service exists but is not running."
                sudo systemctl start vboxclient-clipboard.service
                echo -e "${GREEN}Clipboard service started.${NC}"
            else
                echo -e "${GREEN}Clipboard service is already running.${NC}"
            fi
        fi

        # Also check if the VBoxClient clipboard process is running (as a backup)
        if ! pgrep -f "VBoxClient --clipboard" > /dev/null; then
            echo "Starting clipboard sharing now..."
            VBoxClient --clipboard
            echo -e "${GREEN}Clipboard sharing started.${NC}"
        else
            echo -e "${GREEN}VBoxClient clipboard process is already running.${NC}"
        fi
        
        # Test clipboard functionality
        echo -e "${YELLOW}Testing clipboard functionality...${NC}"
        echo "test_clipboard_text" | xclip -selection clipboard 2>/dev/null || true
        echo -e "${YELLOW}Try pasting in your host system to verify clipboard is working.${NC}"
        
    else
        echo "VirtualBox Guest Additions not found."
        if confirm "Automatically download and install VirtualBox Guest Additions?"; then
            # Install dependencies
            echo "Installing dependencies..."
            sudo apt-get update
            sudo apt-get install -y dkms build-essential linux-headers-$(uname -r) \
                                   wget xclip bzip2 unzip

            # Get VirtualBox version
            echo "Detecting VirtualBox version..."
            vbox_version=$(dmesg | grep -i "virtualbox" | head -n 1 | grep -o "BIOS.*" | cut -d' ' -f2)
            
            if [ -z "$vbox_version" ]; then
                # Alternative detection method
                vbox_version=$(sudo dmidecode -t system | grep -i "virtualbox" | grep -o "Version.*" | cut -d' ' -f2 | cut -d'_' -f1)
            fi
            
            if [ -z "$vbox_version" ]; then
                # If still can't detect, use latest version
                echo "Could not detect VirtualBox version, using latest..."
                vbox_version=$(wget -qO- https://download.virtualbox.org/virtualbox/LATEST.TXT)
            fi
            
            echo "Detected VirtualBox version: $vbox_version"
            
            # Create temp directory
            temp_dir=$(mktemp -d)
            cd "$temp_dir"
            
            # Download Guest Additions ISO
            echo "Downloading VirtualBox Guest Additions ISO..."
            iso_url="https://download.virtualbox.org/virtualbox/$vbox_version/VBoxGuestAdditions_$vbox_version.iso"
            wget "$iso_url" -O VBoxGuestAdditions.iso
            
            if [ ! -f VBoxGuestAdditions.iso ]; then
                echo -e "${RED}Failed to download Guest Additions ISO.${NC}"
                echo "Trying alternative download method with latest version..."
                
                # Get latest version
                latest_version=$(wget -qO- https://download.virtualbox.org/virtualbox/LATEST.TXT)
                iso_url="https://download.virtualbox.org/virtualbox/$latest_version/VBoxGuestAdditions_$latest_version.iso"
                wget "$iso_url" -O VBoxGuestAdditions.iso
                
                if [ ! -f VBoxGuestAdditions.iso ]; then
                    echo -e "${RED}Failed to download Guest Additions ISO with alternative method.${NC}"
                    echo "Please try manual installation."
                    cd
                    rm -rf "$temp_dir"
                    exit 1
                fi
            fi
            
            # Mount ISO
            echo "Mounting Guest Additions ISO..."
            mkdir -p iso
            sudo mount -o loop VBoxGuestAdditions.iso iso
            
            # Install Guest Additions
            echo "Installing Guest Additions..."
            cd iso
            sudo ./VBoxLinuxAdditions.run --nox11
            cd ..
            
            # Cleanup
            sudo umount iso
            cd
            rm -rf "$temp_dir"
            
            # Setup clipboard service
            echo "Setting up persistent clipboard service..."
            
            # Create systemd service for clipboard sharing
            sudo tee /etc/systemd/system/vboxclient-clipboard.service > /dev/null << EOF
[Unit]
Description=VirtualBox Clipboard Service
After=vboxadd.service
ConditionVirtualization=oracle

[Service]
Type=simple
ExecStart=/usr/bin/VBoxClient --clipboard
Restart=on-failure
RestartSec=5
User=$(whoami)

[Install]
WantedBy=multi-user.target
EOF
            
            # Enable and start the clipboard service
            sudo systemctl enable vboxclient-clipboard.service
            sudo systemctl start vboxclient-clipboard.service
            
            echo -e "${GREEN}VirtualBox Guest Additions installed successfully!${NC}"
            echo -e "${GREEN}Clipboard service installed and started.${NC}"
            echo -e "${YELLOW}Note: A system reboot is recommended for all features to work properly.${NC}"
            
            if confirm "Would you like to reboot now?"; then
                sudo reboot
            fi
        else
            echo "Skipping Guest Additions installation."
        fi
    fi
else
    echo "This system is not running in VirtualBox. Skipping Guest Additions setup."
fi

# ===============================================================================
# Time Synchronization
# ===============================================================================
section "Time Synchronization"

echo "Setting up time synchronization (essential for blockchain nodes)..."

# Check current timezone and NTP status
CURRENT_TZ=$(timedatectl | grep "Time zone" | awk '{print $3}')
NTP_ENABLED=$(timedatectl | grep "NTP service" | awk '{print $4}')

echo "Current timezone: $CURRENT_TZ"
echo "NTP service: $NTP_ENABLED"

if [[ "$NTP_ENABLED" != "active" ]]; then
    echo "NTP service is not active."
    if confirm "Enable NTP time synchronization?"; then
        sudo timedatectl set-ntp true
        echo -e "${GREEN}NTP time synchronization enabled.${NC}"
    fi
fi

if confirm "Would you like to set your timezone?"; then
    # Show current timezone and offer to change
    echo "Your current timezone is: $CURRENT_TZ"
    sudo dpkg-reconfigure tzdata
    echo -e "${GREEN}Timezone updated.${NC}"
fi

# Sync time immediately
if confirm "Synchronize time now?"; then
    if command_exists ntpdate; then
        sudo ntpdate -u pool.ntp.org
    else
        # Alternative time sync method
        sudo systemctl restart systemd-timesyncd
    fi
    echo -e "${GREEN}Time synchronized.${NC}"
fi

# ===============================================================================
# Performance Optimization
# ===============================================================================
section "Performance Optimization"

echo "Setting up performance optimizations..."

# Adjust file handle limits
if grep -q "fs.file-max" /etc/sysctl.conf; then
    echo "File handle limits already configured."
else
    echo "Configuring file handle limits..."
    echo "fs.file-max = 500000" | sudo tee -a /etc/sysctl.conf
fi

# Configure swappiness based on available RAM
total_ram=$(free -m | awk '/^Mem:/{print $2}')
if [ $total_ram -gt 32000 ]; then
    # For systems with >32GB RAM, disable swap
    swappiness=0
elif [ $total_ram -gt 16000 ]; then
    # For systems with 16-32GB RAM, minimal swapping
    swappiness=10
else
    # For systems with <16GB RAM, moderate swapping
    swappiness=30
fi

echo "Setting swappiness to $swappiness based on $total_ram MB RAM..."
if grep -q "vm.swappiness" /etc/sysctl.conf; then
    sudo sed -i "s/vm.swappiness.*/vm.swappiness = $swappiness/" /etc/sysctl.conf
else
    echo "vm.swappiness = $swappiness" | sudo tee -a /etc/sysctl.conf
fi

# ===============================================================================
# Network Optimization
# ===============================================================================
section "Network Optimization"

echo "Setting up network optimizations..."

# Create the network_config directory
INSTALL_PATH=${INSTALL_PATH:-/blockchain}
mkdir -p "$INSTALL_PATH/network_config"

# Default to local mode for standard setups
echo "Would you like to optimize network settings for:"
echo "1) Local Mode (default) - For personal use and VM access"
echo "2) Public Mode - For public RPC endpoints with many connections"
read -p "Enter your choice [1/2] (default: 1): " network_mode
network_mode=${network_mode:-1}

if [ "$network_mode" == "1" ]; then
    # Create local config (optimized for high-throughput local/VM access)
    cat > "$INSTALL_PATH/network_config/local_network.conf" << EOF
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
    
    # Apply local settings
    sudo cp "$INSTALL_PATH/network_config/local_network.conf" /etc/sysctl.d/99-pulsechain-network.conf
    sudo sysctl -p /etc/sysctl.d/99-pulsechain-network.conf
    
    # Create symlink to active config
    ln -sf "$INSTALL_PATH/network_config/local_network.conf" "$INSTALL_PATH/network_config/active_network.conf"
    
    # Set current mode indicator
    echo "local" > "$INSTALL_PATH/network_config/current_mode"
    
    echo -e "${GREEN}Network optimized for local/VM usage.${NC}"
    
elif [ "$network_mode" == "2" ]; then
    # Create public config (optimized for many external connections)
    cat > "$INSTALL_PATH/network_config/public_network.conf" << EOF
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
    
    # Apply public settings
    sudo cp "$INSTALL_PATH/network_config/public_network.conf" /etc/sysctl.d/99-pulsechain-network.conf
    sudo sysctl -p /etc/sysctl.d/99-pulsechain-network.conf
    
    # Create symlink to active config
    ln -sf "$INSTALL_PATH/network_config/public_network.conf" "$INSTALL_PATH/network_config/active_network.conf"
    
    # Set current mode indicator
    echo "public" > "$INSTALL_PATH/network_config/current_mode"
    
    echo -e "${GREEN}Network optimized for public RPC endpoint usage.${NC}"
fi

# Also create the opposite config for future switching
if [ "$network_mode" == "1" ]; then
    # Create public config for future use
    cat > "$INSTALL_PATH/network_config/public_network.conf" << EOF
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
elif [ "$network_mode" == "2" ]; then
    # Create local config for future use
    cat > "$INSTALL_PATH/network_config/local_network.conf" << EOF
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
fi

echo -e "${YELLOW}Note: You can switch between network modes anytime using the menu system.${NC}"
echo -e "${YELLOW}Run: plsmenu -> System Menu -> Network Configuration${NC}"
echo -e "${GREEN}Network optimization complete!${NC}"

# ===============================================================================
# Completion
# ===============================================================================
section "Setup Complete"

echo -e "${GREEN}All dependencies have been installed and configured.${NC}"
echo ""
echo "Summary of changes:"
echo "✓ System packages updated"
echo "✓ Essential packages installed"
echo "✓ Docker and Docker Compose configured"
if dmesg | grep -i "virtualbox" > /dev/null; then
    echo "✓ VirtualBox integration configured"
fi
echo "✓ Time synchronization set up"
echo "✓ Performance optimizations applied"
echo "✓ Network optimizations applied"
echo ""
echo "Your system is now ready to run a PulseChain node!"
echo ""

if [[ "$INTERACTIVE" == true ]]; then
    read -p "Press Enter to exit..."
fi

exit 0 