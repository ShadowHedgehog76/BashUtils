#!/bin/bash
set -euo pipefail

# Website checker and monitoring utility
# Checks website availability, response times, and basic metrics

declare -r SCRIPT_NAME="webcheck"
declare -r VERSION="1.0.0"

URL=""
TIMEOUT=10
FOLLOW_REDIRECTS=true
CHECK_SSL=true
OUTPUT_FORMAT="simple"
LANG_SETTING="en"

show_help() {
    echo "Usage: webcheck.sh [OPTIONS] URL"
    echo ""
    echo "Website checker and monitoring utility."
    echo ""
    echo "Options:"
    echo "  --timeout N       Connection timeout in seconds (default: 10)"
    echo "  --no-redirects    Don't follow HTTP redirects"
    echo "  --no-ssl-check    Skip SSL certificate validation"
    echo "  --format FORMAT   Output format: simple, detailed, json (default: simple)"
    echo "  --en, --fr, --jp  Language selection"
    echo "  -h, --help        Show this help"
    echo ""
    echo "Examples:"
    echo "  webcheck.sh https://www.google.com"
    echo "  webcheck.sh --format detailed --timeout 5 https://example.com"
    echo "  webcheck.sh --format json --no-ssl-check http://localhost:8080"
}

# Check website availability and get basic metrics
check_website() {
    local url="$1"
    local curl_opts=(-s -w '%{http_code}|%{time_total}|%{size_download}|%{speed_download}|%{url_effective}')
    
    # Configure curl options
    curl_opts+=(--connect-timeout "$TIMEOUT")
    
    if [[ "$FOLLOW_REDIRECTS" == "true" ]]; then
        curl_opts+=(-L)
    fi
    
    if [[ "$CHECK_SSL" == "false" ]]; then
        curl_opts+=(-k)
    fi
    
    # Perform the request
    local result
    result=$(curl "${curl_opts[@]}" -o /dev/null "$url" 2>/dev/null || echo "000|0|0|0|$url")
    
    echo "$result"
}

# Get SSL certificate information
check_ssl_cert() {
    local url="$1"
    local hostname
    
    # Extract hostname from URL
    hostname=$(echo "$url" | sed -E 's|^https?://([^/]+).*|\1|')
    
    if [[ "$url" =~ ^https:// ]]; then
        if command -v openssl >/dev/null 2>&1; then
            local cert_info
            cert_info=$(echo | openssl s_client -servername "$hostname" -connect "$hostname:443" 2>/dev/null | openssl x509 -noout -dates 2>/dev/null)
            echo "$cert_info"
        else
            echo "openssl not available"
        fi
    else
        echo "not-https"
    fi
}

# Simple website check
simple_check() {
    local url="$1"
    
    echo "Checking: $url"
    
    local result
    result=$(check_website "$url")
    
    IFS='|' read -r http_code time_total size_download speed_download final_url <<< "$result"
    
    # Convert speed from bytes/sec to KB/sec
    local speed_kb
    if (( $(echo "$speed_download > 0" | bc -l 2>/dev/null || echo "0") )); then
        speed_kb=$(echo "scale=2; $speed_download / 1024" | bc -l 2>/dev/null || echo "0")
    else
        speed_kb="0"
    fi
    
    echo
    echo "Status Code: $http_code"
    echo "Response Time: ${time_total}s"
    echo "Download Size: ${size_download} bytes"
    echo "Download Speed: ${speed_kb} KB/s"
    
    if [[ "$final_url" != "$url" ]]; then
        echo "Redirected to: $final_url"
    fi
    
    # Status assessment
    case "$http_code" in
        200) echo "Status: OK" ;;
        3*) echo "Status: Redirect" ;;
        4*) echo "Status: Client Error" ;;
        5*) echo "Status: Server Error" ;;
        000) echo "Status: Connection Failed" ;;
        *) echo "Status: Unknown" ;;
    esac
}

# Detailed website check
detailed_check() {
    local url="$1"
    
    echo "=== Detailed Website Check ==="
    echo "URL: $url"
    echo "Timestamp: $(date)"
    echo
    
    # Basic check
    local result
    result=$(check_website "$url")
    
    IFS='|' read -r http_code time_total size_download speed_download final_url <<< "$result"
    
    echo "=== HTTP Response ==="
    echo "Status Code: $http_code"
    echo "Response Time: ${time_total}s"
    echo "Content Size: ${size_download} bytes"
    echo "Transfer Speed: $(echo "scale=2; $speed_download / 1024" | bc -l 2>/dev/null || echo "0") KB/s"
    
    if [[ "$final_url" != "$url" ]]; then
        echo "Final URL: $final_url"
    fi
    
    echo
    echo "=== SSL Certificate ==="
    local ssl_info
    ssl_info=$(check_ssl_cert "$url")
    
    if [[ "$ssl_info" == "not-https" ]]; then
        echo "Not using HTTPS"
    elif [[ "$ssl_info" == "openssl not available" ]]; then
        echo "Cannot check SSL (openssl not available)"
    else
        echo "$ssl_info"
    fi
    
    echo
    echo "=== DNS Resolution ==="
    local hostname
    hostname=$(echo "$url" | sed -E 's|^https?://([^/]+).*|\1|')
    
    if command -v nslookup >/dev/null 2>&1; then
        nslookup "$hostname" | grep -A 10 "Name:" || echo "DNS lookup failed"
    else
        echo "nslookup not available"
    fi
}

# JSON output format
json_check() {
    local url="$1"
    
    local result
    result=$(check_website "$url")
    
    IFS='|' read -r http_code time_total size_download speed_download final_url <<< "$result"
    
    local ssl_info
    ssl_info=$(check_ssl_cert "$url")
    
    cat << EOF
{
  "webcheck": {
    "timestamp": "$(date -Iseconds)",
    "url": "$url",
    "final_url": "$final_url",
    "http_status_code": $http_code,
    "response_time_seconds": $time_total,
    "content_size_bytes": $size_download,
    "transfer_speed_bytes_per_sec": $speed_download,
    "ssl_enabled": $(if [[ "$url" =~ ^https:// ]]; then echo "true"; else echo "false"; fi),
    "ssl_certificate": "$(echo "$ssl_info" | tr '\n' ' ')",
    "status": "$(
      case "$http_code" in
        200) echo "ok" ;;
        3*) echo "redirect" ;;
        4*) echo "client_error" ;;
        5*) echo "server_error" ;;
        000) echo "connection_failed" ;;
        *) echo "unknown" ;;
      esac
    )"
  }
}
EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --timeout)
            TIMEOUT="$2"
            if ! [[ "$TIMEOUT" =~ ^[0-9]+$ ]] || [[ "$TIMEOUT" -lt 1 ]]; then
                echo "Error: Timeout must be a positive integer" >&2
                return 1
            fi
            shift 2
            ;;
        --no-redirects)
            FOLLOW_REDIRECTS=false
            shift
            ;;
        --no-ssl-check)
            CHECK_SSL=false
            shift
            ;;
        --format)
            OUTPUT_FORMAT="$2"
            if [[ ! "$OUTPUT_FORMAT" =~ ^(simple|detailed|json)$ ]]; then
                echo "Error: Output format must be 'simple', 'detailed', or 'json'" >&2
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
        -*)
            echo "Error: Unknown option $1" >&2
            show_help
            return 1
            ;;
        *)
            URL="$1"
            shift
            ;;
    esac
done

if [[ -z "$URL" ]]; then
    echo "Error: No URL specified" >&2
    show_help
    return 1
fi

# Validate URL format
if [[ ! "$URL" =~ ^https?:// ]]; then
    echo "Error: URL must start with http:// or https://" >&2
    return 1
fi

# Check dependencies
if ! command -v curl >/dev/null 2>&1; then
    echo "Error: curl is required for website checking" >&2
    return 1
fi

# Run check based on format
case "$OUTPUT_FORMAT" in
    "simple")
        simple_check "$URL"
        ;;
    "detailed")
        detailed_check "$URL"
        ;;
    "json")
        json_check "$URL"
        ;;
esac