#!/bin/bash

# Source common functions
source "$(dirname "$0")/../functions.sh"

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Peer limits for different clients
MAX_PEERS_SYNC_EXECUTION=800    # During sync
MAX_PEERS_NORMAL_EXECUTION=500  # After sync
MAX_PEERS_SYNC_CONSENSUS=400    # During sync
MAX_PEERS_NORMAL_CONSENSUS=250  # After sync
MIN_REQUIRED_PEERS=25           # Minimum before retry
CHECK_INTERVAL=300              # 5 minutes between checks

# Get current peer count for a specific client
get_peer_count() {
    local client_type=$1
    local peer_count=0
    
    case "$client_type" in
        "geth")
            # Use admin.peers.length via RPC
            peer_count=$(curl -s -X POST -H "Content-Type: application/json" \
                --data '{"jsonrpc":"2.0","method":"admin_peers","params":[],"id":1}' \
                http://localhost:8545 | jq '.result | length')
            ;;
        "erigon")
            # Use net.peerCount via RPC
            peer_count=$(curl -s -X POST -H "Content-Type: application/json" \
                --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' \
                http://localhost:8545 | jq '.result' | sed 's/"0x\([0-9a-f]*\)"/\1/g' | awk '{print $1}')
            ;;
        "lighthouse")
            # Use lighthouse API
            peer_count=$(curl -s http://localhost:5052/eth/v1/node/peer_count | \
                jq '.data.connected')
            ;;
        "prysm")
            # Use prysm API
            peer_count=$(curl -s http://localhost:3500/eth/v1/node/peer_count | \
                jq '.data.connected')
            ;;
    esac
    
    echo "${peer_count:-0}"  # Return 0 if null or empty
}

# Check if client is syncing
check_if_syncing() {
    local client_type=$1
    local is_syncing=false
    
    case "$client_type" in
        "geth"|"erigon")
            # Check execution client sync status
            local sync_status=$(curl -s -X POST -H "Content-Type: application/json" \
                --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
                http://localhost:8545)
            if [[ "$sync_status" != *"false"* ]]; then
                is_syncing=true
            fi
            ;;
        "lighthouse"|"prysm")
            # Check consensus client sync status
            local api_port=5052
            if [ "$client_type" = "prysm" ]; then
                api_port=3500
            fi
            local sync_status=$(curl -s http://localhost:${api_port}/eth/v1/node/syncing)
            if [[ "$sync_status" == *"\"is_syncing\":true"* ]]; then
                is_syncing=true
            fi
            ;;
    esac
    
    echo "$is_syncing"
}

# Discover more peers using available methods
discover_more_peers() {
    local client_type=$1
    
    log_info "Attempting to discover more peers for $client_type..."
    
    # Common discovery methods
    case "$client_type" in
        "geth"|"erigon")
            # Add static nodes if available
            if [ -f "/blockchain/config/static-nodes.json" ]; then
                log_info "Adding static nodes..."
                curl -s -X POST -H "Content-Type: application/json" \
                    --data '{"jsonrpc":"2.0","method":"admin_addPeer","params":["'$(cat /blockchain/config/static-nodes.json | jq -r '.[0]')'"],"id":1}' \
                    http://localhost:8545
            fi
            
            # Enable discovery v5 for execution clients
            curl -s -X POST -H "Content-Type: application/json" \
                --data '{"jsonrpc":"2.0","method":"admin_enableDiscovery","params":[],"id":1}' \
                http://localhost:8545
                
            # For Erigon, enable torrent discovery
            if [ "$client_type" = "erigon" ]; then
                log_info "Enabling torrent discovery for Erigon..."
                curl -s -X POST -H "Content-Type: application/json" \
                    --data '{"jsonrpc":"2.0","method":"admin_enableTorrent","params":[],"id":1}' \
                    http://localhost:8545
            fi
            ;;
            
        "lighthouse"|"prysm")
            # Consensus clients handle peer discovery automatically
            # We can only ensure the discovery is enabled
            log_info "Ensuring peer discovery is enabled for $client_type..."
            ;;
    esac
}

# Main peer management function
manage_peers() {
    local client_type=$1
    local current_peers=$(get_peer_count "$client_type")
    local is_syncing=$(check_if_syncing "$client_type")
    
    # Set appropriate limits based on client type
    if [ "$client_type" = "geth" ] || [ "$client_type" = "erigon" ]; then
        MAX_PEERS_SYNC=$MAX_PEERS_SYNC_EXECUTION
        MAX_PEERS_NORMAL=$MAX_PEERS_NORMAL_EXECUTION
    else
        MAX_PEERS_SYNC=$MAX_PEERS_SYNC_CONSENSUS
        MAX_PEERS_NORMAL=$MAX_PEERS_NORMAL_CONSENSUS
    fi
    
    # Log current status
    log_info "$client_type status - Peers: $current_peers, Syncing: $is_syncing"
    
    # During sync: maximize peers
    if [ "$is_syncing" = "true" ]; then
        if [ "$current_peers" -lt "$MAX_PEERS_SYNC" ]; then
            log_info "Syncing in progress, attempting to reach $MAX_PEERS_SYNC peers..."
            discover_more_peers "$client_type"
        fi
    else
        # Normal operation: maintain healthy peer count
        if [ "$current_peers" -lt "$MIN_REQUIRED_PEERS" ]; then
            log_info "Peer count below minimum, discovering more peers..."
            discover_more_peers "$client_type"
        elif [ "$current_peers" -lt "$MAX_PEERS_NORMAL" ]; then
            log_info "Operating normally with $current_peers peers"
        fi
    fi
}

# Main loop
main() {
    log_info "Starting peer management service..."
    
    while true; do
        # Check execution client if configured
        if [ -n "$ETH_CLIENT" ]; then
            manage_peers "$ETH_CLIENT"
        fi
        
        # Check consensus client if configured
        if [ -n "$CONSENSUS_CLIENT" ]; then
            manage_peers "$CONSENSUS_CLIENT"
        fi
        
        sleep $CHECK_INTERVAL
    done
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 