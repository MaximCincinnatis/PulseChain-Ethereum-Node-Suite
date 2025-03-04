#!/bin/bash

# Source configuration
if [ -f "$(dirname "$0")/../config.sh" ]; then
    source "$(dirname "$0")/../config.sh"
else
    echo "Error: Configuration file not found."
    exit 1
fi

# Get local IP address
get_local_ip() {
    hostname -I | awk '{print $1}'
}

# Function to display section header
print_section() {
    echo -e "\033[1;36m=== $1 ===\033[0m"
    echo
}

# Function to display a field with description
print_field() {
    echo -e "\033[1;33m$1:\033[0m $2"
}

# Clear screen
clear

# Display title
echo -e "\033[1;32m============================================\033[0m"
echo -e "\033[1;32m    Mempool Access Information Guide        \033[0m"
echo -e "\033[1;32m============================================\033[0m"
echo

# Basic Connection Information
print_section "Connection Details"
LOCAL_IP=$(get_local_ip)
print_field "Local Node IP" "$LOCAL_IP"
print_field "WebSocket Endpoint" "ws://${LOCAL_IP}:8546"
print_field "HTTP RPC Endpoint" "http://${LOCAL_IP}:8545"
echo

# Available Methods
print_section "Essential Mempool Methods"
echo "1. Get Mempool Contents:"
echo "   Method: txpool_content"
echo "   Example: curl -X POST --data '{\"jsonrpc\":\"2.0\",\"method\":\"txpool_content\",\"params\":[],\"id\":1}' -H \"Content-Type: application/json\" http://${LOCAL_IP}:8545"
echo
echo "2. Get Mempool Status:"
echo "   Method: txpool_status"
echo "   Example: curl -X POST --data '{\"jsonrpc\":\"2.0\",\"method\":\"txpool_status\",\"params\":[],\"id\":1}' -H \"Content-Type: application/json\" http://${LOCAL_IP}:8545"
echo
echo "3. Subscribe to New Pending Transactions (WebSocket):"
echo "   Method: eth_subscribe"
echo "   Example using wscat:"
echo "   wscat -c ws://${LOCAL_IP}:8546"
echo "   > {\"jsonrpc\":\"2.0\",\"method\":\"eth_subscribe\",\"params\":[\"newPendingTransactions\"],\"id\":1}"
echo

# Code Examples
print_section "Code Examples"
echo "JavaScript (Web3.js):"
echo '```javascript
const Web3 = require("web3");
const web3 = new Web3(new Web3.providers.WebsocketProvider("ws://LOCAL_IP:8546"));

// Subscribe to pending transactions
web3.eth.subscribe("pendingTransactions", (error, txHash) => {
    if (!error) {
        console.log("Pending TX:", txHash);
        // Get full transaction details
        web3.eth.getTransaction(txHash).then(console.log);
    }
});

// Get mempool content
async function getMempoolContent() {
    return await web3.eth.send("txpool_content", []);
}
```'
echo

echo "Python (Web3.py):"
echo '```python
from web3 import Web3

# Connect to your node
w3 = Web3(Web3.HTTPProvider("http://LOCAL_IP:8545"))

# Get mempool content
def get_mempool_content():
    return w3.provider.make_request("txpool_content", [])

# Get pending transaction count
def get_pending_tx_count():
    return w3.eth.get_block_transaction_count("pending")
```'
echo

# Performance Tips
print_section "Performance Optimization Tips"
echo "1. Use WebSocket for real-time updates instead of polling"
echo "2. Implement proper error handling and reconnection logic"
echo "3. Consider using batch requests for multiple transactions"
echo "4. Monitor your connection limits and adjust as needed"
echo

# Troubleshooting
print_section "Troubleshooting"
echo "1. If connection fails, verify:"
echo "   - Node is fully synced"
echo "   - Ports 8545 (HTTP) and 8546 (WS) are accessible"
echo "   - Your local machine can reach the node IP"
echo
echo "2. For performance issues:"
echo "   - Check network connectivity"
echo "   - Monitor system resources"
echo "   - Verify node is not overloaded"
echo

echo -e "\033[1;32m============================================\033[0m"
echo "Press Enter to return to the menu..."
read -r 