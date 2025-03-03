#!/bin/bash

# ===============================================================================
# Ethereum Node Maintenance Script
# ===============================================================================
# Version: 0.1.0
# Description: Handles updates and maintenance tasks for Ethereum node
# ===============================================================================

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config/eth_config.sh"

update_docker_images() {
    echo "Updating Docker images..."
    
    # Pull latest images
    docker pull ${GETH_ETH_IMAGE}
    docker pull ${ERIGON_ETH_IMAGE}
    docker pull ${LIGHTHOUSE_ETH_IMAGE}
    docker pull ${PRYSM_ETH_IMAGE}
    
    # Clean up old images
    docker image prune -f
}

perform_pruning() {
    echo "Performing database pruning..."
    
    case $ETH_CLIENT in
        "geth"|"geth-pruned")
            docker-compose exec execution geth snapshot prune-state
            ;;
        "erigon"|"erigon-pruned")
            docker-compose exec execution erigon db prune
            ;;
    esac
}

check_for_updates() {
    echo "Checking for client updates..."
    
    # Get current versions
    local current_geth=$(docker inspect ${GETH_ETH_IMAGE} 2>/dev/null | jq -r '.[0].Config.Labels.version' || echo "unknown")
    local current_erigon=$(docker inspect ${ERIGON_ETH_IMAGE} 2>/dev/null | jq -r '.[0].Config.Labels.version' || echo "unknown")
    local current_lighthouse=$(docker inspect ${LIGHTHOUSE_ETH_IMAGE} 2>/dev/null | jq -r '.[0].Config.Labels.version' || echo "unknown")
    local current_prysm=$(docker inspect ${PRYSM_ETH_IMAGE} 2>/dev/null | jq -r '.[0].Config.Labels.version' || echo "unknown")
    
    echo "Current versions:"
    echo "- Geth: ${current_geth}"
    echo "- Erigon: ${current_erigon}"
    echo "- Lighthouse: ${current_lighthouse}"
    echo "- Prysm: ${current_prysm}"
}

cleanup_logs() {
    echo "Cleaning up old logs..."
    
    find "${ETH_LOGS_DIR}" -name "*.log" -mtime +30 -delete
    
    # Rotate Docker logs
    echo '{"log-driver": "json-file", "log-opts": {"max-size": "10m", "max-file": "3"}}' | sudo tee /etc/docker/daemon.json
    sudo systemctl restart docker
}

optimize_system() {
    echo "Optimizing system settings..."
    
    # Update system limits
    cat > /etc/sysctl.d/99-ethereum.conf << EOL
# Increase max open files
fs.file-max = 1000000

# Increase network buffer sizes
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864

# Increase max UDP receive buffer
net.core.rmem_default = 67108864

# Increase number of allowed pending connections
net.core.somaxconn = 1024

# Increase TCP max syn backlog
net.ipv4.tcp_max_syn_backlog = 1024

# Enable TCP fast open
net.ipv4.tcp_fastopen = 3

# Increase ephemeral ports range
net.ipv4.ip_local_port_range = 1024 65535
EOL

    # Apply sysctl settings
    sysctl -p /etc/sysctl.d/99-ethereum.conf
    
    # Update user limits
    cat > /etc/security/limits.d/99-ethereum.conf << EOL
${USER} soft nofile 1000000
${USER} hard nofile 1000000
${USER} soft nproc 65535
${USER} hard nproc 65535
EOL
}

perform_maintenance() {
    echo "Performing Ethereum node maintenance..."
    echo "======================================"
    
    # Create maintenance backup
    "${SCRIPT_DIR}/node_backup.sh" create
    
    # Update images
    update_docker_images
    
    # Stop services
    systemctl stop eth-execution eth-consensus eth-monitoring
    
    # Perform maintenance tasks
    perform_pruning
    cleanup_logs
    optimize_system
    
    # Start services
    systemctl start eth-execution eth-consensus eth-monitoring
    
    # Run health check
    "${SCRIPT_DIR}/health_check.sh"
    
    echo "Maintenance completed successfully!"
}

case "$1" in
    check-updates)
        check_for_updates
        ;;
    update-images)
        update_docker_images
        ;;
    prune)
        perform_pruning
        ;;
    cleanup)
        cleanup_logs
        ;;
    optimize)
        optimize_system
        ;;
    all)
        perform_maintenance
        ;;
    *)
        echo "Usage: $0 {check-updates|update-images|prune|cleanup|optimize|all}"
        exit 1
        ;;
esac 