#!/bin/bash

# Test Path Verification Script
# This script tests all critical paths in the menu system

# Color definitions
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Initialize counters
TESTS_PASSED=0
TESTS_FAILED=0

# Helper function for logging
log_test() {
    local test_name="$1"
    local status="$2"
    if [ "$status" -eq 0 ]; then
        echo -e "${GREEN}✓ $test_name passed${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ $test_name failed${NC}"
        ((TESTS_FAILED++))
    fi
}

# Test 1: Basic System Access
test_system_access() {
    echo "Testing system access..."
    
    # Check if required directories exist
    [ -d "/blockchain" ] && \
    [ -d "/blockchain/helper" ] && \
    [ -f "/blockchain/config.sh" ]
    log_test "System Access" $?
}

# Test 2: Service Status
test_services() {
    echo "Testing service status..."
    
    # Check Docker service
    systemctl is-active --quiet docker && \
    docker ps >/dev/null 2>&1
    log_test "Docker Service" $?
    
    # Check client containers
    docker ps | grep -q "execution-client" && \
    docker ps | grep -q "consensus-client"
    log_test "Client Containers" $?
}

# Test 3: Menu Access
test_menu_access() {
    echo "Testing menu access..."
    
    # Check if menu script exists and is executable
    [ -x "/usr/local/bin/plsmenu" ] || [ -x "/blockchain/menu.sh" ]
    log_test "Menu Script" $?
}

# Test 4: Log Access
test_log_access() {
    echo "Testing log access..."
    
    # Check if log directories are accessible
    [ -d "/blockchain/logs" ] && \
    [ -r "/blockchain/logs" ]
    log_test "Log Directory" $?
}

# Test 5: Configuration
test_configuration() {
    echo "Testing configuration..."
    
    # Check configuration files
    [ -f "/blockchain/config.sh" ] && \
    [ -f "/blockchain/node_config.json" ]
    log_test "Configuration Files" $?
}

# Test 6: Network Connectivity
test_network() {
    echo "Testing network connectivity..."
    
    # Test basic network connectivity
    ping -c 1 8.8.8.8 >/dev/null 2>&1
    log_test "Internet Connectivity" $?
    
    # Test client ports
    nc -z localhost 8545 >/dev/null 2>&1
    log_test "Execution Client Port" $?
    
    nc -z localhost 9000 >/dev/null 2>&1
    log_test "Consensus Client Port" $?
}

# Test 7: Helper Scripts
test_helper_scripts() {
    echo "Testing helper scripts..."
    
    # Check if critical helper scripts exist and are executable
    [ -x "/blockchain/helper/health_check.sh" ] && \
    [ -x "/blockchain/helper/log_viewer.sh" ] && \
    [ -x "/blockchain/helper/sync_recovery.sh" ]
    log_test "Helper Scripts" $?
}

# Run all tests
main() {
    echo "Starting path verification tests..."
    echo "-----------------------------------"
    
    test_system_access
    test_services
    test_menu_access
    test_log_access
    test_configuration
    test_network
    test_helper_scripts
    
    echo "-----------------------------------"
    echo "Test Summary:"
    echo "Passed: $TESTS_PASSED"
    echo "Failed: $TESTS_FAILED"
    echo "Total: $((TESTS_PASSED + TESTS_FAILED))"
    
    # Return overall status
    [ "$TESTS_FAILED" -eq 0 ]
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi 