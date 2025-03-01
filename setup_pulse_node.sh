#!/bin/bash

# v.1.1
# PulseChain Node Setup Script
# Author: Maxim Broadcast

# This script automates the installation and configuration of a PulseChain node.
# It handles dependencies, directory setup, Docker configuration, and network selection.
# The script is designed to be user-friendly with appropriate prompts and validations.

# Define color codes for better readability
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Exit script on error
set -e

# Set up error handling
trap 'handle_error $?' ERR

# Error handling function
handle_error() {
  echo -e "${RED}An error occurred. Exit code: $1${NC}"
  echo "Cleaning up and restoring state..."
  # Add any cleanup actions needed here
  exit 1
}

# Store initial directory to return later if needed
start_dir=$(pwd)
script_dir=$(dirname "$0")

# Import helper functions
if [ ! -f "$script_dir/functions.sh" ]; then
  echo -e "${RED}Error: Required functions.sh file not found!${NC}"
  exit 1
fi
source "$script_dir/functions.sh"

clear
echo "     Pulse Node/Validator/Monitoring Setup"
echo "                                                                                                                                                    
                   ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                          
                 ▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                         
                ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒                       
               ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                      
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

echo -e "\033[1;33m"
echo "┌─────────────────────────────────────────────────────────┐"
echo "│ DISCLAIMER! Please read the following carefully!        │"
echo "├─────────────────────────────────────────────────────────┤"
echo "│ This script automates the installation and setup        │"
echo "│ process for a PulseChain Node/Validator.                │"
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

# Clear screen and continue with setup
clear

press_enter_to_continue
clear

# Continue with the rest of the script
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
    set_network_variables "mainnet"
    ;;
  2)
    set_network_variables "testnet"
    ;;
  *)
    echo "Invalid choice. Exiting."
    exit 1
    ;;
esac

#enabling ntp for timesyncronization
clear
echo ""
echo "We are going to setup the timezone first, it is important to be synced in time for the Chain to work correctly"
sleep 2
echo "enabling ntp for timesync"
sudo timedatectl set-ntp true
echo ""
echo "enabled ntp timesync"
echo ""
echo -e "${RED}Please choose your CORRECT timezone at the following screen${NC}"
echo ""
echo "Press Enter to continue..."
read -p ""
sudo dpkg-reconfigure tzdata
echo "timezone set"
sleep 1
echo ""
clear
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
      ETH_CLIENT="erigon"
      break
      ;;
    *)
      echo "Invalid choice. Please enter a valid choice (1, 2, or 3)."
      ;;
  esac
done


while true; do
  echo ""
  echo ""
  echo -e "+===================================+"
  echo -e "| Choose your Consensus client:     |"
  echo -e "+===================================+"
  echo -e "| 1) Lighthouse                     |"
  echo -e "| 2) Prysm                          |"
  echo -e "+-----------------------------------+"
  echo ""
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

# Enable tab autocompletion for the read command if line editing is enabled
if [ -n "$BASH_VERSION" ] && [ -n "$PS1" ] && [ -t 0 ]; then
  bind '"\t":menu-complete'
fi
clear

# Get custom path for the blockchain folder
echo ""
echo -e "+===============================================================+"
echo -e "| Node/Clients and all required DataFolders/files will be       |"
echo -e "| installed under the specified path. It includes databases,    |"
echo -e "| keystore, and various startup/helper scripts.                 |"
echo -e "+===============================================================+"
echo ""
read -e -p 'Enter target path (Press Enter for default: /blockchain): ' CUSTOM_PATH
echo ""

# Set the default value for custom path if the user enters nothing
if [ -z "$CUSTOM_PATH" ]; then
  CUSTOM_PATH="/blockchain"
fi

# Docker run commands for Ethereum clients
GETH_CMD="sudo -u geth docker run -dt --restart=always \\
--network=host \\
--name execution \\
-v ${CUSTOM_PATH}:/blockchain \\
registry.gitlab.com/pulsechaincom/go-pulse:latest \\
--${EXECUTION_NETWORK_FLAG} \\
--authrpc.jwtsecret=/blockchain/jwt.hex \\
--datadir=/blockchain/execution/geth \\
--http \\
--ws \\
--state.scheme=path \\
--gpo.ignoreprice 1 \\
--metrics \\
--pprof \\
--ws.api web3,eth,txpool,net,engine \\
--http.api web3,eth,txpool,net,engine,admin,debug "

ERIGON_CMD="sudo -u erigon docker run -dt --restart=always  \\
--network=host \\
--name execution \\
-v ${CUSTOM_PATH}:/blockchain \\
registry.gitlab.com/pulsechaincom/erigon-pulse:latest \\
--chain=${EXECUTION_NETWORK_FLAG} \\
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
--state.scheme=path"

ERIGON_CMD2="sudo -u erigon docker run -dt --restart=always  \\
--network=host \\
--name execution \\
-v ${CUSTOM_PATH}:/blockchain \\
registry.gitlab.com/pulsechaincom/erigon-pulse:latest \\
--chain=${EXECUTION_NETWORK_FLAG} \\
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
--prune=r  "

# Docker run commands for Consensus clients
PRYSM_CMD="# Retrieve the current IP address 
#IP=\$(curl -s ipinfo.io/ip)
#if [ -z \"\$IP\" ]; then
#    echo \"Failed to retrieve IP address. Exiting...\"
#    echo ""
#fi

sudo -u prysm docker run -dt --restart=always \\
--network=host \\
--name beacon \\
-v ${CUSTOM_PATH}:/blockchain \\
registry.gitlab.com/pulsechaincom/prysm-pulse/beacon-chain:latest \\
--${PRYSM_NETWORK_FLAG} \\
--jwt-secret=/blockchain/jwt.hex \\
--datadir=/blockchain/consensus/prysm \\
--checkpoint-sync-url=${CHECKPOINT} \\
--min-sync-peers 1 \\
--genesis-beacon-api-url=${CHECKPOINT} \\
#--p2p-host-ip \$IP
"

LIGHTHOUSE_CMD="sudo -u lighthouse docker run -dt --restart=always \\
--network=host \\
--name beacon \\
-v ${CUSTOM_PATH}:/blockchain \\
registry.gitlab.com/pulsechaincom/lighthouse-pulse:latest \\
lighthouse bn \\
--network=${LIGHTHOUSE_NETWORK_FLAG} \\
--execution-jwt=/blockchain/jwt.hex \\
--datadir=/blockchain/consensus/lighthouse \\
--execution-endpoint=http://localhost:8551 \\
--checkpoint-sync-url=${CHECKPOINT} \\
--staking \\
--metrics \\
--validator-monitor-auto \\
--http "

# Use the variables in both single and separate script modes
clear
# check for any snap Version of docker installed and remove it (because it enables images to be mounted writable only in home folders)

if snap list | grep -q '^docker '; then
    echo "Docker snap package found. Removing..."
    sudo snap remove docker
else
    echo "No Docker snap package found."
fi

# Add the deadsnakes PPA repository to install the latest Python version
echo -e "${GREEN}Adding deadsnakes PPA to get the latest Python Version${NC}"
sudo add-apt-repository ppa:deadsnakes/ppa -y
echo ""
echo -e "${GREEN}Installing Dependencies...${NC}"
sudo apt-get update -y
sudo apt-get upgrade -y
echo ""
# Perform distribution upgrade and remove unused packages
sudo apt-get dist-upgrade -y
sudo apt autoremove -y
echo ""
# Install required packages
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    htop \
    gnupg \
    git \
    ufw \
    tmux \
    dialog \
    rhash \
    openssl \
    wmctrl \
    jq \
    lsb-release \
    dbus-x11 \
    python3.8 python3.8-venv python3.8-dev python3-pip
echo ""
# Downloading Docker
echo -e "${GREEN}Adding Docker PPA and installing Docker${NC}"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
"deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
echo ""
sudo apt-get update -y
echo ""
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose
echo ""
clear
echo -e "${GREEN}Starting and enabling docker service${NC}"
sudo systemctl start docker
sudo systemctl enable docker

# Adding Main user to the Docker group
add_user_to_docker_group


echo -e "${GREEN}Creating ${CUSTOM_PATH} Main-Folder${NC}"
sudo mkdir "${CUSTOM_PATH}"
echo ""
echo -e "${GREEN}Generating jwt.hex secret${NC}"
sudo sh -c "openssl rand -hex 32 | tr -d '\n' > ${CUSTOM_PATH}/jwt.hex"
echo ""
echo -e "${GREEN}Creating subFolders for ${ETH_CLIENT} and ${CONSENSUS_CLIENT}${NC}"
sudo mkdir -p "${CUSTOM_PATH}/execution/$ETH_CLIENT"
sudo mkdir -p "${CUSTOM_PATH}/consensus/$CONSENSUS_CLIENT"
echo ""

get_main_user

echo -e "${GREEN}Creating the users ${ETH_CLIENT} and ${CONSENSUS_CLIENT} and setting permissions to the folders${NC}"

sudo useradd -M -G docker $ETH_CLIENT
sudo useradd -M -G docker $CONSENSUS_CLIENT

sudo chown -R ${ETH_CLIENT}:docker "${CUSTOM_PATH}/execution"
sudo chmod -R 750 "${CUSTOM_PATH}/execution"

sudo chown -R ${CONSENSUS_CLIENT}:docker "${CUSTOM_PATH}/consensus/"
sudo chmod -R 750 "${CUSTOM_PATH}/consensus"

press_enter_to_continue


echo "Creating shared group to access jwt.hex file"

# Permission Madness
# defining group for jwt.hex file
sudo groupadd pls-shared
sudo usermod -aG pls-shared ${ETH_CLIENT}
sudo usermod -aG pls-shared ${CONSENSUS_CLIENT}

# defining file permissions for jwt.hexSS
#echo "ETH_CLIENT: ${ETH_CLIENT}"
#echo "CUSTOM_PATH: ${CUSTOM_PATH}"
#echo "File path: ${CUSTOM_PATH}/jwt.hex"
#ls -l "${CUSTOM_PATH}/jwt.hex"

sleep 1
sudo chown ${ETH_CLIENT}:pls-shared ${CUSTOM_PATH}/jwt.hex
sleep 1
sudo chmod 640 ${CUSTOM_PATH}/jwt.hex
sleep 1

#ls -l "${CUSTOM_PATH}/jwt.hex"
press_enter_to_continue
#clear
echo ""

# Firewall Setup



# Prompt for the Rules to add

echo -e "${GREEN}Setting up firewall to allow access to SSH and port 8545 for localhost and private network connection to the RPC.${NC}"

ip_range=$(get_ip_range)
read -p "Do you want to allow access to the RPC and SSH from within your local network ($ip_range) only? (y/N): " local_network_choice
read -p "Do you want to allow RPC (8545) access ?(y/N): " rpc_choice

if [[ $rpc_choice == "y" ]]; then
  sudo ufw allow from 127.0.0.1 to any port 8545 proto tcp comment 'RPC Port'
  if [[ $local_network_choice == "y" ]]; then
    sudo ufw allow from $ip_range to any port 8545 proto tcp comment 'RPC Port for private IP range'
  fi
  
  # Add option for remote AI indexing machine
  read -p "Do you want to allow a specific remote machine to access the RPC for AI indexing? (y/N): " ai_indexing_choice
  if [[ $ai_indexing_choice == "y" ]]; then
    read -p "Enter the IP address of the AI indexing machine: " ai_machine_ip
    if [[ -n "$ai_machine_ip" ]]; then
      sudo ufw allow from $ai_machine_ip to any port 8545 proto tcp comment 'RPC Port for AI indexing machine'
      sudo ufw allow from $ai_machine_ip to any port 8546 proto tcp comment 'WebSocket Port for AI indexing machine'
      echo "Allowed RPC and WebSocket access from $ai_machine_ip"
    fi
  fi
fi

read -p "Do you want to allow SSH access to this server? (y/N): " ssh_choice

if [[ $ssh_choice == "y" ]]; then 
  read -p "Enter SSH port (default is 22): " ssh_port 
  if [[ $ssh_port == "" ]]; then 
    ssh_port=22 
  fi 
  
  if [[ $local_network_choice == "n" ]]; then 
    sudo ufw allow $ssh_port/tcp comment 'SSH Port' 
  elif [[ $local_network_choice == "y" ]]; then 
    sudo ufw allow from $ip_range to any port $ssh_port proto tcp comment 'SSH Port for private IP range' 
  fi 
fi
 

#############################################################################################################

echo ""
echo -e "${GREEN}Setting Firewall to default, deny incomming and allow outgoing, enabling the Firewall${NC}"
echo ""
sudo ufw default deny incoming
echo ""
sudo ufw default allow outgoing
echo ""
# Allow inbound traffic for specific ports based on user choices 
if [ "$ETH_CLIENT_CHOICE" = "1" ]; then # as per https://geth.ethereum.org/docs/fundamentals/security
  sudo ufw allow 30303/tcp
  sudo ufw allow 30303/udp
  
elif [ "$ETH_CLIENT_CHOICE" = "2" ]; then #as per https://github.com/ledgerwatch/erigon
  sudo ufw allow 30303/tcp
  sudo ufw allow 30303/udp
  sudo ufw allow 30304/tcp
  sudo ufw allow 30304/udp
  sudo ufw allow 42069/tcp
  sudo ufw allow 42069/udp
  sudo ufw allow 4000/udp
  sudo ufw allow 4001/tcp
fi


if [ "$CONSENSUS_CLIENT" = "prysm" ]; then #as per https://docs.prylabs.network/docs/prysm-usage/p2p-host-ip
  sudo ufw allow 13000/tcp
  sudo ufw allow 12000/udp
elif [ "$CONSENSUS_CLIENT" = "lighthouse" ]; then #as per https://lighthouse-book.sigmaprime.io/faq.html
  sudo ufw allow 9000
fi

echo ""
echo "enabling firewall now..."
sudo ufw enable
sleep 1
clear
echo ""
echo "The Ethereum and Consensus clients will be started separately using two different scripts."
echo "The start_execution.sh script will start the execution client."
echo "The start_consensus.sh script will start the consensus (beacon) client."
echo "The scripts will be generated in the directory \"$CUSTOM_PATH\"."
echo ""
echo "Generating scripts..."

echo ""
echo -e "${GREEN}Generating start_execution.sh script${NC}"
cat > start_execution.sh << EOL
#!/bin/bash

echo "Starting ${ETH_CLIENT}"

EOL

if [ $ETH_CLIENT_CHOICE = "1" ]; then
    sudo docker pull registry.gitlab.com/pulsechaincom/go-pulse:latest
    cat >> start_execution.sh << EOL
${GETH_CMD}
EOL
fi

if [ $ETH_CLIENT_CHOICE = "2" ]; then
    sudo docker pull registry.gitlab.com/pulsechaincom/erigon-pulse:latest
    cat >> start_execution.sh << EOL
${ERIGON_CMD}
EOL
fi

if [ $ETH_CLIENT_CHOICE = "3" ]; then
    cat >> start_execution.sh << EOL
${ERIGON_CMD2}
EOL
fi

chmod +x start_execution.sh
sudo mv start_execution.sh "$CUSTOM_PATH"
sudo chown $main_user:docker "$CUSTOM_PATH/start_execution.sh"

echo ""
echo -e "${GREEN}Generating start_consensus.sh script${NC}"
cat > start_consensus.sh << EOL
#!/bin/bash

echo "Starting ${CONSENSUS_CLIENT}"

EOL

if [ "$CONSENSUS_CLIENT" = "prysm" ]; then
sudo docker pull registry.gitlab.com/pulsechaincom/prysm-pulse/beacon-chain:latest
sudo docker pull registry.gitlab.com/pulsechaincom/prysm-pulse/prysmctl:latest
  cat >> start_consensus.sh << EOL
${PRYSM_CMD}

EOL
elif [ "$CONSENSUS_CLIENT" = "lighthouse" ]; then
sudo docker pull registry.gitlab.com/pulsechaincom/lighthouse-pulse:latest
  cat >> start_consensus.sh << EOL
${LIGHTHOUSE_CMD}

EOL
fi

chmod +x start_consensus.sh
sudo mv start_consensus.sh "$CUSTOM_PATH"
sudo chown $main_user:docker "$CUSTOM_PATH/start_consensus.sh"

echo ""
echo -e "${GREEN}start_execution.sh and start_consensus.sh created successfully!${NC}"
echo ""
echo ""
# Create the helper directory if it doesn't exist
sudo mkdir -p "${CUSTOM_PATH}/helper"

# Create AI indexing configuration file if needed
if [[ "$ETH_CLIENT_CHOICE" = "2" && "$ai_indexing_choice" == "y" ]]; then
  echo ""
  echo -e "${GREEN}Creating AI indexing configuration file${NC}"
  
  # Create the AI indexing directory
  sudo mkdir -p "${CUSTOM_PATH}/ai_indexing"
  
  # Get the server's IP address for the node connection
  SERVER_IP=$(hostname -I | awk '{print $1}')
  
  # Ask for database details if not already provided
  read -p "Would you like to configure database details for the indexer? (y/N): " db_config_choice
  if [[ "$db_config_choice" == "y" ]]; then
    read -p "Enter database type (default: postgresql): " db_type
    db_type=${db_type:-postgresql}
    
    read -p "Enter database username: " db_user
    read -p "Enter database password: " db_password
    read -p "Enter database host (default: localhost): " db_host
    db_host=${db_host:-localhost}
    
    read -p "Enter database port (default: 5432): " db_port
    db_port=${db_port:-5432}
    
    read -p "Enter database name (default: blockchain_index): " db_name
    db_name=${db_name:-blockchain_index}
    
    DB_CONNECTION="${db_type}://${db_user}:${db_password}@${db_host}:${db_port}/${db_name}"
  else
    DB_CONNECTION="postgresql://username:password@localhost:5432/blockchain_index"
  fi
  
  # Create the configuration file with actual values
  cat > ai_indexing_config.json << EOL
{
  "node": {
    "url": "http://${SERVER_IP}:8545",
    "ws_url": "ws://${SERVER_IP}:8546"
  },
  "indexing": {
    "start_block": 0,
    "batch_size": 1000,
    "concurrency": 5
  },
  "database": {
    "type": "${db_type:-postgresql}",
    "connection_string": "${DB_CONNECTION}"
  },
  "api": {
    "port": 3001,
    "host": "0.0.0.0",
    "rate_limit": 100
  }
}
EOL
  
  sudo mv ai_indexing_config.json "${CUSTOM_PATH}/ai_indexing/"
  sudo chown $main_user:docker "${CUSTOM_PATH}/ai_indexing/ai_indexing_config.json"
  echo "AI indexing configuration file created at ${CUSTOM_PATH}/ai_indexing/ai_indexing_config.json"
  echo "The configuration includes your server's IP (${SERVER_IP}) and the database connection details you provided."
  echo ""
fi

echo ""
echo -e "${GREEN}copying over helper scripts${NC}"

sudo cp setup_validator.sh "$CUSTOM_PATH/helper"
sudo cp setup_monitoring.sh "$CUSTOM_PATH/helper"
sudo cp functions.sh "$CUSTOM_PATH/helper"
sudo cp helper/* "$CUSTOM_PATH/helper"

# Permissions to folders
sudo chmod -R +x $CUSTOM_PATH/helper/
sudo chmod -R 755 $CUSTOM_PATH/helper/
sudo chown -R $main_user:docker $CUSTOM_PATH/helper

echo ""
echo -e "${GREEN}Finished copying helper scripts${NC}"
echo ""

echo ""
echo "Creating a small menu for general housekeeping"
echo ""
menu_script="$(script_launch_template)"
menu_script+="$(printf '\nhelper_scripts_path="%s/helper"\n' "${CUSTOM_PATH}")"
menu_script+="$(menu_script_template)"

# Write the menu script to the helper directory
echo "${menu_script}" | sudo tee "${CUSTOM_PATH}/menu.sh" > /dev/null 2>&1
sudo chmod +x "${CUSTOM_PATH}/menu.sh"
sudo cp "${CUSTOM_PATH}/menu.sh" /usr/local/bin/plsmenu > /dev/null 2>&1
sudo chown -R $main_user:docker $CUSTOM_PATH/menu.sh

echo "Menu script has been generated and written to ${CUSTOM_PATH}/menu.sh"

read -p "Do you want to add Desktop-Shortcuts to a menu for general logging and node/validator settings (Recommended)? [Y/n] " log_choice
echo ""
echo -e "${RED}Note: You might have to right-click > allow launching on these${NC}"
echo ""
if [[ "$log_choice" =~ ^[Yy]$ || "$log_choice" == "" ]]; then
    create-desktop-shortcut ${CUSTOM_PATH}/helper/tmux_logviewer.sh tmux_LOGS
    create-desktop-shortcut ${CUSTOM_PATH}/helper/log_viewer.sh ui_LOGS
    #create-desktop-shortcut ${CUSTOM_PATH}/helper/restart_docker.sh Restart-clients
    create-desktop-shortcut ${CUSTOM_PATH}/helper/stop_docker.sh Stop-clients
    #create-desktop-shortcut ${CUSTOM_PATH}/helper/update_docker.sh Update-clients
    create-desktop-shortcut ${CUSTOM_PATH}/menu.sh Node-Menu ${CUSTOM_PATH}/helper/LogoVector.svg
fi

echo "Menu generated and copied over to /usr/local/bin/plsmenu - you can open this helper menu by running plsmenu in the terminal"
echo ""
press_enter_to_continue


###### added features
cron
grace
#beacon

# setting 775 for the exeuction folder, in case of backup
sudo chmod 775 -R $CUSTOM_PATH/execution

# setting 777 for install_path 
sudo chmod 777 -R ${INSTALL_PATH}

clear

echo ""
echo -e "${GREEN}Congratulations, node installation/setup is now complete.${NC}"
echo ""  
display_credits

# Inform the user that a reboot is required, making 'Yes' the default choice
echo ""
echo "The system now requires a reboot to complete the setup. Would you like to reboot now? (Yes/no)"

read -p "" user_response

# Treat an empty response as 'yes'
if [[ -z "$user_response" ]] || [[ "$user_response" == "yes" ]] || [[ "$user_response" == "y" ]]; then
    echo "Rebooting the system..."
    sleep 1
    sudo reboot
else
    echo "Please reboot the system manually to complete the setup."
    exit 0
fi
  exit 0
