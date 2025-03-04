#!/bin/bash

# Menu System Test Script
# This script tests all menu options and their functionality

# Color definitions
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Initialize counters
TESTS_PASSED=0
TESTS_FAILED=0

# Source configuration
source /blockchain/config.sh 2>/dev/null || {
    echo "Error: Cannot source config.sh"
    exit 1
}

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

# Test Logviewer Menu
test_logviewer_menu() {
    echo -e "\n${YELLOW}Testing Logviewer Menu...${NC}"
    
    # Test execution client logs
    [ -f "/blockchain/logs/execution.log" ]
    log_test "Execution Logs Accessible" $?
    
    # Test consensus client logs
    [ -f "/blockchain/logs/consensus.log" ]
    log_test "Consensus Logs Accessible" $?
    
    # Test health logs
    [ -f "/blockchain/logs/health_check.log" ]
    log_test "Health Logs Accessible" $?
}

# Test Client Management Menu
test_client_menu() {
    echo -e "\n${YELLOW}Testing Client Management Menu...${NC}"
    
    # Test client status
    docker ps | grep -q "execution-client"
    log_test "Execution Client Status" $?
    
    docker ps | grep -q "consensus-client"
    log_test "Consensus Client Status" $?
    
    # Test client configuration
    [ -f "/blockchain/config/${NETWORK}_${EXECUTION_CLIENT}.toml" ]
    log_test "Client Configuration" $?
}

# Test Health Menu
test_health_menu() {
    echo -e "\n${YELLOW}Testing Health Menu...${NC}"
    
    # Test health check script
    [ -x "/blockchain/helper/health_check.sh" ]
    log_test "Health Check Script" $?
    
    # Test sync status script
    [ -x "/blockchain/helper/check_sync.sh" ]
    log_test "Sync Check Script" $?
    
    # Test monitoring
    docker ps | grep -q "prometheus"
    log_test "Monitoring Stack" $?
}

# Test System Menu
test_system_menu() {
    echo -e "\n${YELLOW}Testing System Menu...${NC}"
    
    # Test update script
    [ -x "/blockchain/helper/update_docker.sh" ]
    log_test "Update Script" $?
    
    # Test backup script
    [ -x "/blockchain/helper/backup_restore.sh" ]
    log_test "Backup Script" $?
    
    # Test network config
    [ -x "/blockchain/helper/network_config.sh" ]
    log_test "Network Config Script" $?
}

# Test Network Selection
test_network_selection() {
    echo -e "\n${YELLOW}Testing Network Selection...${NC}"
    
    # Test network indicator file
    [ -f "/blockchain/network.txt" ]
    log_test "Network Indicator File" $?
    
    # Test network configuration
    grep -q "NETWORK=" "/blockchain/config.sh"
    log_test "Network Configuration" $?
}

# Test Menu Navigation
test_menu_navigation() {
    echo -e "\n${YELLOW}Testing Menu Navigation...${NC}"
    
    # Test main menu script
    [ -x "/usr/local/bin/plsmenu" ] || [ -x "/blockchain/menu.sh" ]
    log_test "Main Menu Script" $?
    
    # Test menu functions
    grep -q "show_main_menu" "/blockchain/menu.sh" 2>/dev/null
    log_test "Menu Functions" $?
}

# Run all tests
main() {
    echo "Starting menu system tests..."
    echo "-----------------------------------"
    
    test_menu_navigation
    test_network_selection
    test_logviewer_menu
    test_client_menu
    test_health_menu
    test_system_menu
    
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