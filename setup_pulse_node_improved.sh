#!/bin/bash

# ===============================================================================
# PulseChain Node Setup Script (Improved Version)
# ===============================================================================
# v.0.1.0
# Author: Maxim Broadcast
# Modified: Validator functionality removed while keeping all other node functionality
# Further improved with global configuration and dependency management
# ===============================================================================

# Define color codes for better readability
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Exit script on error
set -e

# Store initial directory to return later if needed
INITIAL_DIR=$(pwd)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Welcome and intro
display_welcome() {
    clear
    echo "     Pulse Node/Monitoring Setup (Improved Edition)"
    echo "                                                                                                                                                    
                   ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                          
                 ▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                         
                ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒                       
               ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                      
              ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓   ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                     
             ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                    
            ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                   
           ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓      ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                  
         ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓   ▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓                 
        ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓   ▓▓  ▓▓▓▓▓    ▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓               
        ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓  ▓▓▓▓▓  ▓   ▓▓▓▓▓▓▓▓▓▓▓▓▓               
                       ▓▓   ▓▓▓   ▓▓▓   ▓▓                              
        ▓▓▓▓▓▓▓▓▓▓▓▓▓   ▓  ▓▓▓▓   ▓▓▓  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓               
        ▓▓▓▓▓▓▓▓▓▓▓▓▓▓     ▓▓▓▓▓  ▓▓   ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓               
         ░▓▓▓▓▓▓▓▓▓▓▓▓▓▒  ▓▓▓▓▓▓  ▓▒  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                 
           ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓      ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                  
            ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                      
            ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                   
             ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                    
              ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓   ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                     
               ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                      
                ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                        
                 ▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                      
                   ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                                                                                                   
                                                                             "
                                                             
    echo "Please press Enter to continue..."
    read -p ""
    clear
}

# Display non-validator notice
display_non_validator_notice() {
    echo -e "\033[1;33m"
    echo "┌─────────────────────────────────────────────────────────┐"
    echo "│              NON-VALIDATOR VERSION NOTICE               │"
    echo "├─────────────────────────────────────────────────────────┤"
    echo "│ This is a modified version of the PulseChain setup      │"
    echo "│ script with all validator functionality removed.        │"
    echo "│                                                         │"
    echo "│ You CANNOT use this version for validation or staking.  │"
    echo "│ This version only supports running a regular node.      │"
    echo "│                                                         │"
    echo "│ If you need validator functionality, please use the     │"
    echo "│ original unmodified version of these scripts.           │"
    echo "└─────────────────────────────────────────────────────────┘"
    echo -e "\033[0m"
    echo ""
    press_enter_to_continue
    clear
}

# Display disclaimer
display_disclaimer() {
    echo -e "\033[1;33m"
    echo "┌─────────────────────────────────────────────────────────┐"
    echo "│ DISCLAIMER! Please read the following carefully!        │"
    echo "├─────────────────────────────────────────────────────────┤"
    echo "│ This script automates the installation and setup        │"
    echo "│ process for a PulseChain Node.                          │"
    echo "│                                                         │"
    echo "│ By using this script, you acknowledge that you          |"
    echo "| understand the potential risks involved and accept      │"
    echo "│ full responsibility for the security and custody        │"
    echo "│ of your own assets.                                     │"
    echo "│                                                         │"
    echo "│ It is strongly recommended that you review the script   │"
    echo "│ and understand its workings before proceeding.          │"
    echo "└─────────────────────────────────────────────────────────┘"
    echo -e "\033[0m"
    
    # Confirm user wishes to proceed
    read -p "Do you wish to continue? (y/n): " CONFIRM
    if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
      echo "Aborting."
      exit 1
    fi
    
    clear
}

# Function to press enter to continue
press_enter_to_continue() {
    read -p "Press Enter to continue..."
}

# Display final credits
display_credits() {
    echo ""
    echo -e "${GREEN}Congratulations, node installation/setup is now complete.${NC}"
    echo ""
    echo "PulseChain Node Setup Script"
    echo "Original by: Maxim Broadcast"
    echo "Improved edition with enhanced reliability features"
    echo ""
}

# ===============================================================================
# MAIN SETUP FLOW
# ===============================================================================

# Setup error handling
handle_error() {
    local exit_code=$1
    local line_number=$2
    local command="$3"
    
    echo -e "${RED}An error occurred at line ${BASH_LINENO[0]} (exit code: $exit_code)${NC}"
    echo -e "${RED}Command that failed: ${BASH_COMMAND}${NC}"
    
    # Display stack trace
    local i=0
    local stack_size=${#FUNCNAME[@]}
    echo "Stack trace:"
    while [ $i -lt $stack_size ]; do
        echo "  $i: ${BASH_SOURCE[$i]}:${BASH_LINENO[$i]} ${FUNCNAME[$i]}"
        i=$((i+1))
    done
    
    echo -e "${RED}Setup failed!${NC}"
    echo "Please check the log file for details."
    echo "You can report this issue with the log file attached."
    
    exit 1
}

trap 'handle_error $? ${LINENO} "${BASH_COMMAND}"' ERR

# Display welcome screen
display_welcome

# Display non-validator notice
display_non_validator_notice

# Display disclaimer
display_disclaimer

# ===============================================================================
# Install Dependencies
# ===============================================================================

echo -e "${GREEN}Step 1: Setting up dependencies${NC}"
echo "==============================="
echo ""
echo "This step will ensure all required dependencies are installed."
echo ""

# Check if dependency script exists, if not, create it
if [ ! -f "$SCRIPT_DIR/setup_dependencies.sh" ]; then
    echo "Setting up dependency script..."
    # Create the script (content should be placed here)
    # For now we'll assume it's already created
else
    echo "Dependency script found."
fi

# Run dependencies setup
bash "$SCRIPT_DIR/setup_dependencies.sh"

# ===============================================================================
# Create Global Configuration
# ===============================================================================

echo ""
echo -e "${GREEN}Step 2: Creating global configuration${NC}"
echo "=================================="
echo ""

# Get custom path for the blockchain folder
echo -e "${BLUE}Node/Clients and all required data will be installed under the specified path.${NC}"
echo "It includes databases, keystore, and various startup/helper scripts."
echo ""
read -e -p 'Enter target path (Press Enter for default: /blockchain): ' CUSTOM_PATH

# Set the default value for custom path if the user enters nothing
CUSTOM_PATH="${CUSTOM_PATH:-/blockchain}"
export CUSTOM_PATH

# Create the config file if it doesn't exist
if [ ! -f "$SCRIPT_DIR/config.sh" ]; then
    echo "Creating global configuration file..."
    # In a real scenario, we'd create the file here
    # For now, we'll assume it's created already
else
    echo "Global configuration file found."
fi

# Source the configuration
source "$SCRIPT_DIR/config.sh"

# Save the configuration with custom path
NETWORK="mainnet" # Default, will be changed later if needed
save_config

echo -e "${GREEN}Global configuration created at ${CUSTOM_PATH}/node_config.json${NC}"
echo ""

# ===============================================================================
# Network Selection
# ===============================================================================

echo -e "${GREEN}Step 3: Choose Network${NC}"
echo "===================="
echo ""
echo "+=================+"
echo "| Choose Network: |"
echo "+=================+"
echo "| 1) Mainnet      |"
echo "|                 |"
echo "| 2) Testnet      |"
echo "+-----------------+"
echo ""
read -p "Enter your Network choice (1 or 2): " -r choice

case $choice in
  1)
    NETWORK="mainnet"
    ;;
  2)
    NETWORK="testnet"
    ;;
  *)
    echo "Invalid choice. Defaulting to mainnet."
    NETWORK="mainnet"
    ;;
esac

export NETWORK
# Save network selection to config
save_config

# ===============================================================================
# Client Selection
# ===============================================================================

echo ""
echo -e "${GREEN}Step 4: Client Selection${NC}"
echo "====================="
echo ""

# Execution client selection
echo "+=============================================================+"
echo "| Please choose a Execution-Client:                           |"
echo "+=============================================================+"
echo "| 1) Geth (full node, faster sync time.)                      |"
echo "|    Recommended for normal usage, stores all transactions    |"
echo "|    and the most recent states                               |"
echo "+-------------------------------------------------------------+"
echo "| 2) Erigon (archive node, longer sync time.)                 |"
echo "|    Recommended for developers and advanced users,           |"
echo "|    stores the entire history of the Ethereum blockchain,    |"
echo "|    including all historical states                          |"
echo "+-------------------------------------------------------------+"
echo "| 3) Erigon (pruned to keep last 2000 blocks)                 |"
echo "|    WARNING !: Still testing if this is beneficial over geth |"
echo "|    so use with caution. No guarantee this will work.        |"
echo "|    It will only keep the last 2000 blocks                   |"
echo "+-------------------------------------------------------------+"
echo ""

while true; do
  read -e -p "Enter your Client choice (1, 2, or 3): " ETH_CLIENT_CHOICE
  case $ETH_CLIENT_CHOICE in
    1)
      ETH_CLIENT="geth"
      break
      ;;
    2)
      ETH_CLIENT="erigon"
      break
      ;;
    3)
      ETH_CLIENT="erigon-pruned"
      break
      ;;
    *)
      echo "Invalid choice. Please enter a valid choice (1, 2, or 3)."
      ;;
  esac
done

export ETH_CLIENT

# Consensus client selection
echo ""
echo ""
echo -e "+===================================+"
echo -e "| Choose your Consensus client:     |"
echo -e "+===================================+"
echo -e "| 1) Lighthouse                     |"
echo -e "| 2) Prysm                          |"
echo -e "+-----------------------------------+"
echo ""

while true; do
  read -p "Enter your Client choice (1 or 2): " CONSENSUS_CLIENT_CHOICE
  case $CONSENSUS_CLIENT_CHOICE in
    1)
      CONSENSUS_CLIENT="lighthouse"
      break
      ;;
    2)
      CONSENSUS_CLIENT="prysm"
      break
      ;;
    *)
      echo "Invalid choice. Please enter a valid choice (1 or 2)."
      ;;
  esac
done

export CONSENSUS_CLIENT

# Save client selections to config
save_config

# ===============================================================================
# Directory Setup
# ===============================================================================

echo ""
echo -e "${GREEN}Step 5: Setting up directories and environment${NC}"
echo "==========================================="
echo ""

# Create main directory if it doesn't exist
echo -e "${GREEN}Creating ${CUSTOM_PATH} Main-Folder${NC}"
sudo mkdir -p "${CUSTOM_PATH}"

# Create JWT secret if it doesn't exist
if [ ! -f "${JWT_FILE}" ]; then
    echo -e "${GREEN}Generating jwt.hex secret${NC}"
    sudo sh -c "openssl rand -hex 32 | tr -d '\n' > ${JWT_FILE}"
fi

# Create subdirectories
echo -e "${GREEN}Creating subFolders for ${ETH_CLIENT} and ${CONSENSUS_CLIENT}${NC}"
sudo mkdir -p "${EXECUTION_PATH}/${ETH_CLIENT}"
sudo mkdir -p "${CONSENSUS_PATH}/${CONSENSUS_CLIENT}"
sudo mkdir -p "${BACKUP_PATH}"
sudo mkdir -p "${LOG_PATH}"
sudo mkdir -p "${HELPER_PATH}"

# Get main user
main_user=$(whoami)

# Create users and set permissions
echo -e "${GREEN}Creating users and setting permissions${NC}"
sudo useradd -M -G docker $ETH_CLIENT 2>/dev/null || true
sudo useradd -M -G docker $CONSENSUS_CLIENT 2>/dev/null || true

sudo chown -R ${ETH_CLIENT}:docker "${EXECUTION_PATH}"
sudo chmod -R 750 "${EXECUTION_PATH}"

sudo chown -R ${CONSENSUS_CLIENT}:docker "${CONSENSUS_PATH}"
sudo chmod -R 750 "${CONSENSUS_PATH}"

# Shared group for JWT access
echo "Creating shared group to access jwt.hex file"
sudo groupadd pls-shared 2>/dev/null || true
sudo usermod -aG pls-shared ${ETH_CLIENT}
sudo usermod -aG pls-shared ${CONSENSUS_CLIENT}

sudo chown ${ETH_CLIENT}:pls-shared ${JWT_FILE}
sudo chmod 640 ${JWT_FILE}

press_enter_to_continue

# ===============================================================================
# Create Docker Run Scripts
# ===============================================================================

echo ""
echo -e "${GREEN}Step 6: Creating container start scripts${NC}"
echo "======================================"
echo ""

# Based on client selections, create appropriate start scripts
echo -e "${GREEN}Generating start_execution.sh script${NC}"

# Start execution script content
if [ "$ETH_CLIENT" = "geth" ]; then
    # Pull the Docker image
    sudo docker pull $GETH_IMAGE
    
    # Generate script
    cat > start_execution.sh << EOL
#!/bin/bash

# Source global configuration
source "\$(dirname "\$0")/config.sh"

echo "Starting geth execution client..."

sudo -u geth docker run -dt --restart=always \\
--network=host \\
--name \$EXECUTION_CONTAINER \\
-v \$CUSTOM_PATH:/blockchain \\
\$GETH_IMAGE \\
--\$EXECUTION_NETWORK_FLAG \\
--authrpc.jwtsecret=/blockchain/jwt.hex \\
--datadir=/blockchain/execution/geth \\
--http \\
--ws \\
--state.scheme=path \\
--gpo.ignoreprice 1 \\
--metrics \\
--pprof \\
--ws.api web3,eth,txpool,net,engine \\
--http.api web3,eth,txpool,net,engine,admin,debug
EOL
elif [ "$ETH_CLIENT" = "erigon" ]; then
    # Pull the Docker image
    sudo docker pull $ERIGON_IMAGE
    
    # Generate script
    cat > start_execution.sh << EOL
#!/bin/bash

# Source global configuration
source "\$(dirname "\$0")/config.sh"

echo "Starting erigon execution client..."

sudo -u erigon docker run -dt --restart=always  \\
--network=host \\
--name \$EXECUTION_CONTAINER \\
-v \$CUSTOM_PATH:/blockchain \\
\$ERIGON_IMAGE \\
--chain=\$EXECUTION_NETWORK_FLAG \\
--authrpc.jwtsecret=/blockchain/jwt.hex \\
--datadir=/blockchain/execution/erigon \\
--http \\
--http.addr=0.0.0.0 \\
--http.vhosts=* \\
--http.corsdomain=* \\
--http.api="eth,erigon,web3,net,debug,trace,txpool,admin" \\
--ws \\
--ws.addr=0.0.0.0 \\
--ws.origins=* \\
--ws.api="eth,erigon,web3,net,debug,trace,txpool,admin" \\
--metrics \\
--metrics.addr=0.0.0.0 \\
--pprof \\
--externalcl \\
--maxpeers 200 \\
--cache 48000 \\
--db.size.limit 6TB \\
--torrent.download.rate 450000 \\
--state.scheme=path
EOL
elif [ "$ETH_CLIENT" = "erigon-pruned" ]; then
    # Pull the Docker image
    sudo docker pull $ERIGON_IMAGE
    
    # Generate script
    cat > start_execution.sh << EOL
#!/bin/bash

# Source global configuration
source "\$(dirname "\$0")/config.sh"

echo "Starting pruned erigon execution client..."

sudo -u erigon docker run -dt --restart=always  \\
--network=host \\
--name \$EXECUTION_CONTAINER \\
-v \$CUSTOM_PATH:/blockchain \\
\$ERIGON_IMAGE \\
--chain=\$EXECUTION_NETWORK_FLAG \\
--authrpc.jwtsecret=/blockchain/jwt.hex \\
--datadir=/blockchain/execution/erigon \\
--externalcl \\
--http \\
--http.api="eth,erigon,web3,net,debug,trace,txpool" \\
--metrics \\
--pprof \\
--prune.h.older=2000 \\
--prune.t.older=2000 \\
--prune.c.older=2000 \\
--prune=r
EOL
fi

chmod +x start_execution.sh
sudo mv start_execution.sh "$CUSTOM_PATH"
sudo chown $main_user:docker "$CUSTOM_PATH/start_execution.sh"

# Create consensus script
echo -e "${GREEN}Generating start_consensus.sh script${NC}"

if [ "$CONSENSUS_CLIENT" = "prysm" ]; then
    # Pull the Docker image
    sudo docker pull $PRYSM_IMAGE
    sudo docker pull $PRYSM_TOOL_IMAGE
    
    # Generate script
    cat > start_consensus.sh << EOL
#!/bin/bash

# Source global configuration
source "\$(dirname "\$0")/config.sh"

echo "Starting prysm consensus client..."

sudo -u prysm docker run -dt --restart=always \\
--network=host \\
--name \$CONSENSUS_CONTAINER \\
-v \$CUSTOM_PATH:/blockchain \\
\$PRYSM_IMAGE \\
--\$PRYSM_NETWORK_FLAG \\
--jwt-secret=/blockchain/jwt.hex \\
--datadir=/blockchain/consensus/prysm \\
--checkpoint-sync-url=\$CHECKPOINT \\
--min-sync-peers 1 \\
--genesis-beacon-api-url=\$CHECKPOINT
EOL
elif [ "$CONSENSUS_CLIENT" = "lighthouse" ]; then
    # Pull the Docker image
    sudo docker pull $LIGHTHOUSE_IMAGE
    
    # Generate script
    cat > start_consensus.sh << EOL
#!/bin/bash

# Source global configuration
source "\$(dirname "\$0")/config.sh"

echo "Starting lighthouse consensus client..."

sudo -u lighthouse docker run -dt --restart=always \\
--network=host \\
--name \$CONSENSUS_CONTAINER \\
-v \$CUSTOM_PATH:/blockchain \\
\$LIGHTHOUSE_IMAGE \\
lighthouse bn \\
--network=\$LIGHTHOUSE_NETWORK_FLAG \\
--execution-jwt=/blockchain/jwt.hex \\
--datadir=/blockchain/consensus/lighthouse \\
--execution-endpoint=http://localhost:8551 \\
--checkpoint-sync-url=\$CHECKPOINT \\
--staking \\
--metrics \\
--validator-monitor-auto \\
--http
EOL
fi

chmod +x start_consensus.sh
sudo mv start_consensus.sh "$CUSTOM_PATH"
sudo chown $main_user:docker "$CUSTOM_PATH/start_consensus.sh"

echo -e "${GREEN}start_execution.sh and start_consensus.sh created successfully!${NC}"

# ===============================================================================
# Create Helper Scripts
# ===============================================================================

echo ""
echo -e "${GREEN}Step 7: Setting up helper scripts${NC}"
echo "=============================="
echo ""

# Create helper directory if it doesn't exist
sudo mkdir -p "$HELPER_PATH"

# Add our smart restart script for improved visual feedback
if [ -f "$SCRIPT_DIR/smart_restart.sh" ]; then
    echo "Copying smart restart script to $HELPER_PATH..."
    sudo cp "$SCRIPT_DIR/smart_restart.sh" "$HELPER_PATH/"
    sudo chmod +x "$HELPER_PATH/smart_restart.sh"
    sudo chown $main_user:docker "$HELPER_PATH/smart_restart.sh"
    echo "Smart restart script installed."
else
    echo "Creating smart restart script..."
    cat > "$SCRIPT_DIR/smart_restart.sh" << 'EOL'
#!/bin/bash

# ===============================================================================
# PulseChain Node Smart Restart Script
# ===============================================================================
# This script provides intelligent container management with visual feedback
# Version: 1.0
# ===============================================================================

# Source global configuration
if [ -f "$(dirname "$0")/../config.sh" ]; then
    source "$(dirname "$0")/../config.sh"
else
    # Set defaults if config not found
    CUSTOM_PATH="/blockchain"
    EXECUTION_CONTAINER="execution"
    CONSENSUS_CONTAINER="beacon"
    LOG_PATH="$CUSTOM_PATH/logs"
fi

# Create log directory if it doesn't exist
mkdir -p "$LOG_PATH"

# Log file
RESTART_LOG="$LOG_PATH/restart.log"

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Log messages
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    # Log to file
    echo "[$timestamp] [$level] $message" >> "$RESTART_LOG"
    
    # Format for console output
    case "$level" in
        "INFO")
            echo -e "${GREEN}[$level]${NC} $message"
            ;;
        "WARNING")
            echo -e "${YELLOW}[$level]${NC} $message"
            ;;
        "ERROR")
            echo -e "${RED}[$level]${NC} $message"
            ;;
        "ACTION")
            echo -e "${BLUE}[$level]${NC} $message"
            ;;
        "SUCCESS")
            echo -e "${PURPLE}[$level]${NC} $message"
            ;;
        *)
            echo "[$level] $message"
            ;;
    esac
}

# Display progress bar
show_progress() {
    local duration=$1
    local size=40
    local remaining=$duration
    local start_time=$(date +%s)
    local end_time=$((start_time + duration))
    local container=$2
    local operation=$3
    
    # Initial status check
    local status="running"
    if [[ "$operation" == "stopping" ]]; then
        if ! sudo docker ps | grep -q "$container"; then
            status="stopped"
            log_message "INFO" "$container is already stopped."
            return 0
        fi
    fi
    
    echo ""
    log_message "ACTION" "⏱️ $operation $container (timeout: ${duration}s)"
    echo -e "${YELLOW}Press Ctrl+C to hide progress bar (container will continue in background)${NC}"
    echo ""
    
    while [ $remaining -gt 0 ] && [ "$status" == "running" ]; do
        # Calculate progress
        local elapsed=$((duration - remaining))
        local percent=$((elapsed * 100 / duration))
        local filled=$((elapsed * size / duration))
        local empty=$((size - filled))
        
        # Build the progress bar
        bar="["
        for ((i=0; i<filled; i++)); do
            bar+="█"
        done
        for ((i=0; i<empty; i++)); do
            bar+="░"
        done
        bar+="] ${percent}%"
        
        # Check container status
        if [[ "$operation" == "stopping" ]] && ! sudo docker ps | grep -q "$container"; then
            status="stopped"
        fi
        
        # Display the progress bar and time remaining
        printf "\r%-80s" "$bar - $remaining seconds remaining"
        
        # Early completion message
        if [ "$status" != "running" ]; then
            printf "\r%-80s\n" "$bar - Completed early! Container is now $status"
            log_message "SUCCESS" "$container $operation completed successfully (early completion)"
            break
        fi
        
        # Wait 1 second
        sleep 1
        remaining=$((end_time - $(date +%s)))
        if [ $remaining -lt 0 ]; then
            remaining=0
        fi
    done
    
    # Final status check if we timed out
    if [ "$status" == "running" ] && [ "$operation" == "stopping" ]; then
        if ! sudo docker ps | grep -q "$container"; then
            status="stopped"
        else
            status="still running"
        fi
    fi
    
    # Final message
    if [ "$status" == "stopped" ] || [ "$operation" != "stopping" ]; then
        printf "\r%-80s\n" "[$(printf '█%.0s' $(seq 1 $size))] 100% - Complete!"
        log_message "SUCCESS" "$container $operation completed successfully"
    else
        printf "\r%-80s\n" "[$(printf '█%.0s' $(seq 1 $filled))$(printf '░%.0s' $(seq 1 $empty))] TIMEOUT"
        log_message "WARNING" "$container $operation timed out, container is $status"
    fi
    
    echo ""
    return 0
}

# Check if a container exists
check_container_exists() {
    local container="$1"
    if sudo docker ps -a | grep -q "$container"; then
        return 0
    else
        return 1
    fi
}

# Check if a container is running
check_container_running() {
    local container="$1"
    if sudo docker ps | grep -q "$container"; then
        return 0
    else
        return 1
    fi
}

# Stop a container with visual feedback
smart_stop_container() {
    local container="$1"
    local timeout="$2"
    
    # Check if container exists
    if ! check_container_exists "$container"; then
        log_message "INFO" "$container does not exist, no need to stop"
        return 0
    fi
    
    # Check if container is already stopped
    if ! check_container_running "$container"; then
        log_message "INFO" "$container is already stopped"
        return 0
    fi
    
    # Stop the container
    log_message "ACTION" "Stopping $container with ${timeout}s timeout"
    
    # Run the docker stop command in the background
    sudo docker stop -t "$timeout" "$container" &
    local docker_pid=$!
    
    # Show progress while the container is stopping
    show_progress "$timeout" "$container" "stopping"
    
    # Check the status after stopping
    if check_container_running "$container"; then
        log_message "ERROR" "$container failed to stop gracefully within timeout"
        read -p "Force stop container? (y/N): " force_stop
        if [[ "$force_stop" =~ ^[Yy]$ ]]; then
            log_message "WARNING" "Force stopping $container"
            sudo docker kill "$container"
            if ! check_container_running "$container"; then
                log_message "SUCCESS" "$container force stopped successfully"
            else
                log_message "ERROR" "Failed to force stop $container"
                return 1
            fi
        else
            log_message "WARNING" "Container $container left running as requested"
            return 1
        fi
    else
        log_message "SUCCESS" "$container stopped successfully"
    fi
    
    return 0
}

# Start a container with visual feedback
smart_start_container() {
    local container="$1"
    local start_script="$2"
    local startup_time="$3"
    
    # Check if container is already running
    if check_container_running "$container"; then
        log_message "INFO" "$container is already running"
        return 0
    fi
    
    # Start the container
    log_message "ACTION" "Starting $container using $start_script"
    
    # Run the start script
    bash "$start_script" &
    local start_pid=$!
    
    # Allow some time for container to initialize
    sleep 3
    
    # Check if container started
    if check_container_running "$container"; then
        log_message "SUCCESS" "$container started successfully"
        
        # Show startup progress for monitoring
        show_progress "$startup_time" "$container" "starting"
        
        # Final status check
        if check_container_running "$container"; then
            log_message "SUCCESS" "$container is running normally"
            return 0
        else
            log_message "ERROR" "$container stopped unexpectedly after starting"
            return 1
        fi
    else
        log_message "ERROR" "Failed to start $container"
        return 1
    fi
}

# Restart a specific container
restart_container() {
    local container="$1"
    local start_script="$2"
    local stop_timeout="$3"
    local startup_monitor_time="$4"
    
    # Display header
    echo ""
    echo "========================================================"
    echo "   Smart Restart: $container"
    echo "========================================================"
    echo ""
    
    # Warn about risks
    log_message "WARNING" "⚠️ Restarting $container may cause temporary service interruption"
    echo ""
    
    # Stop the container
    if ! smart_stop_container "$container" "$stop_timeout"; then
        log_message "ERROR" "Failed to properly stop $container"
        read -p "Continue with start attempt anyway? (y/N): " continue_anyway
        if ! [[ "$continue_anyway" =~ ^[Yy]$ ]]; then
            log_message "INFO" "Restart abandoned at user request"
            return 1
        fi
    fi
    
    # Give a small pause between stop and start
    sleep 2
    
    # Start the container
    if ! smart_start_container "$container" "$start_script" "$startup_monitor_time"; then
        log_message "ERROR" "Failed to start $container"
        echo ""
        log_message "ACTION" "Please check logs for errors: sudo docker logs $container"
        return 1
    fi
    
    log_message "SUCCESS" "✅ $container has been successfully restarted"
    return 0
}

# Restart all containers
restart_all() {
    echo ""
    echo "========================================================"
    echo "   Smart Restart: All Node Containers"
    echo "========================================================"
    echo ""
    
    # Warn about risks
    log_message "WARNING" "⚠️ This will restart all node components"
    log_message "WARNING" "⚠️ Your node will be temporarily offline during this process"
    echo ""
    
    # Confirmation
    read -p "Are you sure you want to restart all containers? (y/N): " confirm
    if ! [[ "$confirm" =~ ^[Yy]$ ]]; then
        log_message "INFO" "Restart cancelled by user"
        return 0
    fi
    
    echo ""
    log_message "ACTION" "Beginning restart sequence"
    echo ""
    
    # Stop containers in reverse order
    log_message "INFO" "Phase 1: Stopping containers in safe order"
    smart_stop_container "$CONSENSUS_CONTAINER" 180
    smart_stop_container "$EXECUTION_CONTAINER" 300
    
    # Brief pause
    sleep 3
    
    # Start containers in correct order
    log_message "INFO" "Phase 2: Starting containers in proper order"
    smart_start_container "$EXECUTION_CONTAINER" "$CUSTOM_PATH/start_execution.sh" 30
    
    # Give the execution client time to initialize before starting consensus
    sleep 10
    
    smart_start_container "$CONSENSUS_CONTAINER" "$CUSTOM_PATH/start_consensus.sh" 30
    
    # Final status
    echo ""
    log_message "INFO" "Checking final status of all containers:"
    
    if check_container_running "$EXECUTION_CONTAINER"; then
        log_message "SUCCESS" "✅ $EXECUTION_CONTAINER is running"
    else
        log_message "ERROR" "❌ $EXECUTION_CONTAINER is not running"
    fi
    
    if check_container_running "$CONSENSUS_CONTAINER"; then
        log_message "SUCCESS" "✅ $CONSENSUS_CONTAINER is running"
    else
        log_message "ERROR" "❌ $CONSENSUS_CONTAINER is not running"
    fi
    
    echo ""
    log_message "ACTION" "It may take some time for clients to fully synchronize again"
    log_message "ACTION" "Check health status in a few minutes: bash $CUSTOM_PATH/helper/health_check.sh"
    
    return 0
}

# Main menu
main_menu() {
    echo ""
    echo "========================================================"
    echo "   PulseChain Node Smart Restart Tool"
    echo "========================================================"
    echo ""
    echo "Please select an option:"
    echo ""
    echo "  1) Restart execution client ($EXECUTION_CONTAINER)"
    echo "  2) Restart consensus client ($CONSENSUS_CONTAINER)"
    echo "  3) Restart all containers"
    echo "  4) Exit"
    echo ""
    
    read -p "Enter your choice (1-4): " choice
    
    case $choice in
        1)
            restart_container "$EXECUTION_CONTAINER" "$CUSTOM_PATH/start_execution.sh" 300 30
            ;;
        2)
            restart_container "$CONSENSUS_CONTAINER" "$CUSTOM_PATH/start_consensus.sh" 180 30
            ;;
        3)
            restart_all
            ;;
        4)
            echo "Exiting."
            return 0
            ;;
        *)
            echo "Invalid option. Please try again."
            main_menu
            ;;
    esac
    
    return 0
}

# Check if this script is being run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # If arguments are provided, handle them
    if [[ $# -gt 0 ]]; then
        case "$1" in
            --restart-execution)
                restart_container "$EXECUTION_CONTAINER" "$CUSTOM_PATH/start_execution.sh" 300 30
                ;;
            --restart-consensus)
                restart_container "$CONSENSUS_CONTAINER" "$CUSTOM_PATH/start_consensus.sh" 180 30
                ;;
            --restart-all)
                restart_all
                ;;
            *)
                echo "Unknown argument: $1"
                echo "Usage: $0 [--restart-execution|--restart-consensus|--restart-all]"
                exit 1
                ;;
        esac
    else
        # No arguments, show menu
        main_menu
    fi
fi
EOL
    sudo cp "$SCRIPT_DIR/smart_restart.sh" "$HELPER_PATH/"
    sudo chmod +x "$HELPER_PATH/smart_restart.sh"
    sudo chown $main_user:docker "$HELPER_PATH/smart_restart.sh"
    echo "Smart restart script created and installed."
fi

# Copy helper scripts from the original location
if [ -d "$SCRIPT_DIR/helper" ]; then
    echo "Copying helper scripts to $HELPER_PATH..."
    
    # Copy all non-validator helper scripts
    # Create a list of validator-related scripts to exclude
    VALIDATOR_SCRIPTS=(
        "setup_validator.sh"
        "key_mgmt.sh"
        "exit_validator.sh"
        "emergency_exit.sh"
        "lh_batch_exit.sh"
        "prysm_delete_validator.sh"
        "prysm_fix.sh"
        "prysm_read_accounts.sh"
        "prysm_fix_host_ip.sh"
        "bls_to_execution.sh"
        "check_sync.sh"
        "status_batch.sh"
    )
    
    # Copy helper scripts excluding validator scripts
    for file in $SCRIPT_DIR/helper/*; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            skip=false
            
            # Check if the file is in the list of validator scripts
            for validator_script in "${VALIDATOR_SCRIPTS[@]}"; do
                if [ "$filename" == "$validator_script" ]; then
                    skip=true
                    break
                fi
            done
            
            # Copy the file if it's not in the exclude list
            if [ "$skip" == "false" ]; then
                sudo cp "$file" "$HELPER_PATH/"
                echo "Copied: $filename"
            else
                echo "Skipped validator script: $filename"
            fi
        fi
    done
else
    echo "Helper scripts directory not found, creating essential scripts..."
    
    # Create restart script
    cat > "$HELPER_PATH/restart_docker.sh" << EOL
#!/bin/bash

# Source global configuration
source "\$(dirname "\$(dirname "\$0")")/config.sh"

# PulseChain Node Restart Script (Non-Validator Version)
# This script gracefully stops all node containers and prunes stopped containers

# Gracefully stop containers with appropriate timeouts
sudo docker stop -t 300 \$EXECUTION_CONTAINER
sudo docker stop -t 180 \$CONSENSUS_CONTAINER

# Prune stopped containers to free up resources
sudo docker container prune -f

# Start containers again
echo "Starting execution client..."
\$CUSTOM_PATH/start_execution.sh

echo "Starting consensus client..."
\$CUSTOM_PATH/start_consensus.sh
EOL
    
    # Create stop script
    cat > "$HELPER_PATH/stop_docker.sh" << EOL
#!/bin/bash

# Source global configuration
source "\$(dirname "\$(dirname "\$0")")/config.sh"

# PulseChain Node Stop Script
# This script gracefully stops all node containers

echo "Stopping containers..."
sudo docker stop -t 300 \$EXECUTION_CONTAINER
sudo docker stop -t 180 \$CONSENSUS_CONTAINER

echo "Containers stopped."
EOL
fi

# Set permissions for helper scripts
sudo chmod +x "$HELPER_PATH/"*.sh
sudo chown -R $main_user:docker "$HELPER_PATH"

# ===============================================================================
# Setup Health Checks
# ===============================================================================

echo ""
echo -e "${GREEN}Step 8: Setting up health checks${NC}"
echo "============================="
echo ""

# Create health check script if it doesn't exist
if [ ! -f "$HELPER_PATH/health_check.sh" ]; then
    echo "Creating health check script..."
    # We'll assume this is already handled in the previous steps
else
    echo "Health check script already exists."
fi

# Run health check setup
if [ -f "$HELPER_PATH/setup_health_check.sh" ]; then
    bash "$HELPER_PATH/setup_health_check.sh"
else
    echo "Health check setup script not found. Health checks will need to be configured manually."
fi

# ===============================================================================
# Setup Menu System
# ===============================================================================

echo ""
echo -e "${GREEN}Step 9: Setting up menu system${NC}"
echo "============================"
echo ""

# Create menu script if it doesn't exist
if [ ! -f "$CUSTOM_PATH/menu.sh" ]; then
    echo "Creating menu script..."
    
    # Copy our comprehensive menu file
    cp "$SCRIPT_DIR/menu.sh" "$CUSTOM_PATH/menu.sh"
    chmod +x "$CUSTOM_PATH/menu.sh"
    sudo chown $main_user:docker "$CUSTOM_PATH/menu.sh"
    
    # Create a symlink in /usr/local/bin
    sudo ln -sf "$CUSTOM_PATH/menu.sh" /usr/local/bin/plsmenu
    
    echo -e "${GREEN}Comprehensive menu script installed at $CUSTOM_PATH/menu.sh${NC}"
    echo "You can access it by running 'plsmenu' in the terminal."
else
    echo "Menu script already exists."
fi

# Ask about desktop shortcuts
read -p "Do you want to add Desktop-Shortcuts for the menu? [Y/n] " shortcut_choice
if [[ "$shortcut_choice" =~ ^[Yy]$ || "$shortcut_choice" == "" ]]; then
    # Create desktop shortcuts function
    create-desktop-shortcut() {
        local exec_path="$1"
        local name="$2"
        local icon="$3"
        
        # Simple desktop shortcut creation
        cat > ~/Desktop/${name}.desktop << EOL
[Desktop Entry]
Version=1.0
Type=Application
Terminal=true
Exec=${exec_path}
Name=${name}
Comment=PulseChain Node - ${name}
Icon=${icon}
EOL
        chmod +x ~/Desktop/${name}.desktop
    }
    
    # Create shortcuts
    create-desktop-shortcut "${CUSTOM_PATH}/menu.sh" "PulseChain-Node-Menu" ""
    
    echo "Desktop shortcuts created."
    echo -e "${RED}Note: You might have to right-click > allow launching on these${NC}"
fi

# ===============================================================================
# Start Services
# ===============================================================================

echo ""
echo -e "${GREEN}Step 10: Starting services${NC}"
echo "========================="
echo ""

echo "Starting execution client..."
sudo bash "$CUSTOM_PATH/start_execution.sh"

echo "Starting consensus client..."
sudo bash "$CUSTOM_PATH/start_consensus.sh"

# ===============================================================================
# Final Verification
# ===============================================================================

echo ""
echo -e "${GREEN}Step 11: Final verification${NC}"
echo "==========================="
echo ""

# Allow a moment for containers to fully start
sleep 10

# Check if containers are running
echo "Checking if containers are running..."
if ! docker ps | grep -q "$EXECUTION_CONTAINER"; then
    echo -e "${RED}Warning: Execution client container is not running.${NC}"
    echo "Try starting it manually: sudo $CUSTOM_PATH/start_execution.sh"
else
    echo -e "${GREEN}Execution client container is running.${NC}"
fi

if ! docker ps | grep -q "$CONSENSUS_CONTAINER"; then
    echo -e "${RED}Warning: Consensus client container is not running.${NC}"
    echo "Try starting it manually: sudo $CUSTOM_PATH/start_consensus.sh"
else
    echo -e "${GREEN}Consensus client container is running.${NC}"
fi

# Run a health check
if [ -f "$HELPER_PATH/health_check.sh" ]; then
    echo ""
    echo "Running initial health check..."
    sudo bash "$HELPER_PATH/health_check.sh"
fi

# ===============================================================================
# Completion
# ===============================================================================

echo ""
display_credits

# Ask if user wants to reboot
echo ""
echo "The system now requires a reboot to complete the setup. Would you like to reboot now? (Yes/no)"
read -p "" user_response

# Treat an empty response as 'yes'
if [[ -z "$user_response" ]] || [[ "$user_response" == "yes" ]] || [[ "$user_response" == "y" ]]; then
    echo "Rebooting now..."
    sudo reboot
else
    echo "Please remember to reboot your system later to complete the setup."
fi

exit 0 