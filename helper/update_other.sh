#!/bin/bash

# Stop all containers first
docker stop -t 300 execution
docker stop -t 180 beacon

# Get list of all current containers for the node
echo "Current containers:"
docker ps -a | grep -E "beacon|execution"
echo ""

# Read user input for which images to pull/update
read -p "Do you want to update all containers? (y/N): " update_all

if [[ "$update_all" == "y" || "$update_all" == "Y" ]]; then
    # Update all execution clients
    docker pull registry.gitlab.com/pulsechaincom/go-pulse:latest
    docker pull registry.gitlab.com/pulsechaincom/erigon-pulse:latest
    
    # Update all consensus clients
    docker pull registry.gitlab.com/pulsechaincom/prysm-pulse/beacon-chain:latest
    docker pull registry.gitlab.com/pulsechaincom/lighthouse-pulse:latest
else
    echo "Skipping update. No changes made."
fi

echo "Update process completed. Please restart your node containers."
echo "You can do this by running:"
echo "- /blockchain/start_execution.sh"
echo "- /blockchain/start_consensus.sh"
