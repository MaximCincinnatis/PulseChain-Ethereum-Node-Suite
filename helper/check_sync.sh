#!/bin/bash

# Functions
epoch_to_time(){
    expr 1683785555 + \( $1 \* 320 \)
}

time_to_epoch(){
    expr \( $1 - 1683785555 \) / 320
}

display_epoch(){
    echo "epoch: $1 : $(date -d@$(epoch_to_time $1)) <-- $2"
}

# Main script
echo "PulseChain Node Sync Status Check"
echo "================================="
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
    EXEC_SYNCED=$(curl -s -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' http://localhost:8545 | jq .result)
    if [ "$EXEC_SYNCED" == "false" ]; then
        echo "Execution client is fully synced."
    else
        echo "Execution client is still syncing."
    fi
fi

echo ""
echo "Sync check complete."

echo "Press [Enter] to exit..."
read
