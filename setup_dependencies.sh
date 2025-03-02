#!/bin/bash

# ===============================================================================
# PulseChain Node Dependencies Setup Script
# ===============================================================================
# This script installs and configures all dependencies required for a PulseChain node
# Including system updates, required packages, and VirtualBox integration
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
        echo "VirtualBox Guest Additions is installed."
        
        # Check clipboard status
        if ! pgrep -f "VBoxClient --clipboard" > /dev/null; then
            echo "VirtualBox clipboard sharing is not running."
            if confirm "Start clipboard sharing?"; then
                VBoxClient --clipboard
                echo -e "${GREEN}Clipboard sharing started.${NC}"
            fi
            
            # Ask to set up clipboard sharing to start automatically
            if confirm "Set up clipboard sharing to start automatically at login?"; then
                # Create autostart file
                mkdir -p ~/.config/autostart
                cat > ~/.config/autostart/vbox-clipboard.desktop << EOF
[Desktop Entry]
Type=Application
Exec=VBoxClient --clipboard
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=VirtualBox Clipboard Sharing
Comment=Enables clipboard sharing with the host OS
EOF
                echo -e "${GREEN}Clipboard sharing will now start automatically at login.${NC}"
            fi
        else
            echo -e "${GREEN}VirtualBox clipboard sharing is already running.${NC}"
        fi
    else
        echo "VirtualBox Guest Additions not found."
        if confirm "Install VirtualBox Guest Additions?"; then
            # Install dependencies
            sudo apt-get install -y dkms build-essential linux-headers-$(uname -r)
            
            # Mount VBoxGuestAdditions
            echo "Please insert the VirtualBox Guest Additions CD image in VirtualBox"
            echo "(Devices -> Insert Guest Additions CD image...)"
            if confirm "Have you inserted the Guest Additions CD?"; then
                # Try to mount the CD
                sudo mkdir -p /mnt/cdrom
                sudo mount /dev/cdrom /mnt/cdrom
                
                # Run the installer
                cd /mnt/cdrom
                sudo ./VBoxLinuxAdditions.run
                
                # Clean up
                cd -
                sudo umount /mnt/cdrom
                
                echo -e "${GREEN}VirtualBox Guest Additions installed. Please reboot your system.${NC}"
                if confirm "Would you like to reboot now?"; then
                    sudo reboot
                fi
            else
                echo "Skipping Guest Additions installation."
            fi
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
# Performance Optimizations
# ===============================================================================
section "Performance Optimizations"

# Adjust maximum file handles
if confirm "Increase system file handle limits? (Recommended for nodes)"; then
    if ! grep -q "fs.file-max" /etc/sysctl.conf; then
        echo "fs.file-max = 500000" | sudo tee -a /etc/sysctl.conf
    else
        sudo sed -i 's/fs.file-max = .*/fs.file-max = 500000/' /etc/sysctl.conf
    fi
    
    if ! grep -q "* soft nofile" /etc/security/limits.conf; then
        echo "* soft nofile 65535" | sudo tee -a /etc/security/limits.conf
        echo "* hard nofile 65535" | sudo tee -a /etc/security/limits.conf
    fi
    
    sudo sysctl -p
    echo -e "${GREEN}File handle limits increased.${NC}"
fi

# Adjust swappiness for better performance with large memory systems
if confirm "Optimize memory swappiness settings? (Recommended)"; then
    # Get total RAM in GB
    TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    TOTAL_RAM_GB=$((TOTAL_RAM_KB / 1024 / 1024))
    
    # Set swappiness based on available RAM
    if [[ $TOTAL_RAM_GB -ge 32 ]]; then
        # Very low swappiness for high-RAM systems
        SWAPPINESS=1
    elif [[ $TOTAL_RAM_GB -ge 16 ]]; then
        # Low swappiness for medium-high RAM
        SWAPPINESS=10
    elif [[ $TOTAL_RAM_GB -ge 8 ]]; then
        # Moderate swappiness for medium RAM
        SWAPPINESS=20
    else
        # Default for lower RAM systems
        SWAPPINESS=60
    fi
    
    # Update swappiness
    if ! grep -q "vm.swappiness" /etc/sysctl.conf; then
        echo "vm.swappiness = $SWAPPINESS" | sudo tee -a /etc/sysctl.conf
    else
        sudo sed -i "s/vm.swappiness = .*/vm.swappiness = $SWAPPINESS/" /etc/sysctl.conf
    fi
    
    sudo sysctl -p
    echo -e "${GREEN}Memory swappiness set to $SWAPPINESS.${NC}"
fi

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
echo ""
echo "Your system is now ready to run a PulseChain node!"
echo ""

if [[ "$INTERACTIVE" == true ]]; then
    read -p "Press Enter to exit..."
fi

exit 0 