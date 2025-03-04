#!/bin/bash

# Enhanced Backup Script for PulseChain Node
# This script implements comprehensive backup functionality with encryption and verification

# Source the main configuration
source /blockchain/config.sh

# Initialize backup logging
BACKUP_LOG="${LOG_PATH}/backup.log"
mkdir -p "$(dirname "$BACKUP_LOG")"

# Logging function
log_backup() {
    local level="$1"
    local message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$BACKUP_LOG"
    
    # If error, send alert
    if [ "$level" = "ERROR" ]; then
        send_alert "Backup error: $message"
    fi
}

# Alert function
send_alert() {
    local message="$1"
    
    # Log the alert
    echo "[ALERT] $message" >> "$BACKUP_LOG"
    
    # If webhook URL is configured, send alert
    if [ -n "$ALERT_WEBHOOK_URL" ]; then
        curl -X POST -H "Content-Type: application/json" \
             -d "{\"message\": \"$message\"}" \
             "$ALERT_WEBHOOK_URL"
    fi
}

# Check available space
check_backup_space() {
    local required_space="$1"
    local available_space=$(df -BG "$BACKUP_LOCATION" | awk 'NR==2 {print $4}' | sed 's/G//')
    
    if [ "$available_space" -lt "$required_space" ]; then
        log_backup "ERROR" "Insufficient space for backup. Required: ${required_space}GB, Available: ${available_space}GB"
        return 1
    fi
    return 0
}

# Clean old backups
clean_old_backups() {
    local backup_path="$1"
    
    # Find and delete backups older than retention period
    find "$backup_path" -type f -name "*.tar.gz.enc" -mtime +"$BACKUP_RETENTION_DAYS" -delete
    
    # Keep only the specified number of most recent backups
    local backup_count=$(ls -1 "$backup_path"/*.tar.gz.enc 2>/dev/null | wc -l)
    if [ "$backup_count" -gt "$KEEP_BACKUPS" ]; then
        ls -1t "$backup_path"/*.tar.gz.enc | tail -n +$((KEEP_BACKUPS + 1)) | xargs rm -f
    fi
}

# Encrypt backup
encrypt_backup() {
    local input_file="$1"
    local output_file="$2"
    local password_file="${CUSTOM_PATH}/.secrets/backup_key"
    
    # Generate encryption key if it doesn't exist
    if [ ! -f "$password_file" ]; then
        mkdir -p "$(dirname "$password_file")"
        openssl rand -base64 32 > "$password_file"
        chmod 600 "$password_file"
    fi
    
    # Encrypt the backup
    openssl enc -aes-256-cbc -salt -pbkdf2 \
            -in "$input_file" \
            -out "$output_file" \
            -pass file:"$password_file"
    
    if [ $? -ne 0 ]; then
        log_backup "ERROR" "Encryption failed for $input_file"
        return 1
    fi
    return 0
}

# Verify backup integrity
verify_backup() {
    local backup_file="$1"
    local password_file="${CUSTOM_PATH}/.secrets/backup_key"
    local temp_dir=$(mktemp -d)
    
    # Try to decrypt a small portion of the backup
    if ! openssl enc -aes-256-cbc -d -salt -pbkdf2 \
            -in "$backup_file" \
            -pass file:"$password_file" \
            | tar tz > /dev/null 2>&1; then
        log_backup "ERROR" "Backup verification failed for $backup_file"
        rm -rf "$temp_dir"
        return 1
    fi
    
    rm -rf "$temp_dir"
    return 0
}

# Perform backup
perform_backup() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_name="pulse_node_backup_${timestamp}"
    local temp_dir=$(mktemp -d)
    local temp_backup="${temp_dir}/${backup_name}.tar.gz"
    local final_backup="${BACKUP_LOCATION}/${backup_name}.tar.gz.enc"
    
    # Ensure backup directory exists
    mkdir -p "$BACKUP_LOCATION"
    
    # Check available space (estimate 110% of current data size)
    local data_size=$(du -s --block-size=1G "${CUSTOM_PATH}" | cut -f1)
    local required_space=$((data_size * 11 / 10))
    
    if ! check_backup_space "$required_space"; then
        rm -rf "$temp_dir"
        return 1
    fi
    
    log_backup "INFO" "Starting backup: $backup_name"
    
    # Stop services if full backup
    if [ "$BACKUP_TYPE" = "full" ]; then
        log_backup "INFO" "Stopping services for full backup"
        docker-compose stop
    fi
    
    # Create backup archive
    tar -czf "$temp_backup" \
        --exclude="*.log" \
        --exclude="*.tmp" \
        --exclude="*.pid" \
        "${CUSTOM_PATH}/chaindata" \
        "${CUSTOM_PATH}/beacondata" \
        "${CUSTOM_PATH}/config" \
        "${CUSTOM_PATH}/.secrets"
    
    # Restart services if they were stopped
    if [ "$BACKUP_TYPE" = "full" ]; then
        log_backup "INFO" "Restarting services"
        docker-compose up -d
    fi
    
    # Encrypt backup
    if ! encrypt_backup "$temp_backup" "$final_backup"; then
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Verify backup
    if [ "$BACKUP_VERIFICATION" = "true" ]; then
        if ! verify_backup "$final_backup"; then
            rm -f "$final_backup"
            rm -rf "$temp_dir"
            return 1
        fi
    fi
    
    # Clean up old backups
    clean_old_backups "$BACKUP_LOCATION"
    
    # Clean up temporary files
    rm -rf "$temp_dir"
    
    # Upload to remote if configured
    if [ "$BACKUP_REMOTE_ENABLED" = "true" ] && [ -n "$BACKUP_REMOTE_URL" ]; then
        log_backup "INFO" "Uploading backup to remote location"
        
        if ! curl -X PUT -H "Authorization: Bearer ${BACKUP_REMOTE_KEY}" \
                  --upload-file "$final_backup" \
                  "${BACKUP_REMOTE_URL}/${backup_name}.tar.gz.enc"; then
            log_backup "ERROR" "Remote backup upload failed"
            return 1
        fi
    fi
    
    log_backup "INFO" "Backup completed successfully: $backup_name"
    return 0
}

# Main backup function
main() {
    # Check if backup is enabled
    if [ "$BACKUP_ENABLED" != "true" ]; then
        log_backup "INFO" "Backup is disabled in configuration"
        exit 0
    fi
    
    # Perform backup
    if ! perform_backup; then
        log_backup "ERROR" "Backup failed"
        exit 1
    fi
    
    exit 0
}

# Start the backup process
main 