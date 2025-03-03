#!/bin/bash

# ===============================================================================
# Ethereum Node Health Check
# ===============================================================================
# Version: 0.1.0
# Description: Monitors health and performance of Ethereum node
# ===============================================================================

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config/eth_config.sh"

# Health check settings
CURL_TIMEOUT=10
MAX_BLOCK_AGE=60  # Maximum acceptable block age in seconds
MIN_PEER_COUNT=10
MAX_CPU_USAGE=90
MAX_MEM_USAGE=90
MAX_DISK_USAGE=90

check_execution_client() {
    echo "Checking execution client..."
    
    # Check if service is running
    if ! docker ps | grep -q "${ETH_CLIENT}"; then
        echo "ERROR: Execution client is not running"
        return 1
    fi
    
    # Check sync status
    local sync_status=$(curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
        http://localhost:${ETH_RPC_PORT})
    
    if [[ $sync_status == *"false"* ]]; then
        echo "✓ Node is synced"
    else
        echo "! Node is still syncing"
    fi
    
    # Check peer count
    local peer_count=$(curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' \
        http://localhost:${ETH_RPC_PORT} | jq -r '.result' | printf "%d" "0x$(cat)")
    
    if [[ $peer_count -lt $MIN_PEER_COUNT ]]; then
        echo "WARNING: Low peer count ($peer_count < $MIN_PEER_COUNT)"
    else
        echo "✓ Peer count: $peer_count"
    fi
    
    # Check latest block
    local latest_block=$(curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
        http://localhost:${ETH_RPC_PORT} | jq -r '.result' | printf "%d" "0x$(cat)")
    
    echo "✓ Latest block: $latest_block"
}

check_consensus_client() {
    echo "Checking consensus client..."
    
    # Check if service is running
    if ! docker ps | grep -q "${CONSENSUS_CLIENT}"; then
        echo "ERROR: Consensus client is not running"
        return 1
    fi
    
    # Check sync status and other metrics based on client type
    case $CONSENSUS_CLIENT in
        "lighthouse")
            local metrics=$(curl -s http://localhost:${ETH_BEACON_METRICS_PORT}/metrics)
            local sync_status=$(echo "$metrics" | grep '^lighthouse_sync_eth2_synced' | awk '{print $2}')
            local peer_count=$(echo "$metrics" | grep '^lighthouse_libp2p_peers' | awk '{print $2}')
            ;;
        "prysm")
            local metrics=$(curl -s http://localhost:${ETH_BEACON_METRICS_PORT}/metrics)
            local sync_status=$(echo "$metrics" | grep '^prysm_sync_eth2_synced' | awk '{print $2}')
            local peer_count=$(echo "$metrics" | grep '^prysm_libp2p_peers' | awk '{print $2}')
            ;;
    esac
    
    if [[ $sync_status == "1" ]]; then
        echo "✓ Beacon node is synced"
    else
        echo "! Beacon node is still syncing"
    fi
    
    if [[ $peer_count -lt $MIN_PEER_COUNT ]]; then
        echo "WARNING: Low peer count ($peer_count < $MIN_PEER_COUNT)"
    else
        echo "✓ Peer count: $peer_count"
    fi
}

check_system_resources() {
    echo "Checking system resources..."
    
    # Check CPU usage
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d. -f1)
    if [[ $cpu_usage -gt $MAX_CPU_USAGE ]]; then
        echo "WARNING: High CPU usage: ${cpu_usage}%"
    else
        echo "✓ CPU usage: ${cpu_usage}%"
    fi
    
    # Check memory usage
    local mem_usage=$(free | grep Mem | awk '{print ($3/$2 * 100)}' | cut -d. -f1)
    if [[ $mem_usage -gt $MAX_MEM_USAGE ]]; then
        echo "WARNING: High memory usage: ${mem_usage}%"
    else
        echo "✓ Memory usage: ${mem_usage}%"
    fi
    
    # Check disk usage
    local disk_usage=$(df -h "${ETH_BASE_DIR}" | awk 'NR==2 {print $5}' | cut -d% -f1)
    if [[ $disk_usage -gt $MAX_DISK_USAGE ]]; then
        echo "WARNING: High disk usage: ${disk_usage}%"
    else
        echo "✓ Disk usage: ${disk_usage}%"
    fi
}

check_monitoring() {
    echo "Checking monitoring services..."
    
    # Check Prometheus
    if curl -s http://localhost:9090/-/healthy > /dev/null; then
        echo "✓ Prometheus is running"
    else
        echo "ERROR: Prometheus is not responding"
    fi
    
    # Check Grafana
    if curl -s http://localhost:3000/api/health > /dev/null; then
        echo "✓ Grafana is running"
    else
        echo "ERROR: Grafana is not responding"
    fi
}

run_health_check() {
    echo "Running Ethereum node health check..."
    echo "===================================="
    echo ""
    
    check_execution_client
    echo ""
    check_consensus_client
    echo ""
    check_system_resources
    echo ""
    check_monitoring
}

# Run health check if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_health_check
fi 