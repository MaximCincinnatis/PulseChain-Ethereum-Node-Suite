#!/bin/bash

# check_rpc_connection.sh
# This script checks the RPC connection to the Erigon node
# It can be used to verify that the AI indexing machine can connect to the node

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Default RPC URL
DEFAULT_RPC_URL="http://localhost:8545"

# Get the RPC URL from command line argument or use default
RPC_URL=${1:-$DEFAULT_RPC_URL}

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
        echo -e "${RED}Node is still syncing${NC}"
        echo "$sync_response"
    fi
fi

echo ""
echo "RPC connection check completed." 