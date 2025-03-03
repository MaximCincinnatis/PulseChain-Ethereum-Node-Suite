#!/bin/bash

# Source the update manager
source /blockchain/helper/updates/update_manager.sh

# Run update check in quiet mode
check_for_updates > /dev/null

# Exit with status based on whether updates are available
if [ -f "/blockchain/updates/available_updates.json" ]; then
    exit 1  # Updates available
else
    exit 0  # No updates available
fi 