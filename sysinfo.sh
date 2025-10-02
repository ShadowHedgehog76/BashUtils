#!/usr/bin/env bash
set -euo pipefail

# sysinfo.sh — comprehensive system information dashboard
# Interface mirrors search.sh: modes, languages (--en/--fr/--jp), -h
# Displays CPU, memory, disk, network, and system information

MODE="summary"    # summary|detailed|json
LANG_CODE="en"    # en|fr|jp
SHOW_HELP=0
INCLUDES=()       # specific sections to include
EXCLUDES=()       # specific sections to exclude

# ===== i18n =====
set_lang() {
  case "$LANG_CODE" in
    en)
      MSG_USAGE='Usage:
  sysinfo.sh [ -s | -d | -j ] [--include "section"] [--exclude "section"]...

Display comprehensive system information.

Modes:
  -s, --summary    Summary view (default)
  -d, --detailed   Detailed view with all metrics
  -j, --json       JSON output format

Sections:
  --include "section"  Include specific sections: cpu, memory, disk, network, services, all
  --exclude "section"  Exclude specific sections (repeatable)

Language:
  --en (default), --fr, --jp
  -h, --help       Show this help.'
      MSG_SYSTEM_INFO="System Information"
      MSG_HOSTNAME="Hostname"
      MSG_UPTIME="Uptime"
      MSG_KERNEL="Kernel"
      MSG_CPU_INFO="CPU Information"
      MSG_MEMORY_INFO="Memory Information"
      MSG_DISK_INFO="Disk Information"
      MSG_NETWORK_INFO="Network Information"
      MSG_SERVICES="Running Services"
      MSG_LOAD_AVG="Load Average"
      MSG_TOTAL="Total"
      MSG_USED="Used"
      MSG_FREE="Free"
      MSG_AVAILABLE="Available"
      MSG_MOUNTED_ON="Mounted on"
      MSG_INTERFACE="Interface"
      MSG_IP_ADDRESS="IP Address"
      MSG_STATUS="Status"
      ;;
    fr)
      MSG_USAGE='Utilisation :
  sysinfo.sh [ -s | -d | -j ] [--include "section"] [--exclude "section"]...

Affiche des informations système complètes.

Modes :
  -s, --summary    Vue résumée (défaut)
  -d, --detailed   Vue détaillée avec toutes les métriques
  -j, --json       Format de sortie JSON

Sections :
  --include "section"  Inclure sections spécifiques : cpu, memory, disk, network, services, all
  --exclude "section"  Exclure sections spécifiques (répétable)

Langue :
  --en (défaut), --fr, --jp
  -h, --help       Afficher cette aide.'
      MSG_SYSTEM_INFO="Informations Système"
      MSG_HOSTNAME="Nom d'hôte"
      MSG_UPTIME="Temps de fonctionnement"
      MSG_KERNEL="Noyau"
      MSG_CPU_INFO="Informations CPU"
      MSG_MEMORY_INFO="Informations Mémoire"
      MSG_DISK_INFO="Informations Disque"
      MSG_NETWORK_INFO="Informations Réseau"
      MSG_SERVICES="Services en Cours"
      MSG_LOAD_AVG="Charge Moyenne"
      MSG_TOTAL="Total"
      MSG_USED="Utilisé"
      MSG_FREE="Libre"
      MSG_AVAILABLE="Disponible"
      MSG_MOUNTED_ON="Monté sur"
      MSG_INTERFACE="Interface"
      MSG_IP_ADDRESS="Adresse IP"
      MSG_STATUS="État"
      ;;
    jp)
      MSG_USAGE='使い方:
  sysinfo.sh [ -s | -d | -j ] [--include "セクション"] [--exclude "セクション"]...

包括的なシステム情報を表示します。

モード:
  -s, --summary    要約表示 (デフォルト)
  -d, --detailed   全メトリクスの詳細表示
  -j, --json       JSON出力形式

セクション:
  --include "セクション"  特定セクションを含める: cpu, memory, disk, network, services, all
  --exclude "セクション"  特定セクションを除外 (繰り返し可)

言語:
  --en (デフォルト), --fr, --jp
  -h, --help       このヘルプを表示'
      MSG_SYSTEM_INFO="システム情報"
      MSG_HOSTNAME="ホスト名"
      MSG_UPTIME="稼働時間"
      MSG_KERNEL="カーネル"
      MSG_CPU_INFO="CPU情報"
      MSG_MEMORY_INFO="メモリ情報"
      MSG_DISK_INFO="ディスク情報"
      MSG_NETWORK_INFO="ネットワーク情報"
      MSG_SERVICES="実行中サービス"
      MSG_LOAD_AVG="負荷平均"
      MSG_TOTAL="合計"
      MSG_USED="使用済み"
      MSG_FREE="空き"
      MSG_AVAILABLE="利用可能"
      MSG_MOUNTED_ON="マウント先"
      MSG_INTERFACE="インターフェース"
      MSG_IP_ADDRESS="IPアドレス"
      MSG_STATUS="状態"
      ;;
  esac
}

print_usage() { set_lang; printf "%s\n" "$MSG_USAGE"; }

# ===== Parse options =====
while (( $# )); do
  case "${1:-}" in
    -h|--help) SHOW_HELP=1; shift ;;
    --en) LANG_CODE="en"; shift ;;
    --fr) LANG_CODE="fr"; shift ;;
    --jp) LANG_CODE="jp"; shift ;;
    -s|--summary) MODE="summary"; shift ;;
    -d|--detailed) MODE="detailed"; shift ;;
    -j|--json) MODE="json"; shift ;;
    --include)
      [[ $# -lt 2 ]] && { echo "ERROR: --include requires a section" >&2; exit 2; }
      INCLUDES+=("$2"); shift 2 ;;
    --exclude)
      [[ $# -lt 2 ]] && { echo "ERROR: --exclude requires a section" >&2; exit 2; }
      EXCLUDES+=("$2"); shift 2 ;;
    -*) echo "ERROR: Unknown option: $1" >&2; print_usage; exit 2 ;;
    *) echo "ERROR: Unexpected argument: $1" >&2; print_usage; exit 2 ;;
  esac
done

if [[ "${SHOW_HELP:-0}" -eq 1 ]]; then print_usage; exit 0; fi
set_lang

# ===== Helper functions =====
should_show_section() {
  local section="$1"
  
  # Check excludes first
  for exc in "${EXCLUDES[@]}"; do
    [[ "$exc" == "$section" ]] && return 1
  done
  
  # If includes are specified, only show included sections
  if [[ ${#INCLUDES[@]} -gt 0 ]]; then
    for inc in "${INCLUDES[@]}"; do
      [[ "$inc" == "$section" || "$inc" == "all" ]] && return 0
    done
    return 1
  fi
  
  return 0
}

format_bytes() {
  local bytes=$1
  local units=("B" "KB" "MB" "GB" "TB")
  local unit_index=0
  local size=$bytes
  
  while (( size > 1024 && unit_index < 4 )); do
    size=$((size / 1024))
    ((unit_index++))
  done
  
  printf "%d %s" "$size" "${units[$unit_index]}"
}

# ===== Information gathering functions =====
get_system_info() {
  local hostname uptime kernel
  hostname=$(hostname)
  uptime=$(uptime -p 2>/dev/null || uptime | cut -d',' -f1 | sed 's/.*up *//')
  kernel=$(uname -r)
  
  if [[ "$MODE" == "json" ]]; then
    printf '{"hostname":"%s","uptime":"%s","kernel":"%s"}' "$hostname" "$uptime" "$kernel"
  else
    printf "%-20s %s\n" "$MSG_HOSTNAME:" "$hostname"
    printf "%-20s %s\n" "$MSG_UPTIME:" "$uptime"
    printf "%-20s %s\n" "$MSG_KERNEL:" "$kernel"
  fi
}

get_cpu_info() {
  local cpu_model cores load_avg
  cpu_model=$(grep "model name" /proc/cpuinfo | head -1 | cut -d':' -f2 | sed 's/^ *//')
  cores=$(nproc)
  load_avg=$(uptime | awk -F'load average:' '{print $2}' | sed 's/^ *//')
  
  if [[ "$MODE" == "json" ]]; then
    printf '{"model":"%s","cores":%d,"load_average":"%s"}' "$cpu_model" "$cores" "$load_avg"
  else
    printf "%-20s %s\n" "Model:" "$cpu_model"
    printf "%-20s %d\n" "Cores:" "$cores"
    printf "%-20s %s\n" "$MSG_LOAD_AVG:" "$load_avg"
  fi
}

get_memory_info() {
  local total used free available
  eval "$(free -b | awk '/^Mem:/ {print "total="$2"; used="$3"; free="$4"; available="$7}')"
  
  if [[ "$MODE" == "json" ]]; then
    printf '{"total":%d,"used":%d,"free":%d,"available":%d}' "$total" "$used" "$free" "$available"
  else
    printf "%-20s %s\n" "$MSG_TOTAL:" "$(format_bytes "$total")"
    printf "%-20s %s\n" "$MSG_USED:" "$(format_bytes "$used")"
    printf "%-20s %s\n" "$MSG_FREE:" "$(format_bytes "$free")"
    printf "%-20s %s\n" "$MSG_AVAILABLE:" "$(format_bytes "$available")"
  fi
}

get_disk_info() {
  if [[ "$MODE" == "json" ]]; then
    echo "["
    df -h | awk 'NR>1 {printf "%s{\"filesystem\":\"%s\",\"size\":\"%s\",\"used\":\"%s\",\"available\":\"%s\",\"use_percent\":\"%s\",\"mounted_on\":\"%s\"}", (NR>2?",":""), $1, $2, $3, $4, $5, $6}'
    echo "]"
  else
    printf "%-15s %-8s %-8s %-8s %-6s %s\n" "Filesystem" "Size" "Used" "Avail" "Use%" "$MSG_MOUNTED_ON"
    df -h | tail -n +2
  fi
}

get_network_info() {
  if [[ "$MODE" == "json" ]]; then
    echo "["
    ip -o addr show | awk '{gsub(/\/.*/, "", $4); if($4 != "" && $2 != "lo") printf "%s{\"interface\":\"%s\",\"ip\":\"%s\"}", (NR>1?",":""), $2, $4}'
    echo "]"
  else
    printf "%-15s %s\n" "$MSG_INTERFACE" "$MSG_IP_ADDRESS"
    ip -o addr show | awk '{gsub(/\/.*/, "", $4); if($4 != "" && $2 != "lo") printf "%-15s %s\n", $2, $4}'
  fi
}

get_services_info() {
  local service_count
  service_count=$(systemctl list-units --type=service --state=running --no-pager --no-legend 2>/dev/null | wc -l)
  
  if [[ "$MODE" == "json" ]]; then
    printf '{"running_services":%d}' "$service_count"
  else
    printf "%-20s %d\n" "$MSG_SERVICES:" "$service_count"
    if [[ "$MODE" == "detailed" ]]; then
      systemctl list-units --type=service --state=running --no-pager 2>/dev/null | head -10
    fi
  fi
}

# ===== Main execution =====
echo "💻 $MSG_SYSTEM_INFO"
printf '%0.s=' {1..50}; echo

if [[ "$MODE" == "json" ]]; then
  echo "{"
  
  if should_show_section "system"; then
    echo "  \"system\": $(get_system_info),"
  fi
  
  if should_show_section "cpu"; then
    echo "  \"cpu\": $(get_cpu_info),"
  fi
  
  if should_show_section "memory"; then
    echo "  \"memory\": $(get_memory_info),"
  fi
  
  if should_show_section "disk"; then
    echo "  \"disk\": $(get_disk_info),"
  fi
  
  if should_show_section "network"; then
    echo "  \"network\": $(get_network_info),"
  fi
  
  if should_show_section "services"; then
    echo "  \"services\": $(get_services_info)"
  fi
  
  echo "}"
else
  if should_show_section "system"; then
    get_system_info
    echo
  fi
  
  if should_show_section "cpu"; then
    echo "$MSG_CPU_INFO:"
    get_cpu_info
    echo
  fi
  
  if should_show_section "memory"; then
    echo "$MSG_MEMORY_INFO:"
    get_memory_info
    echo
  fi
  
  if should_show_section "disk"; then
    echo "$MSG_DISK_INFO:"
    get_disk_info
    echo
  fi
  
  if should_show_section "network"; then
    echo "$MSG_NETWORK_INFO:"
    get_network_info
    echo
  fi
  
  if should_show_section "services"; then
    get_services_info
    echo
  fi
fi