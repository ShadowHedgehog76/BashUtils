#!/bin/bash
set -euo pipefail

# Security checker and hardening utility
# Performs basic security checks and suggestions

declare -r SCRIPT_NAME="secure"
declare -r VERSION="1.0.0"

CHECK_TYPE="basic"
OUTPUT_FORMAT="table"
LANG_SETTING="en"

show_help() {
    echo "Usage: secure.sh [OPTIONS]"
    echo ""
    echo "Security checker and system hardening utility."
    echo ""
    echo "Options:"
    echo "  --type TYPE       Check type: basic, network, files (default: basic)"
    echo "  --format FORMAT   Output format: table, json (default: table)"
    echo "  --en, --fr, --jp  Language selection"
    echo "  -h, --help        Show this help"
    echo ""
    echo "Examples:"
    echo "  secure.sh"
    echo "  secure.sh --type network"
    echo "  secure.sh --type files --format json"
}

check_basic_security() {
    echo "# Basic Security Checks"
    
    # Check for root login
    if [[ "$EUID" -eq 0 ]]; then
        echo "ROOT_LOGIN|Running as root user|⚠ WARNING|Avoid running as root"
    else
        echo "ROOT_LOGIN|Running as non-root user|✓ OK|Good security practice"
    fi
    
    # Check SSH configuration
    if [[ -f /etc/ssh/sshd_config ]]; then
        local root_login=$(grep "^PermitRootLogin" /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' || echo "unknown")
        if [[ "$root_login" == "no" ]]; then
            echo "SSH_ROOT|SSH root login disabled|✓ OK|Good security practice"
        elif [[ "$root_login" == "yes" ]]; then
            echo "SSH_ROOT|SSH root login enabled|⚠ WARNING|Consider disabling root SSH login"
        else
            echo "SSH_ROOT|SSH root login status unknown|ℹ INFO|Check /etc/ssh/sshd_config"
        fi
    else
        echo "SSH_CONFIG|SSH config not found|ℹ INFO|SSH may not be installed"
    fi
    
    # Check for automatic updates
    if command -v unattended-upgrades >/dev/null 2>&1; then
        echo "AUTO_UPDATES|Automatic updates configured|✓ OK|System updates automated"
    else
        echo "AUTO_UPDATES|Automatic updates not found|⚠ WARNING|Consider enabling automatic security updates"
    fi
    
    # Check firewall status
    if command -v ufw >/dev/null 2>&1; then
        local ufw_status=$(ufw status 2>/dev/null | head -1 | awk '{print $2}' || echo "unknown")
        if [[ "$ufw_status" == "active" ]]; then
            echo "FIREWALL|UFW firewall active|✓ OK|Firewall protection enabled"
        else
            echo "FIREWALL|UFW firewall inactive|⚠ WARNING|Consider enabling firewall"
        fi
    elif command -v iptables >/dev/null 2>&1; then
        local rules_count=$(iptables -L 2>/dev/null | wc -l || echo "0")
        if [[ "$rules_count" -gt 10 ]]; then
            echo "FIREWALL|iptables rules configured|✓ OK|Firewall rules present"
        else
            echo "FIREWALL|iptables rules minimal|⚠ WARNING|Consider configuring firewall rules"
        fi
    else
        echo "FIREWALL|No firewall tools found|⚠ WARNING|Install and configure a firewall"
    fi
}

check_network_security() {
    echo "# Network Security Checks"
    
    # Check listening ports
    local listening_ports=""
    if command -v ss >/dev/null 2>&1; then
        listening_ports=$(ss -tlnp 2>/dev/null | grep LISTEN | wc -l || echo "0")
    elif command -v netstat >/dev/null 2>&1; then
        listening_ports=$(netstat -tlnp 2>/dev/null | grep LISTEN | wc -l || echo "0")
    else
        listening_ports="unknown"
    fi
    
    if [[ "$listening_ports" != "unknown" ]]; then
        if [[ "$listening_ports" -lt 10 ]]; then
            echo "OPEN_PORTS|$listening_ports listening ports|✓ OK|Minimal exposed services"
        else
            echo "OPEN_PORTS|$listening_ports listening ports|⚠ WARNING|Review exposed services"
        fi
    else
        echo "OPEN_PORTS|Cannot check listening ports|ℹ INFO|Install ss or netstat"
    fi
    
    # Check for common vulnerable services
    local vulnerable_services=("telnet" "ftp" "rsh" "rlogin")
    for service in "${vulnerable_services[@]}"; do
        if systemctl is-active "$service" >/dev/null 2>&1; then
            echo "VULN_SERVICE|$service service active|⚠ WARNING|Consider disabling insecure service"
        fi
    done
}

check_file_security() {
    echo "# File Security Checks"
    
    # Check world-writable files
    local world_writable=$(find /etc /usr /var -type f -perm -002 2>/dev/null | wc -l || echo "0")
    if [[ "$world_writable" -eq 0 ]]; then
        echo "WORLD_WRITE|No world-writable files in system dirs|✓ OK|Good file permissions"
    else
        echo "WORLD_WRITE|$world_writable world-writable files found|⚠ WARNING|Review file permissions"
    fi
    
    # Check SUID files
    local suid_files=$(find /usr /bin /sbin -type f -perm -4000 2>/dev/null | wc -l || echo "0")
    echo "SUID_FILES|$suid_files SUID files found|ℹ INFO|Review SUID binaries regularly"
    
    # Check empty password accounts
    if [[ -r /etc/shadow ]]; then
        local empty_passwords=$(awk -F: '$2 == "" {print $1}' /etc/shadow 2>/dev/null | wc -l || echo "0")
        if [[ "$empty_passwords" -eq 0 ]]; then
            echo "EMPTY_PASS|No accounts with empty passwords|✓ OK|All accounts secured"
        else
            echo "EMPTY_PASS|$empty_passwords accounts with empty passwords|⚠ WARNING|Set passwords for all accounts"
        fi
    else
        echo "EMPTY_PASS|Cannot check password file|ℹ INFO|Insufficient permissions"
    fi
}

format_table_output() {
    printf "%-15s %-35s %-12s %s\n" "CHECK" "DESCRIPTION" "STATUS" "RECOMMENDATION"
    printf "%-15s %-35s %-12s %s\n" "-----" "-----------" "------" "--------------"
    
    while IFS='|' read -r check desc status recommendation; do
        if [[ "$check" =~ ^# ]]; then
            echo
            echo "=== ${check## } ==="
            continue
        fi
        
        printf "%-15s %-35s %-12s %s\n" "$check" "$desc" "$status" "$recommendation"
    done
}

format_json_output() {
    echo "{"
    echo '  "security_check": {'
    echo '    "timestamp": "'$(date -Iseconds)'",'
    echo '    "categories": {'
    
    local first_category=true
    local category=""
    local first_check=true
    
    while IFS='|' read -r check desc status recommendation; do
        if [[ "$check" =~ ^# ]]; then
            if [[ "$first_category" != "true" ]]; then
                echo
                echo "      ]"
                echo "    },"
            fi
            category="${check## }"
            echo -n '    "'$(echo "$category" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')'": {'
            echo
            echo '      "name": "'$category'",'
            echo '      "checks": ['
            first_category=false
            first_check=true
            continue
        fi
        
        if [[ "$first_check" != "true" ]]; then
            echo ","
        fi
        
        echo -n '        {'
        echo -n '"check": "'$check'", '
        echo -n '"description": "'$desc'", '
        echo -n '"status": "'$status'", '
        echo -n '"recommendation": "'$recommendation'"'
        echo -n '}'
        first_check=false
    done
    
    echo
    echo "      ]"
    echo "    }"
    echo "  }"
    echo "}"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --type)
            CHECK_TYPE="$2"
            if [[ ! "$CHECK_TYPE" =~ ^(basic|network|files)$ ]]; then
                echo "Error: Check type must be 'basic', 'network', or 'files'" >&2
                exit 1
            fi
            shift 2
            ;;
        --format)
            OUTPUT_FORMAT="$2"
            if [[ ! "$OUTPUT_FORMAT" =~ ^(table|json)$ ]]; then
                echo "Error: Output format must be 'table' or 'json'" >&2
                exit 1
            fi
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
        *)
            echo "Error: Unknown option $1" >&2
            show_help
            exit 1
            ;;
    esac
done

# Collect check results
results=""

case "$CHECK_TYPE" in
    "basic")
        results+=$(check_basic_security)
        ;;
    "network")
        results+=$(check_network_security)
        ;;
    "files")
        results+=$(check_file_security)
        ;;
esac

# Format and display output
if [[ "$OUTPUT_FORMAT" == "json" ]]; then
    echo "$results" | format_json_output
else
    echo "$results" | format_table_output
fi