#!/bin/bash
set -euo pipefail

# DNS lookup and testing utility
# Performs DNS queries and network connectivity tests

declare -r SCRIPT_NAME="dns"
declare -r VERSION="1.0.0"

QUERY_TYPE="A"
DNS_SERVER=""
DOMAIN=""
VERBOSE=false
LANG_SETTING="en"

show_help() {
    echo "Usage: dns.sh [OPTIONS] DOMAIN"
    echo ""
    echo "DNS lookup and network connectivity testing utility."
    echo ""
    echo "Options:"
    echo "  --type TYPE       Query type: A, AAAA, MX, NS, TXT, CNAME (default: A)"
    echo "  --server SERVER   DNS server to use (default: system default)"
    echo "  --verbose         Show detailed information"
    echo "  --en, --fr, --jp  Language selection"
    echo "  -h, --help        Show this help"
    echo ""
    echo "Examples:"
    echo "  dns.sh google.com"
    echo "  dns.sh --type MX --server 8.8.8.8 example.com"
    echo "  dns.sh --verbose --type AAAA ipv6.google.com"
}

perform_lookup() {
    local domain="$1"
    local type="$2"
    local server="$3"
    
    echo "=== DNS Lookup: $domain ($type) ==="
    
    local dig_cmd="dig"
    
    if [[ -n "$server" ]]; then
        dig_cmd+=" @$server"
    fi
    
    dig_cmd+=" $domain $type"
    
    if [[ "$VERBOSE" == "true" ]]; then
        echo "Command: $dig_cmd"
        echo
    fi
    
    if command -v dig >/dev/null 2>&1; then
        if [[ "$VERBOSE" == "true" ]]; then
            eval "$dig_cmd"
        else
            eval "$dig_cmd +short"
        fi
    elif command -v nslookup >/dev/null 2>&1; then
        echo "Using nslookup (dig not available):"
        if [[ -n "$server" ]]; then
            nslookup -type="$type" "$domain" "$server"
        else
            nslookup -type="$type" "$domain"
        fi
    else
        echo "Error: Neither dig nor nslookup available" >&2
        return 1
    fi
}

test_connectivity() {
    local domain="$1"
    
    echo
    echo "=== Connectivity Test ==="
    
    # Ping test
    echo "Ping test (4 packets):"
    if ping -c 4 "$domain" 2>/dev/null; then
        echo "Ping: SUCCESS"
    else
        echo "Ping: FAILED"
    fi
    
    echo
    
    # HTTP test if applicable
    if [[ "$domain" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        echo "HTTP connectivity test:"
        if command -v curl >/dev/null 2>&1; then
            if curl -Is "http://$domain" --connect-timeout 5 >/dev/null 2>&1; then
                echo "HTTP: SUCCESS"
            else
                echo "HTTP: FAILED"
            fi
            
            if curl -Is "https://$domain" --connect-timeout 5 >/dev/null 2>&1; then
                echo "HTTPS: SUCCESS"
            else
                echo "HTTPS: FAILED"
            fi
        else
            echo "curl not available for HTTP test"
        fi
    fi
}

show_dns_info() {
    echo "=== DNS Configuration ==="
    
    if [[ -f /etc/resolv.conf ]]; then
        echo "System DNS servers:"
        grep "^nameserver" /etc/resolv.conf | while read -r _ server; do
            echo "  $server"
        done
    fi
    
    echo
    echo "=== Public DNS Servers ==="
    echo "Google DNS:     8.8.8.8, 8.8.4.4"
    echo "Cloudflare DNS: 1.1.1.1, 1.0.0.1"
    echo "Quad9 DNS:      9.9.9.9, 149.112.112.112"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --type)
            QUERY_TYPE="$2"
            if [[ ! "$QUERY_TYPE" =~ ^(A|AAAA|MX|NS|TXT|CNAME|PTR|SOA)$ ]]; then
                echo "Error: Invalid query type: $QUERY_TYPE" >&2
                exit 1
            fi
            shift 2
            ;;
        --server)
            DNS_SERVER="$2"
            shift 2
            ;;
        --verbose)
            VERBOSE=true
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
            DOMAIN="$1"
            shift
            ;;
    esac
done

if [[ -z "$DOMAIN" ]]; then
    show_dns_info
    exit 0
fi

# Perform DNS lookup
perform_lookup "$DOMAIN" "$QUERY_TYPE" "$DNS_SERVER"

# Test connectivity if verbose mode
if [[ "$VERBOSE" == "true" ]]; then
    test_connectivity "$DOMAIN"
fi