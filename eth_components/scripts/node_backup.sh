#!/bin/bash

# ===============================================================================
# Ethereum Node Backup Script
# ===============================================================================
# Version: 0.1.0
# Description: Handles backup and restore operations for Ethereum node data
# ===============================================================================

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config/eth_config.sh"

# Backup settings
BACKUP_RETENTION_DAYS=7
COMPRESSION_LEVEL=9
DATE_FORMAT="%Y%m%d_%H%M%S"

create_backup() {
    local backup_date=$(date +"${DATE_FORMAT}")
    local backup_file="${ETH_BACKUP_DIR}/eth_node_${backup_date}.tar.gz"
    
    echo "Creating backup of Ethereum node data..."
    
    # Ensure backup directory exists
    mkdir -p "${ETH_BACKUP_DIR}"
    
    # Stop services gracefully
    echo "Stopping Ethereum services..."
    docker-compose -f "${ETH_BASE_DIR}/docker-compose.yml" stop
    
    # Create backup
    tar -czf "${backup_file}" \
        --exclude="${ETH_EXECUTION_DIR}/geth/chaindata" \
        --exclude="${ETH_EXECUTION_DIR}/erigon/chaindata" \
        -C "${ETH_BASE_DIR}" .
    
    # Restart services
    echo "Restarting Ethereum services..."
    docker-compose -f "${ETH_BASE_DIR}/docker-compose.yml" start
    
    # Cleanup old backups
    find "${ETH_BACKUP_DIR}" -name "eth_node_*.tar.gz" -mtime +${BACKUP_RETENTION_DAYS} -delete
    
    echo "Backup completed: ${backup_file}"
    echo "Size: $(du -h "${backup_file}" | cut -f1)"
}

restore_backup() {
    local backup_file=$1
    
    if [[ ! -f "${backup_file}" ]]; then
        echo "Error: Backup file not found: ${backup_file}"
        return 1
    fi
    
    echo "Restoring from backup: ${backup_file}"
    
    # Stop services
    echo "Stopping Ethereum services..."
    docker-compose -f "${ETH_BASE_DIR}/docker-compose.yml" down
    
    # Create temporary restore directory
    local temp_dir=$(mktemp -d)
    
    # Extract backup
    tar -xzf "${backup_file}" -C "${temp_dir}"
    
    # Verify backup contents
    if [[ ! -d "${temp_dir}/execution" ]] || [[ ! -d "${temp_dir}/consensus" ]]; then
        echo "Error: Invalid backup file structure"
        rm -rf "${temp_dir}"
        return 1
    fi
    
    # Restore files
    rsync -av --delete \
        --exclude="geth/chaindata" \
        --exclude="erigon/chaindata" \
        "${temp_dir}/" "${ETH_BASE_DIR}/"
    
    # Cleanup
    rm -rf "${temp_dir}"
    
    # Start services
    echo "Starting Ethereum services..."
    docker-compose -f "${ETH_BASE_DIR}/docker-compose.yml" up -d
    
    echo "Restore completed successfully"
}

list_backups() {
    echo "Available backups:"
    echo "================="
    
    if [[ ! -d "${ETH_BACKUP_DIR}" ]]; then
        echo "No backups found"
        return
    fi
    
    find "${ETH_BACKUP_DIR}" -name "eth_node_*.tar.gz" -type f | while read backup; do
        local size=$(du -h "${backup}" | cut -f1)
        local date=$(stat -c %y "${backup}")
        echo "$(basename "${backup}") (${size}) - ${date}"
    done
}

case "$1" in
    create)
        create_backup
        ;;
    restore)
        if [[ -z "$2" ]]; then
            echo "Usage: $0 restore <backup_file>"
            exit 1
        fi
        restore_backup "$2"
        ;;
    list)
        list_backups
        ;;
    *)
        echo "Usage: $0 {create|restore <backup_file>|list}"
        exit 1
        ;;
esac 