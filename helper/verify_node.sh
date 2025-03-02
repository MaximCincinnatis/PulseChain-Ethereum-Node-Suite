#!/bin/bash

# PulseChain Node Verification Script
# This script runs a comprehensive verification of the PulseChain node setup
# It tests connectivity, container health, and API functionality

# Determine script location and source helper functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../functions.sh"

# Initialize logging
if [[ -z "$CUSTOM_PATH" ]]; then
    # Try to determine the custom path from the parent directory
    CUSTOM_PATH=$(dirname "$SCRIPT_DIR")
fi

init_logging "$CUSTOM_PATH"
log_info "Starting node verification using verify_node.sh"

# Set up standardized error handling
setup_error_handling

# Verify system requirements before proceeding
log_info "Checking system requirements"
check_disk_space 5 "$CUSTOM_PATH"  # Require at least 5GB free space
check_memory 2                     # Require at least 2GB RAM

# Determine client types from running containers
EXECUTION_CLIENT=""
if docker ps | grep -q "execution"; then
    if docker logs execution 2>&1 | grep -q "Geth"; then
        EXECUTION_CLIENT="geth"
    elif docker logs execution 2>&1 | grep -q "Erigon"; then
        EXECUTION_CLIENT="erigon"
    else
        EXECUTION_CLIENT="execution"
    fi
fi

CONSENSUS_CLIENT=""
if docker ps | grep -q "beacon"; then
    if docker logs beacon 2>&1 | grep -q "Lighthouse"; then
        CONSENSUS_CLIENT="lighthouse"
    elif docker logs beacon 2>&1 | grep -q "Prysm"; then
        CONSENSUS_CLIENT="prysm"
    else
        CONSENSUS_CLIENT="beacon"
    fi
fi

# Validate required arguments
if [[ -z "$EXECUTION_CLIENT" || -z "$CONSENSUS_CLIENT" ]]; then
    log_error "Unable to determine client types for verification"
    echo -e "${RED}Error: Unable to determine client types.${NC}"
    echo "Please make sure your node containers are running."
    echo ""
    echo -e "${YELLOW}Suggestions:${NC}"
    echo "1. Check if Docker is running: sudo systemctl status docker"
    echo "2. Start your node containers: $CUSTOM_PATH/start_execution.sh and $CUSTOM_PATH/start_consensus.sh"
    echo "3. Check if containers are running: docker ps"
    exit 1
fi

echo -e "${GREEN}Detected clients:${NC}"
echo "Execution client: $EXECUTION_CLIENT"
echo "Consensus client: $CONSENSUS_CLIENT"
echo ""

# Determine if we're running detailed checks
DETAILED=${1:-"false"}
if [[ "$DETAILED" == "-v" || "$DETAILED" == "--verbose" ]]; then
    DETAILED="true"
    echo "Running detailed verification..."
fi

# Check network connectivity before proceeding
check_network_connectivity "8.8.8.8" 53 5

echo -e "${GREEN}Running node verification...${NC}"
echo "This may take a moment. Please wait."
echo ""

# Verify node setup (extracted from functions.sh)
if verify_node_setup "$EXECUTION_CLIENT" "$CONSENSUS_CLIENT" "$DETAILED"; then
    log_info "Node verification completed successfully"
    echo -e "${GREEN}Node verification completed successfully!${NC}"
    echo ""
    echo "Your PulseChain node (non-validator) appears to be correctly set up and running."
    echo "You can now safely use your node for connecting to the PulseChain network."
else
    log_error "Node verification completed with issues"
    echo -e "${YELLOW}Node verification completed with some issues.${NC}"
    echo ""
    echo "While your node may still function, there are some issues that should be addressed:"
    echo ""
    echo -e "${YELLOW}Troubleshooting Suggestions:${NC}"
    
    echo "1. Check Docker container logs:"
    echo "   sudo docker logs execution"
    echo "   sudo docker logs beacon"
    
    echo "2. Verify network connectivity:"
    echo "   ping checkpoint.pulsechain.com"
    echo "   - Check firewall settings: sudo ufw status"
    
    echo "3. Ensure you have the latest client versions:"
    echo "   Run the update script in the helper directory"
    
    echo "4. Check disk space:"
    echo "   df -h"
fi

echo ""
echo "Press Enter to continue..."
read 