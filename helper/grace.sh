#!/bin/bash

# This script sets up graceful shutdown for Docker containers
# It creates a systemd service that will stop containers properly on system shutdown

# Get the installation path
if [ -z "$INSTALL_PATH" ]; then
    read -e -p "Please enter the installation path (default: /blockchain): " INSTALL_PATH
    INSTALL_PATH=${INSTALL_PATH:-/blockchain}
fi

# Define script paths
SCRIPTS=("$INSTALL_PATH/start_consensus.sh" "$INSTALL_PATH/start_execution.sh")

# Create the stop_docker.sh script if it doesn't exist
if [ ! -f "$INSTALL_PATH/helper/stop_docker.sh" ]; then
    mkdir -p "$INSTALL_PATH/helper"
    cat > "$INSTALL_PATH/helper/stop_docker.sh" << 'EOF'
#!/bin/bash
docker stop -t 300 execution
docker stop -t 180 beacon
EOF
    chmod +x "$INSTALL_PATH/helper/stop_docker.sh"
fi

# Create a systemd service unit file
cat << EOF | sudo tee /etc/systemd/system/graceful_stop.service
[Unit]
Description=Gracefully stop docker containers on shutdown

[Service]
ExecStart=/bin/true
ExecStop=$INSTALL_PATH/helper/stop_docker.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd manager configuration
sudo systemctl daemon-reload

# Enable the new service to be started on bootup
sudo systemctl enable graceful_stop.service
sudo systemctl start graceful_stop.service

echo "Set up and enabled graceful_stop service."

# Add scripts to crontab for automatic restart on reboot
for script in "${SCRIPTS[@]}"
do
    if [[ -x "$script" ]]
    then
        # Check if the script is already in the cron list
        if ! sudo crontab -l 2>/dev/null | grep -q "$script"; then
            # If it is not in the list, add script to root's crontab
            (sudo crontab -l 2>/dev/null; echo "@reboot $script > /dev/null 2>&1") | sudo crontab -
            echo "Added $script to root's cron jobs."
        else
            echo "Skipping $script - already in root's cron jobs."
        fi
    else
        echo "Skipping $script - does not exist or is not executable."
    fi
done

echo "Press Enter to continue"
read -p ""

