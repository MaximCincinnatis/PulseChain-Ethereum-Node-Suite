#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}PulseChain/Ethereum Node Setup${NC}"
echo "================================"

# Function to install Docker and Docker Compose
install_docker() {
    echo "Checking Docker installation..."
    if ! command -v docker &> /dev/null; then
        echo "Installing Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        rm get-docker.sh
    else
        echo "Docker is already installed"
    fi

    echo "Checking Docker Compose installation..."
    if ! command -v docker-compose &> /dev/null; then
        echo "Installing Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    else
        echo "Docker Compose is already installed"
    fi
}

# Function to check system requirements
check_system_requirements() {
    echo -e "\n${GREEN}Checking System Requirements...${NC}"
    
    # Check CPU cores
    cpu_cores=$(nproc)
    echo -n "CPU Cores: $cpu_cores - "
    if [ "$cpu_cores" -lt 4 ]; then
        echo -e "${RED}WARNING: Minimum 4 CPU cores recommended${NC}"
        read -p "Continue anyway? (y/n): " continue_setup
        if [[ "$continue_setup" != "y" && "$continue_setup" != "Y" ]]; then
            exit 1
        fi
    else
        echo -e "${GREEN}OK${NC}"
    fi
    
    # Check RAM
    total_ram=$(free -g | awk '/^Mem:/{print $2}')
    echo -n "RAM: ${total_ram}GB - "
    if [ "$total_ram" -lt 16 ]; then
        echo -e "${RED}WARNING: Minimum 16GB RAM recommended${NC}"
        read -p "Continue anyway? (y/n): " continue_setup
        if [[ "$continue_setup" != "y" && "$continue_setup" != "Y" ]]; then
            exit 1
        fi
    else
        echo -e "${GREEN}OK${NC}"
    fi
    
    # Check disk space
    free_space=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    echo -n "Free Disk Space: ${free_space}GB - "
    if [ "$free_space" -lt 2000 ]; then
        echo -e "${RED}WARNING: Minimum 2TB free space recommended${NC}"
        read -p "Continue anyway? (y/n): " continue_setup
        if [[ "$continue_setup" != "y" && "$continue_setup" != "Y" ]]; then
            exit 1
        fi
    else
        echo -e "${GREEN}OK${NC}"
    fi
}

# Function to select installation method
select_installation_method() {
    echo -e "\n${GREEN}Select Installation Method:${NC}"
    echo "1) Docker Compose (Recommended)"
    echo "2) Traditional Installation"
    read -p "Enter your choice (1/2): " install_choice

    case $install_choice in
        1)
            install_docker
            if [ -f "start-with-docker-compose.sh" ]; then
                chmod +x start-with-docker-compose.sh
                ./start-with-docker-compose.sh
            else
                echo -e "${RED}Error: Docker Compose setup script not found${NC}"
                exit 1
            fi
            ;;
        2)
            if [ -f "setup_traditional.sh" ]; then
                chmod +x setup_traditional.sh
                ./setup_traditional.sh
            else
                echo -e "${RED}Error: Traditional setup script not found${NC}"
                exit 1
            fi
            ;;
        *)
            echo -e "${RED}Invalid choice. Exiting.${NC}"
            exit 1
            ;;
    esac
}

# Main setup flow
check_system_requirements
select_installation_method

echo -e "${GREEN}Setup completed!${NC}" 