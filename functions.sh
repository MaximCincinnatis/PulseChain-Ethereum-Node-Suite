# PulseChain Node Setup Functions
# v.1.1
# Author: Maxim Broadcast
# Modified: Validator functionality removed while keeping all other node functionality
# This file contains all shared functions used by the PulseChain node setup scripts.
# It handles network configuration, user management, validation, and various utility functions.

# ======== LOGGING FUNCTIONS ========

# Define log file location - will be overridden when CUSTOM_PATH is set
LOG_FILE="/tmp/pulse_node_setup.log"

# Initialize log file
init_logging() {
    local custom_path="$1"
    if [[ -n "$custom_path" ]]; then
        LOG_FILE="${custom_path}/pulse_node_setup.log"
    fi
    
    # Create or clear the log file
    echo "=== PulseChain Node Setup Log $(date) ===" > "$LOG_FILE"
    echo "System: $(uname -a)" >> "$LOG_FILE"
    chmod 644 "$LOG_FILE"
    
    log_info "Logging initialized at $LOG_FILE"
}

# Log levels
log_debug() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [DEBUG] $1" >> "$LOG_FILE"
}

log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $1" >> "$LOG_FILE"
    echo -e "${GREEN}INFO:${NC} $1"
}

log_warning() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARNING] $1" >> "$LOG_FILE"
    echo -e "${YELLOW}WARNING:${NC} $1"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1" >> "$LOG_FILE"
    echo -e "${RED}ERROR:${NC} $1"
}

# Execute command with logging
# Usage: exec_cmd "Description of command" command args
exec_cmd() {
    local description="$1"
    shift
    local cmd="$@"
    
    log_info "$description"
    log_debug "Executing: $cmd"
    
    # Create a temporary file for command output
    local output_file=$(mktemp)
    
    # Execute the command and capture both stdout and stderr
    if ! eval "$cmd" > "$output_file" 2>&1; then
        local exit_code=$?
        log_error "Command failed with exit code $exit_code: $cmd"
        log_error "Command output:"
        cat "$output_file" >> "$LOG_FILE"
        echo -e "${RED}Command failed:${NC} $description"
        echo "See the log file for details: $LOG_FILE"
        rm "$output_file"
        return $exit_code
    fi
    
    # Log command output at debug level
    log_debug "Command output:"
    cat "$output_file" >> "$LOG_FILE"
    rm "$output_file"
    
    return 0
}

# ======== NETWORK CONFIGURATION FUNCTIONS ========

# Sets network variables based on chosen network (mainnet or testnet)
# Args:
#   $1: "testnet" or "mainnet"
set_network_variables() {
  if [[ $1 == "testnet" ]]; then
    CHECKPOINT="https://checkpoint.v4.testnet.pulsechain.com"
    LAUNCHPAD_URL="https://launchpad.v4.testnet.pulsechain.com"
    EXECUTION_NETWORK_FLAG="pulsechain-testnet-v4"
    PRYSM_NETWORK_FLAG="pulsechain-testnet-v4"
    LIGHTHOUSE_NETWORK_FLAG="pulsechain_testnet_v4"
    DEPOSIT_CLI_NETWORK="pulsechain-testnet-v4"
  else
    CHECKPOINT="https://checkpoint.pulsechain.com"
    LAUNCHPAD_URL="https://launchpad.pulsechain.com"
    EXECUTION_NETWORK_FLAG="pulsechain"
    PRYSM_NETWORK_FLAG="pulsechain"
    LIGHTHOUSE_NETWORK_FLAG="pulsechain"
    DEPOSIT_CLI_NETWORK="pulsechain"
  fi

  # Export variables to make them available globally
  export CHECKPOINT
  export LAUNCHPAD_URL
  export EXECUTION_NETWORK_FLAG
  export PRYSM_NETWORK_FLAG
  export LIGHTHOUSE_NETWORK_FLAG
  export DEPOSIT_CLI_NETWORK
}

# Prompts the user to select a network if not already set
# This ensures the correct network flags are used throughout the script
check_and_set_network_variables() {
  if [[ -z $EXECUTION_NETWORK_FLAG ]]; then
    echo ""
    echo "+-----------------+"
    echo "| Choose network: |"
    echo "+-----------------+"
    echo "| 1) Mainnet      |"
    echo "|                 |"
    echo "| 2) Testnet      |"
    echo "+-----------------+"
    echo ""
    read -p "Enter your choice (1 or 2): " -r choice
    echo ""

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
  fi
}

# ======== LOG VIEWER FUNCTIONS ========

# Prompts the user to start a log viewer to monitor client logs
# Offers two options: GUI/TAB based (easy) or TMUX based (advanced)
function logviewer_prompt() {
  local log_it choice

  # Verify INSTALL_PATH is set
  if [[ -z "${INSTALL_PATH}" ]]; then
    echo "Error: INSTALL_PATH is not set. Cannot start log viewer."
    return 1
  fi

  # Verify helper directory exists
  if [[ ! -d "${INSTALL_PATH}/helper" ]]; then
    echo "Error: Helper directory not found at ${INSTALL_PATH}/helper"
    return 1
  fi

  read -e -p "$(echo -e "${GREEN}Would you like to start the logviewer to monitor the client logs? [y/n]:${NC}")" log_it

  if [[ "$log_it" =~ ^[Yy]$ ]]; then
    while true; do
      echo "Choose a log viewer:"
      echo "1. GUI/TAB Based Logviewer (separate tabs; easy)"
      echo "2. TMUX Logviewer (AIO logs; advanced)"

      read -p "Enter your choice (1 or 2): " choice

      case $choice in
        1)
          if [[ -x "${INSTALL_PATH}/helper/log_viewer.sh" ]]; then
            ${INSTALL_PATH}/helper/log_viewer.sh
          else
            echo "Error: Log viewer script not found or not executable"
            return 1
          fi
          break
          ;;
        2)
          if [[ -x "${INSTALL_PATH}/helper/tmux_logviewer.sh" ]]; then
            ${INSTALL_PATH}/helper/tmux_logviewer.sh
          else
            echo "Error: TMUX log viewer script not found or not executable"
            return 1
          fi
          break
          ;;
        *)
          echo "Invalid choice. Please enter 1 or 2."
          ;;
      esac
    done
  fi
}

# ======== ADDRESS VALIDATION FUNCTIONS ========

# Converts an Ethereum address to a valid ERC20 address with checksum
# Args:
#   $1: Input address to convert
function to_valid_erc20_address() {
    local input_address="$1"
    local input_address_lowercase="${input_address,,}"  # Convert to lowercase

    # Validate input format
    if ! [[ "$input_address_lowercase" =~ ^0x[a-f0-9]{40}$ ]]; then
        echo "Error: Invalid address format. Must be 0x followed by 40 hex characters."
        return 1
    fi

    # Calculate the Keccak-256 hash of the lowercase input address using openssl
    local hash=$(echo -n "${input_address_lowercase}" | openssl dgst -sha3-256 -binary | xxd -p -c 32)

    # Build the checksum address
    local checksum_address="0x"
    for ((i=0;i<${#input_address_lowercase};i++)); do
        char="${input_address_lowercase:$i:1}"
        if [ "${char}" != "${char^^}" ]; then
            checksum_address+="${input_address:$i:1}"
        else
            checksum_address+="${hash:$((i/2)):1}"
        fi
    done

    echo "$checksum_address"
}

function restart_tmux_logs_session() {
    # Check if the "logs" tmux session is running
    if tmux has-session -t logs 2>/dev/null; then
        echo "Tmux session 'logs' is running, restarting it."
        press_enter_to_continue
        start_script tmux_logviewer
        #echo "Tmux session 'logs' has been (re)started."
        # Kill the existing "logs" session
        tmux kill-session -t logs
    else
        echo "Tmux session 'logs' is not running."
    fi

}


function reboot_advice() {
    echo "Initial setup completed. To get all permissions right, it is recommended to reboot your system now ."
    read -p "Do you want to reboot now? [y/n]: " choice

    if [ "$choice" == "y" ]; then
        sudo reboot
    elif [ "$choice" == "n" ]; then
        echo "Please remember to reboot your system later."
    else
        echo "Invalid option. Please try again."
        reboot_advice
    fi
}

while getopts "rl" option; do
    case "$option" in
        r)
            sudo reboot
            ;;
        l)
            echo "Please remember to reboot your system later."
            ;;
        *)
            reboot_advice
            ;;
    esac
done

function get_user_choices() {
    echo "Choose your Validator Client"
    echo "based on your consensus/beacon Client"
    echo ""
    echo "1. Lighthouse (Authors choice)"
    echo "2. Prysm"
    echo ""
    read -p "Enter your choice (1 or 2): " client_choice

    # Validate user input for client choice
    while [[ ! "$client_choice" =~ ^[1-2]$ ]]; do
        echo "Invalid input. Please enter a valid choice (1 or 2): "
        read -p "Enter your choice (1 or 2): " client_choice
    done

    echo ""
    echo "Is this a first-time setup or are you adding to an existing setup?"
    echo ""
    echo "1. First-Time Validator Setup"
    echo "2. Add or Import to an Existing setup"
    echo "" 
    read -p "Enter your choice (1 or 2): " setup_choice

    # Validate user input for setup choice
    while [[ ! "$setup_choice" =~ ^[1-2]$ ]]; do
        echo "Invalid input. Please enter a valid choice (1 or 2): "
        read -p "Enter your choice (1 or 2): " setup_choice
    done

    #echo "${client_choice} ${setup_choice}"
}


function press_enter_to_continue(){
    echo ""
    echo "Press Enter to continue"
    read -p ""
    echo ""
}

function stop_docker_container() {
    local container_name_or_id="$1"
    local force_stop="${2:-false}"
    local timeout="${3:-180}"
    
    log_info "Attempting to stop Docker container: $container_name_or_id"
    
    # Check if container exists
    if ! docker ps -a | grep -q "$container_name_or_id"; then
        log_warning "No container found with name or ID: $container_name_or_id"
        return 0
    fi
    
    # Check if container is running
    container_status=$(docker inspect --format "{{.State.Status}}" "$container_name_or_id" 2>/dev/null)
    
    if [ "$container_status" == "running" ]; then
        log_info "Stopping container: $container_name_or_id with timeout of $timeout seconds"
        
        if [ "$force_stop" == "true" ]; then
            log_warning "Force stopping container $container_name_or_id"
            if ! exec_cmd "Force stopping container" sudo docker kill "$container_name_or_id"; then
                log_error "Failed to force stop container $container_name_or_id"
                return 1
            fi
        else
            if ! exec_cmd "Gracefully stopping container" sudo docker stop -t $timeout "$container_name_or_id"; then
                log_error "Failed to gracefully stop container $container_name_or_id"
                log_warning "Attempting to force stop the container"
                if ! exec_cmd "Force stopping container" sudo docker kill "$container_name_or_id"; then
                    log_error "Failed to force stop container $container_name_or_id"
                    return 1
                fi
            fi
        fi
        
        # Prune stopped containers
        log_info "Pruning stopped containers"
        if ! exec_cmd "Pruning stopped containers" sudo docker container prune -f; then
            log_warning "Failed to prune stopped containers"
        fi
        
        log_info "Container $container_name_or_id successfully stopped"
    elif [ -n "$container_status" ]; then
        log_info "Container $container_name_or_id is not running (status: $container_status)"
    else
        log_warning "Could not determine status of container $container_name_or_id"
    fi
    
    return 0
}


function display_credits() {
    echo ""
    echo "PulseChain Node Setup"
    echo "Brought to you by:
  ███╗   ███╗ █████╗ ██╗  ██╗██╗███╗   ███╗    ██████╗ ██████╗  ██████╗  █████╗ ██████╗  ██████╗ █████╗ ███████╗████████╗
  ████╗ ████║██╔══██╗╚██╗██╔╝██║████╗ ████║    ██╔══██╗██╔══██╗██╔═══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗██╔════╝╚══██╔══╝
  ██╔████╔██║███████║ ╚███╔╝ ██║██╔████╔██║    ██████╔╝██████╔╝██║   ██║███████║██║  ██║██║     ███████║███████╗   ██║   
  ██║╚██╔╝██║██╔══██║ ██╔██╗ ██║██║╚██╔╝██║    ██╔══██╗██╔══██╗██║   ██║██╔══██║██║  ██║██║     ██╔══██║╚════██║   ██║   
  ██║ ╚═╝ ██║██║  ██║██╔╝ ██╗██║██║ ╚═╝ ██║    ██████╔╝██║  ██║╚██████╔╝██║  ██║██████╔╝╚██████╗██║  ██║███████║   ██║   
  ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝     ╚═╝    ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝   ╚═╝   "
    echo ""
}

function tab_autocomplete(){
    
    # Enable tab autocompletion for the read command if line editing is enabled
    if [ -n "$BASH_VERSION" ] && [ -n "$PS1" ] && [ -t 0 ]; then
        bind '"\t":menu-complete'
    fi
}

function common_task_software_check(){
    log_info "Checking for required software packages..."

    # Check if req. software is installed
    python_check=$(python3.8 --version 2>/dev/null)
    docker_check=$(docker --version 2>/dev/null)
    docker_compose_check=$(docker-compose --version 2>/dev/null)
    openssl_check=$(openssl version 2>/dev/null)
    
    # Install the req. software only if not already installed
    if [[ -z "${python_check}" || -z "${docker_check}" || -z "${docker_compose_check}" || -z "${openssl_check}" ]]; then
        log_info "Installing required packages..."
        
        # Add Python PPA
        if [[ -z "${python_check}" ]]; then
            log_info "Adding Python repository"
            if ! exec_cmd "Adding Python PPA" sudo add-apt-repository ppa:deadsnakes/ppa -y; then
                log_error "Failed to add Python PPA. Please check your internet connection and try again."
                return 1
            fi
        fi
        
        # Add Docker repository
        if [[ -z "${docker_check}" || -z "${docker_compose_check}" ]]; then
            log_info "Adding Docker repository"
            if ! exec_cmd "Adding Docker GPG key" "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg"; then
                log_error "Failed to add Docker GPG key. Please check your internet connection and try again."
                return 1
            fi
            
            if ! exec_cmd "Adding Docker repository" "echo \"deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null"; then
                log_error "Failed to add Docker repository. Please check your internet connection and try again."
                return 1
            fi
        fi
        
        # Update package lists
        log_info "Updating package lists"
        if ! exec_cmd "Updating apt package lists" sudo apt-get update -y; then
            log_error "Failed to update package lists. Please check your internet connection and try again."
            return 1
        fi
        
        # Install Python if needed
        if [[ -z "${python_check}" ]]; then
            log_info "Installing Python 3.8"
            if ! exec_cmd "Installing Python 3.8" sudo apt-get install -y python3.8 python3.8-venv python3.8-dev python3-pip; then
                log_error "Failed to install Python. Please try again or install it manually."
                return 1
            fi
        fi
        
        # Install Docker if needed
        if [[ -z "${docker_check}" || -z "${docker_compose_check}" ]]; then
            log_info "Installing Docker and Docker Compose"
            if ! exec_cmd "Installing Docker and Docker Compose" sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose; then
                log_error "Failed to install Docker. Please try again or install it manually."
                return 1
            fi
        fi
        
        # Install OpenSSL if needed
        if [[ -z "${openssl_check}" ]]; then
            log_info "Installing OpenSSL"
            if ! exec_cmd "Installing OpenSSL" sudo apt-get install -y openssl; then
                log_error "Failed to install OpenSSL. Please try again or install it manually."
                return 1
            fi
        fi
        
        log_info "All required packages installed successfully."
    else
        log_info "All required packages are already installed."
    fi
    
    # Verify installations
    python_check=$(python3.8 --version 2>/dev/null)
    docker_check=$(docker --version 2>/dev/null)
    docker_compose_check=$(docker-compose --version 2>/dev/null)
    openssl_check=$(openssl version 2>/dev/null)
    
    if [[ -z "${python_check}" || -z "${docker_check}" || -z "${docker_compose_check}" || -z "${openssl_check}" ]]; then
        log_error "Some required packages failed to install properly."
        [[ -z "${python_check}" ]] && log_error "Python 3.8 is not available."
        [[ -z "${docker_check}" ]] && log_error "Docker is not available."
        [[ -z "${docker_compose_check}" ]] && log_error "Docker Compose is not available."
        [[ -z "${openssl_check}" ]] && log_error "OpenSSL is not available."
        return 1
    fi
    
    # Add current user to docker group if not already
    if ! groups | grep -q docker; then
        log_info "Adding current user to docker group"
        if ! exec_cmd "Adding user to docker group" sudo usermod -aG docker $USER; then
            log_warning "Failed to add user to docker group. You may need to run docker commands with sudo."
        else
            log_info "User added to docker group. You may need to log out and back in for this to take effect."
        fi
    fi
    
    return 0
}


function graffiti_setup() { 
    echo "" 
    while true; do
        read -e -p "$(echo -e "${GREEN}Please enter your desired graffiti. Ensure that it does not exceed 32 characters (default: MaximBroadcast):${NC}")" user_graffiti 

        # Set the default value for graffiti if the user enters nothing 
        if [ -z "$user_graffiti" ]; then 
            user_graffiti="MaximBroadcast" 
            break
        # Check if the input length is within the 32 character limit
        elif [ ${#user_graffiti} -le 32 ]; then
            break
        else
            echo -e "${RED}The graffiti you entered is too long. Please ensure it does not exceed 32 characters.${NC}"
        fi
    done

    # Enclose the user_graffiti in double quotes
    user_graffiti="\"${user_graffiti}\""
}
 
 

function set_install_path() {
    echo ""
    read -e -p "$(echo -e "${GREEN}Please specify the directory for storing the validator data. Press Enter to use the default (/blockchain):${NC} ")" INSTALL_PATH
    if [ -z "$INSTALL_PATH" ]; then
        INSTALL_PATH="/blockchain"
    fi

    if [ ! -d "$INSTALL_PATH" ]; then
        sudo mkdir -p "$INSTALL_PATH"
        echo "Created the directory: $INSTALL_PATH"
    else
        echo "The directory already exists: $INSTALL_PATH"
    fi
}

function get_install_path() {
    echo ""
    read -e -p "$(echo -e "${GREEN}Please specify the directory where your blockchain data root folder is located. Press Enter to use the default (/blockchain): ${NC} ")" INSTALL_PATH
    if [ -z "$INSTALL_PATH" ]; then
        INSTALL_PATH="/blockchain"
    fi
}



function get_active_network_device() {
     interface=$(ip route get 8.8.8.8 | awk '{print $5}')
     echo "Your online network interface is: $interface"
}

function cd_into_staking_cli() {
    cd ${INSTALL_PATH}/staking-deposit-cli
    sudo python3 setup.py install > /dev/null 2>&1
}

function network_interface_DOWN() {
    get_active_network_device
    echo "Shutting down Network-Device ${interface} ..."
    sudo ip link set $interface down
    echo "The network interface has been shutdown. It will be put back online after this process."

}

function start_scripts_first_time() {
    # Check if the user wants to run the scripts
    read -e -p "Do you want to run the scripts to start execution and consensus? (y/n) " choice
    if [[ "$choice" =~ ^[Yy]$ || "$choice" == "" ]]; then
        # Generate the commands to start the scripts
        commands=(
            "sudo ${INSTALL_PATH}/start_execution.sh > /dev/null 2>&1 &"
            "sudo ${INSTALL_PATH}/start_consensus.sh > /dev/null 2>&1 &"
        )

        # Run the commands
        for cmd in "${commands[@]}"; do
            echo "Running command: $cmd"
            eval "$cmd"
            sleep 1
        done
    fi
}

function clear_bash_history() {
    echo "Clearing bash history now..."
    history -c && history -w
    echo "Bash history cleared!"
}

function network_interface_UP() {
    echo "Restarting Network-Interface ${interface} ..."
    sudo ip link set $interface up
    echo "Network interface put back online"
}

function create_user() {
    target_user=$1
    if id "$target_user" >/dev/null 2>&1; then
        echo "User $target_user already exists."
    else
        sudo useradd -MG docker "$target_user"
        echo "User $target_user has been created and added to the docker group."
    fi
}

function clone_staking_deposit_cli() {
    target_directory=$1

    # Check if the staking-deposit-cli folder already exists
    if [ -d "${target_directory}/staking-deposit-cli" ]; then
        read -p "The staking-deposit-cli folder already exists. Do you want to delete it and clone the latest version? (y/N): " confirm_delete
        if [ "$confirm_delete" == "y" ] || [ "$confirm_delete" == "Y" ]; then
            sudo rm -rf "${target_directory}/staking-deposit-cli"
        else
            echo "Skipping the cloning process as the user chose not to delete the existing folder."
            return
        fi
    fi

    while true; do
        # Clone the staking-deposit-cli repository
        if sudo git clone https://gitlab.com/pulsechaincom/staking-deposit-cli.git "${target_directory}/staking-deposit-cli"; then
            echo "Cloned staking-deposit-cli repository into ${target_directory}/staking-deposit-cli"
            sudo chown -R $main_user:docker "${target_directory}/staking-deposit-cli"
            break
        else
            echo ""
            echo "Failed to clone staking-deposit-cli repository. Please check your internet connection and try again."
            echo ""
            echo "You can relaunch the script at any time with ./setup_validator.sh from the install folder."
            echo ""
            read -p "Press 'r' to retry, any other key to exit: " choice
            if [ "$choice" != "r" ]; then
                exit 1
            fi
        fi
    done
}

function Staking_Cli_launch_setup() {
    echo "Running staking-cli setup..."

    # Ensure Python 3.8 is installed
    echo "Ensuring Python 3.8 is installed..."
    sudo apt-get install -y software-properties-common
    sudo add-apt-repository -y ppa:deadsnakes/ppa
    sudo apt-get update
    sudo apt-get install -y python3.8 python3.8-venv python3.8-distutils python3.8-dev

    # Verify Python 3.8 installation
    #python3.8_version=$(python3.8 -V 2>&1)
    #if [[ $python3.8_version != "Python 3.8"* ]]; then
    #    echo "Error: Python 3.8 is not installed correctly."
    #    exit 1
    #fi
    #echo "Python 3.8 is successfully installed."

    # Check if the staking-deposit-cli folder exists
    if [ ! -d "${INSTALL_PATH}/staking-deposit-cli" ]; then
        echo "Error: staking-deposit-cli directory not found at ${INSTALL_PATH}."
        exit 1
    fi

    # Set up Python 3.8 virtual environment
    sudo chmod -R 777 ${INSTALL_PATH}/staking-deposit-cli
    echo "Setting up Python 3.8 virtual environment..."
    cd "${INSTALL_PATH}/staking-deposit-cli" || exit
    if [ ! -d "venv" ]; then
        python3.8 -m venv venv
    fi

    # Activate the virtual environment
    source venv/bin/activate

    # Install dependencies inside the virtual environment
    echo "Installing staking-deposit-cli dependencies in virtual environment..."
    pip install --upgrade pip setuptools > /dev/null 2>&1
    pip install -r requirements.txt > /dev/null 2>&1
    pip install . > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "Error: Failed to install dependencies."
        deactivate
        exit 1
    fi

    # Deactivate virtual environment
    deactivate

    # Grant necessary permissions
    echo "Granting necessary permissions..."
    sudo chmod -R 777 "${INSTALL_PATH}/staking-deposit-cli"

    echo "Staking-cli setup complete with virtual environment."
}

#function Staking_Cli_launch_setup() {
#    echo "Running staking-cli setup..."

    # Ensure Python 3.8 is installed
   # echo "Forcing installation of Python 3.8..."
   # sudo apt-get remove -y python3 python3.* python3-pip python3-venv
   # sudo apt-get purge -y python3 python3.* python3-pip python3-venv
   # sudo apt-get autoremove -y
   # sudo apt-get autoclean

#    sudo apt-get install -y software-properties-common
#    sudo add-apt-repository -y ppa:deadsnakes/ppa
#    sudo apt-get update
#    sudo apt-get install -y python3.8 python3.8-venv python3.8-distutils python3.8-dev

    # Ensure Python 3.8 is the default python3 version
 #   echo "Configuring Python 3.8 as the default python3 version..."
 #   sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.8 1
 #   sudo update-alternatives --set python3 /usr/bin/python3.8

    # Install pip for Python 3.8
 #   echo "Installing pip for Python 3.8..."
 #   sudo apt-get install -y python3-pip
 #   python3 -m pip install --upgrade pip setuptools

    # Verify Python 3.8 is correctly installed
  #  python3_version=$(python3 -V 2>&1 | awk '{print $2}')
  #  if [[ $python3_version != 3.8* ]]; then
  #      echo "Error: Python 3.8 is not correctly installed."
  #      exit 1
  #  fi
 #   echo "Python 3.8 setup complete."

    # Check if the staking-deposit-cli folder exists
#    if [ ! -d "${INSTALL_PATH}/staking-deposit-cli" ]; then
#        echo "Error: staking-deposit-cli directory not found at ${INSTALL_PATH}."
#        exit 1
#    fi

    # Grant necessary permissions and navigate to the folder
#    sudo chmod -R 777 "${INSTALL_PATH}/staking-deposit-cli"
#    cd "${INSTALL_PATH}/staking-deposit-cli" || exit

    # Install dependencies using pip
#    echo "Installing staking-deposit-cli dependencies..."
#    pip install -r requirements.txt > /dev/null 2>&1
#    pip install . --user > /dev/null 2>&1
#    if [ $? -ne 0 ]; then
#        echo "Error: Failed to install dependencies."
#        exit 1
#    fi

#    echo "Staking-cli setup complete."
#}

#function Staking_Cli_launch_setup() {
    # Check Python version (>= Python3.8)
#    echo "running staking-cli Checkup"
#    sudo chmod -R 777 "${INSTALL_PATH}/staking-deposit-cli"
#    cd "${INSTALL_PATH}/staking-deposit-cli"
#    python3_version=$(python3 -V 2>&1 | awk '{print $2}')
#    required_version="3.8"

#    if [ "$(printf '%s\n' "$required_version" "$python3_version" | sort -V | head -n1)" = "$required_version" ]; then
#        echo "Python version is greater or equal to 3.8"
#    else
#        echo "Error: Python version must be 3.8 or higher"
#        exit 1
#    fi

#    sudo pip3 install -r "${INSTALL_PATH}/staking-deposit-cli/requirements.txt" > /dev/null 2>&1
#    #read -p "debug 1" 
#    sudo python3 "${INSTALL_PATH}/staking-deposit-cli/setup.py" install > /dev/null 2>&1
#    #read -p "debug 2"
#}


function create_subfolder() {
    subdirectory=$1
    sudo mkdir -p "${INSTALL_PATH}/${subdirectory}"
    sudo chmod 777 "${INSTALL_PATH}/${subdirectory}"
    echo "Created directory: ${install_path}/${subdirectory}"
}

function confirm_prompt() {
    message="$1"
    while true; do
        echo "$message"
        read -p "Do you confirm? (y/n): " yn
        case $yn in
            [Yy]* )
                # User confirmed, return success (0)
                return 0
                ;;
            [Nn]* )
                # User did not confirm, return failure (1)
                return 1
                ;;
            * )
                # Invalid input, ask again
                echo "Please answer 'y' (yes) or 'n' (no)."
                ;;
        esac
    done
}



function create_prysm_wallet_password() {
    password_file="${INSTALL_PATH}/wallet/pw.txt"

    if [ -f "$password_file" ]; then
        echo ""
        echo -e "${RED}Warning: A password file already exists at ${password_file}${NC}"
        echo ""
        read -n 1 -p "Do you want to continue and overwrite the existing password file? (y/n) [n]: " confirm
        if [ "$confirm" != "y" ]; then
            echo "Cancelled password creation."
            return
        fi
    fi

    echo "" 
    echo ""
    echo -e "Please enter your Prysm Wallet password now."
    echo ""
    echo "This has nothing to do with the 24-word SeedPhrase that Staking-Cli will output during key-generation."
    echo "Unlocking your wallet is necessary for the Prysm Validator Client to function."
    echo ""
    while true; do
        echo "Please enter a password (must be at least 8 characters):"
        read -s password
        if [[ ${#password} -ge 8 ]]; then
            break
        else
            echo "Error: Password must be at least 8 characters long."
        fi
    done
    echo "$password" > "$password_file"
}

function check_and_pull_lighthouse() {
    # Check if the Lighthouse validator Docker image is present
    lighthouse_image_exists=$(sudo docker images registry.gitlab.com/pulsechaincom/lighthouse-pulse:latest -q)

    # If the image does not exist, pull the image
    if [ -z "$lighthouse_image_exists" ]; then
        echo ""
        echo "Lighthouse validator Docker image not found. Pulling the latest image..."
        sudo docker pull registry.gitlab.com/pulsechaincom/lighthouse-pulse:latest
        echo ""
    else
        echo ""
        echo "Lighthouse validator Docker image is already present."
        echo ""
    fi
}

function check_and_pull_prysm_validator() {
    # Check if the Prysm validator Docker image is present
    prysm_image_exists=$(sudo docker images registry.gitlab.com/pulsechaincom/prysm-pulse/validator:latest -q)
    # If the image does not exist, pull the image
    if [ -z "$prysm_image_exists" ]; then
        echo ""
        echo "Prysm validator Docker image not found. Pulling the latest image..."
        sudo docker pull registry.gitlab.com/pulsechaincom/prysm-pulse/validator:latest
        echo ""
    else
        echo ""
    fi
}

function stop_and_prune_validator_import(){
    sudo docker stop validator_import > /dev/null 2>&1
    sudo docker container prune -f > /dev/null 2>&1
}

function stop_docker_image(){
    echo "To import the keys into an existing setup, we need to stop the running validator container first."
    image=$1
    sudo docker stop -t 300 ${image} > /dev/null 2>&1
    sudo docker prune -f > /dev/null 2>&1
}

function start_script(){
    target=$1
    echo ""
    echo -e "Restarting ${target}"
    bash "${INSTALL_PATH}/helper/${target}.sh"
    echo "${target} container restartet"
}


#function import_lighthouse_validator() {
#    stop_and_prune_validator_import
#    echo ""
#    docker pull registry.gitlab.com/pulsechaincom/lighthouse-pulse:latest
#    echo ""
#    sudo docker run -it \
#        --name validator_import \
#        --network=host \
#        -v ${INSTALL_PATH}:/blockchain \
#        -v ${INSTALL_PATH}/validator_keys:/keys \
#        registry.gitlab.com/pulsechaincom/lighthouse-pulse:latest \
#        lighthouse \
#        --network=${LIGHTHOUSE_NETWORK_FLAG} \
#        account validator import \
#        --directory=/keys \
#        --datadir=/blockchain
#    stop_and_prune_validator_import
#}

function import_lighthouse_validator() {
    stop_and_prune_validator_import
    echo ""

    # Prompt the user
    echo -n "Are you importing multiple validators with the same password? (y/N): "
    read user_response

    # If nothing is entered, default to "N"
    if [ -z "$user_response" ]; then
        user_response="N"
    fi

    docker pull registry.gitlab.com/pulsechaincom/lighthouse-pulse:latest
    echo ""

    # Base command
    cmd="sudo docker run -it \
        --name validator_import \
        --network=host \
        -v ${INSTALL_PATH}:/blockchain \
        -v ${INSTALL_PATH}/validator_keys:/keys \
        registry.gitlab.com/pulsechaincom/lighthouse-pulse:latest \
        lighthouse \
        --network=${LIGHTHOUSE_NETWORK_FLAG} \
        account validator import \
        --directory=/keys \
        --datadir=/blockchain"

    # Conditionally add the --reuse-password flag
    if [ "${user_response,,}" == "y" ]; then
        cmd="$cmd \
        --reuse-password"
    fi

    # Execute the command
    eval $cmd

    stop_and_prune_validator_import
}


function import_prysm_validator() {
    stop_and_prune_validator_import
    echo ""
    docker pull registry.gitlab.com/pulsechaincom/prysm-pulse/validator:latest
    docker pull registry.gitlab.com/pulsechaincom/prysm-pulse/prysmctl:latest
    echo ""
    if [ -f "${INSTALL_PATH}/wallet/direct/accounts/all-accounts.keystore.json" ]; then
        sudo chmod -R 0600 "${INSTALL_PATH}/wallet/direct/accounts/all-accounts.keystore.json"
    fi
    docker run --rm -it \
        --name validator_import \
        -v $INSTALL_PATH/validator_keys:/keys \
        -v $INSTALL_PATH/wallet:/wallet \
        registry.gitlab.com/pulsechaincom/prysm-pulse/validator:latest \
        accounts import \
        --${PRYSM_NETWORK_FLAG} \
        --keys-dir=/keys \
        --wallet-dir=/wallet \
        --wallet-password-file=/wallet/pw.txt
    stop_and_prune_validator_import
}



function deposit_upload_info() {

    echo ""
    echo -e "Upload your 'deposit_data-xxxyyyzzzz.json' to ${LAUNCHPAD_URL} after the full chain sync. ${RED}Uploading before completion may result in slashing.${NC}"
    echo ""
    echo -e "${RED}For security reasons, it's recommended to store the validator_keys in a safe, offline location after importing it.${NC}"
    echo ""
    press_enter_to_continue
}

function warn_network() {

    echo ""
    echo "Enhance security by generating new keys or restoring them from a seed phrase (mnemonic) offline."
    echo ""
    echo -e "${RED}WARNING:${NC} Disabling your network interface may result in loss of remote"
    echo -e "         access to your machine. Ensure you have an alternative way to"
    echo -e "         access your machine, such as a local connection or a remote"
    echo -e "         VPS terminal, before proceeding."
    echo -e ""
    echo -e "${RED}IMPORTANT:${NC} Proceed with caution, as disabling the network interface"
    echo -e "           without any other means of access may leave you unable to"
    echo -e "           access your machine remotely. Make sure you fully understand"
    echo -e "           the consequences and have a backup plan in place before taking"
    echo -e "           this step."

    echo ""
    echo -e "Would you like to disable the network interface during the key"
    echo -e "generation process? This increases security, but ${RED}may affect remote"
    echo -e "access temporarily${NC}"
    echo ""
    read -e -p "Please enter 'y' to confirm or 'n' to decline (default: n): " network_off
    network_off=${network_off:-n}

}


function get_fee_receipt_address() {
    read -e -p "$(echo -e "${GREEN}Enter fee-receipt address (can be changed later in start_validator.sh):${NC}")" fee_wallet
    echo ""
    # Use a regex pattern to validate the input wallet address
    if [[ -z "${fee_wallet}" ]] || ! [[ "${fee_wallet}" =~ ^0x[a-fA-F0-9]{40}$ ]]; then
        fee_wallet=""
        echo " - No fee-receipt address provided"
    else
        echo " - Using provided fee-receipt address"
    fi
}

function get_user_choices_monitor() {
  local client_choice

  while true; do
    echo "Choose your Client"
    echo ""
    echo "1. Lighthouse"
    echo "2. Prysm"
    echo ""
    read -p "Enter your choice (1 or 2): " client_choice

    case $client_choice in
      1|2)
        break
        ;;
      *)
        echo "Invalid choice. Please enter 1 or 2."
        ;;
    esac
  done

  #echo "${client_choice}"
}

function add_user_to_docker_group() {
    # Check if the script is run as root
    if [ "$EUID" -eq 0 ]; then
        # Get the main non-root user
        local main_user=$(logname)

        # Check if the main user is already in the docker group
        if id -nG "${main_user}" | grep -qw "docker"; then
            echo "User ${main_user} is already a member of the docker group."
        else
            # Add the main user to the docker group
            usermod -aG docker "${main_user}"
            echo "User ${main_user} added to the docker group. Please log out and log back in for the changes to take effect."
        fi
    else
        # Get the current user
        local current_user=$(whoami)

        # Check if the user is already in the docker group
        if id -nG "${current_user}" | grep -qw "docker"; then
            echo "User ${current_user} is already a member of the docker group."
        else
            # Add the user to the docker group
            sudo usermod -aG docker "${current_user}"
            echo "User ${current_user} added to the docker group. Please log out and log back in for the changes to take effect."
        fi
    fi
}

function create-desktop-shortcut() {
  # Check if at least two arguments are provided
  if [[ $# -lt 2 ]]; then
      echo "Usage: create-desktop-shortcut <target-shell-script> <shortcut-name> [icon-path]"
      return 1
  fi

  # get main user
  main_user=$(logname || echo $SUDO_USER || echo $USER)

  # check if desktop directory exists for main user
  desktop_dir="/home/$main_user/Desktop"
  if [ ! -d "$desktop_dir" ]; then
    echo "Desktop directory not found for user $main_user"
    return 1
  fi

  # check if script file exists
  if [ ! -f "$1" ]; then
    echo "Script file not found: $1"
    return 1
  fi

  # set shortcut name
  shortcut_name=${2:-$(basename "$1" ".sh")}

  # set terminal emulator command
  terminal_emulator="gnome-terminal -- bash -c"

  # set icon path if provided and file exists
  icon_path=""
  if [[ -n "$3" ]] && [[ -f "$3" ]]; then
    icon_path="Icon=$3"
  fi

  # create shortcut file
  cat > "$desktop_dir/$shortcut_name.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=$shortcut_name
Exec=$terminal_emulator '$1; exec bash'
Terminal=true
$icon_path
EOF

  # make shortcut executable
  chmod +x "$desktop_dir/$shortcut_name.desktop"

  echo "Desktop shortcut created: $desktop_dir/$shortcut_name.desktop"
}

# Helper script function template
function script_launch_template() {
    cat <<-'EOF'
    script_launch() {
        local script_name=$1
        local script_path="${helper_scripts_path}/${script_name}"
        
        if [[ -x ${script_path} ]]; then
            ${script_path}
        else
            echo "Error: ${script_path} not found or not executable."
            exit 1
        fi
    }
EOF
}

function menu_script_template() {
    cat <<-'EOF' | sed "s|@@CUSTOM_PATH@@|$CUSTOM_PATH|g"
#!/bin/bash
CUSTOM_PATH="@@CUSTOM_PATH@@"
VERSION="1.5"
script_launch() {
    echo "Launching script: ${CUSTOM_PATH}/helper/$1"
    ${CUSTOM_PATH}/helper/$1
}

main_menu() {
    while true; do
        options=$(dialog --stdout --title "PulseChain Node Menu $VERSION" --backtitle "PulseChain Node Setup by Maxim Broadcast" --menu "Choose an option:" 0 0 0 \
                      "Node Status" "View Node Status and Information" \
                      "Clients Menu" "Execution and Beacon Clients" \
                      "Node Information" "Tools for Node Information" \
                      "-" ""\
                      "Log & Metrics Menu" "Log Viewer, Prometheus and Grafana" \
                      "Update Menu" "Update Clients, Scripts and More" \
                      "Archive Node Management" "Remote Access, API, and Indexing Support for Archive Node" \
                      "-" ""\
                      "Main Menu Settings" "Adjust Main-Menu Settings" \
                      "exit" "Exit")
        
        case $? in
          0)
            case $options in
                "Node Status")
                    clear && script_launch "node_status.sh"
                    ;;
                "Clients Menu")
                    client_actions_submenu
                    ;;
                "Node Information")
                    node_info_submenu
                    ;;
                "Archive Node Management")
                    archive_node_submenu
                    ;;
                "System")
                    system_submenu
                    ;;
                "-")
                    ;;
                "exit")
                    clear
                    break
                    ;;
            esac
            ;;
          1)
            break
            ;;
        esac
    done
}

logviewer_submenu() {
    while true; do
        lv_opt=$(dialog --stdout --title "Logviewer Menu $VERSION" --stdout --backtitle "PulseChain Node Setup by Maxim Broadcast" --menu "Choose an option:" 0 0 0 \
                        "Tabbed-Terminal Logs" "Multiple Tabs" \
                        "Tmux-Style Logs" "Single Window" \
                        "-" ""\
                        "back" "Back to main menu")

        case $? in
          0)
            case $lv_opt in
                "Tabbed-Terminal Logs")
                    clear && script_launch "log_viewer.sh"
                    ;;
                "Tmux-Style Logs")
                    clear && script_launch "tmux_logviewer.sh"
                    ;;
                "-")
                    ;;
                "back")
                    break
                    ;;
            esac
            ;;
          1)
            break
            ;;
        esac
    done
}

client_actions_submenu() {
    while true; do
        ca_opt=$(dialog --stdout --title "Client Menu $VERSION" --backtitle "PulseChain Node Setup by Maxim Broadcast" --menu "Choose an option:" 0 0 0 \
                        "Execution-Client Menu" ""\
                        "Beacon-Client Menu" ""\
                        "-" ""\
                        "Start all Clients" ""\
                        "Stop all Clients" ""\
                        "Restart all Clients" ""\
                        "Update all Clients" ""\
                        "-" ""\
                        "back" "Back to main menu")

        case $? in
          0)
            case $ca_opt in
                "Execution-Client Menu")
                    execution_submenu
                    ;;
                "Beacon-Client Menu")
                    beacon_submenu
                    ;;
                "-")
                    ;;
                "Start all Clients")
                    clear
                    ${CUSTOM_PATH}/start_execution.sh
                    ${CUSTOM_PATH}/start_consensus.sh
                    ;;
                "Stop all Clients")
                    clear && script_launch "stop_docker.sh"
                    ;;
                "Restart all Clients")
                    clear && script_launch "stop_docker.sh"
                    ${CUSTOM_PATH}/start_execution.sh
                    ${CUSTOM_PATH}/start_consensus.sh
                    ;;
                "Update all Clients")
                    clear && script_launch "update_docker.sh"
                    ${CUSTOM_PATH}/start_execution.sh
                    ${CUSTOM_PATH}/start_consensus.sh
                    ;;
                "back")
                    break
                    ;;
            esac
            ;;
          1)
            break
            ;;
        esac
    done
}

execution_submenu() {
    while true; do
        exe_opt=$(dialog --stdout --title "Execution-Client Menu $VERSION" --backtitle "PulseChain Node Setup by Maxim Broadcast" --menu "Choose an option:" 0 0 0 \
                        "Start Execution-Client" "" \
                        "Stop Execution-Client" "" \
                        "Restart Execution-Client" "" \
                        "-" ""\
                        "Edit Execution-Client Config" "" \
                        "Show Logs" "" \
                        "Update Execution-Client" "" \
                        "-" ""\
                        "back" "Back to Client Actions Menu")

        case $? in
          0)
            case $exe_opt in
                "Start Execution-Client")
                    clear && ${CUSTOM_PATH}/start_execution.sh
                    ;;
                "Stop Execution-Client")
                    clear && sudo docker stop -t 300 execution
                    sleep 1
                    sudo docker container prune -f
                    ;;
                "Restart Execution-Client")
                    clear && sudo docker stop -t 300 execution
                    sleep 1
                    sudo docker container prune -f
                    clear && ${CUSTOM_PATH}/start_execution.sh
                    ;;
                 "Edit Execution-Client Config")
                    clear && sudo nano "${CUSTOM_PATH}/start_execution.sh"
                    ;;
                 "Show Logs")
                    clear && sudo docker logs -f execution
                    ;;
                 "Update Execution-Client")
                   clear && docker stop -t 300 execution
                   docker container prune -f && docker image prune -f
                   docker rmi registry.gitlab.com/pulsechaincom/go-pulse > /dev/null 2>&1
                   docker rmi registry.gitlab.com/pulsechaincom/go-erigon > /dev/null 2>&1
                   ${CUSTOM_PATH}/start_execution.sh
                   ;;
                "-")
                    ;;
                "back")
                    break
                    ;;
            esac
            ;;
          1)
            break
            ;;
        esac
    done
}

beacon_submenu() {
    while true; do
        bcn_opt=$(dialog --stdout --title "Beacon-Client Menu $VERSION" --backtitle "PulseChain Node Setup by Maxim Broadcast" --menu "Choose an option:" 0 0 0 \
                        "Start Beacon-Client" "" \
                        "Stop Beacon-Client" "" \
                        "Restart Beacon-Client" "" \
                        "-" ""\
                        "Edit Beacon-Client Config" "" \
                        "Show Logs" "" \
                        "Update Beacon-Client" "" \
                        "-" ""\
                        "back" "Back to Client Actions Menu")

        case $? in
          0)
            case $bcn_opt in
                "Start Beacon-Client")
                    clear && ${CUSTOM_PATH}/start_consensus.sh
                    ;;
                "Stop Beacon-Client")
                    clear && sudo docker stop -t 180 beacon 
                    sleep 1
                    sudo docker container prune -f
                    ;;
                "Restart Beacon-Client")
                    clear && sudo docker stop -t 180 beacon
                    sleep 1
                    sudo docker container prune -f
                    ${CUSTOM_PATH}/start_consensus.sh
                    ;;
                 "Edit Beacon-Client Config")
                    clear && sudo nano "${CUSTOM_PATH}/start_consensus.sh"
                    ;;
                 "Show Logs")
                    clear && sudo docker logs -f beacon
                    ;;
                 "Update Beacon-Client")
                   clear && docker stop -t 180 beacon
                   docker container prune -f && docker image prune -f
                   docker rmi registry.gitlab.com/pulsechaincom/prysm-pulse/beacon-chain > /dev/null 2>&1
                   docker rmi registry.gitlab.com/pulsechaincom/lighthouse-pulse > /dev/null 2>&1
                   ${CUSTOM_PATH}/start_consensus.sh
                   ;;
                "-")
                    ;;
                "back")
                    break
                    ;;
            esac
            ;;
          1)
            break
            ;;
        esac
    done
}

node_info_submenu() {
    while true; do
        options=("Client Info" "Prints currently used client version" \
                 "-" "" \
                 "GoPLS - BlockMonitor" "Compare local Block# with scan.puslechain.com" \
                 "GoPLS - Database Prunning" "Prune your local DB to freeup space" \
                 "-" "" \
                 "back" "Back to main menu; Return to the main menu.")
        ni_opt=$(dialog --stdout --title "Node Information $VERSION" --backtitle "PulseChain Node Setup by Maxim Broadcast" --menu "Choose an option:" 0 0 0 "${options[@]}")
        case $? in
            0)
                case $ni_opt in
                    "-")
                        ;;
                    "Client Info")
                       clear && script_launch "show_version.sh"
                       ;;
                    "-")
                       ;;
                    "GoPLS - BlockMonitor")
                        clear && script_launch "compare_blocks.sh"
                        ;;
                    "GoPLS - Database Prunning")
                        tmux new-session -s prune $CUSTOM_PATH/helper/gopls_prune.sh
                        ;;
                    "-")
                        ;;
                    "back")
                        break
                        ;;
                esac
                ;;
            1)
                break
                ;;
        esac
    done
}

system_submenu() {
    while true; do
        sys_opt=$(dialog --stdout --title "System Menu $VERSION" --backtitle "PulseChain Node Setup by Maxim Broadcast" --menu "Choose an option:" 0 0 0 \
                        "Update Local Helper-Files" "Get latest additions/changes for plsmenu" \
                        "Add Graceful-Shutdown to System" "for system shutdown/reboot" \
                        "-" "" \
                        "Update & Reboot System" "" \
                        "Reboot System" "" \
                        "Shutdown System" "" \
                        "-" "" \
                        "Backup and Restore" "Chaindata for go-pulse" \
                        "-" "" \
                        "Verify Node Status" "Run comprehensive node verification" \
                        "back" "Back to main menu")

        case $? in
          0)
            case $sys_opt in
                "Update Local Helper-Files")
                    clear && script_launch "update_files.sh"
                    ;;
                "Add Graceful-Shutdown to System")
                    clear && script_launch "grace.sh"
                    ;;                    
                "-")
                    ;;                    
                "Update & Reboot System")
                    clear
                    echo "Stopping running docker container..."
                    script_launch "stop_docker.sh"
                    sleep 3
                    clear
                    echo "Getting System updates..."
                    sudo apt update && sudo apt upgrade -y && sudo apt dist-upgrade -y && sudo apt autoremove -y
                    read -p "Update done, reboot now? Press enter to continue or Ctrl+C to cancel."
                    sleep 5
                    sudo reboot now
                    ;;
                "Reboot System")
                    echo "Stopping running docker container..."
                    script_launch "stop_docker.sh"  
                    sleep 3
                    read -p "Reboot now? Press enter to continue or Ctrl+C to cancel."
                    sudo reboot now
                    ;;
                "Shutdown System")
                    echo "Stopping running docker container..."
                    script_launch "stop_docker.sh"  
                    sleep 3
                    read -p "Shutdown now? Press enter to continue or Ctrl+C to cancel."                    
                    sudo shutdown now
                    ;;

                "-")
                    ;;
                "Backup and Restore")
                    if tmux has-session -t bandr 2>/dev/null; then
                    # If the session exists, attach to it
                    tmux attach-session -t bandr
                    else
                    # If the session does not exist, create and attach to it
                    tmux new-session -d -s bandr $CUSTOM_PATH/helper/backup_restore.sh
                    tmux attach-session -t bandr
                    fi
                    ;;
                "-")
                    ;;
                "Verify Node Status")
                    # Check if a verify session already exists
                    if tmux has-session -t verify 2>/dev/null; then
                        # If the session exists, attach to it
                        tmux attach-session -t verify
                    else
                        # If the session does not exist, create and attach to it
                        tmux new-session -d -s verify $CUSTOM_PATH/helper/verify_node.sh
                        tmux attach-session -t verify
                    fi
                    ;;
                "back")
                    break
                    ;;
            esac
            ;;
          1)
            break
            ;;
        esac
    done
}

archive_node_submenu() {
    while true; do
        an_opt=$(dialog --stdout --title "Archive Node Management $VERSION" --backtitle "PulseChain Node Setup by Maxim Broadcast" --menu "Choose an option:" 0 0 0 \
                        "Remote Access Management" "Configure and manage remote access to your node" \
                        "API Endpoint Management" "Configure and test API endpoints" \
                        "Indexing Support" "Configure and optimize node for indexing" \
                        "-" ""\
                        "back" "Back to main menu")

        case $? in
          0)
            case $an_opt in
                "Remote Access Management")
                    clear && script_launch "remote_access.sh"
                    ;;
                "API Endpoint Management")
                    clear && script_launch "api_management.sh"
                    ;;
                "Indexing Support")
                    clear && script_launch "indexing_support.sh"
                    ;;
                "-")
                    ;;
                "back")
                    break
                    ;;
            esac
            ;;
          1)
            break
            ;;
        esac
    done
}

main_menu
EOF
}


# Generate the menu script for usage with the upper functions
#menu_script="$(script_launch_template)"
#menu_script+="$(printf '\nhelper_scripts_path="%s/helper"\n' "${CUSTOM_PATH}")"
#menu_script+="$(menu_script_template)"

# Write the menu script to the helper directory
#echo "${menu_script}" > "${CUSTOM_PATH}/menu.sh"
#chmod +x "${CUSTOM_PATH}/menu.sh"

#echo "Menu script has been generated and written to ${CUSTOM_PATH}/menu.sh"

#Function to get the IP-Adress Range from the local, private network

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

function exit_validator_LH() {
    # Get the keystore file path from the user with tab-autocomplete
    echo "Please enter the full path to your keystore file, including the filename and extension:"
    echo ""
    echo "Note: Your local installation folder is always mounted as /blockchain within the Docker container."
    echo "This means that if your local installation folder is /home/username/blockchain, it will be mounted as /blockchain without /home/username."
    echo "Therefore, when entering the path to your keystore file, please only include the /blockchain prefix, such as /blockchain/validator_keys/keys_###.json."
    echo ""
    read -e -p "Enter path now: " keystore_path
    #echo "${keystore_path}"
    echo ""
    # Run the Docker command with the provided keystore path and the network variable
    sudo -u lighthouse docker exec -it validator lighthouse \
    --network "${LIGHTHOUSE_NETWORK_FLAG}" \
    account validator exit \
    --keystore="${keystore_path}" \
    --beacon-node http://127.0.0.1:5052 \
    --datadir "${INSTALL_PATH}"
}


function exit_validator_PR(){
    #read -e -p "Enter the path to your wallet dir now (default /blockchain): " wallet_path
    #wallet_path=${wallet_path:-/blockchain}
    sudo -u prysm docker run -it --network="host" --name="exit_validator" \
    -v "${INSTALL_PATH}/wallet/":/wallet \
    registry.gitlab.com/pulsechaincom/prysm-pulse/prysmctl:latest \
    validator exit \
    --wallet-dir=/wallet --wallet-password-file=/wallet/pw.txt \
    --beacon-rpc-provider=127.0.0.1:4000 
    #echo "Executing: $cmd"
    #eval "$cmd"
}



function set_directory_permissions() {
  local user1=$1
  local user2=$2
  local directory=$3
  local group=$4
  local permissions=$5

  # Check if the user1 exists
  user1_id=$(id -u $user1 2>/dev/null)
  user1_exists=$?

  # Check if the user2 exists
  user2_id=$(id -u $user2 2>/dev/null)
  user2_exists=$?

  # Determine which user is being used and set the owner
  if [ $user1_exists -eq 0 ]; then
    owner=$user1
  elif [ $user2_exists -eq 0 ]; then
    owner=$user2
  else
    echo "Neither '$user1' nor '$user2' users found."
    return 1
  fi

  echo "Using the user: $owner"

  # Set the ownership and permissions for the specified directory
  chown -R $owner:$group $directory
  chmod -R $permissions $directory
}
#set_directory_permissions "geth" "erigon" "execution" "docker" "750

function get_main_user() {
  main_user=$(logname || echo $SUDO_USER || echo $USER)
  echo "Main user: $main_user"
}

function reboot_prompt() {
    zenity --question \
           --title="Reboot Required" \
           --text="A reboot is required in order for the Setup to function properly. Do you want to restart now?" \
           --ok-label="Restart Now" \
           --cancel-label="Cancel"

    if [ $? -eq 0 ]; then
        # User clicked "Restart Now"
        sudo reboot
    else
        # User clicked "Cancel" or closed the dialog
        echo "Reboot later"
    fi
}

grace() {
    echo "Adding systemwide graceful stop for our docker containers, as well as auto-restarts of the start-scripts via cron"
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
    echo ""
    echo "Set up and enabled graceful_stop service."
    echo ""
    read -p "Press Enter to continue"
}

beacon() {
    echo "Adding beacon startup as system service"
    # Create the systemd service file
cat <<EOF | sudo tee /etc/systemd/system/beacon.service > /dev/null
[Unit]
Description=Consensus Client Startup Script
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=root
ExecStart=$INSTALL_PATH/start_consensus.sh

[Install]
WantedBy=multi-user.target
EOF
    
    # Reload systemd manager configuration
    sudo systemctl daemon-reload

    # Enable the new service to be started on bootup
    sudo systemctl enable beacon.service
    sudo systemctl start beacon.service
    echo ""
    echo "Set up and enabled beacon service."
    echo ""
    read -p "Press Enter to continue"
}

cron() {

    INSTALL_PATH=$CUSTOM_PATH
    INSTALL_PATH=${INSTALL_PATH%/}

    # Define script paths
    SCRIPTS=("$INSTALL_PATH/start_consensus.sh" "$INSTALL_PATH/start_execution.sh")

    # Iterate over scripts and add them to crontab if they exist and are executable
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
}

cron2() {

    INSTALL_PATH=${INSTALL_PATH%/}

    # Define script paths
    SCRIPTS=("$INSTALL_PATH/start_consensus.sh" "$INSTALL_PATH/start_execution.sh")

    # Iterate over scripts and add them to crontab if they exist and are executable
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
}

# ======== VERIFICATION FUNCTIONS ========

# Verify that required Docker services are running properly
function verify_docker_services() {
    log_info "Verifying Docker services..."
    
    # First check Docker version and running status
    if ! check_docker_version; then
        log_warning "Docker compatibility issue detected, attempting recovery..."
        if ! docker_auto_recovery "not_running"; then
            log_error "Docker recovery failed"
            return 1
        fi
    fi
    
    # Verify Docker networking
    if ! docker network ls | grep -q "bridge"; then
        log_error "Docker bridge network is not available"
        log_warning "Network issue detected, attempting recovery..."
        if ! docker_auto_recovery "network_issues"; then
            log_error "Network recovery failed"
            return 1
        fi
        
        # Verify again after recovery attempt
        if ! docker network ls | grep -q "bridge"; then
            log_error "Docker bridge network is still not available after recovery"
            return 1
        fi
    fi
    
    # Check if we can pull an image
    log_info "Testing Docker functionality by pulling a small test image"
    if ! exec_cmd "Pulling test image" docker pull hello-world:latest; then
        log_error "Failed to pull test Docker image. Docker may not be working correctly."
        log_warning "Image pull issue detected, attempting recovery..."
        if ! docker_auto_recovery "not_running"; then
            log_error "Docker recovery failed"
            return 1
        fi
        
        # Try again after recovery
        if ! exec_cmd "Pulling test image (retry)" docker pull hello-world:latest; then
            log_error "Still failed to pull test Docker image after recovery"
            return 1
        fi
    fi
    
    # Try running the hello-world container
    if ! exec_cmd "Running test container" docker run --rm hello-world; then
        log_error "Failed to run test Docker container"
        log_warning "Container run issue detected, attempting recovery..."
        if ! docker_auto_recovery "not_running"; then
            log_error "Docker recovery failed"
            return 1
        fi
        
        # Try again after recovery
        if ! exec_cmd "Running test container (retry)" docker run --rm hello-world; then
            log_error "Still failed to run test Docker container after recovery"
            return 1
        fi
    fi
    
    log_info "Docker services verified successfully"
    return 0
}

# Verify node container health
function verify_node_containers() {
    local execution_client="$1"
    local consensus_client="$2"
    
    log_info "Verifying node containers..."
    
    # Check execution client container
    if ! docker ps | grep -q "${execution_client}"; then
        log_error "Execution client (${execution_client}) container is not running"
        return 1
    fi
    
    # Check consensus client container
    if ! docker ps | grep -q "${consensus_client}"; then
        log_error "Consensus client (${consensus_client}) container is not running"
        return 1
    fi
    
    # Get container health status if available
    local execution_health=$(docker inspect --format='{{.State.Health.Status}}' "${execution_client}" 2>/dev/null)
    local consensus_health=$(docker inspect --format='{{.State.Health.Status}}' "${consensus_client}" 2>/dev/null)
    
    if [[ -n "$execution_health" && "$execution_health" != "healthy" ]]; then
        log_warning "Execution client container health status: $execution_health"
    fi
    
    if [[ -n "$consensus_health" && "$consensus_health" != "healthy" ]]; then
        log_warning "Consensus client container health status: $consensus_health"
    fi
    
    log_info "Node containers are running"
    return 0
}

# Network connectivity testing function
function test_network_connectivity() {
    log_info "Testing network connectivity..."
    
    # Test internet connectivity
    if ! exec_cmd "Testing internet connectivity" ping -c 3 8.8.8.8; then
        log_error "Internet connectivity test failed. Cannot reach 8.8.8.8."
        log_info "Checking DNS resolution..."
        
        # Check if DNS is functioning
        if ! exec_cmd "Testing DNS resolution" ping -c 3 google.com; then
            log_error "DNS resolution test failed. Cannot resolve domain names."
            return 1
        else
            log_warning "DNS works but ping to 8.8.8.8 failed. Possible firewall restriction on ICMP."
        fi
    fi
    
    # Test connection to Docker registry (required for pulling images)
    if ! exec_cmd "Testing connection to Docker registry" curl -s -m 10 https://registry.gitlab.com/v2/; then
        log_error "Cannot connect to GitLab Docker registry. Docker pulls may fail."
        return 1
    fi
    
    # Test connection to checkpoint sync URL if provided
    if [[ -n "$CHECKPOINT" ]]; then
        log_info "Testing connection to checkpoint sync URL: $CHECKPOINT"
        if ! exec_cmd "Testing checkpoint sync URL" curl -s -m 10 $CHECKPOINT; then
            log_warning "Cannot connect to checkpoint sync URL. Sync may be slower or fail."
            # This is a warning, not an error, as some setups might work without checkpoint sync
        fi
    fi
    
    log_info "Network connectivity tests passed"
    return 0
}

# Test open ports for client communication
function test_client_ports() {
    local consensus_client="$1"
    local execution_client="$2"
    
    log_info "Testing if required ports are open..."
    
    # Test execution client ports
    if [[ "$execution_client" == "geth" ]]; then
        if ! exec_cmd "Testing TCP port 30303" nc -z -v -w5 127.0.0.1 30303; then
            log_warning "Port 30303 (TCP) is not responding. Geth P2P functionality may be limited."
        fi
    elif [[ "$execution_client" == "erigon" ]]; then
        if ! exec_cmd "Testing TCP port 30303" nc -z -v -w5 127.0.0.1 30303; then
            log_warning "Port 30303 (TCP) is not responding. Erigon P2P functionality may be limited."
        fi
        if ! exec_cmd "Testing TCP port 42069" nc -z -v -w5 127.0.0.1 42069; then
            log_warning "Port 42069 (TCP) is not responding. Erigon torrent functionality may be limited."
        fi
    fi
    
    # Test consensus client ports
    if [[ "$consensus_client" == "prysm" ]]; then
        if ! exec_cmd "Testing TCP port 13000" nc -z -v -w5 127.0.0.1 13000; then
            log_warning "Port 13000 (TCP) is not responding. Prysm P2P functionality may be limited."
        fi
    elif [[ "$consensus_client" == "lighthouse" ]]; then
        if ! exec_cmd "Testing TCP port 9000" nc -z -v -w5 127.0.0.1 9000; then
            log_warning "Port 9000 (TCP) is not responding. Lighthouse P2P functionality may be limited."
        fi
    fi
    
    # Test RPC and WebSocket ports
    if ! exec_cmd "Testing RPC port 8545" nc -z -v -w5 127.0.0.1 8545; then
        log_warning "Port 8545 (RPC) is not responding. RPC functionality may be unavailable."
    fi
    
    if ! exec_cmd "Testing WebSocket port 8546" nc -z -v -w5 127.0.0.1 8546; then
        log_warning "Port 8546 (WebSocket) is not responding. WebSocket functionality may be unavailable."
    fi
    
    log_info "Port availability tests completed"
    return 0
}

# Test RPC API functionality
function test_execution_rpc() {
    log_info "Testing execution client RPC API..."
    
    # Create a temporary file for the curl response
    local temp_file=$(mktemp)
    
    # Test basic JSON-RPC endpoint with web3_clientVersion
    if ! exec_cmd "Testing RPC API" "curl -s -X POST -H 'Content-Type: application/json' --data '{\"jsonrpc\":\"2.0\",\"method\":\"web3_clientVersion\",\"params\":[],\"id\":1}' http://localhost:8545 > $temp_file"; then
        log_error "Failed to connect to RPC API"
        rm "$temp_file"
        return 1
    fi
    
    # Check if the response contains expected fields
    if ! grep -q "jsonrpc" "$temp_file" || ! grep -q "result" "$temp_file"; then
        log_error "RPC API returned invalid response format"
        log_debug "Response: $(cat "$temp_file")"
        rm "$temp_file"
        return 1
    fi
    
    # Log the client version
    local client_version=$(grep -o '"result":"[^"]*"' "$temp_file" | sed 's/"result":"//;s/"//')
    log_info "Execution client version: $client_version"
    
    # Test eth_syncing to check sync status
    if ! exec_cmd "Checking sync status" "curl -s -X POST -H 'Content-Type: application/json' --data '{\"jsonrpc\":\"2.0\",\"method\":\"eth_syncing\",\"params\":[],\"id\":1}' http://localhost:8545 > $temp_file"; then
        log_error "Failed to query sync status"
        rm "$temp_file"
        return 1
    fi
    
    # Check sync status - if false, the node is in sync; if object, it's still syncing
    if grep -q '"result":false' "$temp_file"; then
        log_info "Execution client is fully synced"
    elif grep -q '"result":{' "$temp_file"; then
        log_warning "Execution client is still syncing"
        # Extract sync details if available
        local current_block=$(grep -o '"currentBlock":"0x[^"]*"' "$temp_file" | sed 's/"currentBlock":"//;s/"//')
        local highest_block=$(grep -o '"highestBlock":"0x[^"]*"' "$temp_file" | sed 's/"highestBlock":"//;s/"//')
        
        if [[ -n "$current_block" && -n "$highest_block" ]]; then
            # Convert hex to decimal
            current_block=$((16#${current_block:2}))
            highest_block=$((16#${highest_block:2}))
            
            log_info "Current block: $current_block, Highest block: $highest_block"
            if [[ "$highest_block" -gt 0 ]]; then
                local sync_percentage=$(( (current_block * 100) / highest_block ))
                log_info "Sync progress: ~$sync_percentage%"
            fi
        fi
    else
        log_warning "Unable to determine sync status"
        log_debug "Response: $(cat "$temp_file")"
    fi
    
    # Test net_version to verify connected network
    if ! exec_cmd "Checking network ID" "curl -s -X POST -H 'Content-Type: application/json' --data '{\"jsonrpc\":\"2.0\",\"method\":\"net_version\",\"params\":[],\"id\":1}' http://localhost:8545 > $temp_file"; then
        log_error "Failed to query network ID"
        rm "$temp_file"
        return 1
    fi
    
    # Extract and log network ID
    local network_id=$(grep -o '"result":"[^"]*"' "$temp_file" | sed 's/"result":"//;s/"//')
    log_info "Connected to network ID: $network_id"
    
    # PulseChain mainnet should be 369 (mainnet) or 943 (testnet)
    # Verify we're on the expected network
    if [[ "$EXECUTION_NETWORK_FLAG" == "pulsechain" && "$network_id" != "369" ]]; then
        log_warning "Expected to be on PulseChain mainnet (Network ID 369), but found Network ID $network_id"
    elif [[ "$EXECUTION_NETWORK_FLAG" == "pulsechain-testnet-v4" && "$network_id" != "943" ]]; then
        log_warning "Expected to be on PulseChain testnet (Network ID 943), but found Network ID $network_id"
    fi
    
    # Cleanup
    rm "$temp_file"
    
    log_info "Execution client RPC API tests completed"
    return 0
}

# Test consensus client API functionality
function test_consensus_api() {
    local consensus_client="$1"
    log_info "Testing consensus client API..."
    
    local api_url=""
    local temp_file=$(mktemp)
    
    # Set the API URL based on the consensus client
    if [[ "$consensus_client" == "prysm" ]]; then
        api_url="http://localhost:3500/eth/v1/node/identity"
    elif [[ "$consensus_client" == "lighthouse" ]]; then
        api_url="http://localhost:5052/eth/v1/node/identity"
    else
        log_error "Unknown consensus client: $consensus_client"
        rm "$temp_file"
        return 1
    fi
    
    # Test the API endpoint
    if ! exec_cmd "Testing consensus client API" "curl -s $api_url > $temp_file"; then
        log_error "Failed to connect to consensus client API"
        rm "$temp_file"
        return 1
    fi
    
    # Check if the response is valid (should contain peer_id)
    if ! grep -q "peer_id" "$temp_file"; then
        log_error "Consensus client API returned invalid response"
        log_debug "Response: $(cat "$temp_file")"
        rm "$temp_file"
        return 1
    fi
    
    # Extract and log peer ID
    local peer_id=$(grep -o '"peer_id":"[^"]*"' "$temp_file" | sed 's/"peer_id":"//;s/"//')
    log_info "Consensus client peer ID: $peer_id"
    
    # Check sync status for the consensus client
    if [[ "$consensus_client" == "prysm" ]]; then
        api_url="http://localhost:3500/eth/v1/node/syncing"
    elif [[ "$consensus_client" == "lighthouse" ]]; then
        api_url="http://localhost:5052/eth/v1/node/syncing"
    fi
    
    if ! exec_cmd "Checking consensus client sync status" "curl -s $api_url > $temp_file"; then
        log_error "Failed to query consensus client sync status"
        rm "$temp_file"
        return 1
    fi
    
    # Check if syncing
    if grep -q '"is_syncing":true' "$temp_file"; then
        log_warning "Consensus client is still syncing"
        
        # Try to extract sync distance if available
        local head_slot=$(grep -o '"head_slot":"[^"]*"' "$temp_file" | sed 's/"head_slot":"//;s/"//')
        local sync_distance=$(grep -o '"sync_distance":"[^"]*"' "$temp_file" | sed 's/"sync_distance":"//;s/"//')
        
        if [[ -n "$head_slot" && -n "$sync_distance" ]]; then
            log_info "Current slot: $head_slot, Sync distance: $sync_distance slots behind"
        fi
    elif grep -q '"is_syncing":false' "$temp_file"; then
        log_info "Consensus client is fully synced"
    else
        log_warning "Unable to determine consensus client sync status"
        log_debug "Response: $(cat "$temp_file")"
    fi
    
    # Cleanup
    rm "$temp_file"
    
    log_info "Consensus client API tests completed"
    return 0
}

# Comprehensive node verification function
function verify_node_setup() {
    local execution_client="$1"
    local consensus_client="$2"
    local detailed_output="${3:-false}"
    
    log_info "Starting comprehensive node verification..."
    echo -e "${GREEN}====== PulseChain Node Verification ======${NC}"
    
    # Initialize counters for test results
    local pass_count=0
    local warn_count=0
    local fail_count=0
    local total_tests=5  # Update this if adding more tests
    
    # Create a temporary log file for test output
    local test_log=$(mktemp)
    
    # Run individual test modules
    run_network_test "$test_log" "$detailed_output"
    check_result $? pass_count warn_count fail_count
    
    run_docker_test "$test_log" "$detailed_output"
    check_result $? pass_count warn_count fail_count
    
    run_container_test "$execution_client" "$consensus_client" "$test_log" "$detailed_output"
    check_result $? pass_count warn_count fail_count
    
    run_execution_rpc_test "$test_log" "$detailed_output"
    check_result $? pass_count warn_count fail_count
    
    run_consensus_api_test "$consensus_client" "$test_log" "$detailed_output"
    check_result $? pass_count warn_count fail_count
    
    # Display verification summary
    display_verification_summary "$pass_count" "$warn_count" "$fail_count" "$total_tests" "$test_log"
    
    # Return overall result
    if [[ "$fail_count" -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

# Function to check result and increment appropriate counter
function check_result() {
    local result=$1
    local -n passes=$2
    local -n warnings=$3
    local -n failures=$4
    
    case $result in
        0) ((passes++)) ;;
        1) ((warnings++)) ;;
        2) ((failures++)) ;;
    esac
}

# Function to run network connectivity test
function run_network_test() {
    local test_log=$1
    local detailed_output=$2
    
    echo -e "${YELLOW}Testing network connectivity...${NC}"
    if test_network_connectivity >> "$test_log" 2>&1; then
        echo -e "  ${GREEN}✓ Network connectivity check passed${NC}"
        return 0
    else
        echo -e "  ${RED}✗ Network connectivity check failed${NC}"
        
        if [[ "$detailed_output" == "true" ]]; then
            echo -e "\n${YELLOW}Network connectivity issues:${NC}"
            grep "ERROR" "$test_log" | tail -5
            echo ""
        fi
        return 2
    fi
}

# Function to run Docker services test
function run_docker_test() {
    local test_log=$1
    local detailed_output=$2
    
    echo -e "${YELLOW}Testing Docker services...${NC}"
    if verify_docker_services >> "$test_log" 2>&1; then
        echo -e "  ${GREEN}✓ Docker services check passed${NC}"
        return 0
    else
        echo -e "  ${RED}✗ Docker services check failed${NC}"
        
        if [[ "$detailed_output" == "true" ]]; then
            echo -e "\n${YELLOW}Docker service issues:${NC}"
            grep "ERROR" "$test_log" | tail -5
            echo ""
        fi
        return 2
    fi
}

# Function to run container test
function run_container_test() {
    local execution_client=$1
    local consensus_client=$2
    local test_log=$3
    local detailed_output=$4
    
    echo -e "${YELLOW}Testing node containers...${NC}"
    if verify_node_containers "$execution_client" "$consensus_client" >> "$test_log" 2>&1; then
        echo -e "  ${GREEN}✓ Node containers check passed${NC}"
        return 0
    else
        echo -e "  ${RED}✗ Node containers check failed${NC}"
        
        if [[ "$detailed_output" == "true" ]]; then
            echo -e "\n${YELLOW}Container issues:${NC}"
            grep "ERROR" "$test_log" | tail -5
            echo ""
        fi
        return 2
    fi
}

# Function to run execution RPC test
function run_execution_rpc_test() {
    local test_log=$1
    local detailed_output=$2
    
    echo -e "${YELLOW}Testing execution client RPC...${NC}"
    if test_execution_rpc >> "$test_log" 2>&1; then
        if grep -q "WARNING" "$test_log"; then
            echo -e "  ${YELLOW}⚠ Execution client RPC check passed with warnings${NC}"
            
            if [[ "$detailed_output" == "true" ]]; then
                echo -e "\n${YELLOW}Execution client warnings:${NC}"
                grep "WARNING" "$test_log" | tail -5
                echo ""
            fi
            return 1
        else
            echo -e "  ${GREEN}✓ Execution client RPC check passed${NC}"
            return 0
        fi
    else
        echo -e "  ${RED}✗ Execution client RPC check failed${NC}"
        
        if [[ "$detailed_output" == "true" ]]; then
            echo -e "\n${YELLOW}Execution client issues:${NC}"
            grep "ERROR" "$test_log" | tail -5
            echo ""
        fi
        return 2
    fi
}

# Function to run consensus API test
function run_consensus_api_test() {
    local consensus_client=$1
    local test_log=$2
    local detailed_output=$3
    
    echo -e "${YELLOW}Testing consensus client API...${NC}"
    if test_consensus_api "$consensus_client" >> "$test_log" 2>&1; then
        if grep -q "WARNING" "$test_log"; then
            echo -e "  ${YELLOW}⚠ Consensus client API check passed with warnings${NC}"
            
            if [[ "$detailed_output" == "true" ]]; then
                echo -e "\n${YELLOW}Consensus client warnings:${NC}"
                grep "WARNING" "$test_log" | tail -5
                echo ""
            fi
            return 1
        else
            echo -e "  ${GREEN}✓ Consensus client API check passed${NC}"
            return 0
        fi
    else
        echo -e "  ${RED}✗ Consensus client API check failed${NC}"
        
        if [[ "$detailed_output" == "true" ]]; then
            echo -e "\n${YELLOW}Consensus client issues:${NC}"
            grep "ERROR" "$test_log" | tail -5
            echo ""
        fi
        return 2
    fi
}

# Function to display verification summary
function display_verification_summary() {
    local pass_count=$1
    local warn_count=$2
    local fail_count=$3
    local total_tests=$4
    local test_log=$5
    
    echo ""
    echo -e "${GREEN}====== Verification Summary ======${NC}"
    echo -e "Tests Passed:   ${GREEN}$pass_count/$total_tests${NC}"
    if [[ "$warn_count" -gt 0 ]]; then
        echo -e "Tests with Warnings: ${YELLOW}$warn_count/$total_tests${NC}"
    fi
    if [[ "$fail_count" -gt 0 ]]; then
        echo -e "Tests Failed:  ${RED}$fail_count/$total_tests${NC}"
    fi
    
    # Final result
    echo ""
    if [[ "$fail_count" -eq 0 ]]; then
        if [[ "$warn_count" -eq 0 ]]; then
            echo -e "${GREEN}✓ Node verification PASSED. All checks completed successfully.${NC}"
            log_info "Node verification completed successfully"
        else
            echo -e "${YELLOW}⚠ Node verification PASSED WITH WARNINGS. The node is operational but may have issues.${NC}"
            log_warning "Node verification completed with warnings"
        fi
        # Cleanup
        rm "$test_log"
    else
        echo -e "${RED}✗ Node verification FAILED. Please check the logs and resolve the issues.${NC}"
        echo -e "Detailed test logs are available at: $LOG_FILE"
        
        # Move the temporary log to a more permanent location
        local failure_log="${CUSTOM_PATH}/node_verification_failure.log"
        mv "$test_log" "$failure_log"
        chmod 644 "$failure_log"
        
        echo -e "Detailed failure information saved to: $failure_log"
        log_error "Node verification failed with $fail_count test failures"
    fi
}

# Standard error handling functions

# Set up standardized error handling for scripts
function setup_error_handling() {
    # Set error handling options
    set -e                  # Exit on error
    set -o pipefail         # Exit if any command in a pipe fails
    
    # Set up trap for errors
    trap 'handle_script_error $? ${LINENO} "${BASH_COMMAND}" ${FUNCNAME[0]}' ERR
    
    log_info "Error handling initialized for script: $(basename "$0")"
}

# Standardized error handler that can be used across all scripts
function handle_script_error() {
    local exit_code=$1
    local line_number=$2
    local command="$3"
    local function_name="${4:-main}"
    
    log_error "======= ERROR DETECTED ======="
    log_error "Script: $(basename "$0")"
    log_error "Exit code: $exit_code"
    log_error "Line: $line_number"
    log_error "Command: $command"
    log_error "Function: $function_name"
    
    # Display stack trace
    display_error_stack_trace
    
    # Show human-friendly error message with suggestions
    display_error_message "$exit_code" "$command"
    
    # Exit with error code
    exit $exit_code
}

# Display stack trace for better debugging
function display_error_stack_trace() {
    local i=0
    local stack_size=${#FUNCNAME[@]}
    
    log_debug "Stack trace:"
    while [ $i -lt $stack_size ]; do
        log_debug "  $i: ${BASH_SOURCE[$i]}:${BASH_LINENO[$i]} ${FUNCNAME[$i]}"
        i=$((i+1))
    done
}

# Display user-friendly error message with troubleshooting suggestions
function display_error_message() {
    local exit_code=$1
    local command="$2"
    
    echo -e "${RED}======================================${NC}"
    echo -e "${RED}ERROR: Script execution failed!${NC}"
    echo -e "${RED}======================================${NC}"
    echo ""
    echo "Command that failed: $command"
    echo "Exit code: $exit_code"
    echo ""
    echo -e "${YELLOW}Possible solutions:${NC}"
    
    # Common error suggestions based on exit code or command
    if [[ "$command" == *"docker"* ]]; then
        echo "1. Make sure Docker is running: sudo systemctl status docker"
        echo "2. Check if you have permission to run Docker: groups | grep docker"
        echo "3. Try restarting Docker: sudo systemctl restart docker"
    elif [[ "$command" == *"apt"* || "$command" == *"apt-get"* ]]; then
        echo "1. Check your internet connection"
        echo "2. Try updating package lists: sudo apt update"
        echo "3. Check for locked apt: sudo lsof /var/lib/dpkg/lock"
    elif [[ "$command" == *"mkdir"* || "$command" == *"cp"* || "$command" == *"mv"* ]]; then
        echo "1. Check if you have permission to write to the directory"
        echo "2. Verify the directory exists: ls -la $(dirname "$command" | awk '{print $NF}')"
        echo "3. Check available disk space: df -h"
    else
        echo "1. Check the log file for more details: $LOG_FILE"
        echo "2. Verify system requirements (disk space, memory, etc.)"
        echo "3. Try running the command manually to see detailed errors"
    fi
    
    echo ""
    echo "For more information, check the log file: $LOG_FILE"
    echo "You can report this issue with the log file attached."
}

# Custom error handler for verifying disk space
function check_disk_space() {
    local required_space=$1  # in GB
    local mount_point=${2:-"/"}
    
    # Get available space in KB and convert to GB
    local available_space=$(df -k "$mount_point" | awk 'NR==2 {print $4}')
    available_space=$(echo "scale=2; $available_space/1024/1024" | bc)
    
    log_info "Checking disk space: $available_space GB available, $required_space GB required"
    
    if (( $(echo "$available_space < $required_space" | bc -l) )); then
        log_error "Insufficient disk space: $available_space GB available, $required_space GB required"
        echo -e "${RED}ERROR: Insufficient disk space!${NC}"
        echo "Available: $available_space GB"
        echo "Required: $required_space GB"
        echo ""
        echo -e "${YELLOW}Suggestions:${NC}"
        echo "1. Free up disk space by removing unnecessary files"
        echo "2. Use a larger disk or mount additional storage"
        echo "3. If you're running in a VM, increase the disk size"
        return 1
    fi
    
    return 0
}

# Custom error handler for verifying memory
function check_memory() {
    local required_mem=$1  # in GB
    
    # Get available memory in KB and convert to GB
    local total_mem=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    total_mem=$(echo "scale=2; $total_mem/1024/1024" | bc)
    
    log_info "Checking memory: $total_mem GB available, $required_mem GB required"
    
    if (( $(echo "$total_mem < $required_mem" | bc -l) )); then
        log_error "Insufficient memory: $total_mem GB available, $required_mem GB required"
        echo -e "${RED}ERROR: Insufficient memory!${NC}"
        echo "Available: $total_mem GB"
        echo "Required: $required_mem GB"
        echo ""
        echo -e "${YELLOW}Suggestions:${NC}"
        echo "1. Close other applications to free up memory"
        echo "2. Add swap space: sudo fallocate -l 4G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile"
        echo "3. Upgrade your system with more RAM"
        return 1
    fi
    
    return 0
}

# Custom error handler for checking network connectivity
function check_network_connectivity() {
    local host=${1:-"8.8.8.8"}
    local port=${2:-53}
    local timeout=${3:-5}
    
    log_info "Checking network connectivity to $host:$port with timeout $timeout seconds"
    
    # Try to connect to the host
    if nc -z -w "$timeout" "$host" "$port" > /dev/null 2>&1; then
        return 0
    else
        log_error "Network connectivity check failed: Cannot connect to $host:$port"
        echo -e "${RED}ERROR: Network connectivity check failed!${NC}"
        echo "Cannot connect to $host:$port"
        echo ""
        echo -e "${YELLOW}Suggestions:${NC}"
        echo "1. Check your internet connection"
        echo "2. Verify firewall settings: sudo ufw status"
        echo "3. Check DNS resolution: dig $host"
        echo "4. Try a different network or VPN"
        return 1
    fi
}

# Function to validate script arguments
function validate_arguments() {
    local required=("$@")
    local missing=()
    
    for var in "${required[@]}"; do
        if [[ -z "${!var}" ]]; then
            missing+=("$var")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required arguments: ${missing[*]}"
        echo -e "${RED}ERROR: Missing required arguments!${NC}"
        echo "The following arguments are required: ${missing[*]}"
        echo ""
        echo "Usage: $(basename "$0") [arguments]"
        return 1
    fi
    
    return 0
}

# Check if Docker version is compatible
function check_docker_version() {
    log_info "Checking Docker version compatibility..."
    
    # Verify Docker is installed
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed or not in PATH"
        return 1
    fi
    
    # Get Docker version
    docker_version=$(docker --version | grep -oP '(?<=Docker version )[0-9]+\.[0-9]+\.[0-9]+')
    
    if [ -z "$docker_version" ]; then
        log_error "Could not determine Docker version"
        return 1
    fi
    
    log_info "Found Docker version: $docker_version"
    
    # Extract major and minor version
    major_version=$(echo $docker_version | cut -d. -f1)
    minor_version=$(echo $docker_version | cut -d. -f2)
    
    # Minimum required Docker version (20.10)
    min_major=20
    min_minor=10
    
    # Check if version is at least the minimum required
    if [ "$major_version" -lt "$min_major" ] || ([ "$major_version" -eq "$min_major" ] && [ "$minor_version" -lt "$min_minor" ]); then
        log_error "Docker version $docker_version is not compatible. Minimum required version is $min_major.$min_minor.0"
        log_warning "Please upgrade Docker to continue."
        return 1
    fi
    
    # Verify Docker Compose is installed
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose is not installed or not in PATH"
        log_warning "Docker Compose is required for this setup."
        return 1
    fi
    
    # Verify Docker is running
    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running"
        log_info "Attempting to start Docker service..."
        
        if ! systemctl is-active --quiet docker; then
            if ! exec_cmd "Starting Docker service" sudo systemctl start docker; then
                log_error "Failed to start Docker service"
                log_warning "Please start Docker manually with: sudo systemctl start docker"
                return 1
            fi
        fi
        
        # Check again after trying to start the service
        if ! docker info &> /dev/null; then
            log_error "Docker daemon still not running after attempting to start the service"
            log_warning "Please ensure Docker is properly installed and the service is running"
            return 1
        fi
    fi
    
    log_info "Docker version check passed. Version $docker_version is compatible"
    return 0
}

# Update the verify_docker_services function to use our new version check
function verify_docker_services() {
    log_info "Verifying Docker services..."
    
    # First check Docker version and running status
    if ! check_docker_version; then
        log_warning "Docker compatibility issue detected, attempting recovery..."
        if ! docker_auto_recovery "not_running"; then
            log_error "Docker recovery failed"
            return 1
        fi
    fi
    
    # Verify Docker networking
    if ! docker network ls | grep -q "bridge"; then
        log_error "Docker bridge network is not available"
        log_warning "Network issue detected, attempting recovery..."
        if ! docker_auto_recovery "network_issues"; then
            log_error "Network recovery failed"
            return 1
        fi
        
        # Verify again after recovery attempt
        if ! docker network ls | grep -q "bridge"; then
            log_error "Docker bridge network is still not available after recovery"
            return 1
        fi
    fi
    
    # Check if we can pull an image
    log_info "Testing Docker functionality by pulling a small test image"
    if ! exec_cmd "Pulling test image" docker pull hello-world:latest; then
        log_error "Failed to pull test Docker image. Docker may not be working correctly."
        log_warning "Image pull issue detected, attempting recovery..."
        if ! docker_auto_recovery "not_running"; then
            log_error "Docker recovery failed"
            return 1
        fi
        
        # Try again after recovery
        if ! exec_cmd "Pulling test image (retry)" docker pull hello-world:latest; then
            log_error "Still failed to pull test Docker image after recovery"
            return 1
        fi
    fi
    
    # Try running the hello-world container
    if ! exec_cmd "Running test container" docker run --rm hello-world; then
        log_error "Failed to run test Docker container"
        log_warning "Container run issue detected, attempting recovery..."
        if ! docker_auto_recovery "not_running"; then
            log_error "Docker recovery failed"
            return 1
        fi
        
        # Try again after recovery
        if ! exec_cmd "Running test container (retry)" docker run --rm hello-world; then
            log_error "Still failed to run test Docker container after recovery"
            return 1
        fi
    fi
    
    log_info "Docker services verified successfully"
    return 0
}

# Attempt to automatically recover from Docker-related issues
function docker_auto_recovery() {
    local issue_type="$1"
    
    log_info "Attempting to recover from Docker issue: $issue_type"
    
    case "$issue_type" in
        "not_running")
            log_info "Trying to restart Docker service..."
            if ! exec_cmd "Restarting Docker service" sudo systemctl restart docker; then
                log_error "Failed to restart Docker service"
                log_warning "Please try restarting Docker manually: sudo systemctl restart docker"
                return 1
            fi
            log_info "Waiting for Docker to start completely..."
            sleep 5
            ;;
            
        "network_issues")
            log_info "Attempting to fix Docker network issues..."
            if ! exec_cmd "Restarting Docker service" sudo systemctl restart docker; then
                log_error "Failed to restart Docker service"
                return 1
            fi
            
            log_info "Waiting for Docker to restart..."
            sleep 5
            
            if ! exec_cmd "Recreating default networks" docker network prune -f; then
                log_error "Failed to prune Docker networks"
                return 1
            fi
            ;;
            
        "container_stuck")
            log_info "Attempting to fix stuck container issues..."
            local container_name="$2"
            
            if [[ -z "$container_name" ]]; then
                log_error "Container name not provided for recovery"
                return 1
            fi
            
            # First try graceful stop
            if ! exec_cmd "Stopping container gracefully" docker stop -t 60 "$container_name"; then
                log_info "Graceful stop failed, trying force kill..."
                if ! exec_cmd "Force killing container" docker kill "$container_name"; then
                    log_error "Failed to kill container $container_name"
                    return 1
                fi
            fi
            
            # Remove the container
            if ! exec_cmd "Removing container" docker rm -f "$container_name"; then
                log_error "Failed to remove container $container_name"
                log_warning "You may need to manually clean up: docker rm -f $container_name"
            fi
            ;;
            
        "disk_space")
            log_info "Attempting to free up disk space by cleaning Docker resources..."
            
            # Remove unused containers
            if ! exec_cmd "Removing unused containers" docker container prune -f; then
                log_warning "Failed to prune containers, continuing anyway..."
            fi
            
            # Remove unused images
            if ! exec_cmd "Removing unused images" docker image prune -a -f; then
                log_warning "Failed to prune images, continuing anyway..."
            fi
            
            # Remove unused volumes
            if ! exec_cmd "Removing unused volumes" docker volume prune -f; then
                log_warning "Failed to prune volumes, continuing anyway..."
            fi
            
            # Remove unused networks
            if ! exec_cmd "Removing unused networks" docker network prune -f; then
                log_warning "Failed to prune networks, continuing anyway..."
            fi
            ;;
            
        *)
            log_error "Unknown Docker issue type: $issue_type"
            log_warning "No automatic recovery available for this issue"
            return 1
            ;;
    esac
    
    log_info "Docker recovery process completed, verifying Docker service..."
    
    # Verify Docker is running after recovery
    if ! docker info &> /dev/null; then
        log_error "Docker service is still not functioning properly after recovery"
        log_warning "You may need to manually troubleshoot Docker issues"
        return 1
    fi
    
    log_info "Docker recovery successful"
    return 0
}
