#!/bin/bash
set -euo pipefail

# File organizer utility
# Organizes files by type, date, or custom rules

declare -r SCRIPT_NAME="organize"
declare -r VERSION="1.0.0"

MODE="type"  # type, date, size
TARGET_DIR=""
DRY_RUN=false
LANG_SETTING="en"

show_help() {
    echo "Usage: organize.sh [OPTIONS] DIRECTORY"
    echo ""
    echo "File organizer utility - organizes files by type, date, or size."
    echo ""
    echo "Options:"
    echo "  --mode MODE       Organization mode: type, date, size (default: type)"
    echo "  --dry-run         Show what would be done without doing it"
    echo "  --en, --fr, --jp  Language selection"
    echo "  -h, --help        Show this help"
    echo ""
    echo "Examples:"
    echo "  organize.sh ~/Downloads"
    echo "  organize.sh --mode date ~/Pictures"
    echo "  organize.sh --dry-run --mode size ~/Documents"
}

get_file_category() {
    local file="$1"
    local ext="${file##*.}"
    ext="${ext,,}"  # Convert to lowercase
    
    case "$ext" in
        jpg|jpeg|png|gif|bmp|tiff|svg|webp)
            echo "Images"
            ;;
        mp4|avi|mkv|mov|wmv|flv|webm|m4v)
            echo "Videos"
            ;;
        mp3|wav|flac|aac|ogg|wma|m4a)
            echo "Audio"
            ;;
        pdf|doc|docx|txt|rtf|odt)
            echo "Documents"
            ;;
        zip|tar|gz|rar|7z|bz2|xz)
            echo "Archives"
            ;;
        exe|msi|deb|rpm|dmg|pkg)
            echo "Executables"
            ;;
        *)
            echo "Other"
            ;;
    esac
}

organize_by_type() {
    local source_dir="$1"
    
    echo "Organizing files by type in: $source_dir"
    
    find "$source_dir" -maxdepth 1 -type f | while read -r file; do
        local category=$(get_file_category "$file")
        local dest_dir="$source_dir/$category"
        local filename=$(basename "$file")
        
        if [[ "$DRY_RUN" == "true" ]]; then
            echo "[DRY-RUN] Move: $filename -> $category/"
        else
            mkdir -p "$dest_dir"
            if mv "$file" "$dest_dir/"; then
                echo "Moved: $filename -> $category/"
            else
                echo "Failed to move: $filename" >&2
            fi
        fi
    done
}

organize_by_date() {
    local source_dir="$1"
    
    echo "Organizing files by date in: $source_dir"
    
    find "$source_dir" -maxdepth 1 -type f | while read -r file; do
        local file_date=$(stat -c %Y "$file" 2>/dev/null || stat -f %m "$file" 2>/dev/null || echo "0")
        local year_month=$(date -d "@$file_date" '+%Y-%m' 2>/dev/null || date -r "$file_date" '+%Y-%m' 2>/dev/null || echo "unknown")
        local dest_dir="$source_dir/$year_month"
        local filename=$(basename "$file")
        
        if [[ "$DRY_RUN" == "true" ]]; then
            echo "[DRY-RUN] Move: $filename -> $year_month/"
        else
            mkdir -p "$dest_dir"
            if mv "$file" "$dest_dir/"; then
                echo "Moved: $filename -> $year_month/"
            else
                echo "Failed to move: $filename" >&2
            fi
        fi
    done
}

organize_by_size() {
    local source_dir="$1"
    
    echo "Organizing files by size in: $source_dir"
    
    find "$source_dir" -maxdepth 1 -type f | while read -r file; do
        local size=$(stat -c %s "$file" 2>/dev/null || stat -f %z "$file" 2>/dev/null || echo "0")
        local category
        
        if [[ $size -lt 1048576 ]]; then     # < 1MB
            category="Small"
        elif [[ $size -lt 104857600 ]]; then # < 100MB
            category="Medium"
        else
            category="Large"
        fi
        
        local dest_dir="$source_dir/$category"
        local filename=$(basename "$file")
        
        if [[ "$DRY_RUN" == "true" ]]; then
            echo "[DRY-RUN] Move: $filename -> $category/"
        else
            mkdir -p "$dest_dir"
            if mv "$file" "$dest_dir/"; then
                echo "Moved: $filename -> $category/"
            else
                echo "Failed to move: $filename" >&2
            fi
        fi
    done
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --mode)
            MODE="$2"
            if [[ ! "$MODE" =~ ^(type|date|size)$ ]]; then
                echo "Error: Mode must be 'type', 'date', or 'size'" >&2
                return 1
            fi
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
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
            if [[ -z "$TARGET_DIR" ]]; then
                TARGET_DIR="$1"
            else
                echo "Error: Multiple directories specified" >&2
                return 1
            fi
            shift
            ;;
    esac
done

if [[ -z "$TARGET_DIR" ]]; then
    echo "Error: No directory specified" >&2
    show_help
    return 1
fi

if [[ ! -d "$TARGET_DIR" ]]; then
    echo "Error: Directory '$TARGET_DIR' does not exist" >&2
    return 1
fi

# Organize files
case "$MODE" in
    "type")
        organize_by_type "$TARGET_DIR"
        ;;
    "date")
        organize_by_date "$TARGET_DIR"
        ;;
    "size")
        organize_by_size "$TARGET_DIR"
        ;;
esac

echo "Organization completed!"