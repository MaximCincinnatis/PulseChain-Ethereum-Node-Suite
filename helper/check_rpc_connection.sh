#!/bin/bash

# check_rpc_connection.sh
# This script checks the RPC connection to the execution client
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

declare -A NETWORK_EXPLORER
NETWORK_EXPLORER["pulsechain"]="https://scan.pulsechain.com"
NETWORK_EXPLORER["ethereum"]="https://etherscan.io"

declare -A PUBLIC_RPC
PUBLIC_RPC["pulsechain"]="https://rpc.pulsechain.com"
PUBLIC_RPC["ethereum"]="https://eth.llamarpc.com"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Default RPC URL
DEFAULT_RPC_URL="http://localhost:8545"

# Get the RPC URL from command line argument or use default
RPC_URL=${1:-$DEFAULT_RPC_URL}

echo "${NETWORK_NAME[$SELECTED_NETWORK]} RPC Connection Check"
echo "=================================="
echo "Checking RPC connection to: $RPC_URL"
echo ""

# Check if curl is installed
if ! command -v curl &> /dev/null; then
    echo -e "${RED}Error: curl is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Warning: jq is not installed. Output will not be formatted.${NC}"
    JQ_AVAILABLE=false
else
    JQ_AVAILABLE=true
fi

# Function to make RPC call
make_rpc_call() {
    local method=$1
    local params=$2
    
    response=$(curl -s -X POST -H "Content-Type: application/json" --data "{\"jsonrpc\":\"2.0\",\"method\":\"$method\",\"params\":$params,\"id\":1}" $RPC_URL)
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Failed to connect to $RPC_URL${NC}"
        exit 1
    fi
    
    echo "$response"
}

# Check chain ID first
echo "Checking chain ID..."
chain_response=$(make_rpc_call "eth_chainId" "[]")

if [[ $chain_response == *"error"* ]]; then
    echo -e "${RED}Error: Failed to get chain ID${NC}"
    echo "$chain_response"
else
    if $JQ_AVAILABLE; then
        chain_id_hex=$(echo $chain_response | jq -r '.result')
        chain_id=$((16#${chain_id_hex:2}))
    else
        chain_id_hex=$(echo $chain_response | grep -o '"result":"[^"]*' | sed 's/"result":"//')
        chain_id=$((16#${chain_id_hex:2}))
    fi
    
    expected_chain_id=${NETWORK_CHAIN_ID[$SELECTED_NETWORK]}
    if [ "$chain_id" == "$expected_chain_id" ]; then
        echo -e "${GREEN}Connected to ${NETWORK_NAME[$SELECTED_NETWORK]} (Chain ID: $chain_id)${NC}"
    else
        echo -e "${RED}Warning: Wrong network detected!${NC}"
        echo -e "Expected: ${NETWORK_NAME[$SELECTED_NETWORK]} (Chain ID: $expected_chain_id)"
        echo -e "Connected to: Chain ID $chain_id"
        echo ""
        echo "Please check your network configuration."
        exit 1
    fi
fi

echo ""

# Check network status
echo "Checking network status..."
network_response=$(make_rpc_call "net_version" "[]")

if [[ $network_response == *"error"* ]]; then
    echo -e "${RED}Error: Failed to get network version${NC}"
    echo "$network_response"
else
    if $JQ_AVAILABLE; then
        network_id=$(echo $network_response | jq -r '.result')
    else
        network_id=$(echo $network_response | grep -o '"result":"[^"]*' | sed 's/"result":"//')
    fi
    echo -e "${GREEN}Connected to network ID: $network_id${NC}"
fi

echo ""

# Check latest block
echo "Checking latest block..."
block_response=$(make_rpc_call "eth_blockNumber" "[]")

if [[ $block_response == *"error"* ]]; then
    echo -e "${RED}Error: Failed to get latest block number${NC}"
    echo "$block_response"
else
    if $JQ_AVAILABLE; then
        block_number=$(echo $block_response | jq -r '.result')
        block_decimal=$((16#${block_number:2}))
    else
        block_number=$(echo $block_response | grep -o '"result":"[^"]*' | sed 's/"result":"//')
        block_decimal=$((16#${block_number:2}))
    fi
    echo -e "${GREEN}Latest block number: $block_decimal (hex: $block_number)${NC}"
    
    # Compare with public RPC endpoint
    echo "Comparing with public RPC endpoint..."
    public_response=$(curl -s -X POST -H "Content-Type: application/json" \
        --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_blockNumber\",\"params\":[],\"id\":1}" \
        "${PUBLIC_RPC[$SELECTED_NETWORK]}")
    
    if [[ $public_response == *"error"* ]]; then
        echo -e "${YELLOW}Warning: Could not compare with public RPC${NC}"
    else
        if $JQ_AVAILABLE; then
            public_block=$(echo $public_response | jq -r '.result')
            public_decimal=$((16#${public_block:2}))
        else
            public_block=$(echo $public_response | grep -o '"result":"[^"]*' | sed 's/"result":"//')
            public_decimal=$((16#${public_block:2}))
        fi
        
        block_diff=$((public_decimal - block_decimal))
        if [ $block_diff -lt 0 ]; then
            block_diff=$((block_diff * -1))
        fi
        
        if [ $block_diff -lt 10 ]; then
            echo -e "${GREEN}Node is in sync with network (within $block_diff blocks)${NC}"
        else
            echo -e "${YELLOW}Node is $block_diff blocks behind network${NC}"
        fi
    fi
fi

echo ""

# Check if node is syncing
echo "Checking sync status..."
sync_response=$(make_rpc_call "eth_syncing" "[]")

if [[ $sync_response == *"error"* ]]; then
    echo -e "${RED}Error: Failed to get sync status${NC}"
    echo "$sync_response"
else
    if $JQ_AVAILABLE; then
        sync_status=$(echo $sync_response | jq -r '.result')
    else
        sync_status=$(echo $sync_response | grep -o '"result":[^,}]*' | sed 's/"result"://')
    fi
    
    if [[ $sync_status == "false" ]]; then
        echo -e "${GREEN}Node is fully synced${NC}"
    else
        echo -e "${YELLOW}Node is still syncing${NC}"
        if $JQ_AVAILABLE; then
            current_block=$(echo $sync_response | jq -r '.result.currentBlock')
            highest_block=$(echo $sync_response | jq -r '.result.highestBlock')
            current_decimal=$((16#${current_block:2}))
            highest_decimal=$((16#${highest_block:2}))
            progress=$(echo "scale=2; $current_decimal * 100 / $highest_decimal" | bc)
            echo "Current Block: $current_decimal"
            echo "Highest Block: $highest_decimal"
            echo "Sync Progress: ${progress}%"
        else
            echo "$sync_response"
        fi
    fi
fi

echo ""
echo "Network Resources:"
echo "1. Block Explorer: ${NETWORK_EXPLORER[$SELECTED_NETWORK]}"
echo "2. Public RPC: ${PUBLIC_RPC[$SELECTED_NETWORK]}"
echo ""

echo "RPC connection check completed." 