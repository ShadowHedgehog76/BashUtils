#!/bin/bash
set -euo pipefail

# Environment checker
# Checks system environment and installed tools

declare -r SCRIPT_NAME="envcheck"
declare -r VERSION="1.0.0"

CHECK_TYPE="all"
OUTPUT_FORMAT="table"
LANG_SETTING="en"

show_help() {
    echo "Usage: envcheck.sh [OPTIONS]"
    echo ""
    echo "Environment checker for system tools and configuration."
    echo ""
    echo "Options:"
    echo "  --type TYPE       Check type: all, dev, system, network (default: all)"
    echo "  --format FORMAT   Output format: table, json (default: table)"
    echo "  --en, --fr, --jp  Language selection"
    echo "  -h, --help        Show this help"
    echo ""
    echo "Examples:"
    echo "  envcheck.sh"
    echo "  envcheck.sh --type dev --format json"
    echo "  envcheck.sh --type network"
}

check_command() {
    local cmd="$1"
    local description="$2"
    
    if command -v "$cmd" >/dev/null 2>&1; then
        local version=""
        case "$cmd" in
            "git") version=$(git --version 2>/dev/null | head -1) ;;
            "node") version="Node.js $(node --version 2>/dev/null)" ;;
            "python3") version="Python $(python3 --version 2>/dev/null | cut -d' ' -f2)" ;;
            "docker") version=$(docker --version 2>/dev/null | head -1) ;;
            *) version=$(which "$cmd") ;;
        esac
        echo "$cmd|$description|✓ Available|$version"
    else
        echo "$cmd|$description|✗ Missing|"
    fi
}

check_system_tools() {
    echo "# System Tools"
    check_command "bash" "Bash shell"
    check_command "curl" "HTTP client"
    check_command "wget" "File downloader"
    check_command "tar" "Archive utility"
    check_command "gzip" "Compression utility"
    check_command "unzip" "Zip extractor"
    check_command "grep" "Text search"
    check_command "sed" "Stream editor"
    check_command "awk" "Text processing"
    check_command "find" "File finder"
    check_command "sort" "Text sorting"
    check_command "crontab" "Task scheduler"
}

check_dev_tools() {
    echo "# Development Tools"
    check_command "git" "Version control"
    check_command "make" "Build automation"
    check_command "gcc" "C compiler"
    check_command "python3" "Python interpreter"
    check_command "node" "Node.js runtime"
    check_command "npm" "Node package manager"
    check_command "docker" "Containerization"
    check_command "vim" "Text editor"
    check_command "nano" "Simple text editor"
    check_command "code" "VS Code editor"
}

check_network_tools() {
    echo "# Network Tools"
    check_command "ping" "Network connectivity test"
    check_command "curl" "HTTP client"
    check_command "wget" "Web downloader"
    check_command "dig" "DNS lookup"
    check_command "nslookup" "DNS resolution"
    check_command "netstat" "Network statistics"
    check_command "ss" "Socket statistics"
    check_command "nmap" "Network scanner"
    check_command "iptables" "Firewall"
    check_command "ssh" "Secure shell"
}

format_table_output() {
    local category=""
    
    printf "%-15s %-25s %-12s %s\n" "TOOL" "DESCRIPTION" "STATUS" "VERSION/PATH"
    printf "%-15s %-25s %-12s %s\n" "----" "-----------" "------" "-----------"
    
    while IFS='|' read -r tool desc status version; do
        if [[ "$tool" =~ ^# ]]; then
            category="${tool## }"
            echo
            echo "=== $category ==="
            continue
        fi
        
        printf "%-15s %-25s %-12s %s\n" "$tool" "$desc" "$status" "$version"
    done
}

format_json_output() {
    echo "{"
    echo '  "environment_check": {'
    echo '    "timestamp": "'$(date -Iseconds)'",'
    echo '    "categories": {'
    
    local first_category=true
    local category=""
    local first_tool=true
    
    while IFS='|' read -r tool desc status version; do
        if [[ "$tool" =~ ^# ]]; then
            if [[ "$first_category" != "true" ]]; then
                echo
                echo "      ]"
                echo "    },"
            fi
            category="${tool## }"
            echo -n '    "'$(echo "$category" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')'": {'
            echo
            echo '      "name": "'$category'",'
            echo '      "tools": ['
            first_category=false
            first_tool=true
            continue
        fi
        
        if [[ "$first_tool" != "true" ]]; then
            echo ","
        fi
        
        local available="false"
        if [[ "$status" == "✓ Available" ]]; then
            available="true"
        fi
        
        echo -n '        {'
        echo -n '"tool": "'$tool'", '
        echo -n '"description": "'$desc'", '
        echo -n '"available": '$available', '
        echo -n '"version": "'$version'"'
        echo -n '}'
        first_tool=false
    done
    
    echo
    echo "      ]"
    echo "    }"
    echo "  }"
    echo "}"
}

# Main function
main() {
# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --type)
            CHECK_TYPE="$2"
            if [[ ! "$CHECK_TYPE" =~ ^(all|dev|system|network)$ ]]; then
                echo "Error: Check type must be 'all', 'dev', 'system', or 'network'" >&2
                return 1
            fi
            shift 2
            ;;
        --format)
            OUTPUT_FORMAT="$2"
            if [[ ! "$OUTPUT_FORMAT" =~ ^(table|json)$ ]]; then
                echo "Error: Output format must be 'table' or 'json'" >&2
                return 1
            fi
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
        *)
            echo "Error: Unknown option $1" >&2
            show_help
            return 1
            ;;
    esac
done

# Collect check results
results=""

case "$CHECK_TYPE" in
    "all")
        results+=$(check_system_tools)$'\n'
        results+=$(check_dev_tools)$'\n'
        results+=$(check_network_tools)
        ;;
    "system")
        results+=$(check_system_tools)
        ;;
    "dev")
        results+=$(check_dev_tools)
        ;;
    "network")
        results+=$(check_network_tools)
        ;;
esac

# Format and display output
if [[ "$OUTPUT_FORMAT" == "json" ]]; then
    echo "$results" | format_json_output
else
    echo "$results" | format_table_output
fi
}

# Call main function with all arguments
main "$@"