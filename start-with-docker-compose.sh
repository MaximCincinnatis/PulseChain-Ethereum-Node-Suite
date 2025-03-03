#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}PulseChain/Ethereum Node Setup with Docker Compose${NC}"
echo "=================================================="

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}Docker Compose is not installed. Please install Docker Compose first.${NC}"
    exit 1
fi

# Create necessary directories
echo "Creating required directories..."
mkdir -p chaindata/{pulsechain,ethereum}
mkdir -p beacondata/{pulsechain,ethereum}
mkdir -p monitoring/{prometheus,grafana}
mkdir -p config

# Copy environment file if it doesn't exist
if [ ! -f .env ]; then
    echo "Creating .env file from template..."
    cp .env.example .env
    echo "Please edit .env file to customize your setup"
fi

# Network selection
echo ""
echo "Please select your network:"
echo "1) PulseChain"
echo "2) Ethereum"
read -p "Enter your choice (1/2): " network_choice

case $network_choice in
    1)
        sed -i 's/NETWORK=.*/NETWORK=pulsechain/' .env
        ;;
    2)
        sed -i 's/NETWORK=.*/NETWORK=ethereum/' .env
        ;;
    *)
        echo -e "${RED}Invalid choice. Exiting.${NC}"
        exit 1
        ;;
esac

# Client selection
echo ""
echo "Please select your execution client:"
echo "1) Geth"
echo "2) Erigon"
read -p "Enter your choice (1/2): " execution_choice

case $execution_choice in
    1)
        sed -i 's/EXECUTION_CLIENT=.*/EXECUTION_CLIENT=geth/' .env
        sed -i 's/EXECUTION_CLIENT_IMAGE=.*/EXECUTION_CLIENT_IMAGE=ethereum\/client-go:latest/' .env
        ;;
    2)
        sed -i 's/EXECUTION_CLIENT=.*/EXECUTION_CLIENT=erigon/' .env
        sed -i 's/EXECUTION_CLIENT_IMAGE=.*/EXECUTION_CLIENT_IMAGE=thorax\/erigon:latest/' .env
        ;;
    *)
        echo -e "${RED}Invalid choice. Using default (Geth)${NC}"
        ;;
esac

echo ""
echo "Please select your consensus client:"
echo "1) Lighthouse"
echo "2) Prysm"
read -p "Enter your choice (1/2): " consensus_choice

case $consensus_choice in
    1)
        sed -i 's/CONSENSUS_CLIENT=.*/CONSENSUS_CLIENT=lighthouse/' .env
        sed -i 's/CONSENSUS_CLIENT_IMAGE=.*/CONSENSUS_CLIENT_IMAGE=sigp\/lighthouse:latest/' .env
        ;;
    2)
        sed -i 's/CONSENSUS_CLIENT=.*/CONSENSUS_CLIENT=prysm/' .env
        sed -i 's/CONSENSUS_CLIENT_IMAGE=.*/CONSENSUS_CLIENT_IMAGE=gcr.io\/prysmaticlabs\/prysm\/beacon-chain:latest/' .env
        ;;
    *)
        echo -e "${RED}Invalid choice. Using default (Lighthouse)${NC}"
        ;;
esac

# Start the services
echo ""
echo -e "${GREEN}Starting services with Docker Compose...${NC}"
docker-compose up -d

# Show running containers
echo ""
echo "Running containers:"
docker-compose ps

echo ""
echo -e "${GREEN}Setup complete!${NC}"
echo "Monitor your node at http://localhost:3000 (Grafana)"
echo "Default credentials: admin/admin" 