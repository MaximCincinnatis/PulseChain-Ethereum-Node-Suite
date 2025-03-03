# Helper Scripts Directory

This directory contains utility scripts for managing and maintaining your PulseChain or Ethereum node.

## Script Categories

### Node Management
- `menu.sh` - Main menu interface for node management
- `network_config.sh` - Network configuration manager for both PulseChain and Ethereum
- `verify_node.sh` - Node verification and health check
- `show_version.sh` - Display client versions

### Monitoring & Health
- `health_check.sh` - Node health monitoring
- `check_sync.sh` - Sync status checker
- `check_rpc_connection.sh` - RPC connection tester
- `status_batch.sh` - Batch status checker

### Log Management
- `log_viewer.sh` - GUI log viewer
- `tmux_logviewer.sh` - Terminal-based log viewer

### Maintenance
- `sync_recovery.sh` - Sync recovery tools
- `backup_restore.sh` - Backup and restore utilities
- `update_docker.sh` - Docker container updater
- `update_files.sh` - File updater
- `update_other.sh` - Miscellaneous updates

### Docker Management
- `restart_docker.sh` - Docker container restart
- `stop_docker.sh` - Docker container stop
- `grace.sh` - Graceful shutdown handler

### API & Remote Access
- `api_management.sh` - API management tools
- `remote_access.sh` - Remote access configuration
- `indexing_support.sh` - Indexing management

### Documentation
- `raw_Commands_WIP.md` - Work in progress commands and documentation

## Usage

Most scripts can be run directly from the command line:
```bash
./script_name.sh
```

For the main interface, use:
```bash
./menu.sh
```

## Network Support

All scripts are designed to work with both PulseChain and Ethereum networks. The active network can be selected through the main menu interface or by setting the `SELECTED_NETWORK` environment variable:

```bash
SELECTED_NETWORK=ethereum ./script_name.sh
```

## Contributing

When adding new scripts to this directory:
1. Follow the existing naming convention
2. Add appropriate network support (PulseChain/Ethereum)
3. Update this documentation
4. Include proper error handling and logging
