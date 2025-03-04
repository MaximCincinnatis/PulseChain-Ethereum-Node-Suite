#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}PulseChain/Ethereum Node Setup${NC}"
echo "================================"

# Define specific versions for dependencies
DOCKER_VERSION="24.0.7"
DOCKER_COMPOSE_VERSION="2.23.3"
MINIMUM_DOCKER_VERSION="20.10.0"
MINIMUM_COMPOSE_VERSION="2.20.0"

# Function to compare versions
version_gt() {
    test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"
}

# Function to validate Docker version
validate_docker_version() {
    local current_version=$(docker --version | cut -d ' ' -f3 | tr -d ',v')
    if version_gt "$MINIMUM_DOCKER_VERSION" "$current_version"; then
        echo -e "${RED}Error: Docker version $current_version is below minimum required version $MINIMUM_DOCKER_VERSION${NC}"
        return 1
    fi
    return 0
}

# Function to validate Docker Compose version
validate_compose_version() {
    local current_version=$(docker-compose --version | cut -d ' ' -f3 | tr -d ',v')
    if version_gt "$MINIMUM_COMPOSE_VERSION" "$current_version"; then
        echo -e "${RED}Error: Docker Compose version $current_version is below minimum required version $MINIMUM_COMPOSE_VERSION${NC}"
        return 1
    fi
    return 0
}

# Function to install Docker with specific version
install_docker() {
    echo "Checking Docker installation..."
    if ! command -v docker &> /dev/null; then
        echo "Installing Docker version $DOCKER_VERSION..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        # Modify the script to install specific version
        sed -i "s/VERSION_STRING=.*/VERSION_STRING=\"$DOCKER_VERSION\"/" get-docker.sh
        sudo sh get-docker.sh
        rm get-docker.sh
        
        # Verify installation
        if ! validate_docker_version; then
            echo -e "${RED}Docker installation failed or version requirements not met${NC}"
            exit 1
        fi
    else
        echo "Docker is already installed"
        # Validate existing version
        if ! validate_docker_version; then
            echo -e "${YELLOW}Warning: Installed Docker version does not meet minimum requirements${NC}"
            echo "Would you like to upgrade Docker? (y/n)"
            read -r upgrade_docker
            if [[ "$upgrade_docker" =~ ^[Yy]$ ]]; then
                sudo apt-get update
                sudo apt-get install -y docker-ce=$DOCKER_VERSION docker-ce-cli=$DOCKER_VERSION containerd.io
            else
                echo -e "${RED}Cannot proceed with incompatible Docker version${NC}"
                exit 1
            fi
        fi
    fi
}

# Function to install Docker Compose with specific version
install_docker_compose() {
    echo "Checking Docker Compose installation..."
    if ! command -v docker-compose &> /dev/null; then
        echo "Installing Docker Compose version $DOCKER_COMPOSE_VERSION..."
        sudo curl -L "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        
        # Verify installation
        if ! validate_compose_version; then
            echo -e "${RED}Docker Compose installation failed or version requirements not met${NC}"
            exit 1
        fi
    else
        echo "Docker Compose is already installed"
        # Validate existing version
        if ! validate_compose_version; then
            echo -e "${YELLOW}Warning: Installed Docker Compose version does not meet minimum requirements${NC}"
            echo "Would you like to upgrade Docker Compose? (y/n)"
            read -r upgrade_compose
            if [[ "$upgrade_compose" =~ ^[Yy]$ ]]; then
                sudo rm -f /usr/local/bin/docker-compose
                sudo curl -L "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
                sudo chmod +x /usr/local/bin/docker-compose
            else
                echo -e "${RED}Cannot proceed with incompatible Docker Compose version${NC}"
                exit 1
            fi
        fi
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
            install_docker_compose
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