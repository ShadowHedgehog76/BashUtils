#!/bin/bash
set -euo pipefail

# Network speed test utility
# Tests internet connection speed and latency

declare -r SCRIPT_NAME="speedtest"
declare -r VERSION="1.0.0"

TEST_SERVER=""
OUTPUT_FORMAT="simple"
LANG_SETTING="en"

show_help() {
    echo "Usage: speedtest.sh [OPTIONS]"
    echo ""
    echo "Network speed test utility for internet connection testing."
    echo ""
    echo "Options:"
    echo "  --server URL      Test server URL (default: auto-select)"
    echo "  --format FORMAT   Output format: simple, detailed, json (default: simple)"
    echo "  --en, --fr, --jp  Language selection"
    echo "  -h, --help        Show this help"  
    echo ""
    echo "Examples:"
    echo "  speedtest.sh"
    echo "  speedtest.sh --format detailed"
    echo "  speedtest.sh --format json"
}

# Test download speed using curl
test_download_speed() {
    local test_url="$1"
    local test_file="speedtest_$$"
    local start_time end_time duration size_bytes speed_mbps
    
    echo "Testing download speed..." >&2
    
    start_time=$(date +%s.%N)
    
    if curl -s -o "$test_file" "$test_url" 2>/dev/null; then
        end_time=$(date +%s.%N)
        size_bytes=$(stat -c%s "$test_file" 2>/dev/null || stat -f%z "$test_file" 2>/dev/null || echo "0")
        rm -f "$test_file"
        
        duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "1")
        
        if (( $(echo "$duration > 0" | bc -l 2>/dev/null || echo "1") )); then
            # Convert to Mbps (Megabits per second)
            speed_mbps=$(echo "scale=2; ($size_bytes * 8) / ($duration * 1000000)" | bc -l 2>/dev/null || echo "0")
            echo "$speed_mbps"
        else
            echo "0"
        fi
    else
        echo "0"
    fi
}

# Test latency using ping
test_latency() {
    local target="$1"
    
    echo "Testing latency..." >&2
    
    if command -v ping >/dev/null 2>&1; then
        # Try to extract average latency from ping
        local ping_result
        ping_result=$(ping -c 4 "$target" 2>/dev/null | tail -1 | awk -F '/' '{print $5}' 2>/dev/null || echo "0")
        echo "${ping_result:-0}"
    else
        echo "0"
    fi
}

# Simple speed test using common methods
simple_speed_test() {
    echo "Starting network speed test..."
    echo
    
    # Test URLs (small to large files)
    local test_urls=(
        "http://speedtest.tele2.net/1MB.zip"
        "http://speedtest.tele2.net/10MB.zip"
    )
    
    local best_speed="0"
    local test_url=""
    
    for url in "${test_urls[@]}"; do
        echo "Testing with: $(basename "$url")"
        local speed=$(test_download_speed "$url")
        
        if (( $(echo "$speed > $best_speed" | bc -l 2>/dev/null || echo "0") )); then
            best_speed="$speed"
            test_url="$url"
        fi
    done
    
    # Test latency
    local latency=$(test_latency "8.8.8.8")
    
    echo
    echo "=== Speed Test Results ==="
    echo "Download Speed: ${best_speed} Mbps"
    echo "Latency (ping): ${latency} ms"
    
    # Basic speed assessment
    if (( $(echo "$best_speed > 25" | bc -l 2>/dev/null || echo "0") )); then
        echo "Connection Quality: Excellent"
    elif (( $(echo "$best_speed > 10" | bc -l 2>/dev/null || echo "0") )); then
        echo "Connection Quality: Good"
    elif (( $(echo "$best_speed > 5" | bc -l 2>/dev/null || echo "0") )); then
        echo "Connection Quality: Fair"
    else
        echo "Connection Quality: Poor"
    fi
}

# Detailed network information
detailed_speed_test() {
    echo "=== Detailed Network Speed Test ==="
    echo
    
    # Network interface information
    echo "Network Interfaces:"
    if command -v ip >/dev/null 2>&1; then
        ip addr show | grep -A 2 "state UP" | grep -E "(inet |^\d+:)" | while read -r line; do
            echo "  $line"
        done
    else
        echo "  ip command not available"
    fi
    echo
    
    # DNS resolution test
    echo "DNS Resolution Test:"
    local dns_start dns_end dns_time
    dns_start=$(date +%s.%N)
    if nslookup google.com >/dev/null 2>&1; then
        dns_end=$(date +%s.%N)
        dns_time=$(echo "scale=3; ($dns_end - $dns_start) * 1000" | bc -l 2>/dev/null || echo "unknown")
        echo "  DNS Lookup Time: ${dns_time} ms"
    else
        echo "  DNS Lookup: Failed"
    fi
    echo
    
    # Run simple speed test
    simple_speed_test
}

# JSON output format
json_speed_test() {
    local test_urls=(
        "http://speedtest.tele2.net/1MB.zip"
        "http://speedtest.tele2.net/10MB.zip"
    )
    
    local best_speed="0"
    for url in "${test_urls[@]}"; do
        local speed=$(test_download_speed "$url")
        if (( $(echo "$speed > $best_speed" | bc -l 2>/dev/null || echo "0") )); then
            best_speed="$speed"
        fi
    done
    
    local latency=$(test_latency "8.8.8.8")
    
    cat << EOF
{
  "speedtest": {
    "timestamp": "$(date -Iseconds)",
    "download_speed_mbps": $best_speed,
    "latency_ms": $latency,
    "test_server": "speedtest.tele2.net",
    "quality_assessment": "$(
      if (( $(echo "$best_speed > 25" | bc -l 2>/dev/null || echo "0") )); then
        echo "excellent"
      elif (( $(echo "$best_speed > 10" | bc -l 2>/dev/null || echo "0") )); then
        echo "good"
      elif (( $(echo "$best_speed > 5" | bc -l 2>/dev/null || echo "0") )); then
        echo "fair"
      else
        echo "poor"
      fi
    )"
  }
}
EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --server)
            TEST_SERVER="$2"
            shift 2
            ;;
        --format)
            OUTPUT_FORMAT="$2"
            if [[ ! "$OUTPUT_FORMAT" =~ ^(simple|detailed|json)$ ]]; then
                echo "Error: Output format must be 'simple', 'detailed', or 'json'" >&2
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

# Check dependencies
if ! command -v curl >/dev/null 2>&1; then
    echo "Error: curl is required for speed testing" >&2
    exit 1
fi

# Run speed test based on format
case "$OUTPUT_FORMAT" in
    "simple")
        simple_speed_test
        ;;
    "detailed")
        detailed_speed_test
        ;;
    "json")
        json_speed_test
        ;;
esac