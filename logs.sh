#!/bin/bash
set -euo pipefail

# Log analyzer and viewer
# Analyzes system logs and provides insights

declare -r SCRIPT_NAME="logs"
declare -r VERSION="1.0.0"

LOG_FILE=""
LINES=50
FOLLOW=false
FILTER=""
LANG_SETTING="en"

show_help() {
    echo "Usage: logs.sh [OPTIONS] [LOG_FILE]"
    echo ""
    echo "Log analyzer and viewer utility."
    echo ""
    echo "Options:"
    echo "  --lines N         Number of lines to show (default: 50)"
    echo "  --follow          Follow log file (like tail -f)"
    echo "  --filter PATTERN  Filter lines containing pattern"
    echo "  --en, --fr, --jp  Language selection"
    echo "  -h, --help        Show this help"
    echo ""
    echo "Examples:"
    echo "  logs.sh /var/log/syslog"
    echo "  logs.sh --lines 100 --filter ERROR /var/log/apache2/error.log"
    echo "  logs.sh --follow /var/log/messages"
}

analyze_log() {
    local logfile="$1"
    
    if [[ ! -f "$logfile" ]]; then
        echo "Error: Log file '$logfile' not found" >&2
        return 1
    fi
    
    echo "=== Log Analysis: $logfile ==="
    echo "File size: $(du -sh "$logfile" | cut -f1)"
    echo "Lines: $(wc -l < "$logfile")"
    echo "Last modified: $(stat -c %y "$logfile" 2>/dev/null || stat -f %Sm "$logfile" 2>/dev/null)"
    echo
    
    # Show recent entries
    echo "=== Recent Entries ==="
    local tail_cmd="tail -n $LINES"
    
    if [[ -n "$FILTER" ]]; then
        tail_cmd+=" | grep '$FILTER'"
    fi
    
    if [[ "$FOLLOW" == "true" ]]; then
        tail_cmd="tail -f -n $LINES"
        if [[ -n "$FILTER" ]]; then
            tail_cmd+=" | grep --line-buffered '$FILTER'"
        fi
        echo "Following log file (Ctrl+C to stop)..."
    fi
    
    eval "$tail_cmd '$logfile'"
}

show_system_logs() {
    echo "=== Available System Logs ==="
    
    local log_dirs=("/var/log" "/var/log/apache2" "/var/log/nginx" "/var/log/mysql")
    
    for dir in "${log_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            echo
            echo "Directory: $dir"
            find "$dir" -name "*.log" -type f 2>/dev/null | head -10 | while read -r logfile; do
                local size=$(du -sh "$logfile" | cut -f1)
                echo "  $logfile ($size)"
            done
        fi
    done
    
    # Common log files
    echo
    echo "=== Common System Logs ==="
    local common_logs=(
        "/var/log/syslog"
        "/var/log/messages" 
        "/var/log/auth.log"
        "/var/log/kern.log"
        "/var/log/dmesg"
    )
    
    for logfile in "${common_logs[@]}"; do
        if [[ -f "$logfile" ]]; then
            local size=$(du -sh "$logfile" | cut -f1)
            echo "  $logfile ($size)"
        fi
    done
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --lines)
            LINES="$2"
            if ! [[ "$LINES" =~ ^[0-9]+$ ]] || [[ "$LINES" -lt 1 ]]; then
                echo "Error: Lines must be a positive integer" >&2
                return 1
            fi
            shift 2
            ;;
        --follow)
            FOLLOW=true
            shift
            ;;
        --filter)
            FILTER="$2"
            shift 2
            ;;
        --en|--fr|--jp)
            LANG_SETTING="${1#--}"
            shift
            ;;
        -h|--help)
            show_help
            return 0
            ;;
        -*)
            echo "Error: Unknown option $1" >&2
            show_help
            return 1
            ;;
        *)
            LOG_FILE="$1"
            shift
            ;;
    esac
done

if [[ -z "$LOG_FILE" ]]; then
    show_system_logs
else
    analyze_log "$LOG_FILE"
fi