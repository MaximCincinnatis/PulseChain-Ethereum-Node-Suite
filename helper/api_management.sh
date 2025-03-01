#!/bin/bash

# API Endpoint Management Script for PulseChain Archive Node
# This script helps manage and configure API endpoints for the node

VERSION="1.0"
CUSTOM_PATH=${CUSTOM_PATH:-"/blockchain"}

# Function to display current API configuration
show_api_config() {
    clear
    echo "Current API Configuration:"
    echo "=========================="
    echo ""
    echo "HTTP API Methods:"
    grep -E 'http.api' "${CUSTOM_PATH}/start_execution.sh"
    echo ""
    echo "WebSocket API Methods:"
    grep -E 'ws.api' "${CUSTOM_PATH}/start_execution.sh"
    echo ""
    read -p "Press Enter to continue..."
}

# Function to modify API methods
modify_api_methods() {
    clear
    echo "Modify API Methods"
    echo "================="
    echo ""
    
    echo "This will modify your start_execution.sh script to update API methods."
    echo "Current configuration:"
    echo ""
    echo "HTTP API Methods:"
    http_api=$(grep -E 'http.api' "${CUSTOM_PATH}/start_execution.sh")
    echo "$http_api"
    echo ""
    echo "WebSocket API Methods:"
    ws_api=$(grep -E 'ws.api' "${CUSTOM_PATH}/start_execution.sh")
    echo "$ws_api"
    echo ""
    
    read -p "Do you want to continue? (y/n): " confirm
    if [[ "$confirm" != "y" ]]; then
        echo "Operation cancelled."
        read -p "Press Enter to continue..."
        return
    fi
    
    # Backup the original file
    cp "${CUSTOM_PATH}/start_execution.sh" "${CUSTOM_PATH}/start_execution.sh.bak"
    
    # Extract current API methods
    current_http_api=$(echo "$http_api" | grep -oP '(?<=http.api=")[^"]*')
    current_ws_api=$(echo "$ws_api" | grep -oP '(?<=ws.api=")[^"]*')
    
    echo ""
    echo "Available API namespaces: admin, debug, eth, erigon, net, trace, txpool, web3"
    echo ""
    
    # Update HTTP API methods
    echo "Current HTTP API methods: $current_http_api"
    read -p "Enter new HTTP API methods (comma-separated, leave empty to keep current): " new_http_api
    
    if [[ -n "$new_http_api" ]]; then
        # Update HTTP API methods in the file
        sed -i "s/--http.api=\"[^\"]*\"/--http.api=\"$new_http_api\"/g" "${CUSTOM_PATH}/start_execution.sh"
    fi
    
    # Update WebSocket API methods
    echo "Current WebSocket API methods: $current_ws_api"
    read -p "Enter new WebSocket API methods (comma-separated, leave empty to keep current): " new_ws_api
    
    if [[ -n "$new_ws_api" ]]; then
        # Update WebSocket API methods in the file
        sed -i "s/--ws.api=\"[^\"]*\"/--ws.api=\"$new_ws_api\"/g" "${CUSTOM_PATH}/start_execution.sh"
    fi
    
    echo ""
    echo "API methods updated successfully!"
    echo "You'll need to restart the execution client for changes to take effect."
    echo ""
    read -p "Do you want to restart the execution client now? (y/n): " restart_now
    if [[ "$restart_now" == "y" ]]; then
        echo "Restarting execution client..."
        sudo docker stop -t 300 execution
        sleep 1
        sudo docker container prune -f
        ${CUSTOM_PATH}/start_execution.sh
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

# Function to test API endpoints
test_api_endpoints() {
    clear
    echo "Test API Endpoints"
    echo "================="
    echo ""
    
    # Check if curl is installed
    if ! command -v curl &> /dev/null; then
        echo "curl is not installed. Installing..."
        sudo apt-get update && sudo apt-get install -y curl
    fi
    
    # Define test methods for different namespaces
    declare -A test_methods=(
        ["eth"]='{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
        ["net"]='{"jsonrpc":"2.0","method":"net_version","params":[],"id":1}'
        ["web3"]='{"jsonrpc":"2.0","method":"web3_clientVersion","params":[],"id":1}'
        ["txpool"]='{"jsonrpc":"2.0","method":"txpool_status","params":[],"id":1}'
        ["admin"]='{"jsonrpc":"2.0","method":"admin_nodeInfo","params":[],"id":1}'
        ["debug"]='{"jsonrpc":"2.0","method":"debug_metrics","params":[],"id":1}'
    )
    
    echo "Select an API namespace to test:"
    echo "1) eth (Ethereum)"
    echo "2) net (Network)"
    echo "3) web3 (Web3)"
    echo "4) txpool (Transaction Pool)"
    echo "5) admin (Admin)"
    echo "6) debug (Debug)"
    echo "7) Test all available namespaces"
    echo ""
    read -p "Enter your choice (1-7): " namespace_choice
    
    case $namespace_choice in
        1) test_namespace "eth" ;;
        2) test_namespace "net" ;;
        3) test_namespace "web3" ;;
        4) test_namespace "txpool" ;;
        5) test_namespace "admin" ;;
        6) test_namespace "debug" ;;
        7) 
            for ns in "${!test_methods[@]}"; do
                test_namespace "$ns"
            done
            ;;
        *) 
            echo "Invalid choice."
            read -p "Press Enter to continue..."
            return
            ;;
    esac
}

# Helper function to test a specific namespace
test_namespace() {
    local namespace=$1
    local data=${test_methods[$namespace]}
    
    echo ""
    echo "Testing $namespace namespace..."
    echo "Request: $data"
    echo "Response:"
    curl -s -X POST -H "Content-Type: application/json" --data "$data" http://localhost:8545
    echo ""
    echo ""
    read -p "Press Enter to continue..."
}

# Function to configure rate limiting
configure_rate_limiting() {
    clear
    echo "Configure Rate Limiting"
    echo "======================="
    echo ""
    
    echo "This feature allows you to set up rate limiting for API requests."
    echo "Note: Rate limiting requires additional setup with a reverse proxy like Nginx."
    echo ""
    
    read -p "Do you want to set up Nginx as a reverse proxy with rate limiting? (y/n): " setup_nginx
    
    if [[ "$setup_nginx" != "y" ]]; then
        echo "Operation cancelled."
        read -p "Press Enter to continue..."
        return
    fi
    
    # Check if Nginx is installed
    if ! command -v nginx &> /dev/null; then
        echo "Nginx is not installed. Installing..."
        sudo apt-get update && sudo apt-get install -y nginx
    fi
    
    # Create Nginx configuration for rate limiting
    echo "Creating Nginx configuration for rate limiting..."
    
    # Get rate limit from user
    read -p "Enter requests per minute limit (default: 600): " rpm
    rpm=${rpm:-600}
    
    # Create Nginx configuration file
    sudo bash -c "cat > /etc/nginx/sites-available/erigon-api << 'EOL'
limit_req_zone \$binary_remote_addr zone=api_limit:10m rate=${rpm}r/m;

server {
    listen 8547;
    
    location / {
        limit_req zone=api_limit burst=20 nodelay;
        
        proxy_pass http://localhost:8545;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOL"
    
    # Enable the site
    sudo ln -sf /etc/nginx/sites-available/erigon-api /etc/nginx/sites-enabled/
    
    # Test Nginx configuration
    echo "Testing Nginx configuration..."
    sudo nginx -t
    
    # Restart Nginx if test is successful
    if [ $? -eq 0 ]; then
        echo "Nginx configuration is valid. Restarting Nginx..."
        sudo systemctl restart nginx
        
        echo ""
        echo "Rate limiting has been set up successfully!"
        echo "The rate-limited API is now available at http://your-server-ip:8547"
        echo "The original API endpoint at port 8545 remains unchanged."
    else
        echo "Nginx configuration test failed. Please check the configuration manually."
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

# Function to monitor API usage
monitor_api_usage() {
    clear
    echo "Monitor API Usage"
    echo "================="
    echo ""
    
    echo "This feature allows you to monitor API usage and active connections."
    echo ""
    
    # Check if netstat is installed
    if ! command -v netstat &> /dev/null; then
        echo "netstat is not installed. Installing net-tools..."
        sudo apt-get update && sudo apt-get install -y net-tools
    fi
    
    echo "Current connections to API ports (8545/8546):"
    echo ""
    netstat -an | grep -E ':8545|:8546' | grep ESTABLISHED
    
    echo ""
    echo "Total number of connections:"
    netstat -an | grep -E ':8545|:8546' | grep ESTABLISHED | wc -l
    
    echo ""
    read -p "Press Enter to continue..."
}

# Main menu
while true; do
    clear
    echo "API Endpoint Management - v${VERSION}"
    echo "===================================="
    echo ""
    echo "1) Show Current API Configuration"
    echo "2) Modify API Methods"
    echo "3) Test API Endpoints"
    echo "4) Configure Rate Limiting"
    echo "5) Monitor API Usage"
    echo ""
    echo "0) Back to Main Menu"
    echo ""
    read -p "Enter your choice: " choice
    
    case $choice in
        1) show_api_config ;;
        2) modify_api_methods ;;
        3) test_api_endpoints ;;
        4) configure_rate_limiting ;;
        5) monitor_api_usage ;;
        0) exit 0 ;;
        *) echo "Invalid option. Please try again." ;;
    esac
done 