#!/bin/bash
set -euo pipefail

# Simple backup utility
# Creates backups of files and directories

declare -r SCRIPT_NAME="backup"
declare -r VERSION="1.0.0"

BACKUP_DIR="$HOME/backups"
COMPRESS=true
EXCLUDE_PATTERNS=()
LANG_SETTING="en"

show_help() {
    echo "Usage: backup.sh [OPTIONS] SOURCE [SOURCE...]"
    echo ""
    echo "Simple backup utility for files and directories."
    echo ""
    echo "Options:"
    echo "  --dest DIR        Backup destination directory (default: ~/backups)"
    echo "  --no-compress     Don't compress backup archives"
    echo "  --exclude PATTERN Exclude files matching pattern"
    echo "  --en, --fr, --jp  Language selection"
    echo "  -h, --help        Show this help"
    echo ""
    echo "Examples:"
    echo "  backup.sh /home/user/documents"
    echo "  backup.sh --dest /backup /etc /home"
    echo "  backup.sh --exclude '*.tmp' /var/log"
}

create_backup() {
    local source="$1"
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local basename=$(basename "$source")
    local backup_name="${basename}_${timestamp}"
    
    if [[ ! -e "$source" ]]; then
        echo "Error: Source '$source' does not exist" >&2
        return 1
    fi
    
    mkdir -p "$BACKUP_DIR"
    
    echo "Creating backup of: $source"
    
    if [[ "$COMPRESS" == "true" ]]; then
        local archive_path="$BACKUP_DIR/${backup_name}.tar.gz"
        echo "Archive: $archive_path"
        
        local exclude_args=()
        for pattern in "${EXCLUDE_PATTERNS[@]}"; do
            exclude_args+=(--exclude="$pattern")
        done
        
        if tar -czf "$archive_path" "${exclude_args[@]}" -C "$(dirname "$source")" "$(basename "$source")"; then
            echo "Backup completed successfully"
            echo "Size: $(du -sh "$archive_path" | cut -f1)"
        else
            echo "Backup failed" >&2
            return 1
        fi
    else
        local dest_path="$BACKUP_DIR/$backup_name"
        echo "Destination: $dest_path"
        
        if cp -r "$source" "$dest_path"; then
            echo "Backup completed successfully"
            echo "Size: $(du -sh "$dest_path" | cut -f1)"
        else
            echo "Backup failed" >&2
            return 1
        fi
    fi
}

# Parse arguments
SOURCES=()
while [[ $# -gt 0 ]]; do
    case $1 in
        --dest)
            BACKUP_DIR="$2"
            shift 2
            ;;
        --no-compress)
            COMPRESS=false
            shift
            ;;
        --exclude)
            EXCLUDE_PATTERNS+=("$2")
            shift 2
            ;;
        --en|--fr|--jp)
            LANG_SETTING="${1#--}"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -*)
            echo "Error: Unknown option $1" >&2
            show_help
            exit 1
            ;;
        *)
            SOURCES+=("$1")
            shift
            ;;
    esac
done

if [[ ${#SOURCES[@]} -eq 0 ]]; then
    echo "Error: No source specified" >&2
    show_help
    exit 1
fi

# Create backups
for source in "${SOURCES[@]}"; do
    create_backup "$source"
    echo
done