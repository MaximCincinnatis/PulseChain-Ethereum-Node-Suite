#!/bin/bash

# ===============================================================================
# Ethereum Node Service Installation
# ===============================================================================
# Version: 0.1.0
# Description: Installs and configures systemd services for Ethereum node
# ===============================================================================

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config/eth_config.sh"

# Service paths
SYSTEMD_DIR="/etc/systemd/system"

install_execution_service() {
    echo "Installing Ethereum execution client service..."
    
    cat > "${SYSTEMD_DIR}/eth-execution.service" << EOL
[Unit]
Description=Ethereum Execution Client
After=docker.service
Requires=docker.service

[Service]
Type=simple
User=${USER}
Restart=always
RestartSec=5
TimeoutStartSec=0
WorkingDirectory=${ETH_BASE_DIR}

ExecStart=/usr/bin/docker-compose -f docker-compose.execution.yml up
ExecStop=/usr/bin/docker-compose -f docker-compose.execution.yml down

[Install]
WantedBy=multi-user.target
EOL
}

install_consensus_service() {
    echo "Installing Ethereum consensus client service..."
    
    cat > "${SYSTEMD_DIR}/eth-consensus.service" << EOL
[Unit]
Description=Ethereum Consensus Client
After=eth-execution.service
Requires=eth-execution.service

[Service]
Type=simple
User=${USER}
Restart=always
RestartSec=5
TimeoutStartSec=0
WorkingDirectory=${ETH_BASE_DIR}

ExecStart=/usr/bin/docker-compose -f docker-compose.consensus.yml up
ExecStop=/usr/bin/docker-compose -f docker-compose.consensus.yml down

[Install]
WantedBy=multi-user.target
EOL
}

install_monitoring_service() {
    echo "Installing Ethereum monitoring service..."
    
    cat > "${SYSTEMD_DIR}/eth-monitoring.service" << EOL
[Unit]
Description=Ethereum Node Monitoring
After=eth-execution.service eth-consensus.service
Requires=eth-execution.service eth-consensus.service

[Service]
Type=simple
User=${USER}
Restart=always
RestartSec=5
TimeoutStartSec=0
WorkingDirectory=${ETH_BASE_DIR}/monitoring

ExecStart=/usr/bin/docker-compose -f docker-compose.yml up
ExecStop=/usr/bin/docker-compose -f docker-compose.yml down

[Install]
WantedBy=multi-user.target
EOL
}

install_services() {
    # Install services
    install_execution_service
    install_consensus_service
    install_monitoring_service
    
    # Reload systemd
    systemctl daemon-reload
    
    # Enable services
    systemctl enable eth-execution.service
    systemctl enable eth-consensus.service
    systemctl enable eth-monitoring.service
    
    # Start services
    systemctl start eth-execution.service
    systemctl start eth-consensus.service
    systemctl start eth-monitoring.service
    
    echo "Services installed and started successfully!"
    echo "Use 'systemctl status eth-*' to check service status"
}

# Run installation if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root"
        exit 1
    fi
    install_services
fi 