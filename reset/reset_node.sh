#!/bin/bash

cat << "EOF"
+----------------------------------------------------------+
| This script will reset and remove everything Node related |
| in a Pulse-Chain docker-setup.                           |
|                                                          |
| This includes all docker-containers, docker-images       |
| downloaded Docker images.                                |
+----------------------------------------------------------+
EOF
echo ""

cat << "EOF"
+----------------------------------------------------------+
| 1. Stop Docker containers                                 |
| 2. Remove Docker containers                               |
| 3. Remove Docker images                                   |
| 4. Remove Node users                                      |
| 5. Remove Node data directories!                          |
+----------------------------------------------------------+
EOF
echo ""
read -p "Are you sure you want to continue? (yes/no): " answer
if [[ $answer != "yes" ]]; then
    echo "Aborted."
    exit 0
fi

echo "Stopping and removing Docker containers..."
sudo docker stop execution
sudo docker stop beacon

sudo docker rm execution
sudo docker rm beacon

sudo docker container prune -f

echo "Removing Docker images..."
sudo docker rmi registry.gitlab.com/pulsechaincom/go-pulse:latest
sudo docker rmi registry.gitlab.com/pulsechaincom/lighthouse-pulse:latest
sudo docker rmi registry.gitlab.com/pulsechaincom/erigon-pulse:latest
sudo docker rmi registry.gitlab.com/pulsechaincom/prysm-pulse:latest
sudo docker rmi registry.gitlab.com/pulsechaincom/prysm-pulse/prysmctl
sudo docker rmi registry.gitlab.com/pulsechaincom/prysm-pulse/beacon-chain
sudo docker rmi registry.gitlab.com/pulsechaincom/go-pulse

echo "Removing system users..."
sudo userdel geth
sudo userdel erigon
sudo userdel lighthouse
sudo userdel prysm

echo "Removing blockchain data directories..."
sudo rm -rf /blockchain/execution
sudo rm -rf /blockchain/consensus

echo "Reset complete. You can now run the setup script again."
