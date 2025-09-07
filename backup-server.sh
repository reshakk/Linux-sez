#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

SDIR="$HOME" # Directory for backup
BDIR="/backup" # Output directory for backup
BDATE="$(date +'%d.%m.%Y_%H.%M')"
HOSTNAME="$(hostname)"
FILENAME="$BDIR/${HOSTNAME}_$BDATE"
LOG_FILE="$FILENAME.log"
MIN_FREE_SPACE_GB=5
RETENTION_DAYS=4

log_message() {
    local level="$1"
    local message="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $message" | tee -a "$LOG_FILE"
}

check_disk_space() {
    local required_space=$1
    local available_space=$(df "$BDIR" | awk 'NR==2 {print int($4/1024/1024)}')
    
    if [[ $available_space -lt $required_space ]]; then
        log_message "ERROR" "Not enough space on disk. Requiers: ${required_space}GB, Available: ${available_space}GB"
        return 1
    fi
    
    return 0
}


cleanup_old_backups() {
    find "$BDIR" -name "*.log" -mtime +$RETENTION_DAYS -delete 2>/dev/null || true
}

verify_backup() {
    local archive_file="$1"
     
    if tar -tzf "$archive_file" >/dev/null 2>&1; then
        return 0
    else
        log_message "ERROR" "Archive is damaged or cannot be read."
        return 1
    fi
}



main() {
    
    if ! mkdir -p "$BDIR"; then
        log_message "ERROR" "Can't create directory: $BDIR"
        exit 1
    fi 
    
    if ! check_disk_space $MIN_FREE_SPACE_GB; then
        exit 1
    fi
     
    if tar --warning=no-file-changed \
           --acls --xattrs \
           -czf "$FILENAME.tar.gz" \
           -C "$SDIR" . 2>&1 | tee -a "$LOG_FILE"; then
        
        
        if ! verify_backup "$FILENAME.tar.gz"; then
            exit 1
        fi
    else
        log_message "ERROR" "Can't create archive"
        exit 1
    fi
    
    #cleanup_old_backups
}


main

