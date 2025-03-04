#!/bin/bash

# Source configuration
source /blockchain/config.sh

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "=== Node Status ==="
echo ""

# Check Docker containers
echo "Docker Container Status:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E 'execution|beacon'

# Check sync status using existing script
if [ -f "${CUSTOM_PATH}/helper/check_sync.sh" ]; then
    ${CUSTOM_PATH}/helper/check_sync.sh
fi

# Check RPC connection using existing script
if [ -f "${CUSTOM_PATH}/helper/check_rpc_connection.sh" ]; then
    ${CUSTOM_PATH}/helper/check_rpc_connection.sh
fi

# Show version information using existing script
if [ -f "${CUSTOM_PATH}/helper/show_version.sh" ]; then
    ${CUSTOM_PATH}/helper/show_version.sh
fi

echo ""
read -p "Press Enter to continue..." 