#!/bin/bash
set -euo pipefail

# Network port scanner and service detector
# Scans for open ports and identifies running services

declare -r SCRIPT_NAME="ports"
declare -r VERSION="1.0.0"

# Default values
TARGET="localhost"
PORT_RANGE="1-1000"
SCAN_TYPE="tcp"
OUTPUT_FORMAT="table"
TIMEOUT=3
SHOW_CLOSED=false
LANG_SETTING="en"

# Help messages
declare -A MSG_USAGE=(
    ["en"]="Usage:
  ports.sh [--target HOST] [--range RANGE] [--type TYPE] [--format FORMAT]
           [--timeout N] [--show-closed] [--en|--fr|--jp] [-h|--help]

Network port scanner and service detector.

Options:
  --target HOST        Target host to scan (default: localhost)
  --range RANGE        Port range to scan (default: 1-1000)
  --type TYPE          Scan type: tcp, udp, both (default: tcp)
  --format FORMAT      Output format: table, json, csv (default: table)
  --timeout N          Connection timeout in seconds (default: 3)
  --show-closed        Show closed ports as well
  --en, --fr, --jp     Language selection
  -h, --help           Show this help

Examples:
  ports.sh                                # Scan localhost TCP ports 1-1000
  ports.sh --target 192.168.1.1          # Scan specific host
  ports.sh --range 80,443,8080           # Scan specific ports
  ports.sh --range 1-65535 --type both   # Full port scan"

    ["fr"]="Usage:
  ports.sh [--target HOST] [--range RANGE] [--type TYPE]

Scanner de ports réseau et détecteur de services.

Options:
  --target HOST        Hôte cible à scanner (défaut: localhost)
  --range RANGE        Plage de ports à scanner (défaut: 1-1000)
  --type TYPE          Type de scan: tcp, udp, both (défaut: tcp)
  --timeout N          Délai d'attente en secondes (défaut: 3)
  --en, --fr, --jp     Sélection de langue
  -h, --help           Afficher cette aide"

    ["jp"]="Usage:
  ports.sh [--target HOST] [--range RANGE] [--type TYPE]

ネットワークポートスキャナーとサービス検出器。

オプション:
  --target HOST        スキャン対象ホスト（デフォルト: localhost）
  --range RANGE        スキャンするポート範囲（デフォルト: 1-1000）
  --type TYPE          スキャンタイプ: tcp, udp, both（デフォルト: tcp）
  --timeout N          接続タイムアウト（秒）（デフォルト: 3）
  --en, --fr, --jp     言語選択
  -h, --help           このヘルプを表示"
)

show_help() {
    echo "${MSG_USAGE[$LANG_SETTING]}" >&2
}

# Check if a TCP port is open
check_tcp_port() {
    local host="$1"
    local port="$2"
    local timeout="$3"
    
    if timeout "$timeout" bash -c "echo >/dev/tcp/$host/$port" 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Get service name for a port
get_service_name() {
    local port="$1"
    local protocol="$2"
    
    # Try /etc/services first
    if [[ -f /etc/services ]]; then
        local service
        service=$(grep "^[^#]*[[:space:]]${port}/${protocol}" /etc/services | head -1 | awk '{print $1}')
        if [[ -n "$service" ]]; then
            echo "$service"
            return
        fi
    fi
    
    # Common services fallback
    case "$port" in
        22) echo "ssh" ;;
        23) echo "telnet" ;;
        25) echo "smtp" ;;
        53) echo "dns" ;;
        80) echo "http" ;;
        110) echo "pop3" ;;
        143) echo "imap" ;;
        443) echo "https" ;;
        993) echo "imaps" ;;
        995) echo "pop3s" ;;
        3306) echo "mysql" ;;
        5432) echo "postgresql" ;;
        6379) echo "redis" ;;
        8080) echo "http-alt" ;;
        *) echo "unknown" ;;
    esac
}

# Parse port range specification
parse_port_range() {
    local range="$1"
    local ports=()
    
    # Handle comma-separated ports
    IFS=',' read -ra ADDR <<< "$range"
    for i in "${ADDR[@]}"; do
        if [[ "$i" =~ ^([0-9]+)-([0-9]+)$ ]]; then
            # Range format: start-end
            local start="${BASH_REMATCH[1]}"
            local end="${BASH_REMATCH[2]}"
            for ((port=start; port<=end; port++)); do
                ports+=("$port")
            done
        elif [[ "$i" =~ ^[0-9]+$ ]]; then
            # Single port
            ports+=("$i")
        else
            echo "Error: Invalid port specification: $i" >&2
            exit 1
        fi
    done
    
    printf '%s\n' "${ports[@]}"
}

# Scan ports
scan_ports() {
    local host="$1"
    local ports_array=("${@:2}")
    local results=()
    
    echo "Scanning $host..." >&2
    
    for port in "${ports_array[@]}"; do
        local status="closed"
        local service="unknown"
        
        if [[ "$SCAN_TYPE" == "tcp" ]] || [[ "$SCAN_TYPE" == "both" ]]; then
            if check_tcp_port "$host" "$port" "$TIMEOUT"; then
                status="open"
                service=$(get_service_name "$port" "tcp")
            fi
        fi
        
        # UDP scanning is more complex and requires root privileges
        # For now, we'll skip it or use a simple approach
        
        if [[ "$status" == "open" ]] || [[ "$SHOW_CLOSED" == "true" ]]; then
            results+=("$port:$status:$service")
        fi
    done
    
    printf '%s\n' "${results[@]}"
}

# Format output
format_output() {
    local results=("$@")
    
    case "$OUTPUT_FORMAT" in
        "table")
            printf "%-8s %-8s %-15s\n" "PORT" "STATUS" "SERVICE"
            printf "%-8s %-8s %-15s\n" "----" "------" "-------"
            for result in "${results[@]}"; do
                IFS=':' read -r port status service <<< "$result"
                printf "%-8s %-8s %-15s\n" "$port" "$status" "$service"
            done
            ;;
        "json")
            echo "{"
            echo '  "target": "'$TARGET'",'
            echo '  "scan_type": "'$SCAN_TYPE'",'
            echo '  "results": ['
            local first=true
            for result in "${results[@]}"; do
                IFS=':' read -r port status service <<< "$result"
                if [[ "$first" == "true" ]]; then
                    first=false
                else
                    echo ","
                fi
                echo -n '    {"port": '$port', "status": "'$status'", "service": "'$service'"}'
            done
            echo ""
            echo "  ]"
            echo "}"
            ;;
        "csv")
            echo "Port,Status,Service"
            for result in "${results[@]}"; do
                IFS=':' read -r port status service <<< "$result"
                echo "$port,$status,$service"
            done
            ;;
    esac
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --target)
            TARGET="$2"
            shift 2
            ;;
        --range)
            PORT_RANGE="$2"
            shift 2
            ;;
        --type)
            SCAN_TYPE="$2"
            if [[ ! "$SCAN_TYPE" =~ ^(tcp|udp|both)$ ]]; then
                echo "Error: Scan type must be 'tcp', 'udp', or 'both'" >&2
                exit 1
            fi
            shift 2
            ;;
        --format)
            OUTPUT_FORMAT="$2"
            if [[ ! "$OUTPUT_FORMAT" =~ ^(table|json|csv)$ ]]; then
                echo "Error: Output format must be 'table', 'json', or 'csv'" >&2
                exit 1
            fi
            shift 2
            ;;
        --timeout)
            TIMEOUT="$2"
            if ! [[ "$TIMEOUT" =~ ^[0-9]+$ ]] || [[ "$TIMEOUT" -lt 1 ]]; then
                echo "Error: Timeout must be a positive integer" >&2
                exit 1
            fi
            shift 2
            ;;
        --show-closed)
            SHOW_CLOSED=true
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

# Parse port range and scan
mapfile -t ports_to_scan < <(parse_port_range "$PORT_RANGE")
mapfile -t scan_results < <(scan_ports "$TARGET" "${ports_to_scan[@]}")

# Format and display results
if [[ ${#scan_results[@]} -gt 0 ]]; then
    format_output "${scan_results[@]}"
else
    echo "No open ports found in the specified range." >&2
fi