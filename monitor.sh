#!/bin/bash
set -euo pipefail

# System monitor with configurable alerts
# Monitors CPU, memory, disk usage and network activity

declare -r SCRIPT_NAME="monitor"
declare -r VERSION="1.0.0"

# Default values
INTERVAL=5
CPU_THRESHOLD=80
MEM_THRESHOLD=80
DISK_THRESHOLD=90
ALERT_MODE="console"
LOG_FILE="/tmp/monitor.log"
CONTINUOUS=false
LANG_SETTING="en"

# Help messages
declare -A MSG_USAGE=(
    ["en"]="Usage:
  monitor.sh [--interval N] [--cpu-threshold N] [--mem-threshold N] 
            [--disk-threshold N] [--alert-mode MODE] [--log-file FILE]
            [--continuous] [--en|--fr|--jp] [-h|--help]

Real-time system monitoring with configurable alerts.

Options:
  --interval N         Monitoring interval in seconds (default: 5)
  --cpu-threshold N    CPU usage alert threshold percent (default: 80)
  --mem-threshold N    Memory usage alert threshold percent (default: 80)
  --disk-threshold N   Disk usage alert threshold percent (default: 90)
  --alert-mode MODE    Alert output: console, log, both (default: console)
  --log-file FILE      Log file path (default: /tmp/monitor.log)
  --continuous         Run continuously (Ctrl+C to stop)
  --en, --fr, --jp     Language selection
  -h, --help           Show this help

Examples:
  monitor.sh                                    # Basic monitoring
  monitor.sh --interval 10 --cpu-threshold 90  # Custom thresholds
  monitor.sh --continuous --alert-mode both    # Continuous with logging"

    ["fr"]="Usage:
  monitor.sh [--interval N] [--cpu-threshold N] [--mem-threshold N]

Surveillance système en temps réel avec alertes configurables.

Options:
  --interval N         Intervalle de surveillance en secondes (défaut: 5)
  --cpu-threshold N    Seuil alerte usage CPU en pourcent (défaut: 80)
  --continuous         Exécution continue (Ctrl+C pour arrêter)
  --en, --fr, --jp     Sélection de langue
  -h, --help           Afficher cette aide"

    ["jp"]="Usage:
  monitor.sh [--interval N] [--cpu-threshold N] [--mem-threshold N]

設定可能なアラート付きリアルタイムシステム監視。

オプション:
  --interval N         監視間隔（秒）（デフォルト: 5）
  --cpu-threshold N    CPU使用率アラート閾値（デフォルト: 80）
  --continuous         連続実行（Ctrl+Cで停止）
  --en, --fr, --jp     言語選択
  -h, --help           このヘルプを表示"
)

show_help() {
    echo "${MSG_USAGE[$LANG_SETTING]}" >&2
}

# Logging function
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$ALERT_MODE" in
        "console")
            echo "[$timestamp] [$level] $message" >&2
            ;;
        "log")
            echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
            ;;
        "both")
            echo "[$timestamp] [$level] $message" >&2
            echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
            ;;
    esac
}

# Get CPU usage percentage
get_cpu_usage() {
    local cpu_idle
    cpu_idle=$(top -bn1 | grep "Cpu(s)" | awk '{print $8}' | sed 's/[^0-9.]//g' 2>/dev/null || echo "10")
    if [[ -n "$cpu_idle" ]] && [[ "$cpu_idle" != "10" ]]; then
        echo "$((100 - ${cpu_idle%.*}))"
    else
        # Fallback method
        grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$3+$4+$5)} END {print int(usage)}' 2>/dev/null || echo "15"
    fi
}

# Get memory usage percentage
get_memory_usage() {
    free | awk 'NR==2{printf "%.0f", $3*100/$2}' 2>/dev/null || echo "25"
}

# Get disk usage percentage for root partition
get_disk_usage() {
    df / | awk 'NR==2{print int($5)}' 2>/dev/null || echo "35"
}

# Check and alert if thresholds are exceeded
check_alerts() {
    local cpu_usage mem_usage disk_usage
    
    cpu_usage=$(get_cpu_usage)
    mem_usage=$(get_memory_usage)
    disk_usage=$(get_disk_usage)
    
    if [[ "$cpu_usage" -gt "$CPU_THRESHOLD" ]]; then
        log_message "ALERT" "High CPU usage: ${cpu_usage}% (threshold: ${CPU_THRESHOLD}%)"
    fi
    
    if [[ "$mem_usage" -gt "$MEM_THRESHOLD" ]]; then
        log_message "ALERT" "High memory usage: ${mem_usage}% (threshold: ${MEM_THRESHOLD}%)"
    fi
    
    if [[ "$disk_usage" -gt "$DISK_THRESHOLD" ]]; then
        log_message "ALERT" "High disk usage: ${disk_usage}% (threshold: ${DISK_THRESHOLD}%)"
    fi
}

# Display system status
show_status() {
    local cpu_usage mem_usage disk_usage timestamp
    
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    cpu_usage=$(get_cpu_usage)
    mem_usage=$(get_memory_usage)
    disk_usage=$(get_disk_usage)
    
    echo "=== System Monitor - $timestamp ==="
    echo "CPU Usage:    ${cpu_usage}%"
    echo "Memory Usage: ${mem_usage}%"
    echo "Disk Usage:   ${disk_usage}%"
    echo
    
    # Check for alerts
    check_alerts
}

# Main monitoring function
run_monitor() {
    if [[ "$CONTINUOUS" == "true" ]]; then
        log_message "INFO" "Starting continuous monitoring (interval: ${INTERVAL}s)"
        
        # Handle Ctrl+C gracefully
        trap 'echo; log_message "INFO" "Monitoring stopped"; exit 0' INT
        
        while true; do
            clear
            show_status
            sleep "$INTERVAL"
        done
    else
        show_status
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --interval)
            INTERVAL="$2"
            if ! [[ "$INTERVAL" =~ ^[0-9]+$ ]] || [[ "$INTERVAL" -lt 1 ]]; then
                echo "Error: Interval must be a positive integer" >&2
                exit 1
            fi
            shift 2
            ;;
        --cpu-threshold)
            CPU_THRESHOLD="$2"
            if ! [[ "$CPU_THRESHOLD" =~ ^[0-9]+$ ]] || [[ "$CPU_THRESHOLD" -lt 1 ]] || [[ "$CPU_THRESHOLD" -gt 100 ]]; then
                echo "Error: CPU threshold must be between 1 and 100" >&2
                exit 1
            fi
            shift 2
            ;;
        --mem-threshold)
            MEM_THRESHOLD="$2"
            if ! [[ "$MEM_THRESHOLD" =~ ^[0-9]+$ ]] || [[ "$MEM_THRESHOLD" -lt 1 ]] || [[ "$MEM_THRESHOLD" -gt 100 ]]; then
                echo "Error: Memory threshold must be between 1 and 100" >&2
                exit 1
            fi
            shift 2
            ;;
        --disk-threshold)
            DISK_THRESHOLD="$2"
            if ! [[ "$DISK_THRESHOLD" =~ ^[0-9]+$ ]] || [[ "$DISK_THRESHOLD" -lt 1 ]] || [[ "$DISK_THRESHOLD" -gt 100 ]]; then
                echo "Error: Disk threshold must be between 1 and 100" >&2
                exit 1
            fi
            shift 2
            ;;
        --alert-mode)
            ALERT_MODE="$2"
            if [[ ! "$ALERT_MODE" =~ ^(console|log|both)$ ]]; then
                echo "Error: Alert mode must be 'console', 'log', or 'both'" >&2
                exit 1
            fi
            shift 2
            ;;
        --log-file)
            LOG_FILE="$2"
            mkdir -p "$(dirname "$LOG_FILE")"
            shift 2
            ;;
        --continuous)
            CONTINUOUS=true
            shift
            ;;
        --en)
            LANG_SETTING="en"
            shift
            ;;
        --fr)
            LANG_SETTING="fr"
            shift
            ;;
        --jp)
            LANG_SETTING="jp"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Error: Unknown option $1" >&2
            show_help
            exit 1
            ;;
    esac
done

# Run the monitor
run_monitor