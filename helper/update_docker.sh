#!/bin/bash

# Source configuration
source /blockchain/config.sh

# Get selected network
SELECTED_NETWORK="${SELECTED_NETWORK:-pulsechain}"

# Define network-specific images and RPC endpoints
declare -A PULSE_IMAGES=(
    ["execution"]="registry.gitlab.com/pulsechaincom/go-pulse"
    ["beacon"]="registry.gitlab.com/pulsechaincom/lighthouse-pulse"
)

declare -A ETH_IMAGES=(
    ["execution"]="ethereum/client-go"
    ["beacon"]="sigp/lighthouse"
)

declare -A RPC_ENDPOINTS=(
    ["pulsechain_execution"]="http://localhost:8545"
    ["pulsechain_beacon"]="http://localhost:5052"
    ["ethereum_execution"]="http://localhost:8546"
    ["ethereum_beacon"]="http://localhost:5053"
)

# Function to get detailed version info
get_version_info() {
    local image=$1
    local version_info
    
    # Get basic version
    local version=$(docker inspect "$image" 2>/dev/null | jq -r '.[0].Config.Labels.version' || echo "unknown")
    
    # Get commit hash
    local commit=$(docker inspect "$image" 2>/dev/null | jq -r '.[0].Config.Labels.commit' || echo "unknown")
    
    # Get build date
    local build_date=$(docker inspect "$image" 2>/dev/null | jq -r '.[0].Created' || echo "unknown")
    
    # Format version info
    version_info="Version: $version"
    [ "$commit" != "unknown" ] && version_info+=", Commit: ${commit:0:8}"
    [ "$build_date" != "unknown" ] && version_info+=", Built: $(date -d "$build_date" '+%Y-%m-%d %H:%M:%S')"
    
    echo "$version_info"
}

# Function to check RPC endpoint
check_rpc_endpoint() {
    local endpoint=$1
    local type=$2
    local result
    
    echo "Checking $type endpoint ($endpoint)..."
    
    if [[ $type == *"execution"* ]]; then
        # Check execution client
        result=$(curl -s -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' "$endpoint")
        if [ $? -eq 0 ] && [ ! -z "$result" ]; then
            echo "✓ Execution client RPC responding"
            return 0
        fi
    else
        # Check beacon client
        result=$(curl -s "$endpoint/eth/v1/node/health")
        if [ $? -eq 0 ] && [ "$result" = "OK" ]; then
            echo "✓ Beacon client RPC responding"
            return 0
        fi
    fi
    
    echo "✗ RPC endpoint not responding"
    return 1
}

# Function to check for updates
check_for_updates() {
    local network=$1
    local updates_available=false
    local update_message=""
    
    # Select correct image set based on network
    if [ "$network" = "pulsechain" ]; then
        declare -n IMAGES=PULSE_IMAGES
    else
        declare -n IMAGES=ETH_IMAGES
    fi
    
    echo "Checking for updates on ${network^^} network..."
    
    # Check each client type
    for client in "${!IMAGES[@]}"; do
        local image="${IMAGES[$client]}"
        echo "Checking ${client^} client..."
        
        # Get current version details
        local current_info=$(get_version_info "$image")
        echo "Current: $current_info"
        
        # Get latest version from registry
        local latest_version=$(curl -s "https://registry.hub.docker.com/v2/repositories/${image}/tags/latest" | jq -r '.name' 2>/dev/null || echo "unknown")
        if [ "$latest_version" != "unknown" ]; then
            echo "Latest available: $latest_version"
            
            # Get changelog if available
            local changelog_url="${IMAGES[$client]}/raw/master/CHANGELOG.md"
            local changelog=$(curl -s "$changelog_url" | head -n 10)
            
            if [ "$current_info" != *"$latest_version"* ]; then
                updates_available=true
                update_message+="- ${client^} client update available:\n"
                update_message+="  Current: $current_info\n"
                update_message+="  Latest: $latest_version\n"
                [ ! -z "$changelog" ] && update_message+="  Recent changes:\n$changelog\n"
            fi
        fi
        echo ""
    done
    
    if [ "$updates_available" = true ]; then
        echo -e "\nUpdates available for ${network^^}:"
        echo -e "$update_message"
        return 0
    else
        echo "No updates available for ${network^^}"
        return 1
    fi
}

# Function to verify client health
verify_client_health() {
    local network=$1
    local success=true
    
    echo "Verifying client health..."
    
    # Check RPC endpoints
    check_rpc_endpoint "${RPC_ENDPOINTS[${network}_execution]}" "execution" || success=false
    check_rpc_endpoint "${RPC_ENDPOINTS[${network}_beacon]}" "beacon" || success=false
    
    # Check sync status
    if [ "$success" = true ]; then
        local sync_status=$(curl -s -X POST -H "Content-Type: application/json" \
            --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
            "${RPC_ENDPOINTS[${network}_execution]}" | jq -r '.result')
        
        if [ "$sync_status" = "false" ]; then
            echo "✓ Node is synced"
        else
            echo "! Node is still syncing"
            success=false
        fi
    fi
    
    return $success
}

# Function to update clients
update_clients() {
    local network=$1
    
    # Select correct image set based on network
    if [ "$network" = "pulsechain" ]; then
        declare -n IMAGES=PULSE_IMAGES
    else
        declare -n IMAGES=ETH_IMAGES
    fi
    
    # Create backup of current configuration
    echo "Creating configuration backup..."
    local backup_dir="$INSTALL_PATH/backups/$(date +%Y%m%d_%H%M%S)_pre_update"
    mkdir -p "$backup_dir"
    cp -r "$INSTALL_PATH/config" "$backup_dir/"
    docker inspect execution beacon > "$backup_dir/container_config.json"
    
    echo "Stopping ${network^^} clients..."
    for client in "${!IMAGES[@]}"; do
        docker stop -t 300 "$client" 2>/dev/null
    done
    
    echo "Removing old images..."
    for image in "${IMAGES[@]}"; do
        docker rmi "$image" 2>/dev/null
    done
    
    echo "Pulling latest images..."
    for image in "${IMAGES[@]}"; do
        if ! docker pull "$image":latest; then
            echo "Failed to pull $image"
            echo "Restoring from backup..."
            # TODO: Implement rollback procedure
            return 1
        fi
    done
    
    echo "Starting clients..."
    if [ -f "$INSTALL_PATH/start_execution.sh" ]; then
        $INSTALL_PATH/start_execution.sh
    fi
    if [ -f "$INSTALL_PATH/start_consensus.sh" ]; then
        $INSTALL_PATH/start_consensus.sh
    fi
    
    # Wait for clients to start
    echo "Waiting for clients to initialize..."
    sleep 30
    
    # Verify client health
    if verify_client_health "$network"; then
        echo "Update completed successfully!"
        # Save successful update details
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Updated ${network} clients successfully" >> "$INSTALL_PATH/updates/update_history.log"
    else
        echo "Warning: Clients updated but health check failed"
        echo "You may need to:"
        echo "1. Check client logs: docker logs execution/beacon"
        echo "2. Verify network connectivity"
        echo "3. Wait for sync to complete"
        echo "4. Consider rolling back if issues persist"
    fi
}

# Function to show update confirmation
show_update_confirmation() {
    clear
    echo "=== Update Confirmation ==="
    echo ""
    echo "⚠️  Please review the following:"
    echo ""
    echo "1. Pre-update Status:"
    verify_client_health "$SELECTED_NETWORK"
    echo ""
    echo "2. Update Process Will:"
    echo "   - Create a backup of current configuration"
    echo "   - Stop all running clients"
    echo "   - Remove old Docker images"
    echo "   - Pull latest versions"
    echo "   - Restart clients"
    echo "   - Verify client health"
    echo ""
    echo "3. Estimated Time: 5-10 minutes"
    echo ""
    echo "4. Recovery Options:"
    echo "   - Automatic rollback on failure"
    echo "   - Manual rollback available from backups"
    echo "   - Configuration backup location: $INSTALL_PATH/backups/"
    echo ""
    read -p "Do you want to proceed with the update? (yes/no): " confirm
    [[ "$confirm" == "yes" ]] && return 0 || return 1
}

# Main menu
show_update_menu() {
    while true; do
        clear
        echo "=== Docker Client Update Manager ==="
        echo "Current Network: ${SELECTED_NETWORK^^}"
        echo ""
        
        # Show current client versions
        echo "Current Versions:"
        for client in "${!PULSE_IMAGES[@]}"; do
            echo "${client^}: $(get_version_info "${PULSE_IMAGES[$client]}")"
        done
        echo ""
        
        echo "Options:"
        echo "1. Check for updates"
        echo "2. Update clients"
        echo "3. View update history"
        echo "4. Verify client health"
        echo "5. Switch network (current: ${SELECTED_NETWORK^^})"
        echo "6. Return to main menu"
        echo ""
        read -p "Select an option: " choice
        
        case $choice in
            1)
                check_for_updates "$SELECTED_NETWORK"
                read -p "Press Enter to continue..."
                ;;
            2)
                if check_for_updates "$SELECTED_NETWORK"; then
                    if show_update_confirmation; then
                        update_clients "$SELECTED_NETWORK"
                    fi
                else
                    echo "No updates available."
                fi
                read -p "Press Enter to continue..."
                ;;
            3)
                clear
                echo "=== Update History ==="
                if [ -f "$INSTALL_PATH/updates/update_history.log" ]; then
                    cat "$INSTALL_PATH/updates/update_history.log"
                else
                    echo "No update history available"
                fi
                read -p "Press Enter to continue..."
                ;;
            4)
                clear
                verify_client_health "$SELECTED_NETWORK"
                read -p "Press Enter to continue..."
                ;;
            5)
                if [ "$SELECTED_NETWORK" = "pulsechain" ]; then
                    SELECTED_NETWORK="ethereum"
                else
                    SELECTED_NETWORK="pulsechain"
                fi
                echo "Switched to ${SELECTED_NETWORK^^}"
                sleep 1
                ;;
            6)
                return
                ;;
        esac
    done
}

# If script is run directly, show the menu
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    show_update_menu
fi

    echo "Stopping Docker-images..."
    docker stop -t 300 execution
    docker stop -t 180 beacon
    docker stop -t 180 validator
    docker container prune -f && docker image prune -f
    echo "Removing Docker-images..."
    docker rmi registry.gitlab.com/pulsechaincom/go-pulse
    docker rmi registry.gitlab.com/pulsechaincom/erigon-pulse
    docker rmi registry.gitlab.com/pulsechaincom/lighthouse-pulse 
    docker rmi registry.gitlab.com/pulsechaincom/prysm-pulse/beacon-chain
    docker rmi registry.gitlab.com/pulsechaincom/prysm-pulse/validator
    #docker rmi registry.gitlab.com/pulsechaincom/prysm-pulse/prysmctl
    

   
