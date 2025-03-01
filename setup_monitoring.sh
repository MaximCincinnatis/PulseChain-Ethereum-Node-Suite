#!/bin/bash

# PulseChain Monitoring Setup Script v1.0
# This script sets up Prometheus and Grafana monitoring for a PulseChain node
# Author: Maxim Broadcast

# Exit script on error
set -e

# Set up error handling
trap 'handle_error $?' ERR

# Error handling function
handle_error() {
  echo -e "${RED}An error occurred during monitoring setup. Exit code: $1${NC}"
  echo "Cleaning up and restoring state..."
  # Add any cleanup actions needed here
  exit 1
}

script_dir=$(dirname "$0")
source "$script_dir/functions.sh"

start_dir=$(pwd)
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Verify that functions.sh exists and is readable
if [ ! -f "./functions.sh" ]; then
  echo -e "${RED}Error: Required functions.sh file not found!${NC}"
  exit 1
fi

source "./functions.sh"

clear

echo "==== PulseChain Monitoring Setup ===="
echo "This script will set up Prometheus and Grafana for monitoring your Lighthouse node."
echo ""

# Create users with appropriate permissions
echo "Adding users for prometheus and grafana"
sudo useradd -M -G docker prometheus 2>/dev/null || echo "User prometheus already exists, skipping creation"
sudo useradd -M -G docker grafana 2>/dev/null || echo "User grafana already exists, skipping creation"

# Prompt for config location with validation
read -e -p "Enter the location to store prometheus.yml (default: /blockchain): " config_location
config_location=$(echo "$config_location" | sed 's:/*$::')

# Set the default location to /blockchain if nothing is entered
if [ -z "$config_location" ]; then
  config_location="/blockchain"
fi

# Ensure the config location exists
if [ ! -d "$config_location" ]; then
  echo "Config directory does not exist. Creating $config_location..."
  sudo mkdir -p "$config_location" || {
    echo -e "${RED}Failed to create config directory. Please check permissions.${NC}"
    exit 1
  }
  sudo chmod -R 755 "$config_location"
fi

# Using Lighthouse as the only client option
echo "Setting up monitoring for Lighthouse beacon node"

# Create directories for prometheus and grafana
echo ""
echo "Creating directories for the prometheus and grafana container"
sudo mkdir -p "$config_location/prometheus" || {
  echo -e "${RED}Error: Failed to create prometheus directory. Check permissions.${NC}"
  exit 1
}
sudo mkdir -p "$config_location/grafana" || {
  echo -e "${RED}Error: Failed to create grafana directory. Check permissions.${NC}"
  exit 1
}

# Create prometheus.yml with Lighthouse configuration (no validator metrics)
PROMETHEUS_YML="global:
  scrape_interval: 15s
  evaluation_interval: 15s
scrape_configs:
   - job_name: 'node_exporter'
     static_configs:
       - targets: ['localhost:9100']
   - job_name: 'nodes'
     metrics_path: /metrics
     static_configs:
       - targets: ['localhost:5054']
   - job_name: 'geth'
     scrape_interval: 15s
     scrape_timeout: 10s
     metrics_path: /debug/metrics/prometheus
     scheme: http
     static_configs:
     - targets: ['localhost:6060']"

# Create prometheus.yml file
echo ""
echo "Creating the yml file for promethesu"
sudo bash -c "cat > $config_location/prometheus.yml << 'EOF'
$PROMETHEUS_YML
EOF"

# Set ownership and permissions
echo ""
echo "Setting ownership for container-folders"
sudo chown -R prometheus:prometheus "$config_location/prometheus"
sudo chown -R grafana:grafana "$config_location/grafana"
sudo chmod 644 "$config_location/prometheus.yml"
sudo chmod -R 777 "$config_location/grafana"

# Set UFW Rules
echo ""
echo "Setting up firewall rules to allow local connection to metric ports"
sudo ufw allow from 127.0.0.1 to any port 8545 proto tcp
sudo ufw allow from 127.0.0.1 to any port 8546 proto tcp
sudo ufw allow from 127.0.0.1 to any port 5052 proto tcp
# Validator port 5064 removed

# Prompt to allow access to Grafana Dashboard in Local Network

function get_local_ip() {
  local_ip=$(hostname -I | awk '{print $1}')
  echo $local_ip
}

function get_ip_range() {
  local_ip=$(get_local_ip)
  ip_parts=(${local_ip//./ })
  ip_range="${ip_parts[0]}.${ip_parts[1]}.${ip_parts[2]}.0/24"
  echo $ip_range
}

#debug
local_ip_debug=$(hostname -I | awk '{print $1}')
ip_range=$(get_ip_range)

echo ""
echo "Your Current IP is: $local_ip_debug"
echo ""
read -p "Do you want to allow access to the Grafana Dashboard from within your local network ($ip_range)? (y/n): " local_network_choice
echo ""

if [[ $local_network_choice == "y" ]]; then
  echo ""
  sudo ufw allow from $ip_range to any port 3000 proto tcp comment 'Grafana Port for private IP range'

fi

echo ""
sudo ufw reload
echo ""

# Define Docker commands as variables
PROMETHEUS_CMD="sudo -u prometheus docker run -dt --name prometheus --restart=always \\
  --net='host' \\
  -v ${config_location}/prometheus.yml:/etc/prometheus/prometheus.yml \\
  -v ${config_location}/prometheus:/prometheus-data \\
  prom/prometheus
  
  "

PROMETHEUS_NODE_CMD="sudo -u prometheus docker run -dt --name node_exporter --restart=always \\
  --net='host' \\
  -v '/:/host:ro,rslave' \\
  prom/node-exporter --path.rootfs=/host 
  
  "

GRAFANA_CMD="sudo -u grafana docker run -dt --name grafana --restart=always \\
  --net='host' \\
  -v ${config_location}/grafana:/var/lib/grafana \\
  grafana/grafana
  
  "

# Create start_monitoring.sh script
echo ""
echo "Creating start_monitor.sh script"
sudo bash -c "cat > $config_location/start_monitoring.sh << 'EOF'
#!/bin/bash

$PROMETHEUS_CMD
$PROMETHEUS_NODE_CMD
$GRAFANA_CMD
EOF"

get_main_user
# Make start_monitoring.sh executable
sudo chmod +x $config_location/start_monitoring.sh
sudo chmod 770 $config_location/start_monitoring.sh
sudo chown $main_user:docker $config_location/start_monitoring.sh

echo ""
echo "Created Monitoring-Scripts and Set Firewall rules"
cd $config_location
echo "..."
sleep 2

echo ""
echo "Launching prometheus, node-exporter and grafana containers"
echo ""
sudo $config_location/start_monitoring.sh
sleep 2

# checking if they are running
echo ""
echo "Checking if the docker started"
echo ""
if sudo docker ps --format '{{.Names}}' | grep -q '^grafana$'; then
  echo "Grafana container is running"
else
  echo "Grafana container is not running"
fi
echo ""
if sudo docker ps --format '{{.Names}}' | grep -q '^prometheus$'; then
  echo "Prometheus container is running"
else
  echo "Prometheus container is not running"
fi
echo ""
if sudo docker ps --format '{{.Names}}' | grep -q '^node_exporter$'; then
  echo "Node Exporter container is running"
else
  echo "Node Exporter container is not running"
fi
echo ""

sleep 2

# Set variables for the API endpoint, authentication, and datasource configuration
grafana_api="http://localhost:3000/api/datasources"
grafana_auth="admin:admin"
prometheus_url="http://localhost:9090"
datasource_name="Prometheus"
datasource_type="prometheus"
access_mode="proxy"
basic_auth_user=""
basic_auth_password=""
is_default="true"

# Send the POST request to add the datasource using curl
curl -X POST -H "Content-Type: application/json" -d \
  '{
    "name": "'$datasource_name'",
    "type": "'$datasource_type'",
    "url": "'$prometheus_url'",
    "access": "'$access_mode'",
    "basicAuthUser": "'$basic_auth_user'",
    "basicAuthPassword": "'$basic_auth_password'",
    "isDefault": '$is_default'
}' \
  --user "$grafana_auth" \
  $grafana_api

sleep 1
echo ""

sudo mkdir -p "${config_location}/Dashboards"
echo "Downloading dashboard JSON..."
sudo wget -qO "${config_location}/Dashboards/002_Geth_dashboard.json" -P "${config_location}/Dashboards" https://gist.githubusercontent.com/karalabe/e7ca79abdec54755ceae09c08bd090cd/raw/dashboard.json >/dev/null
sudo wget -qO "${config_location}/Dashboards/003_System_dashboard.json" -P "${config_location}/Dashboards" https://grafana.com/api/dashboards/11074/revisions/9/download >/dev/null

# Only download node-related dashboards
sudo wget -O "${config_location}/Dashboards/004_Lighthouse_beacon_dashboard.json" -P "${config_location}/Dashboards" https://raw.githubusercontent.com/sigp/lighthouse-metrics/master/dashboards/Summary.json >/dev/null

get_main_user
echo ""
echo ""
get_main_user
sudo chown -R $main_user:docker "${config_location}/Dashboards"
sudo chmod -R 777 "${config_location}/Dashboards"

echo ""
echo -e "${GREEN}Congratulations, setup is now complete.${NC}"
echo ""
if [[ $local_network_choice == "y" ]]; then
  echo "Access Grafana: http://127.0.0.1:3000 or http://${local_ip_debug}:3000"
  echo "Username: admin"
  echo "Password: admin"
  echo ""
  echo "Add dashboards via: http://127.0.0.1:3000/dashboard/import or http://${local_ip_debug}:3000/dashboard/import"
  echo "Import JSONs from '${config_location}/Dashboards'"
else
  echo "Access Grafana: http://127.0.0.1:3000"
  echo "Username: admin"
  echo "Password: admin"
  echo ""
  echo "Add dashboards via: http://127.0.0.1:3000/dashboard/import"
  echo "Import JSONs from '${config_location}/Dashboards'"
  echo ""
  echo "It is adviced to reboot your system after the initial setup has taken place"
fi
echo ""
echo "Brought to you by:
  ███╗   ███╗ █████╗ ██╗  ██╗██╗███╗   ███╗    ██████╗ ██████╗  ██████╗  █████╗ ██████╗  ██████╗ █████╗ ███████╗████████╗
  ████╗ ████║██╔══██╗╚██╗██╔╝██║████╗ ████║    ██╔══██╗██╔══██╗██╔═══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗██╔════╝╚══██╔══╝
  ██╔████╔██║███████║ ╚███╔╝ ██║██╔████╔██║    ██████╔╝██████╔╝██║   ██║███████║██║  ██║██║     ███████║███████╗   ██║   
  ██║╚██╔╝██║██╔══██║ ██╔██╗ ██║██║╚██╔╝██║    ██╔══██╗██╔══██╗██║   ██║██╔══██║██║  ██║██║     ██╔══██║╚════██║   ██║   
  ██║ ╚═╝ ██║██║  ██║██╔╝ ██╗██║██║ ╚═╝ ██║    ██████╔╝██║  ██║╚██████╔╝██║  ██║██████╔╝╚██████╗██║  ██║███████║   ██║   
  ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝     ╚═╝    ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝   ╚═╝   "
sleep 1
echo ""
echo "Press enter to continue..."
read -p ""
echo ""
read -e -p "$(echo -e "${GREEN}Would you like to start the logviewer to monitor the client logs? [y/n]:${NC}")" log_it

if [[ "$log_it" =~ ^[Yy]$ ]]; then
  echo "Choose a log viewer:"
  echo "1. GUI/TAB Based Logviewer (serperate tabs; easy)"
  echo "2. TMUX Logviewer (AIO logs; advanced)"

  read -p "Enter your choice (1 or 2): " choice

  case $choice in
  1)
    ${config_location}/helper/log_viewer.sh
    ;;
  2)
    ${config_location}/helper/tmux_logviewer.sh
    ;;
  *)
    echo "Invalid choice. Exiting."
    ;;
  esac
fi
reboot_prompt
sleep 5
reboot_advice
exit 0
