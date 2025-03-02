VERSION="1.5"
    
    
trap cleanup SIGINT

function cleanup() {
    clear
    echo "Exiting..."
    exit
}

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
# Get the CUSTOM_PATH from environment or use default
CUSTOM_PATH="${CUSTOM_PATH:-/blockchain}"
helper_scripts_path="${CUSTOM_PATH}/helper"

script_launch() {
    echo "Launching script: ${CUSTOM_PATH}/helper/$1"
    ${CUSTOM_PATH}/helper/$1
}

main_menu() {
    while true; do
        main_opt=$(dialog --stdout --title "Main Menu $VERSION" --backtitle "created by Maxim Broadcast" --menu "Choose an option:" 0 0 0 \
                          "Logviewer" "Start different Logviewer" \
                          "Clients Menu" "Execution and Beacon Clients" \
                          "Info and Management" "Tools for Node Information" \
                          "System" "Update, Reboot, shutdown, Backup & Restore" \
                          "-" ""\
                          "exit" "Exit the program")

        case $? in
          0)
            case $main_opt in
                "Logviewer")
                    logviewer_submenu
                    ;;
                "Clients Menu")
                    client_actions_submenu
                    ;;
                "Info and Management")
                    node_info_submenu
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
        lv_opt=$(dialog --stdout --title "Logviewer Menu $VERSION" --stdout --backtitle "created by Maxim Broadcast" --menu "Choose an option:" 0 0 0 \
                        "Tabbed View" "⏱️ Log files in a Tabbed View - gui" \
                        "Tmux View" "⏱️ Log files in Tmux - console" \
                        "BACK" "⏱️ Return to the Main Menu")

        case $? in
          0)
            case $lv_opt in
                "Tabbed View")
                    clear && script_launch "log_viewer.sh"
                    ;;
                "Tmux View")
                    clear && script_launch "tmux_logviewer.sh"
                    ;;
                "BACK")
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
        ca_opt=$(dialog --stdout --title "Client Menu $VERSION" --backtitle "created by Maxim Broadcast" --menu "Choose an option:" 0 0 0 \
                        "Execution-Client Menu" "⚙️ Manage Execution-Client-Settings" \
                        "Beacon-Client Menu" "⚙️ Manage Beacon-Client-Settings" \
                        "BACK" "⏱️ Return to the Main Menu")

        case $? in
          0)
            case $ca_opt in
                "Execution-Client Menu")
                    execution_submenu
                    ;;
                "Beacon-Client Menu")
                    beacon_submenu
                    ;;
                "BACK")
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
        exe_opt=$(dialog --stdout --title "Execution-Client Menu $VERSION" --backtitle "created by Maxim Broadcast" --menu "Choose an option:" 0 0 0 \
                         "Container Start" "⚙️ Start Execution-Client" \
                         "Container Stop" "⚙️ Stop Execution-Client" \
                         "Container Restart" "⚙️ Restart Execution-Client" \
                         "Container Status" "⚙️ Execution-Client Status" \
                         "Docker Logs" "⚙️ Show the Execution-Client Logs" \
                         "Update Client" "⚙️ Update the Execution-Client" \
                         "BACK" "⏱️ Return to the Client-Menu")

        case $? in
          0)
            case $exe_opt in
                "Container Start")
                    clear && ${CUSTOM_PATH}/start_execution.sh
                    ;;
                "Container Stop")
                    clear && sudo docker stop -t 300 execution
                    sleep 1
                    sudo docker container prune -f
                    ;;
                "Container Restart")
                    clear && sudo docker stop -t 300 execution
                    sleep 1
                    sudo docker container prune -f
                    clear && ${CUSTOM_PATH}/start_execution.sh
                    ;;
                "Container Status")
                    clear && sudo docker ps -a | grep execution
                    ;;
                "Docker Logs")
                    clear && sudo docker logs -f execution
                    ;;
                "Update Client")
                   clear && docker stop -t 300 execution
                   docker container prune -f && docker image prune -f
                   docker rmi registry.gitlab.com/pulsechaincom/go-pulse > /dev/null 2>&1
                   docker rmi registry.gitlab.com/pulsechaincom/go-erigon > /dev/null 2>&1
                   ${CUSTOM_PATH}/start_execution.sh
                   ;;
                "BACK")
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
        bcn_opt=$(dialog --stdout --title "Beacon-Client Menu $VERSION" --backtitle "created by Maxim Broadcast" --menu "Choose an option:" 0 0 0 \
                         "Container Start" "⚙️ Start Beacon-Client" \
                         "Container Stop" "⚙️ Stop Beacon-Client" \
                         "Container Restart" "⚙️ Restart Beacon-Client" \
                         "Container Status" "⚙️ Beacon-Client Status" \
                         "Docker Logs" "⚙️ Show the Beacon-Client Logs" \
                         "Update Client" "⚙️ Update the Beacon-Client" \
                         "BACK" "⏱️ Return to the Client-Menu")

        case $? in
          0)
            case $bcn_opt in
                "Container Start")
                    clear && ${CUSTOM_PATH}/start_consensus.sh
                    ;;
                "Container Stop")
                    clear && sudo docker stop -t 180 beacon 
                    sleep 1
                    sudo docker container prune -f
                    ;;
                "Container Restart")
                    clear && sudo docker stop -t 180 beacon
                    sleep 1
                    sudo docker container prune -f
                    ${CUSTOM_PATH}/start_consensus.sh
                    ;;
                "Container Status")
                    clear && sudo docker ps -a | grep beacon
                    ;;
                "Docker Logs")
                    clear && sudo docker logs -f beacon
                    ;;
                "Update Client")
                   clear && docker stop -t 180 beacon
                   docker container prune -f && docker image prune -f
                   docker rmi registry.gitlab.com/pulsechaincom/prysm-pulse/beacon-chain > /dev/null 2>&1
                   docker rmi registry.gitlab.com/pulsechaincom/lighthouse-pulse > /dev/null 2>&1
                   ${CUSTOM_PATH}/start_consensus.sh
                   ;;
                "BACK")
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
        options=$(dialog --stdout --title "Node Information & Management $VERSION" --backtitle "created by Maxim Broadcast" --menu "Choose an option:" 0 0 0 \
                         "Node Information" "⚙️ Check Node Status Information" \
                         "RPC Status" "⚙️ Check RPC Connection Status" \
                         "Sync Status" "⚙️ Check Sync Progress" \
                         "BACK" "⏱️ Return to the Main Menu")

        case $? in
          0)
            case $options in
                "Node Information")
                    clear 
                    echo "Node Status Information (Non-Validator Edition)"
                    echo "----------------------------------------------"
                    echo "This is a non-validator node setup."
                    echo "This version is designed for running a PulseChain node for syncing with"
                    echo "the network, providing RPC endpoints, and monitoring the blockchain."
                    echo ""
                    echo "Validator functionality has been deliberately removed from this version."
                    echo ""
                    echo "Current configuration:"
                    if docker ps | grep -q "execution"; then
                        echo "- Execution client: $(docker ps | grep execution | awk '{print $2}' | cut -d':' -f1 | rev | cut -d'/' -f1 | rev)"
                    else
                        echo "- Execution client: Not running"
                    fi
                    if docker ps | grep -q "beacon"; then
                        echo "- Consensus client: $(docker ps | grep beacon | awk '{print $2}' | cut -d':' -f1 | rev | cut -d'/' -f1 | rev)"
                    else
                        echo "- Consensus client: Not running"
                    fi
                    echo ""
                    echo "Press any key to continue..."
                    read -n 1
                    ;;
                "RPC Status")
                    clear && script_launch "check_rpc_connection.sh"
                    ;;
                "Sync Status")
                    clear && script_launch "check_sync.sh"
                    ;;
                "BACK")
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
        sys_opt=$(dialog --stdout --title "System Menu $VERSION" --backtitle "created by Maxim Broadcast" --menu "Choose an option:" 0 0 0 \
                         "Check Network" "⚙️ Get Network Status" \
                         "Check System" "⚙️ Get System Status" \
                         "Sytem-Time" "⚙️ Sync System-Time" \
                         "Sync Status" "⚙️ Check if client is Synced" \
                         "BlockHeight" "⚙️ Check Current BlockHeight" \
                         "Blocknotifier On" "⚙️ Start the Blocknumber notification" \
                         "Blocknotifier Off" "⚙️ Stop the Blocknumber notification" \
                         "Archive Node Setup" "⚙️ Setup Archive Node" \
                         "BACK" "⏱️ Return to the Main Menu")

        case $? in
          0)
            case $sys_opt in
                "Check Network")
                    clear && script_launch "network_status.sh"
                    ;;
                "Check System")
                    clear && script_launch "system_status.sh"
                    ;;
                "Sytem-Time")
                    clear && script_launch "sync_time.sh"
                    ;;
                "Sync Status")
                    clear && script_launch "sync_status.sh"
                    ;;
                "BlockHeight")
                    clear && script_launch "block_height.sh"
                    ;;
                "Blocknotifier On")
                    clear && script_launch "block_notifier_on.sh"
                    ;;
                "Blocknotifier Off")
                    clear && script_launch "block_notifier_off.sh"
                    ;;
                "Archive Node Setup")
                    clear && script_launch "archive_node_setup.sh"
                    ;;
                "BACK")
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
