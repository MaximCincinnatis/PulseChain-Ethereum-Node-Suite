#!/bin/bash

# PulseChain Monitoring Setup Script v0.1.0
# This script sets up Prometheus and Grafana monitoring for a PulseChain node
# Author: Maxim Broadcast

# Colors for better readability
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

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

# Store starting directory
start_dir=$(pwd)

# Verify that functions.sh exists and is readable (using absolute path)
script_dir=$(dirname "$(readlink -f "$0")")
functions_file="${script_dir}/functions.sh"

if [ ! -f "$functions_file" ]; then
  echo -e "${RED}Error: Required functions.sh file not found at ${functions_file}!${NC}"
  exit 1
fi

# Source functions only once
source "$functions_file"

# Check for required dependencies
echo "Checking for required dependencies..."
for cmd in docker ufw curl wget; do
  if ! command -v $cmd &> /dev/null; then
    echo -e "${RED}Error: $cmd is required but not installed. Please install it first.${NC}"
    exit 1
  fi
done

# Check if docker service is running
if ! systemctl is-active --quiet docker; then
  echo -e "${YELLOW}Warning: Docker service is not running. Attempting to start...${NC}"
  sudo systemctl start docker
  sleep 3
  if ! systemctl is-active --quiet docker; then
    echo -e "${RED}Error: Failed to start Docker service. Please start it manually and try again.${NC}"
    exit 1
  fi
fi

# Check if ufw is enabled
if ! sudo ufw status | grep -q "Status: active"; then
  echo -e "${YELLOW}Warning: UFW firewall is not active. Attempting to enable...${NC}"
  sudo ufw --force enable
  if ! sudo ufw status | grep -q "Status: active"; then
    echo -e "${RED}Error: Failed to enable UFW firewall. Some firewall rules may not be applied.${NC}"
    read -p "Continue anyway? (y/n): " continue_choice
    if [[ ! $continue_choice =~ ^[Yy]$ ]]; then
      echo "Exiting at user request."
      exit 0
    fi
  fi
fi

clear

echo "==== PulseChain Monitoring Setup ===="
echo "This script will set up Prometheus and Grafana for monitoring your Lighthouse node."
echo ""

# Add at start of script
# Check disk space
MIN_DISK_SPACE_GB=10
available_space=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$available_space" -lt "$MIN_DISK_SPACE_GB" ]; then
    echo -e "${RED}Error: Insufficient disk space. Need at least ${MIN_DISK_SPACE_GB}GB free.${NC}"
    exit 1
fi

# Backup existing configs
backup_configs() {
    if [ -d "$config_location" ]; then
        backup_dir="${config_location}_backup_$(date +%Y%m%d_%H%M%S)"
        echo "Backing up existing configurations to $backup_dir"
        cp -r "$config_location" "$backup_dir"
    fi
}

# Create users with appropriate permissions
echo "Adding users for prometheus and grafana"
sudo useradd -M -G docker prometheus 2>/dev/null || echo "User prometheus already exists, skipping creation"
sudo useradd -M -G docker grafana 2>/dev/null || echo "User grafana already exists, skipping creation"

# Verify docker group membership
for user in prometheus grafana; do
  if ! groups $user | grep -q docker; then
    echo -e "${YELLOW}Warning: $user is not in the docker group. Adding...${NC}"
    sudo usermod -aG docker $user
  fi
done

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

storage:
  tsdb:
    retention.time: 15d
    retention.size: 5GB

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
echo "Creating the yml file for prometheus"
sudo bash -c "cat > $config_location/prometheus.yml << 'EOL'
$PROMETHEUS_YML
EOL"

# Verify the file was created successfully
if [ ! -f "$config_location/prometheus.yml" ]; then
  echo -e "${RED}Failed to create prometheus.yml file. Exiting.${NC}"
  exit 1
fi

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
# Function to safely apply UFW rules
apply_ufw_rule() {
  local rule="$1"
  local comment="$2"
  
  if sudo ufw status | grep -q "$rule"; then
    echo "Firewall rule already exists: $rule"
  else
    echo "Adding firewall rule: $rule"
    sudo ufw allow "$rule" comment "$comment"
  fi
}

apply_ufw_rule "from 127.0.0.1 to any port 8545 proto tcp" "Geth HTTP API"
apply_ufw_rule "from 127.0.0.1 to any port 8546 proto tcp" "Geth WebSocket API"
apply_ufw_rule "from 127.0.0.1 to any port 5052 proto tcp" "Lighthouse API"

# Function to reliably get local IP address
function get_local_ip() {
  # Try multiple commands to get the local IP address
  if command -v ip &> /dev/null; then
    local_ip=$(ip -4 addr show scope global | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n 1)
  elif command -v hostname &> /dev/null; then
    local_ip=$(hostname -I | awk '{print $1}')
  elif command -v ifconfig &> /dev/null; then
    local_ip=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | head -n 1)
  fi
  
  # Verify we got a valid IP
  if [[ ! $local_ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "127.0.0.1"  # Fallback to localhost if we can't determine IP
    return
  fi
  
  echo $local_ip
}

function get_ip_range() {
  local_ip=$(get_local_ip)
  ip_parts=(${local_ip//./ })
  if [[ ${#ip_parts[@]} -eq 4 ]]; then
    ip_range="${ip_parts[0]}.${ip_parts[1]}.${ip_parts[2]}.0/24"
  else
    ip_range="192.168.1.0/24"  # Fallback to common range
  fi
  echo $ip_range
}

local_ip=$(get_local_ip)
ip_range=$(get_ip_range)

echo ""
echo "Your Current IP is: $local_ip"
echo ""
read -p "Do you want to allow access to the Grafana Dashboard from within your local network ($ip_range)? (y/n): " local_network_choice
echo ""

if [[ $local_network_choice =~ ^[Yy]$ ]]; then
  echo ""
  apply_ufw_rule "from $ip_range to any port 3000 proto tcp" "Grafana Port for private IP range"
fi

echo ""
sudo ufw reload
echo ""

# Define Docker commands as variables
PROMETHEUS_CMD="sudo -u prometheus docker run -dt --name prometheus --restart=always \\
  --net='host' \\
  --memory=1g \\
  --memory-swap=2g \\
  --cpu-shares=512 \\
  -v ${config_location}/prometheus.yml:/etc/prometheus/prometheus.yml \\
  -v ${config_location}/prometheus:/prometheus-data \\
  prom/prometheus"

PROMETHEUS_NODE_CMD="sudo -u prometheus docker run -dt --name node_exporter --restart=always \\
  --net='host' \\
  -v '/:/host:ro,rslave' \\
  prom/node-exporter --path.rootfs=/host"

GRAFANA_CMD="sudo -u grafana docker run -dt --name grafana --restart=always \\
  --net='host' \\
  -v ${config_location}/grafana:/var/lib/grafana \\
  grafana/grafana"

# Create start_monitoring.sh script
echo ""
echo "Creating start_monitor.sh script"

# Use a safer way to create the script with proper variable expansion
sudo bash -c "cat > $config_location/start_monitoring.sh << EOF
#!/bin/bash

# Check if containers already exist and remove them if they do
for container in prometheus node_exporter grafana; do
  if sudo docker ps -a --format '{{.Names}}' | grep -q \"^\$container\$\"; then
    echo \"Removing existing \$container container...\"
    sudo docker stop \$container >/dev/null 2>&1
    sudo docker rm \$container >/dev/null 2>&1
  fi
done

# Start containers
echo \"Starting Prometheus...\"
$PROMETHEUS_CMD

echo \"Starting Node Exporter...\"
$PROMETHEUS_NODE_CMD

echo \"Starting Grafana...\"
$GRAFANA_CMD

# Verify containers are running
sleep 5
for container in prometheus node_exporter grafana; do
  if sudo docker ps --format '{{.Names}}' | grep -q \"^\$container\$\"; then
    echo \"\$container is running successfully.\"
  else
    echo \"WARNING: \$container failed to start properly.\"
  fi
done
EOF"

# Check if get_main_user function exists, otherwise create a fallback
if ! declare -f get_main_user &>/dev/null; then
  echo -e "${YELLOW}Warning: get_main_user function not found in functions.sh, creating fallback...${NC}"
  
  # Define a fallback get_main_user function
  get_main_user() {
    main_user=$(logname 2>/dev/null || echo $SUDO_USER || echo $USER)
    echo "Using $main_user as the main user"
  }
fi

# Get the main user
get_main_user

# Make start_monitoring.sh executable
sudo chmod +x $config_location/start_monitoring.sh
sudo chmod 770 $config_location/start_monitoring.sh
sudo chown $main_user:docker $config_location/start_monitoring.sh || {
  echo -e "${YELLOW}Warning: Could not set ownership to $main_user:docker. Using root ownership instead.${NC}"
  sudo chown root:docker $config_location/start_monitoring.sh
}

echo ""
echo "Created Monitoring-Scripts and Set Firewall rules"
cd $config_location
echo "..."
sleep 2

echo ""
echo "Launching prometheus, node-exporter and grafana containers"
echo ""
sudo $config_location/start_monitoring.sh

# Function to check if container is healthy
check_container_health() {
  local container_name="$1"
  local max_attempts=10
  local attempt=1
  
  echo "Checking health of $container_name container..."
  
  while [ $attempt -le $max_attempts ]; do
    if sudo docker ps --format '{{.Names}}' | grep -q "^$container_name$"; then
      # For Grafana, check if the API is responsive
      if [ "$container_name" = "grafana" ]; then
        if curl -s "http://localhost:3000/api/health" | grep -q "ok"; then
          echo "$container_name is healthy."
          return 0
        else
          echo "Waiting for $container_name API to become responsive (attempt $attempt/$max_attempts)..."
        fi
      else
        echo "$container_name is running."
        return 0
      fi
    else
      echo "Waiting for $container_name to start (attempt $attempt/$max_attempts)..."
    fi
    
    attempt=$((attempt+1))
    sleep 3
  done
  
  echo -e "${RED}$container_name did not become healthy within the expected time.${NC}"
  return 1
}

# Check health of all containers
check_container_health "prometheus"
check_container_health "node_exporter"
check_container_health "grafana"

# Wait for Grafana to be fully ready
echo "Waiting for Grafana to be fully ready..."
sleep 10

# Create directories for dashboards
sudo mkdir -p "${config_location}/Dashboards"

# Function to safely download files
download_file() {
  local url="$1"
  local output_file="$2"
  local max_attempts=3
  local attempt=1
  
  while [ $attempt -le $max_attempts ]; do
    echo "Downloading $output_file (attempt $attempt/$max_attempts)..."
    if sudo wget -q "$url" -O "$output_file"; then
      echo "Successfully downloaded $output_file"
      return 0
    else
      echo -e "${YELLOW}Failed to download $output_file (attempt $attempt/$max_attempts)${NC}"
      attempt=$((attempt+1))
      sleep 2
    fi
  done
  
  echo -e "${RED}Failed to download $output_file after $max_attempts attempts${NC}"
  return 1
}

echo "Downloading dashboard JSONs..."
download_file "https://gist.githubusercontent.com/karalabe/e7ca79abdec54755ceae09c08bd090cd/raw/dashboard.json" "${config_location}/Dashboards/002_Geth_dashboard.json"
download_file "https://grafana.com/api/dashboards/11074/revisions/9/download" "${config_location}/Dashboards/003_System_dashboard.json"
download_file "https://raw.githubusercontent.com/sigp/lighthouse-metrics/master/dashboards/Summary.json" "${config_location}/Dashboards/004_Lighthouse_beacon_dashboard.json"

# Set ownership and permissions for dashboards
get_main_user  # Get main user again to ensure it's defined
sudo chown -R $main_user:docker "${config_location}/Dashboards" || {
  echo -e "${YELLOW}Warning: Could not set ownership to $main_user:docker for Dashboards. Using root ownership instead.${NC}"
  sudo chown -R root:docker "${config_location}/Dashboards"
}
sudo chmod -R 777 "${config_location}/Dashboards"

# Configure Grafana datasource with proper error handling
echo "Configuring Grafana datasource..."
grafana_api="http://localhost:3000/api/datasources"
grafana_auth="admin:admin"
prometheus_url="http://localhost:9090"
datasource_config='{
  "name": "Prometheus",
  "type": "prometheus",
  "url": "http://localhost:9090",
  "access": "proxy",
  "isDefault": true
}'

# Send the POST request to add the datasource using curl with error handling
if ! curl -s -X POST -H "Content-Type: application/json" -d "$datasource_config" --user "$grafana_auth" $grafana_api; then
  echo -e "${RED}Failed to configure Grafana datasource. Will retry in 5 seconds...${NC}"
  sleep 5
  if ! curl -s -X POST -H "Content-Type: application/json" -d "$datasource_config" --user "$grafana_auth" $grafana_api; then
    echo -e "${RED}Failed to configure Grafana datasource again. Please configure it manually at http://localhost:3000${NC}"
  else
    echo -e "${GREEN}Successfully configured Grafana datasource on second attempt.${NC}"
  fi
else
  echo -e "${GREEN}Successfully configured Grafana datasource.${NC}"
fi

# Check if reboot_prompt and reboot_advice functions exist, otherwise create fallbacks
if ! declare -f reboot_prompt &>/dev/null; then
  echo -e "${YELLOW}Warning: reboot_prompt function not found in functions.sh, creating fallback...${NC}"
  
  # Define a fallback reboot_prompt function
  reboot_prompt() {
    read -p "Would you like to reboot your system now? (recommended) [y/n]: " reboot_now
    if [[ "$reboot_now" =~ ^[Yy]$ ]]; then
      echo "System will reboot in 5 seconds..."
      sleep 5
      sudo reboot
    fi
  }
fi

if ! declare -f reboot_advice &>/dev/null; then
  echo -e "${YELLOW}Warning: reboot_advice function not found in functions.sh, creating fallback...${NC}"
  
  # Define a fallback reboot_advice function
  reboot_advice() {
    echo "It is recommended to reboot your system after installation for all changes to take effect."
  }
fi

echo ""
echo -e "${GREEN}Congratulations, setup is now complete.${NC}"
echo ""
if [[ $local_network_choice =~ ^[Yy]$ ]]; then
  echo "Access Grafana: http://127.0.0.1:3000 or http://${local_ip}:3000"
  echo "Username: admin"
  echo "Password: admin"
  echo ""
  echo "Add dashboards via: http://127.0.0.1:3000/dashboard/import or http://${local_ip}:3000/dashboard/import"
  echo "Import JSONs from '${config_location}/Dashboards'"
else
  echo "Access Grafana: http://127.0.0.1:3000"
  echo "Username: admin"
  echo "Password: admin"
  echo ""
  echo "Add dashboards via: http://127.0.0.1:3000/dashboard/import"
  echo "Import JSONs from '${config_location}/Dashboards'"
  echo ""
  echo "It is advised to reboot your system after the initial setup has taken place"
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
  echo "1. GUI/TAB Based Logviewer (separate tabs; easy)"
  echo "2. TMUX Logviewer (AIO logs; advanced)"

  read -p "Enter your choice (1 or 2): " choice

  case $choice in
  1)
    # Check if the log viewer script exists
    if [ -f "${config_location}/helper/log_viewer.sh" ]; then
      ${config_location}/helper/log_viewer.sh
    else
      echo -e "${RED}Error: Log viewer script not found at ${config_location}/helper/log_viewer.sh${NC}"
    fi
    ;;
  2)
    # Check if the tmux log viewer script exists
    if [ -f "${config_location}/helper/tmux_logviewer.sh" ]; then
      ${config_location}/helper/tmux_logviewer.sh
    else
      echo -e "${RED}Error: TMUX log viewer script not found at ${config_location}/helper/tmux_logviewer.sh${NC}"
    fi
    ;;
  *)
    echo "Invalid choice. Exiting."
    ;;
  esac
fi

# Call reboot prompt and advice functions
reboot_prompt
sleep 5
reboot_advice
exit 0

# Add function to setup automated health checks
setup_automated_health_checks() {
    echo -e "${GREEN}Setting up automated health checks...${NC}"
    
    # Create health check directory
    sudo mkdir -p /blockchain/monitoring/alerts
    
    # Create Prometheus alert rules
    cat > /blockchain/monitoring/alerts/node_alerts.yml << EOL
groups:
- name: node_alerts
  rules:
  - alert: NodeDown
    expr: up == 0
    for: 5m
    labels:
      severity: critical
    annotations:
      description: "Node {{ \$labels.instance }} has been down for more than 5 minutes"
      summary: "Node is down"

  - alert: HighSyncDelay
    expr: ethereum_sync_delay > 100
    for: 10m
    labels:
      severity: warning
    annotations:
      description: "Node {{ \$labels.instance }} sync delay is high (> 100 blocks)"
      summary: "High sync delay detected"

  - alert: DiskSpaceLow
    expr: node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"} * 100 < 10
    for: 5m
    labels:
      severity: warning
    annotations:
      description: "Disk space is below 10% on {{ \$labels.instance }}"
      summary: "Low disk space warning"

  - alert: HighCPUUsage
    expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 90
    for: 15m
    labels:
      severity: warning
    annotations:
      description: "CPU usage is above 90% on {{ \$labels.instance }} for more than 15 minutes"
      summary: "High CPU usage detected"

  - alert: HighMemoryUsage
    expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100 > 90
    for: 15m
    labels:
      severity: warning
    annotations:
      description: "Memory usage is above 90% on {{ \$labels.instance }} for more than 15 minutes"
      summary: "High memory usage detected"

  - alert: LowPeerCount
    expr: ethereum_peer_count < 10
    for: 10m
    labels:
      severity: warning
    annotations:
      description: "Peer count is below 10 on {{ \$labels.instance }}"
      summary: "Low peer count detected"

  - alert: BlockchainNotSyncing
    expr: increase(ethereum_block_height[1h]) == 0
    for: 1h
    labels:
      severity: critical
    annotations:
      description: "Blockchain is not syncing on {{ \$labels.instance }}"
      summary: "Blockchain sync stalled"
EOL

    # Update Prometheus configuration to include alerts
    cat > /blockchain/prometheus.yml << EOL
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "/etc/prometheus/alerts/*.yml"

alerting:
  alertmanagers:
  - static_configs:
    - targets:
      - localhost:9093

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
    - targets: ['localhost:6060']
EOL

    echo -e "${GREEN}Automated health checks have been set up${NC}"
    echo "Health checks will run every 15 minutes"
    echo "Check /blockchain/logs/health_check.log for results"
}

# Add health check setup to the main monitoring setup
setup_monitoring() {
    # ... existing monitoring setup code ...
    
    # Add health checks
    setup_automated_health_checks
    
    echo -e "${GREEN}Monitoring and health checks setup complete${NC}"
    echo "You can access Grafana at http://localhost:3000"
    echo "Default credentials: admin/admin"
    echo "Health check logs are in /blockchain/logs/health_check.log"
}

# Create health check script
cat > /blockchain/helper/health_check.sh << 'EOL'
#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Function to check if a service is running
check_service() {
    local service=$1
    if docker ps | grep -q "$service"; then
        echo -e "${GREEN}$service is running${NC}"
        return 0
    else
        echo -e "${RED}$service is not running${NC}"
        return 1
    fi
}

# Function to check disk space
check_disk_space() {
    local threshold=10
    local disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$disk_usage" -gt "$threshold" ]; then
        echo -e "${RED}Warning: Disk usage is at ${disk_usage}%${NC}"
        return 1
    else
        echo -e "${GREEN}Disk space OK (${disk_usage}% used)${NC}"
        return 0
    fi
}

# Function to check memory usage
check_memory() {
    local threshold=90
    local memory_usage=$(free | awk '/Mem:/ {print int($3/$2 * 100)}')
    if [ "$memory_usage" -gt "$threshold" ]; then
        echo -e "${RED}Warning: Memory usage is at ${memory_usage}%${NC}"
        return 1
    else
        echo -e "${GREEN}Memory usage OK (${memory_usage}%)${NC}"
        return 0
    fi
}

# Function to check sync status
check_sync_status() {
    local sync_status=$(curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
        http://localhost:8545)
    
    if echo "$sync_status" | grep -q "false"; then
        echo -e "${GREEN}Node is in sync${NC}"
        return 0
    else
        echo -e "${YELLOW}Node is still syncing${NC}"
        return 1
    fi
}

# Main health check
echo "Running health check..."
echo "======================"

check_service "execution"
check_service "beacon"
check_service "prometheus"
check_service "grafana"
check_disk_space
check_memory
check_sync_status

# Log results
logger "PulseChain node health check completed"
EOL

# Make health check script executable
sudo chmod +x /blockchain/helper/health_check.sh

# Create cron job for automated health checks
(crontab -l 2>/dev/null; echo "*/15 * * * * /blockchain/helper/health_check.sh > /blockchain/logs/health_check.log 2>&1") | crontab -

echo -e "${GREEN}Automated health checks have been set up${NC}"
echo "Health checks will run every 15 minutes"
echo "Check /blockchain/logs/health_check.log for results"

# Add after Grafana setup
# Change default Grafana password
GRAFANA_NEW_PASSWORD=$(openssl rand -base64 12)
curl -X PUT -H "Content-Type: application/json" \
     -d "{\"oldPassword\":\"admin\",\"newPassword\":\"$GRAFANA_NEW_PASSWORD\"}" \
     --user "admin:admin" \
     http://localhost:3000/api/user/password

echo "New Grafana password: $GRAFANA_NEW_PASSWORD"
echo "Please save this password securely!"

uninstall_monitoring() {
    echo "Removing monitoring setup..."
    
    # Stop and remove containers
    for container in prometheus node_exporter grafana; do
        sudo docker stop $container 2>/dev/null
        sudo docker rm $container 2>/dev/null
    done
    
    # Remove configuration
    [ -d "$config_location" ] && sudo rm -rf "$config_location"
    
    # Remove users
    sudo userdel prometheus 2>/dev/null
    sudo userdel grafana 2>/dev/null
    
    # Remove firewall rules
    sudo ufw delete allow from 127.0.0.1 to any port 8545 proto tcp
    sudo ufw delete allow from 127.0.0.1 to any port 8546 proto tcp
    sudo ufw delete allow from 127.0.0.1 to any port 5052 proto tcp
    
    echo "Monitoring setup removed successfully"
}
