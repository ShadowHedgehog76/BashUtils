#!/bin/bash
set -euo pipefail

# Deployment utility
# Simple deployment automation for applications

declare -r SCRIPT_NAME="deploy"
declare -r VERSION="1.0.0"

TARGET=""
SOURCE="."
METHOD="rsync"
DRY_RUN=false
LANG_SETTING="en"

show_help() {
    echo "Usage: deploy.sh [OPTIONS] TARGET"
    echo ""
    echo "Simple deployment utility for applications."
    echo ""
    echo "Options:"
    echo "  --source DIR      Source directory (default: current directory)"
    echo "  --method METHOD   Deployment method: rsync, scp, git (default: rsync)"
    echo "  --dry-run         Show what would be deployed without doing it"
    echo "  --en, --fr, --jp  Language selection"
    echo "  -h, --help        Show this help"
    echo ""
    echo "Examples:"
    echo "  deploy.sh user@server:/var/www/html"
    echo "  deploy.sh --source ./dist --method scp user@server:~/app"
    echo "  deploy.sh --dry-run --method git origin"
}

deploy_rsync() {
    local source="$1"
    local target="$2"
    
    echo "Deploying with rsync: $source -> $target"
    
    local rsync_opts=(-avz --progress --delete)
    
    if [[ "$DRY_RUN" == "true" ]]; then
        rsync_opts+=(--dry-run)
    fi
    
    if rsync "${rsync_opts[@]}" "$source/" "$target/"; then
        echo "Deployment completed successfully"
    else
        echo "Deployment failed" >&2
        return 1
    fi
}

deploy_scp() {
    local source="$1"
    local target="$2"
    
    echo "Deploying with scp: $source -> $target"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY-RUN] Would copy $source to $target"
        return 0
    fi
    
    if scp -r "$source"/* "$target/"; then
        echo "Deployment completed successfully"
    else
        echo "Deployment failed" >&2
        return 1
    fi
}

deploy_git() {
    local source="$1"
    local target="$2"
    
    echo "Deploying with git: pushing to $target"
    
    if [[ ! -d "$source/.git" ]]; then
        echo "Error: Source is not a git repository" >&2
        return 1
    fi
    
    cd "$source"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY-RUN] Would push to $target"
        return 0
    fi
    
    if git push "$target" HEAD; then
        echo "Deployment completed successfully"
    else
        echo "Deployment failed" >&2
        return 1
    fi
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --source)
            SOURCE="$2"
            shift 2
            ;;
        --method)
            METHOD="$2"
            if [[ ! "$METHOD" =~ ^(rsync|scp|git)$ ]]; then
                echo "Error: Method must be 'rsync', 'scp', or 'git'" >&2
                exit 1
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
            exit 0
            ;;
        -*)
            echo "Error: Unknown option $1" >&2
            show_help
            exit 1
            ;;
        *)
            TARGET="$1"
            shift
            ;;
    esac
done

if [[ -z "$TARGET" ]]; then
    echo "Error: No target specified" >&2
    show_help
    exit 1
fi

if [[ ! -d "$SOURCE" ]]; then
    echo "Error: Source directory '$SOURCE' does not exist" >&2
    exit 1
fi

# Deploy based on method
case "$METHOD" in
    "rsync")
        deploy_rsync "$SOURCE" "$TARGET"
        ;;
    "scp")
        deploy_scp "$SOURCE" "$TARGET"
        ;;
    "git")
        deploy_git "$SOURCE" "$TARGET"
        ;;
esac