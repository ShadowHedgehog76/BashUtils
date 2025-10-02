#!/bin/bash
set -euo pipefail

# Git utilities collection
# Common git operations and repository management

declare -r SCRIPT_NAME="gitutils"
declare -r VERSION="1.0.0"

COMMAND=""
LANG_SETTING="en"

show_help() {
    echo "Usage: gitutils.sh COMMAND [OPTIONS]"
    echo ""
    echo "Git utilities for common repository operations."
    echo ""
    echo "Commands:"
    echo "  status        Show repository status with branch info"
    echo "  clean         Clean untracked files and directories"
    echo "  branches      List all branches (local and remote)"
    echo "  sync          Sync with remote (fetch + pull)"
    echo "  backup        Create a backup archive of the repository"
    echo "  size          Show repository size and largest files"
    echo ""
    echo "Options:"
    echo "  --en, --fr, --jp  Language selection"
    echo "  -h, --help        Show this help"
    echo ""
    echo "Examples:"
    echo "  gitutils.sh status"
    echo "  gitutils.sh clean"
    echo "  gitutils.sh branches"
}

check_git_repo() {
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        echo "Error: Not in a git repository" >&2
        return 1
    fi
}

cmd_status() {
    check_git_repo
    
    echo "=== Git Repository Status ==="
    echo
    
    # Current branch
    local branch=$(git branch --show-current 2>/dev/null || echo "detached")
    echo "Current branch: $branch"
    
    # Remote tracking
    if [[ "$branch" != "detached" ]]; then
        local remote=$(git config "branch.$branch.remote" 2>/dev/null || echo "none")
        if [[ "$remote" != "none" ]]; then
            echo "Tracking: $remote/$(git config "branch.$branch.merge" | sed 's|refs/heads/||')"
        fi
    fi
    
    # Commit info
    echo "Latest commit: $(git log -1 --pretty=format:'%h - %s (%an, %ar)')"
    echo
    
    # Status
    git status --short
    
    # Stash info
    local stash_count=$(git stash list | wc -l)
    if [[ $stash_count -gt 0 ]]; then
        echo
        echo "Stashed changes: $stash_count"
    fi
}

cmd_clean() {
    check_git_repo
    
    echo "=== Cleaning Repository ==="
    
    # Show what would be removed
    echo "Files that would be removed:"
    git clean -n -d
    
    echo
    echo -n "Proceed with cleaning? (y/N): "
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        git clean -f -d
        echo "Repository cleaned!"
    else
        echo "Cleaning cancelled"
    fi
}

cmd_branches() {
    check_git_repo
    
    echo "=== Local Branches ==="
    git branch -v
    
    echo
    echo "=== Remote Branches ==="
    git branch -r
    
    echo
    echo "=== Branch Status ==="
    git for-each-ref --format='%(refname:short) %(upstream:track)' refs/heads | while read -r branch status; do
        if [[ -n "$status" ]]; then
            echo "$branch: $status"
        else
            echo "$branch: no upstream"
        fi
    done
}

cmd_sync() {
    check_git_repo
    
    echo "=== Syncing with Remote ==="
    
    echo "Fetching from remote..."
    git fetch --all
    
    local branch=$(git branch --show-current 2>/dev/null || echo "")
    if [[ -n "$branch" ]]; then
        local remote=$(git config "branch.$branch.remote" 2>/dev/null || echo "")
        if [[ -n "$remote" ]]; then
            echo "Pulling changes for branch: $branch"
            git pull
        else
            echo "No remote configured for branch: $branch"
        fi
    else
        echo "Not on a branch - skipping pull"
    fi
    
    echo "Sync completed!"
}

cmd_backup() {
    check_git_repo
    
    local repo_name=$(basename "$(git rev-parse --show-toplevel)")
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_name="${repo_name}_backup_${timestamp}.tar.gz"
    local backup_dir="$HOME/git_backups"
    
    mkdir -p "$backup_dir"
    
    echo "Creating backup: $backup_name"
    
    # Create archive excluding .git directory to save space
    if tar -czf "$backup_dir/$backup_name" --exclude='.git' -C .. "$repo_name"; then
        echo "Backup created: $backup_dir/$backup_name"
        echo "Size: $(du -sh "$backup_dir/$backup_name" | cut -f1)"
    else
        echo "Backup failed" >&2
        return 1
    fi
}

cmd_size() {
    check_git_repo
    
    echo "=== Repository Size Information ==="
    
    # Overall repository size
    local repo_root=$(git rev-parse --show-toplevel)
    echo "Total size: $(du -sh "$repo_root" | cut -f1)"
    
    # .git directory size
    echo ".git size: $(du -sh "$repo_root/.git" | cut -f1)"
    
    echo
    echo "=== Largest Files ==="
    find "$repo_root" -type f -not -path "$repo_root/.git/*" -exec du -h {} + | sort -hr | head -10
    
    echo
    echo "=== File Type Summary ==="
    find "$repo_root" -type f -not -path "$repo_root/.git/*" | sed 's/.*\.//' | sort | uniq -c | sort -nr | head -10
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        status|clean|branches|sync|backup|size)
            COMMAND="$1"
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
        *)
            echo "Error: Unknown command or option: $1" >&2
            show_help
            return 1
            ;;
    esac
done

if [[ -z "$COMMAND" ]]; then
    echo "Error: No command specified" >&2
    show_help
    return 1
fi

# Execute command
case "$COMMAND" in
    "status") cmd_status ;;
    "clean") cmd_clean ;;
    "branches") cmd_branches ;;
    "sync") cmd_sync ;;
    "backup") cmd_backup ;;
    "size") cmd_size ;;
esac