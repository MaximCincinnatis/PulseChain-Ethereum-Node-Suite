#!/bin/bash

# Prompt the user for the installation path with a default value
read -p "Enter the installation path [/blockchain]: " install_path
install_path=${install_path:-/blockchain}

# Define the path to the service file
service_file="/etc/systemd/system/beacon.service"

# Use sudo to create or overwrite the service file
sudo bash -c "cat > $service_file" <<EOF
[Unit]
Description=Consensus Client Startup Script
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=root
ExecStart=$install_path/start_consensus.sh

[Install]
WantedBy=multi-user.target
EOF

# Reload the systemd daemon to recognize the new service
sudo systemctl daemon-reload

# Enable the service to start on boot
sudo systemctl enable beacon.service

# Start the service
sudo systemctl start beacon.service

# Create peer management service
cat > /etc/systemd/system/peer-management.service << EOL
[Unit]
Description=PulseChain Peer Management Service
After=docker.service execution.service beacon.service
Requires=docker.service execution.service beacon.service

[Service]
Type=simple
User=$USER
ExecStart=/bin/bash $CUSTOM_PATH/helper/peer_management.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOL

# Make peer management script executable
chmod +x $CUSTOM_PATH/helper/peer_management.sh

# Enable and start peer management service
systemctl daemon-reload
systemctl enable peer-management.service
systemctl start peer-management.service

echo "beacon.service has been created, enabled, and started."
