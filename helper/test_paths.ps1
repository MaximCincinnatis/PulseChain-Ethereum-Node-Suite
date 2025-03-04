# Test Path Verification Script
# This script tests all critical paths in the menu system

# Initialize counters
$TESTS_PASSED = 0
$TESTS_FAILED = 0

# Helper function for logging
function Log-Test {
    param(
        [string]$TestName,
        [bool]$Status
    )
    
    if ($Status) {
        Write-Host "✓ $TestName passed" -ForegroundColor Green
        $script:TESTS_PASSED++
    } else {
        Write-Host "✗ $TestName failed" -ForegroundColor Red
        $script:TESTS_FAILED++
    }
}

# Test 1: Basic System Access
function Test-SystemAccess {
    Write-Host "`nTesting system access..."
    
    # Check if required directories exist
    $status = (Test-Path "C:\blockchain" -PathType Container) -and 
              (Test-Path "C:\blockchain\helper" -PathType Container) -and 
              (Test-Path "C:\blockchain\config.sh" -PathType Leaf)
    
    Log-Test "System Access" $status
}

# Test 2: Service Status
function Test-Services {
    Write-Host "`nTesting service status..."
    
    # Check Docker service
    $dockerService = Get-Service "docker" -ErrorAction SilentlyContinue
    $dockerStatus = $dockerService -and ($dockerService.Status -eq "Running")
    Log-Test "Docker Service" $dockerStatus
    
    # Check client containers
    $containers = docker ps 2>$null
    $clientStatus = ($containers -match "execution-client") -and ($containers -match "consensus-client")
    Log-Test "Client Containers" $clientStatus
}

# Test 3: Menu Access
function Test-MenuAccess {
    Write-Host "`nTesting menu access..."
    
    # Check if menu script exists
    $status = Test-Path "C:\blockchain\menu.sh" -PathType Leaf
    Log-Test "Menu Script" $status
}

# Test 4: Log Access
function Test-LogAccess {
    Write-Host "`nTesting log access..."
    
    # Check if log directories are accessible
    $status = Test-Path "C:\blockchain\logs" -PathType Container
    Log-Test "Log Directory" $status
}

# Test 5: Configuration
function Test-Configuration {
    Write-Host "`nTesting configuration..."
    
    # Check configuration files
    $status = (Test-Path "C:\blockchain\config.sh" -PathType Leaf) -and 
              (Test-Path "C:\blockchain\node_config.json" -PathType Leaf)
    Log-Test "Configuration Files" $status
}

# Test 6: Network Connectivity
function Test-Network {
    Write-Host "`nTesting network connectivity..."
    
    # Test basic network connectivity
    $pingStatus = Test-Connection 8.8.8.8 -Count 1 -Quiet
    Log-Test "Internet Connectivity" $pingStatus
    
    # Test client ports
    $executionPort = Test-NetConnection -ComputerName localhost -Port 8545 -WarningAction SilentlyContinue
    Log-Test "Execution Client Port" $executionPort.TcpTestSucceeded
    
    $consensusPort = Test-NetConnection -ComputerName localhost -Port 9000 -WarningAction SilentlyContinue
    Log-Test "Consensus Client Port" $consensusPort.TcpTestSucceeded
}

# Test 7: Helper Scripts
function Test-HelperScripts {
    Write-Host "`nTesting helper scripts..."
    
    # Check if critical helper scripts exist
    $status = (Test-Path "C:\blockchain\helper\health_check.sh" -PathType Leaf) -and 
              (Test-Path "C:\blockchain\helper\log_viewer.sh" -PathType Leaf) -and 
              (Test-Path "C:\blockchain\helper\sync_recovery.sh" -PathType Leaf)
    Log-Test "Helper Scripts" $status
}

# Run all tests
function Main {
    Write-Host "`nStarting path verification tests..."
    Write-Host "-----------------------------------"
    
    Test-SystemAccess
    Test-Services
    Test-MenuAccess
    Test-LogAccess
    Test-Configuration
    Test-Network
    Test-HelperScripts
    
    Write-Host "`n-----------------------------------"
    Write-Host "Test Summary:"
    Write-Host "Passed: $TESTS_PASSED"
    Write-Host "Failed: $TESTS_FAILED"
    Write-Host "Total: $($TESTS_PASSED + $TESTS_FAILED)"
    
    # Return overall status
    return $TESTS_FAILED -eq 0
}

# Run main if script is executed directly
if ($MyInvocation.InvocationName -eq $PSCommandPath) {
    Main
} 