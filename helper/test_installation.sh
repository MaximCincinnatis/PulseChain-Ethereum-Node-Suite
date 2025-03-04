#!/bin/bash

# Installation Test Script
# This script tests the installation process and its components

# Color definitions
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
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

# Test Dependencies
test_dependencies() {
    echo -e "\n${YELLOW}Testing Dependencies...${NC}"
    
    # Test Docker
    which docker >/dev/null 2>&1
    log_test "Docker Installation" $?
    
    # Test Docker Compose
    which docker-compose >/dev/null 2>&1
    log_test "Docker Compose Installation" $?
    
    # Test Python
    which python3 >/dev/null 2>&1
    log_test "Python Installation" $?
    
    # Test OpenSSL
    which openssl >/dev/null 2>&1
    log_test "OpenSSL Installation" $?
}

# Test Directory Structure
test_directory_structure() {
    echo -e "\n${YELLOW}Testing Directory Structure...${NC}"
    
    # Test main directories
    [ -d "/blockchain" ]
    log_test "Main Directory" $?
    
    [ -d "/blockchain/helper" ]
    log_test "Helper Directory" $?
    
    [ -d "/blockchain/config" ]
    log_test "Config Directory" $?
    
    [ -d "/blockchain/logs" ]
    log_test "Logs Directory" $?
}

# Test User Setup
test_user_setup() {
    echo -e "\n${YELLOW}Testing User Setup...${NC}"
    
    # Test Docker group
    getent group docker >/dev/null
    log_test "Docker Group" $?
    
    # Test user in Docker group
    id -nG "$USER" | grep -qw "docker"
    log_test "User Docker Group" $?
}

# Test Network Configuration
test_network_config() {
    echo -e "\n${YELLOW}Testing Network Configuration...${NC}"
    
    # Test network selection
    [ -f "/blockchain/network.txt" ]
    log_test "Network Selection" $?
    
    # Test network configuration
    [ -f "/blockchain/config.sh" ] && grep -q "NETWORK=" "/blockchain/config.sh"
    log_test "Network Config" $?
}

# Test Client Setup
test_client_setup() {
    echo -e "\n${YELLOW}Testing Client Setup...${NC}"
    
    # Test execution client
    [ -d "/blockchain/execution" ]
    log_test "Execution Client Directory" $?
    
    # Test consensus client
    [ -d "/blockchain/consensus" ]
    log_test "Consensus Client Directory" $?
    
    # Test JWT file
    [ -f "/blockchain/jwt.hex" ]
    log_test "JWT Authentication" $?
}

# Test Docker Configuration
test_docker_config() {
    echo -e "\n${YELLOW}Testing Docker Configuration...${NC}"
    
    # Test docker-compose file
    [ -f "/blockchain/docker-compose.yml" ]
    log_test "Docker Compose File" $?
    
    # Test container definitions
    grep -q "execution-client:" "/blockchain/docker-compose.yml" 2>/dev/null
    log_test "Execution Client Container" $?
    
    grep -q "consensus-client:" "/blockchain/docker-compose.yml" 2>/dev/null
    log_test "Consensus Client Container" $?
}

# Test Script Permissions
test_permissions() {
    echo -e "\n${YELLOW}Testing Script Permissions...${NC}"
    
    # Test helper scripts
    [ -x "/blockchain/helper/health_check.sh" ]
    log_test "Health Check Permissions" $?
    
    [ -x "/blockchain/helper/log_viewer.sh" ]
    log_test "Log Viewer Permissions" $?
    
    # Test main scripts
    [ -x "/blockchain/menu.sh" ]
    log_test "Menu Script Permissions" $?
}

# Test Configuration Files
test_config_files() {
    echo -e "\n${YELLOW}Testing Configuration Files...${NC}"
    
    # Test main config
    [ -f "/blockchain/config.sh" ]
    log_test "Main Config" $?
    
    # Test client configs
    [ -f "/blockchain/config/execution_config.toml" ]
    log_test "Execution Config" $?
    
    [ -f "/blockchain/config/consensus_config.yaml" ]
    log_test "Consensus Config" $?
}

# Run all tests
main() {
    echo "Starting installation tests..."
    echo "-----------------------------------"
    
    test_dependencies
    test_directory_structure
    test_user_setup
    test_network_config
    test_client_setup
    test_docker_config
    test_permissions
    test_config_files
    
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