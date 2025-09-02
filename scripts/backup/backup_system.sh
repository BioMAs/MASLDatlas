#!/bin/bash

# 💾 MASLDatlas Backup and Recovery Script
# Automated backup of configuration and critical files
# Author: MASLDatlas Team
# Version: 1.0

set -euo pipefail

# Configuration
BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"
RETENTION_DAYS=30
LOG_FILE="logs/backup_$(date +%Y%m%d).log"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Create necessary directories
mkdir -p logs
mkdir -p backups

# Logging function
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local color=""
    
    case $level in
        "INFO") color=$GREEN ;;
        "WARN") color=$YELLOW ;;
        "ERROR") color=$RED ;;
        *) color=$NC ;;
    esac
    
    echo -e "${color}[$level]${NC} $message"
    echo "$timestamp [$level] $message" >> "$LOG_FILE"
}

# Create backup directory
create_backup_dir() {
    log "INFO" "📁 Creating backup directory: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
}

# Backup configuration files
backup_config() {
    log "INFO" "⚙️ Backing up configuration files..."
    
    local config_backup="$BACKUP_DIR/config"
    mkdir -p "$config_backup"
    
    # Backup all config files
    if [ -d "config" ]; then
        cp -r config/* "$config_backup/" 2>/dev/null || log "WARN" "Some config files could not be copied"
        log "INFO" "✅ Configuration backup completed"
    else
        log "WARN" "Config directory not found"
    fi
}

# Backup scripts
backup_scripts() {
    log "INFO" "📜 Backing up scripts..."
    
    local scripts_backup="$BACKUP_DIR/scripts"
    mkdir -p "$scripts_backup"
    
    if [ -d "scripts" ]; then
        cp -r scripts/* "$scripts_backup/" 2>/dev/null || log "WARN" "Some script files could not be copied"
        log "INFO" "✅ Scripts backup completed"
    else
        log "WARN" "Scripts directory not found"
    fi
}

# Backup R modules
backup_r_modules() {
    log "INFO" "📊 Backing up R modules..."
    
    local r_backup="$BACKUP_DIR/R"
    mkdir -p "$r_backup"
    
    if [ -d "R" ]; then
        cp -r R/* "$r_backup/" 2>/dev/null || log "WARN" "Some R files could not be copied"
        log "INFO" "✅ R modules backup completed"
    else
        log "WARN" "R directory not found"
    fi
}

# Backup Docker configuration
backup_docker() {
    log "INFO" "🐳 Backing up Docker configuration..."
    
    local docker_backup="$BACKUP_DIR/docker"
    mkdir -p "$docker_backup"
    
    # Copy Docker files
    for file in Dockerfile docker-compose.yml docker-compose.prod.yml; do
        if [ -f "$file" ]; then
            cp "$file" "$docker_backup/"
            log "INFO" "📄 Copied $file"
        fi
    done
    
    log "INFO" "✅ Docker configuration backup completed"
}

# Backup logs (last 7 days)
backup_recent_logs() {
    log "INFO" "📝 Backing up recent logs..."
    
    local logs_backup="$BACKUP_DIR/logs"
    mkdir -p "$logs_backup"
    
    if [ -d "logs" ]; then
        # Find and copy logs from last 7 days
        find logs -name "*.log" -mtime -7 -exec cp {} "$logs_backup/" \; 2>/dev/null || true
        log "INFO" "✅ Recent logs backup completed"
    else
        log "WARN" "Logs directory not found"
    fi
}

# Create backup manifest
create_manifest() {
    log "INFO" "📋 Creating backup manifest..."
    
    local manifest="$BACKUP_DIR/backup_manifest.txt"
    
    cat > "$manifest" << EOF
# MASLDatlas Backup Manifest
# Created: $(date)
# Backup ID: $(basename "$BACKUP_DIR")

BACKUP_INFO:
- Timestamp: $(date)
- Hostname: $(hostname)
- User: $(whoami)
- Working Directory: $(pwd)
- Git Commit: $(git rev-parse HEAD 2>/dev/null || echo "Not available")
- Git Branch: $(git branch --show-current 2>/dev/null || echo "Not available")

CONTENTS:
$(find "$BACKUP_DIR" -type f | sort)

SIZES:
$(du -sh "$BACKUP_DIR"/* 2>/dev/null || echo "No files")

TOTAL_SIZE:
$(du -sh "$BACKUP_DIR" | cut -f1)
EOF

    log "INFO" "✅ Backup manifest created"
}

# Compress backup
compress_backup() {
    log "INFO" "🗜️ Compressing backup..."
    
    local archive_name="$(basename "$BACKUP_DIR").tar.gz"
    local archive_path="backups/$archive_name"
    
    if tar -czf "$archive_path" -C "$(dirname "$BACKUP_DIR")" "$(basename "$BACKUP_DIR")"; then
        log "INFO" "✅ Backup compressed: $archive_path"
        
        # Remove uncompressed backup
        rm -rf "$BACKUP_DIR"
        log "INFO" "🧹 Cleaned up uncompressed backup"
        
        # Show final size
        local size=$(du -sh "$archive_path" | cut -f1)
        log "INFO" "📦 Final backup size: $size"
    else
        log "ERROR" "Failed to compress backup"
        return 1
    fi
}

# Clean old backups
cleanup_old_backups() {
    log "INFO" "🧹 Cleaning up old backups (older than $RETENTION_DAYS days)..."
    
    local deleted_count=0
    
    if [ -d "backups" ]; then
        while IFS= read -r -d '' file; do
            rm -f "$file"
            deleted_count=$((deleted_count + 1))
        done < <(find backups -name "*.tar.gz" -mtime +$RETENTION_DAYS -print0 2>/dev/null)
        
        if [ $deleted_count -gt 0 ]; then
            log "INFO" "🗑️ Deleted $deleted_count old backup(s)"
        else
            log "INFO" "No old backups to clean"
        fi
    fi
}

# Verify backup integrity
verify_backup() {
    log "INFO" "🔍 Verifying backup integrity..."
    
    local archive_name="$(basename "$BACKUP_DIR").tar.gz"
    local archive_path="backups/$archive_name"
    
    if [ -f "$archive_path" ]; then
        if tar -tzf "$archive_path" > /dev/null 2>&1; then
            log "INFO" "✅ Backup integrity verified"
            return 0
        else
            log "ERROR" "❌ Backup integrity check failed"
            return 1
        fi
    else
        log "ERROR" "Backup file not found: $archive_path"
        return 1
    fi
}

# Main backup function
perform_backup() {
    log "INFO" "🚀 Starting MASLDatlas backup process..."
    
    create_backup_dir
    backup_config
    backup_scripts
    backup_r_modules
    backup_docker
    backup_recent_logs
    create_manifest
    
    if compress_backup && verify_backup; then
        cleanup_old_backups
        log "INFO" "🎉 Backup completed successfully!"
        return 0
    else
        log "ERROR" "❌ Backup failed"
        return 1
    fi
}

# Restore function
restore_backup() {
    local backup_file="$1"
    local restore_dir="restore_$(date +%Y%m%d_%H%M%S)"
    
    log "INFO" "🔄 Restoring from backup: $backup_file"
    
    if [ ! -f "$backup_file" ]; then
        log "ERROR" "Backup file not found: $backup_file"
        return 1
    fi
    
    mkdir -p "$restore_dir"
    
    if tar -xzf "$backup_file" -C "$restore_dir"; then
        log "INFO" "✅ Backup extracted to: $restore_dir"
        log "INFO" "📋 Contents:"
        ls -la "$restore_dir"
        return 0
    else
        log "ERROR" "Failed to extract backup"
        return 1
    fi
}

# List available backups
list_backups() {
    log "INFO" "📋 Available backups:"
    
    if [ -d "backups" ]; then
        find backups -name "*.tar.gz" -exec ls -lh {} \; | sort -k9
    else
        log "INFO" "No backups directory found"
    fi
}

# Usage information
usage() {
    echo "MASLDatlas Backup Script"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  backup                Create a new backup (default)"
    echo "  restore <file>        Restore from backup file"
    echo "  list                  List available backups"
    echo "  cleanup               Clean up old backups only"
    echo "  help                  Show this help"
    echo ""
    echo "Examples:"
    echo "  $0                    # Create backup"
    echo "  $0 backup             # Create backup"
    echo "  $0 restore backups/20250902_143000.tar.gz"
    echo "  $0 list               # List backups"
    echo "  $0 cleanup            # Clean old backups"
}

# Main script logic
main() {
    case "${1:-backup}" in
        "backup")
            perform_backup
            ;;
        "restore")
            if [ -z "${2:-}" ]; then
                log "ERROR" "Please specify backup file to restore"
                usage
                exit 1
            fi
            restore_backup "$2"
            ;;
        "list")
            list_backups
            ;;
        "cleanup")
            cleanup_old_backups
            ;;
        "help"|"--help"|"-h")
            usage
            exit 0
            ;;
        *)
            log "ERROR" "Unknown command: $1"
            usage
            exit 1
            ;;
    esac
}

# Execute main function
main "$@"
