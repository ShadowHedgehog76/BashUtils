#!/usr/bin/env bash
set -euo pipefail

# network.sh — detects devices on the same network and filters like search.sh
# Interface mirrors search.sh: modes (simple|eregex|pcre), --name, --exclude, languages (--en/--fr/--jp), -h
# Discovery backends: arp-scan, nmap -sn, ip neigh / arp -a (best-effort)
# Output format: <IP>\t<HOSTNAME>\t<MAC>

MODE="simple"   # simple|eregex|pcre
LANG_CODE="en"  # en|fr|jp
SHOW_HELP=0
INCLUDES=()      # --name globs (match host/ip/mac)
EXCLUDES=()      # --exclude globs (match host/ip/mac)
START_NET=""    # optional subnet override (e.g., 192.168.1.0/24)

# ===== i18n =====
set_lang() {
  case "$LANG_CODE" in
    en)
      MSG_USAGE="Usage:\n  network.sh [ -s | -e | -p ] <pattern_or_glob> [subnet] [--name \"glob\"] [--exclude \"glob\"]...\n\nDetect who is on the same network and filter the results similarly to search.sh.\n\nModes:\n  -s, --simple     Simple fixed-string match (default)\n  -e, --regex      Extended regex (-E)\n  -p, --perl       Perl-compatible regex (-P), if supported\n\nFilters:\n  --name \"glob\"    Include only entries whose host/IP/MAC match the glob (repeatable)\n  --exclude \"glob\" Exclude entries whose host/IP/MAC match the glob (repeatable)\n\nLanguage:\n  --en (default), --fr, --jp\n  -h, --help       Show this help."
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
      MSG_WARN_NO_PCRE="Warning: PCRE (-P) not supported by grep; falling back to extended regex (-E)."
      MSG_SCANNING_WITH="Scanning using"
      ;;
    fr)
      MSG_USAGE="Utilisation :\n  network.sh [ -s | -e | -p ] <motif_ou_glob> [sous-reseau] [--name \"glob\"] [--exclude \"glob\"]...\n\nDétecte qui est connecté au même réseau et filtre les résultats à la manière de search.sh.\n\nModes :\n  -s, --simple     Texte exact (par défaut)\n  -e, --regex      Regex étendues (-E)\n  -p, --perl       Regex Perl (-P), si supporté\n\nFiltres :\n  --name \"glob\"    Inclut uniquement les entrées dont hôte/IP/MAC correspondent au glob (répétable)\n  --exclude \"glob\" Exclut les entrées dont hôte/IP/MAC correspondent au glob (répétable)\n\nLangue :\n  --en (défaut), --fr, --jp\n  -h, --help       Afficher l'aide."
      MSG_FN_SEARCH="Recherche (glob) sur le nom d'hôte pour"
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
      MSG_WARN_NO_PCRE="Attention : PCRE (-P) non pris en charge par grep ; repli sur regex étendues (-E)."
      MSG_SCANNING_WITH="Scan avec"
      ;;
    jp)
      MSG_USAGE="使い方:\n  network.sh [ -s | -e | -p ] <パターン/グロブ> [サブネット] [--name \"glob\"] [--exclude \"glob\"]...\n\n同じネットワーク上の機器を検出し、search.sh と同様にフィルタします。\n\nモード:\n  -s, --simple     固定文字列 (デフォルト)\n  -e, --regex      拡張正規表現 (-E)\n  -p, --perl       Perl互換正規表現 (-P)\n\nフィルタ:\n  --name \"glob\"    ホスト/IP/MAC がグロブに一致するもののみ (繰り返し可)\n  --exclude \"glob\" ホスト/IP/MAC がグロブに一致するものを除外 (繰り返し可)\n\n言語:\n  --en (デフォルト), --fr, --jp\n  -h, --help       このヘルプを表示"
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
      MSG_WARN_NO_PCRE="警告: grep が PCRE (-P) 非対応のため、拡張正規表現 (-E) にフォールバックします。"
      MSG_SCANNING_WITH="使用するスキャナ:"
      ;;
  esac
}

print_usage() { set_lang; printf "%s\n" "$MSG_USAGE"; }

is_glob() { case "$1" in *'*'*|*'?'*|*'['*']'* ) return 0 ;; * ) return 1 ;; esac; }

supports_pcre() { echo "" | grep -P "" >/dev/null 2>&1; }

COLOR_MODE="always"
if [[ -t 1 ]]; then COLOR_MODE="auto"; else COLOR_MODE="never"; fi

# ===== Parse options =====
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
    -*) set_lang; echo "ERROR: $MSG_ERR_UNKNOWN_OPT: $1" >&2; print_usage; exit 2 ;;
    *) ARGS+=("$1"); shift ;;
  esac
done

if [[ "${SHOW_HELP:-0}" -eq 1 ]]; then print_usage; exit 0; fi

[[ ${#ARGS[@]} -lt 1 ]] && { print_usage; exit 2; }
PATTERN_OR_GLOB="${ARGS[0]}"
if [[ ${#ARGS[@]} -ge 2 ]]; then START_NET="${ARGS[1]}"; fi

set_lang

# ===== Helpers =====
normalize_mac() { awk '{print toupper($0)}' | sed 's/-/:/g'; }

field_matches_any_glob() {
  local value="$1"; shift
  local g
  for g in "$@"; do
    [[ -z "$g" ]] && continue
    if [[ $value == $g ]]; then return 0; fi
  done
  return 1
}

line_is_excluded() {
  local line="$1"
  local ip host mac
  ip=${line%%\t*}; rest=${line#*\t}; host=${rest%%\t*}; mac=${line##*\t}
  local v1 v2 v3
  v1=${host:-"-"}; v2=${ip:-"-"}; v3=${mac:-"-"}
  for g in "${EXCLUDES[@]}"; do
    [[ -z "$g" ]] && continue
    if [[ $v1 == $g || $v2 == $g || $v3 == $g ]]; then return 0; fi
  done
  return 1
}

line_passes_includes() {
  # If no includes specified, accept
  [[ ${#INCLUDES[@]} -eq 0 ]] && return 0
  local line="$1"
  local ip host mac
  ip=${line%%\t*}; rest=${line#*\t}; host=${rest%%\t*}; mac=${line##*\t}
  local g
  for g in "${INCLUDES[@]}"; do
    [[ -z "$g" ]] && continue
    if [[ $host == $g || $ip == $g || $mac == $g ]]; then return 0; fi
  done
  return 1
}

emit_unique_sorted() { sort -u; }

# ===== Discovery backends =====
iface_for_default_route() {
  ip route get 1.1.1.1 2>/dev/null | awk '/dev/ {print $5; exit}' || true
}

cidr_guess_from_route() {
  ip -4 route get 1.1.1.1 2>/dev/null | awk '{print $7"/24"; exit}' || true
}

collect_hosts() {
  local out scanner=""

  # 1) arp-scan
  if command -v arp-scan >/dev/null 2>&1; then
    local iface arg ifc
    ifc=$(iface_for_default_route)
    [[ -n "$ifc" ]] && arg=(--interface "$ifc") || arg=()
    if [[ -n "$START_NET" ]]; then
      out=$(arp-scan "${arg[@]}" "$START_NET" 2>/dev/null || true)
    else
      out=$(arp-scan "${arg[@]}" --localnet 2>/dev/null || true)
    fi
    scanner="arp-scan"
    # arp-scan lines: IP\tMAC\tHOST?  (HOST may be vendor; try to resolve name)
    echo "$out" \
    | awk '/([0-9]{1,3}\.){3}[0-9]{1,3}/ {print $1"\t"$3"\t"$2}' \
    | sed -E '/^0\.0\.0\.0/d' \
    | emit_unique_sorted
    echo "# ${MSG_SCANNING_WITH} ${scanner}" >&2
    return
  fi

  # 2) nmap -sn
  if command -v nmap >/dev/null 2>&1; then
    local target="$START_NET"
    [[ -z "$target" ]] && target=$(cidr_guess_from_route)
    if [[ -n "$target" ]]; then
      out=$(nmap -sn "$target" 2>/dev/null || true)
      scanner="nmap -sn"
      # Patterns handled:
      #  - Nmap scan report for example (192.168.1.10)
      #  - Nmap scan report for 192.168.1.10
      #  - MAC Address: XX:XX:XX:XX:XX:XX (Vendor)
      awk -v OFS='\t' '
        /Nmap scan report for / {
          host=""; ip="";
          for (i=5; i<=NF; i++) s=s $i " ";
          sub(/^[ ]+/, "", s); sub(/[ ]+$/, "", s);
          if (match(s, /\(([0-9.]+)\)/, m)) { ip=m[1]; sub(/ \(.*\)/, "", s); host=s; }
          else { ip=$NF; host="-"; }
          pending_ip=ip; pending_host=host; print_pending=1
        }
        /MAC Address:/ {
          mac=$3; gsub(/\(|\)/, "", mac);
          if (print_pending==1) { print pending_ip, (pending_host?pending_host:"-"), mac; print_pending=0 }
          else { print "-", "-", mac }
        }
        END { if (print_pending==1 && pending_ip!="") print pending_ip, (pending_host?pending_host:"-"), "-" }
      ' <<<"$out" | emit_unique_sorted
      echo "# ${MSG_SCANNING_WITH} ${scanner}" >&2
      return
    fi
  fi

  # 3) ip neigh
  if command -v ip >/dev/null 2>&1; then
    scanner="ip neigh"
    ip neigh show | awk -v OFS='\t' '{
      ip=$1; mac="-"; for(i=1;i<=NF;i++) if($i=="lladdr") {mac=$(i+1)}
      print ip, "-", toupper(mac)
    }' | emit_unique_sorted
    echo "# ${MSG_SCANNING_WITH} ${scanner}" >&2
    return
  fi

  # 4) arp -a
  if command -v arp >/dev/null 2>&1; then
    scanner="arp -a"
    arp -a | awk -v OFS='\t' '{gsub(/\(|\)/,"",$2); print $2, $1, toupper($4)}' | emit_unique_sorted
    echo "# ${MSG_SCANNING_WITH} ${scanner}" >&2
    return
  fi

  return 0
}

# ===== Build grep mode =====
case "$MODE" in
  simple) GREP_OPTS=(-F); MODE_LABEL="$MSG_MODE_SIMPLE" ;;
  eregex) GREP_OPTS=(-E); MODE_LABEL="$MSG_MODE_EREGEX" ;;
  pcre)
    if supports_pcre; then GREP_OPTS=(-P); MODE_LABEL="$MSG_MODE_PCRE";
    else echo "$MSG_WARN_NO_PCRE" >&2; GREP_OPTS=(-E); MODE_LABEL="$MSG_MODE_EREGEX"; fi ;;
  *) echo "$MSG_ERR_INTERNAL: unknown mode '$MODE'"; exit 2 ;;
esac

GREP_CMD=(grep -n --color="$COLOR_MODE" "${GREP_OPTS[@]}")

# ===== Run =====
TARGET_LABEL="${START_NET:-local network}"

# If pattern is a glob and there are no --name includes, treat it like a hostname/IP/MAC glob filter
if is_glob "$PATTERN_OR_GLOB" && [[ ${#INCLUDES[@]} -eq 0 ]]; then
  echo "🔎 ${MSG_FN_SEARCH} '$PATTERN_OR_GLOB' ${MSG_IN} '${TARGET_LABEL}'..."
  collect_hosts | while IFS=$'\t' read -r ip host mac; do
    [[ -z "$host" || "$host" == "-" ]] && host="$ip"
    line="$ip\t$host\t$mac"
    line_is_excluded "$line" && continue
    if [[ $host == $PATTERN_OR_GLOB || $ip == $PATTERN_OR_GLOB || $mac == $PATTERN_OR_GLOB ]]; then
      printf "%s\t%s\t%s\n" "$ip" "$host" "$mac"
    fi
  done | emit_unique_sorted
  exit 0
fi

# Otherwise, collect then regex/text-filter across full line
echo "🔎 ${MSG_CONTENT_SEARCH} (${MODE_LABEL}) '${PATTERN_OR_GLOB}' ${MSG_IN} '${TARGET_LABEL}'..."
printf '%0.s=' {1..60}; echo

RESULTS=$(collect_hosts || true)
if [[ -z "${RESULTS}" ]]; then
  echo "${MSG_NO_RESULTS} '${PATTERN_OR_GLOB}'."
  exit 0
fi

FILTERED=$(printf "%s\n" "$RESULTS" | ${GREP_CMD[@]} -- "$PATTERN_OR_GLOB" 2>/dev/null || true)

# Apply --name includes/excludes on top (matching host/ip/mac)
FINAL=$(while IFS=$'\t' read -r ip host mac; do
  [[ -z "$ip" ]] && continue
  line="$ip\t${host:--}\t${mac:--}"
  line_is_excluded "$line" && continue
  line_passes_includes "$line" || continue
  printf "%s\t%s\t%s\n" "$ip" "${host:--}" "${mac:--}"
done <<<"$FILTERED" | emit_unique_sorted)

if [[ -z "$FINAL" ]]; then
  echo "${MSG_NO_RESULTS} '${PATTERN_OR_GLOB}'."
  exit 0
fi

printf "%s\n" "$FINAL"
