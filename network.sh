#!/bin/bash
set -euo pipefail

# network.sh — détecte qui est connecté au même réseau et le filtre comme search.sh
# Interface volontairement identique à search.sh : modes (simple/eregex/pcre), --name, --exclude, langues (--en/--fr/--jp), -h
# Par "même réseau" on tente plusieurs méthodes (arp-scan, nmap -sn, ip neigh / arp -a)

MODE="simple"   # simple|eregex|pcre
LANG_CODE="en"  # en|fr|jp
SHOW_HELP=0
INCLUDES=()
EXCLUDES=()
START_NET=""    # optional subnet override (ex: 192.168.1.0/24)

# i18n
set_lang() {
  case "$LANG_CODE" in
    en)
      MSG_USAGE="Usage:\n  network.sh [ -s | -e | -p ] <pattern_or_glob> [subnet] [--name \"glob\"] [--exclude \"glob\"]\n\nDetect who is on the same network and filter the results similarly to search.sh"
      MSG_FN_SEARCH="Hostname glob search for"
      MSG_CONTENT_SEARCH="Network scan"
      MSG_MODE_SIMPLE="simple"
      MSG_MODE_EREGEX="extended regex"
      MSG_MODE_PCRE="PCRE"
      MSG_IN="in"
      MSG_NO_RESULTS="No results found for"
      MSG_ERR_UNKNOWN_OPT="Unknown option"
      MSG_ERR_NAME_NEEDS_GLOB="ERROR: --name requires a glob"
      MSG_ERR_EXCLUDE_NEEDS_GLOB="ERROR: --exclude requires a glob"
      MSG_ERR_INTERNAL="Internal error"
      ;;
    fr)
      MSG_USAGE="Utilisation:\n  network.sh [ -s | -e | -p ] <motif_ou_glob> [sous-reseau] [--name \"glob\"] [--exclude \"glob\"]\n\nDétecte qui est connecté au même réseau et filtre les résultats à la manière de search.sh"
      MSG_FN_SEARCH="Recherche de nom (glob) pour"
      MSG_CONTENT_SEARCH="Scan réseau"
      MSG_MODE_SIMPLE="simple"
      MSG_MODE_EREGEX="regex étendue"
      MSG_MODE_PCRE="PCRE"
      MSG_IN="dans"
      MSG_NO_RESULTS="Aucun résultat trouvé pour"
      MSG_ERR_UNKNOWN_OPT="Option inconnue"
      MSG_ERR_NAME_NEEDS_GLOB="ERREUR : --name nécessite un glob"
      MSG_ERR_EXCLUDE_NEEDS_GLOB="ERREUR : --exclude nécessite un glob"
      MSG_ERR_INTERNAL="Erreur interne"
      ;;
    jp)
      MSG_USAGE="使い方:\n  network.sh [ -s | -e | -p ] <パターンまたはグロブ> [サブネット] [--name \"glob\"] [--exclude \"glob\"]\n\n同じネットワークに接続されている機器を検出し、search.sh と同じ形式でフィルタします"
      MSG_FN_SEARCH="ホスト名グロブ検索"
      MSG_CONTENT_SEARCH="ネットワークスキャン"
      MSG_MODE_SIMPLE="固定文字列"
      MSG_MODE_EREGEX="拡張正規表現"
      MSG_MODE_PCRE="PCRE"
      MSG_IN="で"
      MSG_NO_RESULTS="該当なし"
      MSG_ERR_UNKNOWN_OPT="不明なオプション"
      MSG_ERR_NAME_NEEDS_GLOB="エラー: --name には glob が必要です"
      MSG_ERR_EXCLUDE_NEEDS_GLOB="エラー: --exclude には glob が必要です"
      MSG_ERR_INTERNAL="内部エラー"
      ;;
    *) LANG_CODE="en"; set_lang ;;
  esac
}

print_usage() { set_lang; printf "%s\n" "$MSG_USAGE"; }

is_glob() {
  case "$1" in *'*'*|*'?'*|*'['*']'* ) return 0 ;; * ) return 1 ;; esac
}

# Parse options
ARGS=()
while (( $# )); do
  case "${1:-}" in
    -h|--help) SHOW_HELP=1; shift ;;
    --en) LANG_CODE="en"; shift ;;
    --fr) LANG_CODE="fr"; shift ;;
    --jp) LANG_CODE="jp"; shift ;;
    -s|--simple) MODE="simple"; shift ;;
    -e|--regex)  MODE="eregex"; shift ;;
    -p|--perl)   MODE="pcre"; shift ;;
    --name)
      [[ $# -lt 2 ]] && { set_lang; echo "$MSG_ERR_NAME_NEEDS_GLOB" >&2; exit 2; }
      INCLUDES+=("$2"); shift 2 ;;
    --exclude)
      [[ $# -lt 2 ]] && { set_lang; echo "$MSG_ERR_EXCLUDE_NEEDS_GLOB" >&2; exit 2; }
      EXCLUDES+=("$2"); shift 2 ;;
    --) shift; while (( $# )); do ARGS+=("$1"); shift; done ;;
    -* ) set_lang; echo "ERROR: $MSG_ERR_UNKNOWN_OPT: $1" >&2; print_usage; exit 2 ;;
    *) ARGS+=("$1"); shift ;;
  esac
done

if [[ "${SHOW_HELP:-0}" -eq 1 ]]; then print_usage; exit 0; fi

[[ ${#ARGS[@]} -lt 1 ]] && { print_usage; exit 2; }
PATTERN_OR_GLOB="${ARGS[0]}"
if [[ ${#ARGS[@]} -ge 2 ]]; then START_NET="${ARGS[1]}"; fi

set_lang

# Discover hosts on the local network using several fallbacks
# Output lines like: <IP>\t<HOSTNAME>\t<MAC>
collect_hosts() {
  local out=""

  # 1) try arp-scan if available
  if command -v arp-scan >/dev/null 2>&1; then
    if [[ -n "$START_NET" ]]; then
      out=$(arp-scan --localnet --interface=$(ip route get 1.1.1.1 2>/dev/null | awk '/dev/ {print $5; exit}') 2>/dev/null || true)
    else
      out=$(arp-scan --localnet 2>/dev/null || true)
    fi
    # arp-scan prints lines with IP\tMAC\tHOST
    echo "$out" | awk '/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/ {print $1"\t"($3? $3: "-")"\t"$2}' | sed '/^0.0.0.0/d'
    return
  fi

  # 2) try nmap -sn (ping scan)
  if command -v nmap >/dev/null 2>&1; then
    local target="$START_NET"
    if [[ -z "$target" ]]; then
      # guess /24 from default route
      target=$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{print $7"/24"; exit}') || true
    fi
    if [[ -n "$target" ]]; then
      out=$(nmap -sn "$target" 2>/dev/null || true)
      # Parse nmap output
      echo "$out" | awk '/Nmap scan report/{ip=$5} /MAC Address:/{mac=$3; $1=$2=$3=""; sub(/^ +/,"",$0); host=$0; print ip"\t"(host?host:"-")"\t"mac} '
      return
    fi
  fi

  # 3) fallback to ip neigh / arp -a
  if command -v ip >/dev/null 2>&1; then
    ip neigh | awk '{print $1"\t-\t"$5}'
    return
  fi
  if command -v arp >/dev/null 2>&1; then
    arp -a | awk '{gsub(/\(|\)/,"",$2); print $2"\t"$1"\t"$4}'
    return
  fi

  # If nothing found, print nothing
  return
}

# Filter helpers
matches_exclude() {
  local hostline="$1"
  for e in "${EXCLUDES[@]}"; do
    # treat exclude as glob against hostname, ip or mac
    host=$(awk -F"\t" '{print $2" "$1" "$3}' <<<"$hostline")
    if [[ $host == $e ]]; then
      return 0
    fi
    # shell globmatch
    if [[ ${host,,} == ${e,,} ]] && [[ "$e" == *"*"* || "$e" == *"?"* || "$e" == *"["* ]]; then
      # attempt glob match against hostname, ip, mac
      name=$(awk -F"\t" '{print $2}' <<<"$hostline")
      ip=$(awk -F"\t" '{print $1}' <<<"$hostline")
      mac=$(awk -F"\t" '{print $3}' <<<"$hostline")
      if [[ $name == $e || $ip == $e || $mac == $e ]]; then
        return 0
      fi
    fi
  done
  return 1
}

# Build grep options for filtering when not using glob filename mode
case "$MODE" in
  simple) GREP_OPTS=(-F) ; MODE_LABEL="$MSG_MODE_SIMPLE" ;;
  eregex) GREP_OPTS=(-E) ; MODE_LABEL="$MSG_MODE_EREGEX" ;;
  pcre)   GREP_OPTS=(-P) ; MODE_LABEL="$MSG_MODE_PCRE" ;;
  *) echo "$MSG_ERR_INTERNAL: unknown mode '$MODE'"; exit 2 ;;
 esac

# If pattern looks like a glob and no --name filters were provided, do hostname glob filtering
if is_glob "$PATTERN_OR_GLOB" && [[ ${#INCLUDES[@]} -eq 0 ]]; then
  echo "🔎 ${MSG_FN_SEARCH} '$PATTERN_OR_GLOB' ${MSG_IN} '${START_NET:-local network}'..."
  # iterate discovered hosts, match hostname against glob
  collect_hosts | while IFS=$'\t' read -r ip host mac; do
    # normalize host if missing
    hostname_to_match="$host"
    # fallback to ip if no hostname
    [[ -z "$hostname_to_match" || "$hostname_to_match" == "-" ]] && hostname_to_match="$ip"
    # check excludes
    if matches_exclude "$ip\t$host\t$mac"; then
      continue
    fi
    if [[ $hostname_to_match == $PATTERN_OR_GLOB ]]; then
      printf "%s\t%s\t%s\n" "$ip" "$host" "$mac"
    fi
  done
  exit 0
fi

# Otherwise: FILTER on the textual representation (IP HOST MAC) using grep
# Build grep arguments
GREP_CMD=(grep -n --color=always)
# mode-specific
case "$MODE" in
  simple) GREP_CMD+=( -F ) ;;
  eregex) GREP_CMD+=( -E ) ;;
  pcre) GREP_CMD+=( -P ) ;;
esac

# include globs (only apply to hostname matching)
# we will post-filter by checking hostname with --name globs if any

echo "🔎 ${MSG_CONTENT_SEARCH} (${MODE_LABEL}) '${PATTERN_OR_GLOB}' ${MSG_IN} '${START_NET:-local network}'..."
echo "============================================================"

# Collect then filter
RESULTS=$(collect_hosts)
if [[ -z "$RESULTS" ]]; then
  echo "${MSG_NO_RESULTS} '${PATTERN_OR_GLOB}'."
  exit 0
fi

# Apply grep filter
# We search pattern against the full line "IP\tHOST\tMAC"
if ! printf "%s\n" "$RESULTS" | ${GREP_CMD[@]} -- "$PATTERN_OR_GLOB" 2>/dev/null; then
  # if no results, exit with message
  echo "${MSG_NO_RESULTS} '${PATTERN_OR_GLOB}'."
  exit 0
fi

# Note: --name and --exclude are best-effort: further filtering can be applied by user
exit 0
