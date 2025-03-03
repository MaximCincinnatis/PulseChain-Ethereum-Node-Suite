#!/bin/bash

# Blockchain Node Verification Script
# This script runs a comprehensive verification of the node setup
# Supports both PulseChain and Ethereum networks

# Get the selected network from environment or use default
SELECTED_NETWORK="${SELECTED_NETWORK:-pulsechain}"

# Network-specific parameters
declare -A NETWORK_NAME
NETWORK_NAME["pulsechain"]="PulseChain"
NETWORK_NAME["ethereum"]="Ethereum"

declare -A NETWORK_CHAIN_ID
NETWORK_CHAIN_ID["pulsechain"]="943"
NETWORK_CHAIN_ID["ethereum"]="1"

declare -A NETWORK_CHECKPOINT
NETWORK_CHECKPOINT["pulsechain"]="checkpoint.pulsechain.com"
NETWORK_CHECKPOINT["ethereum"]="beaconcha.in"

declare -A NETWORK_EXPLORER
NETWORK_EXPLORER["pulsechain"]="scan.pulsechain.com"
NETWORK_EXPLORER["ethereum"]="etherscan.io"

declare -A NETWORK_BOOTNODE
NETWORK_BOOTNODE["pulsechain"]="boot.pulsechain.com"
NETWORK_BOOTNODE["ethereum"]="boot.ethereum.org"

# Determine script location and source helper functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../functions.sh"

# Initialize logging
if [[ -z "$CUSTOM_PATH" ]]; then
    # Try to determine the custom path from the parent directory
    CUSTOM_PATH=$(dirname "$SCRIPT_DIR")
fi

init_logging "$CUSTOM_PATH"
log_info "Starting ${NETWORK_NAME[$SELECTED_NETWORK]} node verification using verify_node.sh"

# Set up standardized error handling
setup_error_handling

# Verify system requirements before proceeding
log_info "Checking system requirements"
# Adjust disk space requirements based on network
if [ "$SELECTED_NETWORK" = "ethereum" ]; then
    check_disk_space 10 "$CUSTOM_PATH"  # Require at least 10GB free space for Ethereum
else
    check_disk_space 5 "$CUSTOM_PATH"   # Require at least 5GB free space for PulseChain
fi
check_memory 4                          # Require at least 4GB RAM

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

echo -e "${GREEN}Detected configuration:${NC}"
echo "Network: ${NETWORK_NAME[$SELECTED_NETWORK]}"
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
check_network_connectivity "${NETWORK_CHECKPOINT[$SELECTED_NETWORK]}" 443 5

echo -e "${GREEN}Running ${NETWORK_NAME[$SELECTED_NETWORK]} node verification...${NC}"
echo "This may take a moment. Please wait."
echo ""

# Verify chain ID
echo "Verifying chain ID..."
CHAIN_ID=$(curl -s -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
    http://localhost:8545 | jq -r '.result')

if [ -n "$CHAIN_ID" ]; then
    CHAIN_ID_DEC=$((16#${CHAIN_ID:2}))
    if [ "$CHAIN_ID_DEC" = "${NETWORK_CHAIN_ID[$SELECTED_NETWORK]}" ]; then
        echo -e "${GREEN}Chain ID verified: $CHAIN_ID_DEC${NC}"
    else
        echo -e "${RED}Error: Wrong chain ID detected!${NC}"
        echo "Expected: ${NETWORK_CHAIN_ID[$SELECTED_NETWORK]}"
        echo "Found: $CHAIN_ID_DEC"
        exit 1
    fi
else
    echo -e "${RED}Error: Could not verify chain ID${NC}"
    exit 1
fi

# Verify node setup (extracted from functions.sh)
if verify_node_setup "$EXECUTION_CLIENT" "$CONSENSUS_CLIENT" "$DETAILED"; then
    log_info "Node verification completed successfully"
    echo -e "${GREEN}Node verification completed successfully!${NC}"
    echo ""
    echo "Your ${NETWORK_NAME[$SELECTED_NETWORK]} node (non-validator) appears to be correctly set up and running."
    echo "You can now safely use your node for connecting to the ${NETWORK_NAME[$SELECTED_NETWORK]} network."
    
    # Display network-specific information
    echo ""
    echo -e "${GREEN}Network Resources:${NC}"
    echo "1. Block Explorer: https://${NETWORK_EXPLORER[$SELECTED_NETWORK]}"
    echo "2. Checkpoint Sync: https://${NETWORK_CHECKPOINT[$SELECTED_NETWORK]}"
    echo "3. Boot Node: ${NETWORK_BOOTNODE[$SELECTED_NETWORK]}"
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
    echo "   ping ${NETWORK_CHECKPOINT[$SELECTED_NETWORK]}"
    echo "   - Check firewall settings: sudo ufw status"
    
    echo "3. Ensure you have the latest client versions:"
    echo "   Run the update script in the helper directory"
    
    echo "4. Check disk space:"
    echo "   df -h"
    
    echo "5. Verify network configuration:"
    echo "   - Check if you're connected to the right network (Chain ID: ${NETWORK_CHAIN_ID[$SELECTED_NETWORK]})"
    echo "   - Verify your client configurations match your selected network"
fi

echo ""
echo "Press Enter to continue..."
read 