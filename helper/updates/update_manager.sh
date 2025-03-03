#!/bin/bash

# Source common functions and configuration
source /blockchain/config.sh
source /blockchain/functions.sh

# Create required directories if they don't exist
mkdir -p /blockchain/updates
mkdir -p /blockchain/backups

# Function to get current versions
get_current_versions() {
    CURRENT_BEACON_VERSION=$(docker inspect registry.gitlab.com/pulsechaincom/lighthouse-pulse:latest | jq -r '.[0].Config.Labels.version' 2>/dev/null || echo "unknown")
    CURRENT_EXECUTION_VERSION=$(docker inspect registry.gitlab.com/pulsechaincom/go-pulse:latest | jq -r '.[0].Config.Labels.version' 2>/dev/null || echo "unknown")
    
    echo "{\"beacon\": \"$CURRENT_BEACON_VERSION\", \"execution\": \"$CURRENT_EXECUTION_VERSION\"}"
}

# Function to check for updates
check_for_updates() {
    echo "Checking for updates..."
    
    # Get current versions
    CURRENT_VERSIONS=$(get_current_versions)
    CURRENT_BEACON_VERSION=$(echo $CURRENT_VERSIONS | jq -r '.beacon')
    CURRENT_EXECUTION_VERSION=$(echo $CURRENT_VERSIONS | jq -r '.execution')
    
    # Check for new versions
    NEW_BEACON_VERSION=$(curl -s "https://gitlab.com/api/v4/projects/pulsechaincom%2Flighthouse-pulse/releases/latest" | jq -r '.tag_name' 2>/dev/null || echo "unknown")
    NEW_EXECUTION_VERSION=$(curl -s "https://gitlab.com/api/v4/projects/pulsechaincom%2Fgo-pulse/releases/latest" | jq -r '.tag_name' 2>/dev/null || echo "unknown")
    
    UPDATES_AVAILABLE=false
    UPDATE_MESSAGE=""
    
    # Check beacon client
    if [ "$CURRENT_BEACON_VERSION" != "$NEW_BEACON_VERSION" ] && [ "$NEW_BEACON_VERSION" != "unknown" ]; then
        UPDATES_AVAILABLE=true
        UPDATE_MESSAGE+="- Beacon client update available: ${CURRENT_BEACON_VERSION} → ${NEW_BEACON_VERSION}\n"
    fi
    
    # Check execution client
    if [ "$CURRENT_EXECUTION_VERSION" != "$NEW_EXECUTION_VERSION" ] && [ "$NEW_EXECUTION_VERSION" != "unknown" ]; then
        UPDATES_AVAILABLE=true
        UPDATE_MESSAGE+="- Execution client update available: ${CURRENT_EXECUTION_VERSION} → ${NEW_EXECUTION_VERSION}\n"
    fi
    
    if [ "$UPDATES_AVAILABLE" = true ]; then
        # Store update information
        echo "{
            \"type\": \"update_available\",
            \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\",
            \"message\": \"${UPDATE_MESSAGE}\",
            \"versions\": {
                \"current\": ${CURRENT_VERSIONS},
                \"new\": {
                    \"beacon\": \"${NEW_BEACON_VERSION}\",
                    \"execution\": \"${NEW_EXECUTION_VERSION}\"
                }
            }
        }" > /blockchain/updates/available_updates.json
        
        # Add visual indicator
        echo "🔔 Updates available" > /blockchain/updates/indicator
        
        # Log the update availability
        logger "PulseChain node updates available: ${UPDATE_MESSAGE}"
        
        echo -e "\n${UPDATE_MESSAGE}"
        echo "Updates are available! Use the update menu to apply them."
    else
        echo "No updates available. Your node is up to date!"
        rm -f /blockchain/updates/available_updates.json
        rm -f /blockchain/updates/indicator
    fi
}

# Function to backup the node
backup_node() {
    BACKUP_TIME=$(date +%Y%m%d_%H%M%S)
    BACKUP_DIR="/blockchain/backups/backup_${BACKUP_TIME}"
    
    echo "Creating backup in ${BACKUP_DIR}..."
    mkdir -p "${BACKUP_DIR}"
    
    # Backup configuration files
    cp /blockchain/config.sh "${BACKUP_DIR}/"
    cp /blockchain/jwt.hex "${BACKUP_DIR}/" 2>/dev/null || true
    cp -r /blockchain/*.sh "${BACKUP_DIR}/"
    
    # Record versions
    get_current_versions > "${BACKUP_DIR}/versions.json"
    
    echo "Backup completed successfully!"
}

# Function to perform the update
perform_update() {
    echo "Starting update process..."
    
    # Create backup
    backup_node
    
    echo "Stopping services..."
    docker stop -t 180 beacon
    docker stop -t 300 execution
    
    echo "Pulling latest versions..."
    docker pull registry.gitlab.com/pulsechaincom/lighthouse-pulse:latest
    docker pull registry.gitlab.com/pulsechaincom/go-pulse:latest
    
    echo "Starting services..."
    /blockchain/start_execution.sh
    /blockchain/start_consensus.sh
    
    # Record update in history
    CURRENT_VERSIONS=$(get_current_versions)
    echo "{
        \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\",
        \"versions\": ${CURRENT_VERSIONS}
    }" >> /blockchain/updates/update_history.json
    
    # Clean up
    rm -f /blockchain/updates/available_updates.json
    rm -f /blockchain/updates/indicator
    
    echo "Update completed successfully!"
}

# Function to show update history
show_update_history() {
    clear
    echo "=== Update History ==="
    echo ""
    
    if [ -f "/blockchain/updates/update_history.json" ]; then
        jq -r '.[] | "Date: \(.timestamp)\nVersions: \(.versions | @json)\n"' /blockchain/updates/update_history.json
    else
        echo "No update history available"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

# Main menu function
show_update_menu() {
    while true; do
        clear
        echo "=== PulseChain Node Updates ==="
        echo ""
        
        # Show any available updates
        if [ -f "/blockchain/updates/available_updates.json" ]; then
            echo "📦 Available Updates:"
            echo "-------------------"
            jq -r '.message' /blockchain/updates/available_updates.json
            echo ""
        else
            echo "✓ Your node is up to date"
            echo ""
        fi
        
        echo "Options:"
        echo "1. Check for updates now"
        echo "2. Update node"
        echo "3. View update history"
        echo "4. Back to main menu"
        echo ""
        read -p "Select an option: " choice
        
        case $choice in
            1)
                check_for_updates
                read -p "Press Enter to continue..."
                ;;
            2)
                if [ -f "/blockchain/updates/available_updates.json" ]; then
                    echo ""
                    echo "⚠️  Before updating:"
                    echo "- A backup will be created automatically"
                    echo "- Both beacon and execution clients will need to restart"
                    echo "- This may take several minutes"
                    echo ""
                    read -p "Would you like to proceed with the update? (y/N): " confirm
                    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                        perform_update
                        read -p "Press Enter to continue..."
                    fi
                else
                    echo "No updates available"
                    sleep 2
                fi
                ;;
            3)
                show_update_history
                ;;
            4)
                return
                ;;
        esac
    done
}

# If script is run directly, show the menu
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    show_update_menu
fi 