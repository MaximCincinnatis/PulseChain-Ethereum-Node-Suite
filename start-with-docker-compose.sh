#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Docker Compose Setup${NC}"
echo "===================="

# Function to select network
select_network() {
    echo -e "\n${GREEN}Select Network:${NC}"
    echo "1) PulseChain"
    echo "2) Ethereum"
    read -p "Enter your choice (1/2): " network_choice

    case $network_choice in
        1)
            cp .env.example .env
            sed -i 's/NETWORK_TYPE=.*/NETWORK_TYPE=pulsechain/' .env
            sed -i 's/CHAIN_ID=.*/CHAIN_ID=943/' .env
            ;;
        2)
            cp .env.example .env
            sed -i 's/NETWORK_TYPE=.*/NETWORK_TYPE=ethereum/' .env
            sed -i 's/CHAIN_ID=.*/CHAIN_ID=1/' .env
            ;;
        *)
            echo -e "${RED}Invalid choice. Exiting.${NC}"
            exit 1
            ;;
    esac
}

# Function to check Docker status
check_docker_status() {
    echo -e "\n${GREEN}Checking Docker status...${NC}"
    
    if ! docker info > /dev/null 2>&1; then
        echo -e "${RED}Docker is not running. Please start Docker and try again.${NC}"
        exit 1
    fi
    
    echo "Docker is running"
}

# Function to create data directories
create_directories() {
    echo -e "\n${GREEN}Creating data directories...${NC}"
    
    mkdir -p data/execution
    mkdir -p data/consensus
    mkdir -p data/monitoring/grafana
    mkdir -p data/monitoring/prometheus
    
    echo "Data directories created successfully"
}

# Function to pull Docker images
pull_images() {
    echo -e "\n${GREEN}Pulling Docker images...${NC}"
    docker-compose pull
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to pull Docker images. Please check your internet connection and try again.${NC}"
        exit 1
    fi
    
    echo "Docker images pulled successfully"
}

# Function to start services
start_services() {
    echo -e "\n${GREEN}Starting services...${NC}"
    docker-compose up -d
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to start services. Please check the logs for more information.${NC}"
        exit 1
    fi
    
    echo -e "Services started successfully"
}

# Function to display service status
show_status() {
    echo -e "\n${GREEN}Service Status:${NC}"
    docker-compose ps
    
    echo -e "\n${YELLOW}Useful Commands:${NC}"
    echo "- View logs: docker-compose logs -f"
    echo "- Stop services: docker-compose down"
    echo "- Restart services: docker-compose restart"
    echo -e "\n${YELLOW}Access Points:${NC}"
    echo "- Execution Client RPC: http://localhost:8545"
    echo "- Consensus Client API: http://localhost:5052"
    echo "- Monitoring Dashboard: http://localhost:3000"
}

# Main setup flow
check_docker_status
select_network
create_directories
pull_images
start_services
show_status

echo -e "\n${GREEN}Setup completed successfully!${NC}" 