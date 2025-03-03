#!/bin/bash

# Get the selected network from environment or use default
SELECTED_NETWORK="${SELECTED_NETWORK:-pulsechain}"

# Network-specific parameters
declare -A GENESIS_TIME
GENESIS_TIME["pulsechain"]=1683785555  # PulseChain genesis time
GENESIS_TIME["ethereum"]=1606824023     # Ethereum genesis time

declare -A SLOT_TIME
SLOT_TIME["pulsechain"]=12  # PulseChain slot time in seconds
SLOT_TIME["ethereum"]=12    # Ethereum slot time in seconds

declare -A NETWORK_NAME
NETWORK_NAME["pulsechain"]="PulseChain"
NETWORK_NAME["ethereum"]="Ethereum"

# Functions
epoch_to_time() {
    local network_genesis=${GENESIS_TIME[$SELECTED_NETWORK]}
    local slot_time=${SLOT_TIME[$SELECTED_NETWORK]}
    expr $network_genesis + \( $1 \* \( 32 \* $slot_time \) \)
}

time_to_epoch() {
    local network_genesis=${GENESIS_TIME[$SELECTED_NETWORK]}
    local slot_time=${SLOT_TIME[$SELECTED_NETWORK]}
    expr \( $1 - $network_genesis \) / \( 32 \* $slot_time \)
}

display_epoch() {
    echo "epoch: $1 : $(date -d@$(epoch_to_time $1)) <-- $2"
}

# Main script
echo "${NETWORK_NAME[$SELECTED_NETWORK]} Node Sync Status Check"
echo "=================================================="
echo ""

# Get local epoch from the beacon node
BEACON_PORT=""
BEACON_NODE="http://localhost"

# Determine which beacon client is running
if docker ps | grep -q "beacon"; then
    if docker logs beacon 2>&1 | grep -q "Lighthouse"; then
        echo "Detected Lighthouse beacon client"
        BEACON_PORT="5052"
    elif docker logs beacon 2>&1 | grep -q "Prysm"; then
        echo "Detected Prysm beacon client"
        BEACON_PORT="3500"
    else
        echo "Unknown beacon client. Using default port 5052."
        BEACON_PORT="5052"
    fi
else
    echo "No beacon client running. Please start your beacon client first."
    exit 1
fi

BEACON_NODE="${BEACON_NODE}:${BEACON_PORT}"
echo "Using beacon node at: ${BEACON_NODE}"
echo "Network: ${NETWORK_NAME[$SELECTED_NETWORK]}"
echo ""

# Get current finalized epoch
FINALIZED_EPOCH=$(curl -s -X GET "${BEACON_NODE}/eth/v1/beacon/states/finalized/finality_checkpoints" | jq .data.finalized.epoch)
if [ -z "$FINALIZED_EPOCH" ] || [ "$FINALIZED_EPOCH" == "null" ]; then
    echo "Error: Unable to get finalized epoch from beacon node."
    exit 1
fi

# Get current head epoch
CURRENT_SLOT=$(curl -s -X GET "${BEACON_NODE}/eth/v1/beacon/headers/head" | jq .data.header.message.slot)
if [ -z "$CURRENT_SLOT" ] || [ "$CURRENT_SLOT" == "null" ]; then
    echo "Error: Unable to get current slot from beacon node."
    exit 1
fi
CURRENT_EPOCH=$((CURRENT_SLOT / 32))

echo "Current finalized epoch: $FINALIZED_EPOCH ($(date -d@$(epoch_to_time $FINALIZED_EPOCH)))"
echo "Current head epoch: $CURRENT_EPOCH ($(date -d@$(epoch_to_time $CURRENT_EPOCH)))"
echo ""
echo "Node is $(($CURRENT_EPOCH - $FINALIZED_EPOCH)) epochs ahead of finality."
echo ""

# Check if execution client is synced
if docker ps | grep -q "execution"; then
    # Get network-specific chain ID
    CHAIN_ID=$(curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
        http://localhost:8545 | jq -r .result)
    
    # Verify chain ID
    EXPECTED_CHAIN_ID=""
    case $SELECTED_NETWORK in
        "pulsechain")
            EXPECTED_CHAIN_ID="0x3af"  # 943 in hex
            ;;
        "ethereum")
            EXPECTED_CHAIN_ID="0x1"    # 1 in hex
            ;;
    esac
    
    if [ "$CHAIN_ID" != "$EXPECTED_CHAIN_ID" ]; then
        echo "Warning: Connected to wrong network!"
        echo "Expected chain ID: $EXPECTED_CHAIN_ID (${NETWORK_NAME[$SELECTED_NETWORK]})"
        echo "Connected to chain ID: $CHAIN_ID"
        echo ""
    fi
    
    EXEC_SYNCED=$(curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
        http://localhost:8545 | jq .result)
    if [ "$EXEC_SYNCED" == "false" ]; then
        echo "Execution client is fully synced."
    else
        echo "Execution client is still syncing."
        # Get detailed sync status
        SYNC_STATUS=$(curl -s -X POST -H "Content-Type: application/json" \
            --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
            http://localhost:8545)
        CURRENT_BLOCK=$(echo $SYNC_STATUS | jq -r '.result.currentBlock // "0x0"')
        HIGHEST_BLOCK=$(echo $SYNC_STATUS | jq -r '.result.highestBlock // "0x0"')
        echo "Current block: $((16#${CURRENT_BLOCK#0x}))"
        echo "Highest block: $((16#${HIGHEST_BLOCK#0x}))"
        PROGRESS=$(echo "scale=2; $((16#${CURRENT_BLOCK#0x})) * 100 / $((16#${HIGHEST_BLOCK#0x}))" | bc)
        echo "Sync progress: ${PROGRESS}%"
    fi
fi

echo ""
echo "Sync check complete."

# Network-specific troubleshooting tips
echo ""
echo "Troubleshooting Tips for ${NETWORK_NAME[$SELECTED_NETWORK]}:"
case $SELECTED_NETWORK in
    "pulsechain")
        echo "1. Check PulseChain block explorer: https://scan.pulsechain.com"
        echo "2. Verify your node against PulseChain checkpoint: https://checkpoint.pulsechain.com"
        echo "3. PulseChain RPC status: https://rpc.pulsechain.com"
        ;;
    "ethereum")
        echo "1. Check Ethereum block explorer: https://etherscan.io"
        echo "2. Verify your node against Ethereum checkpoint: https://beaconcha.in"
        echo "3. Check Ethereum network status: https://ethstats.net"
        ;;
esac
echo ""

echo "Press [Enter] to exit..."
read
