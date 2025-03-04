# Script Interaction Map

## Table of Contents
1. [Core Configuration Structure](#core-configuration-structure)
2. [Service Management](#service-management)
3. [Script Launch Patterns](#script-launch-patterns)
4. [User Interface Structure](#user-interface-structure)
5. [Core Functions Structure](#core-functions-structure)
6. [Script Launch Methods](#script-launch-methods)
7. [Error Handling & Logging](#error-handling--logging)
8. [Security Framework](#security-framework)
9. [Noted Inconsistencies](#noted-inconsistencies)
10. [Critical Dependencies](#critical-dependencies)
11. [Recommended Standardization](#recommended-standardization)
12. [Testing & Validation](#testing--validation)
13. [Version Control](#version-control)
14. [Document Maintenance](#document-maintenance)

## Core Configuration Structure

### Primary Configuration Sources
- `/blockchain/config.sh`: Main configuration file
- `/blockchain/functions.sh`: Core functions and utilities
- `/blockchain/eth_components/config/eth_config.sh`: Ethereum-specific configurations

## Service Management

### 1. System Services
```
systemd Services
├── docker.service (Main Docker daemon)
├── eth-execution.service (Execution client)
├── eth-consensus.service (Consensus client)
├── eth-monitoring.service (Monitoring stack)
├── vboxclient-clipboard.service (VirtualBox integration)
└── graceful_stop.service (Graceful shutdown)
```

### 2. Docker Compose Services
```
docker-compose.yml
├── execution-client
├── consensus-client
├── prometheus
└── grafana
```

## Script Launch Patterns

### 1. Configuration Loading Pattern
```bash
# Pattern 1: Direct source from known path
source /blockchain/config.sh

# Pattern 2: Relative path source using dirname
source "$(dirname "$0")/config.sh"

# Pattern 3: Parent directory source
source "$(dirname "$(dirname "$0")")/config.sh"
```

### 2. Script Execution Hierarchy

#### Entry Points
1. `plsmenu` (symlinked to `/usr/local/bin/plsmenu` from `menu.sh`)
2. `setup_pulse_node.sh` (main setup script)
3. `setup_eth_node.sh` (Ethereum setup script)
4. `start-with-docker-compose.sh` (Docker setup)

#### Menu System Structure
```
menu.sh (plsmenu)
├── logviewer_submenu
│   └── Various log viewing scripts
├── client_actions_submenu
│   ├── smart_restart.sh
│   ├── start_execution.sh
│   └── start_consensus.sh
├── health_submenu
│   ├── health_check.sh
│   └── sync_recovery.sh
├── node_info_submenu
│   ├── node_status.sh
│   └── mempool_info.sh
└── system_submenu
    ├── update_docker.sh
    └── network_config.sh
```

### 3. Update System
```
update_docker.sh
├── updates/update_manager.sh
└── updates/check_updates.sh
```

## User Interface Structure

### Complete Menu Tree
```
plsmenu (Main Menu)
├── Logviewer
│   ├── Execution Client Logs
│   │   ├── Live View (--tail)
│   │   ├── Error Only
│   │   └── Search Logs
│   ├── Consensus Client Logs
│   │   ├── Live View (--tail)
│   │   ├── Error Only
│   │   └── Search Logs
│   ├── Health Logs
│   │   ├── View Recent
│   │   └── View History
│   ├── System Logs
│   │   ├── Journalctl Output
│   │   └── Docker Events
│   └── Docker Events
│       ├── Recent Events
│       └── Live Monitor
├── Clients Menu
│   ├── Restart Options
│   │   ├── Restart Execution
│   │   ├── Restart Consensus
│   │   └── Restart All
│   ├── View Status
│   │   ├── Execution Status
│   │   ├── Consensus Status
│   │   └── Overall Health
│   ├── Client Management
│   │   ├── Start Clients
│   │   ├── Stop Clients
│   │   └── Update Clients
│   └── Configuration
│       ├── Network Selection
│       ├── Port Configuration
│       └── Client Settings
├── Health
│   ├── Quick Health Check
│   │   ├── Service Status
│   │   ├── Sync Status
│   │   └── Network Status
│   ├── Detailed Diagnostics
│   │   ├── Performance Metrics
│   │   ├── Resource Usage
│   │   └── Network Metrics
│   ├── Sync Management
│   │   ├── Check Sync Status
│   │   ├── Force Resync
│   │   └── Repair Database
│   └── Monitoring
│       ├── Grafana Dashboard
│       ├── Prometheus Metrics
│       └── Alert Configuration
├── Info and Management
│   ├── Node Information
│   │   ├── Version Info
│   │   ├── Network Status
│   │   └── Peer Count
│   ├── Performance Stats
│   │   ├── System Resources
│   │   ├── Client Performance
│   │   └── Network Usage
│   ├── Blockchain Info
│   │   ├── Latest Block
│   │   ├── Sync Progress
│   │   └── Chain Stats
│   └── Configuration Info
│       ├── Current Settings
│       ├── Network Config
│       └── Client Config
└── System
    ├── Updates
    │   ├── Check Updates
    │   ├── Update Scripts
    │   └── Update Clients
    ├── Backup/Restore
    │   ├── Create Backup
    │   ├── Restore Backup
    │   └── Manage Backups
    ├── Security
    │   ├── Key Management
    │   ├── Permission Check
    │   └── Security Audit
    └── Maintenance
        ├── Cleanup Old Data
        ├── Reset Configs
        └── System Optimization
```

### Common User Operations
1. **Daily Operations**
   - View client status
   - Check sync status
   - Monitor logs
   - View health metrics

2. **Periodic Maintenance**
   - Update clients
   - Backup data
   - Check performance
   - Review logs

3. **Troubleshooting**
   - View error logs
   - Check diagnostics
   - Restart services
   - Repair sync

4. **Configuration**
   - Change network
   - Adjust settings
   - Manage security
   - Update configurations

## Core Functions Structure

### 1. System Management Functions
```
functions.sh
├── verify_docker_services()
├── verify_node_containers()
├── test_network_connectivity()
├── test_client_ports()
├── test_execution_rpc()
└── test_consensus_api()
```

### 2. Setup Functions
```
functions.sh
├── set_install_path()
├── get_install_path()
├── create_user()
├── add_user_to_docker_group()
└── set_directory_permissions()
```

### 3. Validator Functions
```
functions.sh
├── import_lighthouse_validator()
├── import_prysm_validator()
├── exit_validator_LH()
└── exit_validator_PR()
```

## Script Launch Methods

1. Direct Execution: `./script_name.sh`
2. Sourced Execution: `source script_name.sh`
3. Background Service: Used in docker-compose.yml
4. Menu-Driven: Through plsmenu interface
5. Systemd Service: Through systemctl commands

## Error Handling & Logging

### 1. Error Handling Patterns
```
Error Management
├── setup_error_handling() - Global error handler setup
├── handle_script_error() - Script-specific error handling
├── display_error_stack_trace() - Debug information
└── display_error_message() - User-friendly errors
```

### 2. Logging System
```
Logging Structure
├── /blockchain/logs/ (Main log directory)
│   ├── execution.log
│   ├── consensus.log
│   ├── health_check.log
│   └── update.log
├── Log Levels: INFO, WARNING, ERROR, DEBUG
└── Log Rotation: Daily with 7-day retention
```

### 3. Recovery Procedures
- Automatic recovery attempts for Docker services
- Network connectivity recovery
- Database corruption recovery
- Sync recovery procedures

## Security Framework

### 1. Permission Model
```
Security Layers
├── Root/Sudo Requirements
│   ├── Docker operations
│   ├── Service management
│   └── Network configuration
├── User Permissions
│   ├── Log access
│   ├── Configuration reads
│   └── Status checks
└── File Permissions
    ├── Configurations (600)
    ├── Scripts (755)
    └── Logs (644)
```

### 2. Network Security
- Port exposure management
- RPC endpoint security
- API access controls
- Rate limiting

### 3. Key Management
- Validator key handling
- JWT secret management
- API key storage
- Backup encryption

## Version Control

### 1. Version Tracking
```
Version Management
├── Script versions
│   ├── menu.sh: v0.1.0
│   └── setup_pulse_node.sh: v1.0.0
├── Configuration versions
└── Docker image versions
```

### 2. Update Management
- Version compatibility checks
- Dependency version mapping
- Update sequence management
- Rollback procedures

## Testing & Validation

### 1. Test Categories
1. Functionality Tests
   - Menu navigation
   - Script execution
   - Service management
   - Network switching

2. Security Tests
   - Permission validation
   - Network security
   - Key management
   - Access controls

3. Integration Tests
   - Service interactions
   - Network communication
   - Client synchronization
   - Update procedures

### 2. Validation Procedures
1. Pre-deployment Checks
2. Post-update Validation
3. Security Audits
4. Performance Monitoring

## Noted Inconsistencies

1. **Path References**
   - Some scripts use `/blockchain/` absolute path
   - Others use relative paths with `$(dirname "$0")`
   - Inconsistent use of `$CUSTOM_PATH` vs hardcoded paths
   - Docker Compose file paths vary between relative and absolute

2. **Configuration Loading**
   - Multiple patterns for sourcing config.sh
   - Inconsistent error handling when config is missing
   - Some scripts load eth_config.sh directly, others through inheritance

3. **Script Permissions**
   - Some scripts require explicit sudo
   - Others assume root privileges
   - Docker commands sometimes run with sudo, sometimes without

4. **Network Selection**
   - Inconsistent handling of `$SELECTED_NETWORK`
   - Mixed usage between environment variables and config file
   - Network-specific configurations spread across multiple locations

5. **Update Mechanisms**
   - Multiple update paths (menu system vs direct script execution)
   - Inconsistent version checking methods
   - Docker image updates handled differently in different scripts

6. **Service Management**
   - Mixed use of systemd and Docker Compose
   - Inconsistent service naming conventions
   - Variable approaches to service dependencies

## Critical Dependencies

1. Core Configuration Files:
   - `/blockchain/config.sh`
   - `/blockchain/functions.sh`
   - `/blockchain/eth_components/config/eth_config.sh`

2. Essential Scripts:
   - `menu.sh` (plsmenu)
   - `setup_pulse_node.sh`
   - `update_docker.sh`
   - `network_config.sh`
   - `docker-compose.yml`

3. System Services:
   - Docker daemon
   - Execution client service
   - Consensus client service
   - Monitoring services

## Recommended Standardization

1. **Path References**
   - Standardize on `$CUSTOM_PATH` for root directory
   - Use relative paths with `$(dirname "$0")` for script-local references
   - Consistent Docker Compose file paths

2. **Configuration Loading**
   - Implement consistent config loading pattern
   - Standardize error handling for missing configs
   - Unified approach to network-specific configurations

3. **Script Permissions**
   - Implement consistent privilege escalation
   - Document required permissions
   - Standardize Docker command execution

4. **Network Selection**
   - Standardize network selection handling
   - Implement consistent environment variable usage
   - Centralize network-specific configurations

5. **Service Management**
   - Standardize service management approach
   - Consistent naming conventions
   - Clear dependency documentation

## Document Maintenance

### 1. Update Procedures
- Document version tracking
- Change log maintenance
- Dependency updates
- Security patch documentation

### 2. Review Schedule
- Monthly security review
- Quarterly feature review
- Bi-annual architecture review
- Annual complete audit 