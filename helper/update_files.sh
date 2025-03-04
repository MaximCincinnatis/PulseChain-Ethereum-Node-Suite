#!/bin/bash

# Source configuration
source /blockchain/config.sh

# Function to check for updates
check_for_updates() {
    # Define the repository URL (only use Maxim's repository)
    REPO_URL="https://raw.githubusercontent.com/MaximCincinnatus/install_pulse_node/main"
    
    # Get current version
    CURRENT_VERSION=$(cat "$INSTALL_PATH/version.txt" 2>/dev/null || echo "unknown")
    
    # Get latest version
    LATEST_VERSION=$(curl -s "$REPO_URL/version.txt")
    
    # Compare versions
    if [ "$CURRENT_VERSION" != "$LATEST_VERSION" ] && [ -n "$LATEST_VERSION" ]; then
        # Get changelog
        CHANGELOG=$(curl -s "$REPO_URL/CHANGELOG.md" | head -n 10)
        
        # Store update information
        mkdir -p "$INSTALL_PATH/updates"
        cat > "$INSTALL_PATH/updates/available_update.json" << EOF
{
    "current_version": "$CURRENT_VERSION",
    "latest_version": "$LATEST_VERSION",
    "changelog": "$CHANGELOG",
    "check_date": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
        return 0
    fi
    return 1
}

# Function to perform update
perform_update() {
    echo "Starting update process..."
    
    # Create temp directory
    TMP_DIR=$(mktemp -d)
    trap 'rm -rf "$TMP_DIR"' EXIT
    
    # Download new files
    echo "Downloading updated files..."
    wget -q $REPO_URL/setup_pulse_node.sh -O $TMP_DIR/setup_pulse_node.sh
    wget -q $REPO_URL/setup_monitoring.sh -O $TMP_DIR/setup_monitoring.sh
    wget -q $REPO_URL/functions.sh -O $TMP_DIR/functions.sh
    
    # Backup current files
    echo "Creating backup of current files..."
    BACKUP_DIR="$INSTALL_PATH/backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    cp "$INSTALL_PATH"/*.sh "$BACKUP_DIR/"
    cp -r "$INSTALL_PATH/helper" "$BACKUP_DIR/"
    
    # Copy new files
    echo "Installing updates..."
    cp $TMP_DIR/setup_pulse_node.sh $INSTALL_PATH/
    cp $TMP_DIR/setup_monitoring.sh $INSTALL_PATH/
    cp $TMP_DIR/functions.sh $INSTALL_PATH/
    
    # Update helper scripts
    mkdir -p "$INSTALL_PATH/helper"
    for script in menu.sh verify_node.sh check_sync.sh backup_restore.sh stop_docker.sh grace.sh; do
        wget -q "$REPO_URL/helper/$script" -O "$TMP_DIR/$script"
        cp "$TMP_DIR/$script" "$INSTALL_PATH/helper/"
    done
    
    # Set permissions
    chmod +x $INSTALL_PATH/*.sh
    chmod +x $INSTALL_PATH/helper/*.sh
    
    # Update version file
    echo "$LATEST_VERSION" > "$INSTALL_PATH/version.txt"
    
    # Remove update notification
    rm -f "$INSTALL_PATH/updates/available_update.json"
    
    echo "Update completed successfully!"
    echo "Backup of previous version stored in: $BACKUP_DIR"
}

# Main menu
show_update_menu() {
    while true; do
        clear
        echo "=== PulseChain Node Update Manager ==="
        echo ""
        
        # Check for stored update information
        if [ -f "$INSTALL_PATH/updates/available_update.json" ]; then
            echo "📦 Update Available!"
            echo "-------------------"
            CURRENT_VERSION=$(jq -r .current_version "$INSTALL_PATH/updates/available_update.json")
            LATEST_VERSION=$(jq -r .latest_version "$INSTALL_PATH/updates/available_update.json")
            echo "Current version: $CURRENT_VERSION"
            echo "Latest version:  $LATEST_VERSION"
            echo ""
            echo "Recent changes:"
            jq -r .changelog "$INSTALL_PATH/updates/available_update.json" | sed 's/^/  /'
            echo ""
        else
            echo "✓ Your node software is up to date"
            echo ""
        fi
        
        echo "Options:"
        echo "1. Check for updates"
        echo "2. Install available update"
        echo "3. View update history"
        echo "4. Return to main menu"
        echo ""
        read -p "Select an option: " choice
        
        case $choice in
            1)
                echo "Checking for updates..."
                if check_for_updates; then
                    echo "Updates are available!"
                else
                    echo "No updates available."
                fi
                read -p "Press Enter to continue..."
                ;;
            2)
                if [ -f "$INSTALL_PATH/updates/available_update.json" ]; then
                    echo ""
                    echo "⚠️  Warning:"
                    echo "- A backup will be created automatically"
                    echo "- Your current configuration will be preserved"
                    echo "- You can rollback using the backup if needed"
                    echo ""
                    read -p "Do you want to proceed with the update? (y/N): " confirm
                    if [[ "$confirm" =~ ^[Yy]$ ]]; then
                        perform_update
                    fi
                else
                    echo "No updates available to install."
                fi
                read -p "Press Enter to continue..."
                ;;
            3)
                clear
                echo "=== Update History ==="
                echo ""
                if [ -d "$INSTALL_PATH/backups" ]; then
                    ls -lh "$INSTALL_PATH/backups"
                else
                    echo "No update history available"
                fi
                echo ""
                read -p "Press Enter to continue..."
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
