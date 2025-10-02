#!/bin/bash
set -euo pipefail

# System cleanup utility
# Cleans temporary files, logs, caches, and other system clutter

declare -r SCRIPT_NAME="cleanup"
declare -r VERSION="1.0.0"

# Default values
DRY_RUN=false
VERBOSE=false
INTERACTIVE=false
CLEAN_TEMP=true
CLEAN_LOGS=true
CLEAN_CACHE=true
CLEAN_TRASH=true
LOG_RETENTION_DAYS=7
LANG_SETTING="en"

# Help messages
declare -A MSG_USAGE=(
    ["en"]="Usage:
  cleanup.sh [--dry-run] [--verbose] [--interactive] [--no-temp] [--no-logs]
             [--no-cache] [--no-trash] [--log-days N] [--en|--fr|--jp] [-h|--help]

System cleanup utility for temporary files, logs, caches, and trash.

Options:
  --dry-run            Show what would be cleaned without actually doing it
  --verbose            Show detailed information about cleanup operations
  --interactive        Ask for confirmation before each cleanup operation
  --no-temp            Skip temporary files cleanup
  --no-logs            Skip log files cleanup
  --no-cache           Skip cache cleanup
  --no-trash           Skip trash cleanup
  --log-days N         Keep log files newer than N days (default: 7)
  --en, --fr, --jp     Language selection
  -h, --help           Show this help

Examples:
  cleanup.sh                     # Standard cleanup
  cleanup.sh --dry-run           # Preview cleanup actions
  cleanup.sh --interactive       # Interactive cleanup
  cleanup.sh --log-days 14       # Keep logs for 14 days"

    ["fr"]="Usage:
  cleanup.sh [--dry-run] [--verbose] [--interactive]

Utilitaire de nettoyage système pour fichiers temporaires, logs et cache.

Options:
  --dry-run            Afficher ce qui serait nettoyé sans le faire
  --verbose            Afficher des informations détaillées
  --interactive        Demander confirmation avant chaque opération
  --log-days N         Conserver les logs plus récents que N jours (défaut: 7)
  --en, --fr, --jp     Sélection de langue
  -h, --help           Afficher cette aide"

    ["jp"]="Usage:
  cleanup.sh [--dry-run] [--verbose] [--interactive]

一時ファイル、ログ、キャッシュのシステムクリーンアップユーティリティ。

オプション:
  --dry-run            実際の処理なしでクリーンアップ内容を表示
  --verbose            詳細情報を表示
  --interactive        各操作前に確認を求める
  --log-days N         N日より新しいログファイルを保持（デフォルト: 7）
  --en, --fr, --jp     言語選択
  -h, --help           このヘルプを表示"
)

show_help() {
    echo "${MSG_USAGE[$LANG_SETTING]}" >&2
}

# Logging functions
log_info() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo "[INFO] $*" >&2
    fi
}

log_action() {
    echo "[ACTION] $*" >&2
}

# Ask for confirmation
ask_confirmation() {
    local message="$1"
    if [[ "$INTERACTIVE" == "true" ]]; then
        echo -n "$message (y/N): " >&2
        read -r response
        [[ "$response" =~ ^[Yy]$ ]]
    else
        return 0
    fi
}

# Execute or show command
execute_or_show() {
    local action="$1"
    shift
    local cmd="$*"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY-RUN] $action: $cmd"
    else
        log_action "$action"
        if [[ "$VERBOSE" == "true" ]]; then
            echo "Executing: $cmd" >&2
        fi
        eval "$cmd"
    fi
}

# Get directory size in human readable format
get_dir_size() {
    local dir="$1"
    if [[ -d "$dir" ]]; then
        du -sh "$dir" 2>/dev/null | cut -f1
    else
        echo "0B"
    fi
}

# Count files in directory
count_files() {
    local dir="$1"
    if [[ -d "$dir" ]]; then
        find "$dir" -type f 2>/dev/null | wc -l
    else
        echo "0"
    fi
}

# Clean temporary files
clean_temp_files() {
    if [[ "$CLEAN_TEMP" != "true" ]]; then
        return
    fi
    
    local temp_dirs=("/tmp" "/var/tmp")
    local home_temp_dirs=()
    
    # Add user-specific temp directories
    if [[ -n "${HOME:-}" ]]; then
        home_temp_dirs+=("$HOME/.tmp" "$HOME/tmp")
    fi
    
    for temp_dir in "${temp_dirs[@]}" "${home_temp_dirs[@]}"; do
        if [[ ! -d "$temp_dir" ]]; then
            continue
        fi
        
        local size=$(get_dir_size "$temp_dir")
        local file_count=$(count_files "$temp_dir")
        
        log_info "Temp directory: $temp_dir (Size: $size, Files: $file_count)"
        
        if ask_confirmation "Clean temporary files in $temp_dir?"; then
            # Clean files older than 1 day in /tmp and /var/tmp
            if [[ "$temp_dir" == "/tmp" ]] || [[ "$temp_dir" == "/var/tmp" ]]; then
                execute_or_show "Clean old temp files" "find '$temp_dir' -type f -atime +1 -delete 2>/dev/null || true"
            else
                execute_or_show "Clean temp files" "rm -rf '$temp_dir'/* 2>/dev/null || true"
            fi
        fi
    done
}

# Clean log files
clean_log_files() {
    if [[ "$CLEAN_LOGS" != "true" ]]; then
        return
    fi
    
    local log_dirs=("/var/log")
    
    # Add user log directories
    if [[ -n "${HOME:-}" ]]; then
        log_dirs+=("$HOME/.local/share/logs" "$HOME/logs")
    fi
    
    for log_dir in "${log_dirs[@]}"; do
        if [[ ! -d "$log_dir" ]]; then
            continue
        fi
        
        local size=$(get_dir_size "$log_dir")
        log_info "Log directory: $log_dir (Size: $size)"
        
        if ask_confirmation "Clean old log files in $log_dir?"; then
            execute_or_show "Clean old logs" "find '$log_dir' -name '*.log' -type f -mtime +$LOG_RETENTION_DAYS -delete 2>/dev/null || true"
            execute_or_show "Clean rotated logs" "find '$log_dir' -name '*.log.*' -type f -mtime +$LOG_RETENTION_DAYS -delete 2>/dev/null || true"
        fi
    done
}

# Clean cache files
clean_cache_files() {
    if [[ "$CLEAN_CACHE" != "true" ]]; then
        return
    fi
    
    local cache_dirs=()
    
    # Add user cache directories
    if [[ -n "${HOME:-}" ]]; then
        cache_dirs+=("$HOME/.cache")
        
        # Browser caches
        cache_dirs+=("$HOME/.mozilla/firefox/*/Cache*")
        cache_dirs+=("$HOME/.config/google-chrome/Default/Cache*")
        cache_dirs+=("$HOME/.config/chromium/Default/Cache*")
    fi
    
    for cache_pattern in "${cache_dirs[@]}"; do
        # Use glob expansion
        for cache_dir in $cache_pattern; do
            if [[ ! -d "$cache_dir" ]]; then
                continue
            fi
            
            local size=$(get_dir_size "$cache_dir")
            log_info "Cache directory: $cache_dir (Size: $size)"
            
            if ask_confirmation "Clean cache in $cache_dir?"; then
                execute_or_show "Clean cache" "rm -rf '$cache_dir'/* 2>/dev/null || true"
            fi
        done
    done
}

# Clean trash
clean_trash() {
    if [[ "$CLEAN_TRASH" != "true" ]]; then
        return
    fi
    
    local trash_dirs=()
    
    # Add user trash directories
    if [[ -n "${HOME:-}" ]]; then
        trash_dirs+=("$HOME/.local/share/Trash" "$HOME/.Trash")
    fi
    
    for trash_dir in "${trash_dirs[@]}"; do
        if [[ ! -d "$trash_dir" ]]; then
            continue
        fi
        
        local size=$(get_dir_size "$trash_dir")
        log_info "Trash directory: $trash_dir (Size: $size)"
        
        if ask_confirmation "Empty trash in $trash_dir?"; then
            execute_or_show "Empty trash" "rm -rf '$trash_dir'/* 2>/dev/null || true"
        fi
    done
}

# Main cleanup function
run_cleanup() {
    echo "Starting system cleanup..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "DRY RUN MODE - No files will be actually deleted"
    fi
    
    clean_temp_files
    clean_log_files  
    clean_cache_files
    clean_trash
    
    echo "Cleanup completed!"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --interactive)
            INTERACTIVE=true
            shift
            ;;
        --no-temp)
            CLEAN_TEMP=false
            shift
            ;;
        --no-logs)
            CLEAN_LOGS=false
            shift
            ;;
        --no-cache)
            CLEAN_CACHE=false
            shift
            ;;
        --no-trash)
            CLEAN_TRASH=false
            shift
            ;;
        --log-days)
            LOG_RETENTION_DAYS="$2"
            if ! [[ "$LOG_RETENTION_DAYS" =~ ^[0-9]+$ ]] || [[ "$LOG_RETENTION_DAYS" -lt 0 ]]; then
                echo "Error: Log retention days must be a non-negative integer" >&2
                return 1
            fi
            shift 2
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
            return 0
            ;;
        *)
            echo "Error: Unknown option $1" >&2
            show_help
            return 1
            ;;
    esac
done

# Run cleanup
run_cleanup