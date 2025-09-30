#!/bin/bash
set -euo pipefail

# search.sh — content & filename search, with simple/regex modes + i18n help
# Languages: --en (default), --fr, --jp
# Help: -h | --help
# Exclusions: --exclude "glob" (repeatable, for both dirs & files)

# ===== Defaults =====
MODE="simple"   # simple|eregex|pcre
START="."
INCLUDES=()     # --include globs
EXCLUDES=()     # --exclude globs
LANG_CODE="en"  # en|fr|jp

# ===== i18n strings =====
set_lang() {
  case "$LANG_CODE" in
    en)
      MSG_USAGE="Usage:
  search.sh [ -s | -e | -p ] <pattern_or_glob> [start_dir] [--name \"glob\"] [--exclude \"glob\"]...

Modes:
  -s, --simple     Simple fixed-string search (default)
  -e, --regex      Extended regex (-E)
  -p, --perl       Perl-compatible regex (-P), if supported

Exclusions:
  --exclude \"glob\"  Exclude files/dirs matching glob (repeatable)

Examples:
  search.sh -s \"WORD\" . --name \"*.go\" --exclude \"vendor/*\"
  search.sh -e \"foo(bar|baz)$\" src --exclude \"*.min.js\"
  search.sh \"ma*.go\"          # filename-only search

Language:
  --en (default), --fr, --jp
  -h, --help        Show this help."
      MSG_FN_SEARCH="Filename search for glob"
      MSG_CONTENT_SEARCH="Content search"
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
      MSG_USAGE="Utilisation :
  search.sh [ -s | -e | -p ] <motif_ou_glob> [répertoire] [--name \"glob\"] [--exclude \"glob\"]...

Modes :
  -s, --simple     Recherche texte exacte (par défaut)
  -e, --regex      Regex étendues (-E)
  -p, --perl       Regex Perl (-P), si supporté

Exclusions :
  --exclude \"glob\"  Exclut fichiers/répertoires correspondant au glob (répétable)

Exemples :
  search.sh -s \"MOT\" . --name \"*.go\" --exclude \"vendor/*\"
  search.sh -e \"foo(bar|baz)$\" src --exclude \"*.min.js\"
  search.sh \"ma*.go\"          # recherche par nom de fichier

Langue :
  --en (défaut), --fr, --jp
  -h, --help        Afficher l'aide."
      MSG_FN_SEARCH="Recherche par nom de fichier pour le glob"
      MSG_CONTENT_SEARCH="Recherche de contenu"
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
      MSG_USAGE="使い方:
  search.sh [ -s | -e | -p ] <パターン/グロブ> [開始ディレクトリ] [--name \"glob\"] [--exclude \"glob\"]...

モード:
  -s, --simple     固定文字列検索 (デフォルト)
  -e, --regex      拡張正規表現 (-E)
  -p, --perl       Perl互換正規表現 (-P)

除外:
  --exclude \"glob\"  グロブに一致するファイル/ディレクトリを除外 (繰り返し可)

例:
  search.sh -s \"WORD\" . --name \"*.go\" --exclude \"vendor/*\"
  search.sh -e \"foo(bar|baz)$\" src --exclude \"*.min.js\"
  search.sh \"ma*.go\"          # ファイル名検索

言語:
  --en (デフォルト), --fr, --jp
  -h, --help        このヘルプを表示"
      MSG_FN_SEARCH="グロブに対するファイル名検索"
      MSG_CONTENT_SEARCH="内容検索"
      MSG_MODE_SIMPLE="固定文字列"
      MSG_MODE_EREGEX="拡張正規表現"
      MSG_MODE_PCRE="PCRE"
      MSG_IN="範囲"
      MSG_NO_RESULTS="該当なし:"
      MSG_ERR_UNKNOWN_OPT="不明なオプション"
      MSG_ERR_NAME_NEEDS_GLOB="エラー: --name には glob が必要です"
      MSG_ERR_EXCLUDE_NEEDS_GLOB="エラー: --exclude には glob が必要です"
      MSG_ERR_INTERNAL="内部エラー"
      ;;
  esac
}

print_usage() { set_lang; printf "%s\n" "$MSG_USAGE"; }

is_glob() {
  case "$1" in *'*'*|*'?'*|*'['*']'* ) return 0 ;; * ) return 1 ;; esac
}

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
    -*)
      set_lang; echo "ERROR: $MSG_ERR_UNKNOWN_OPT: $1" >&2; print_usage; exit 2 ;;
    *) ARGS+=("$1"); shift ;;
  esac
done

# Help
if [[ "${SHOW_HELP:-0}" -eq 1 ]]; then print_usage; exit 0; fi

# Positionals
[[ ${#ARGS[@]} -lt 1 ]] && { print_usage; exit 2; }
PATTERN_OR_GLOB="${ARGS[0]}"
if [[ ${#ARGS[@]} -ge 2 ]]; then START="${ARGS[1]}"; fi

set_lang

# ===== Filename-only search =====
if is_glob "$PATTERN_OR_GLOB" && [[ ${#INCLUDES[@]} -eq 0 ]]; then
  echo "🔎 ${MSG_FN_SEARCH} '$PATTERN_OR_GLOB' ${MSG_IN} '$START'..."
  # Build exclusions for find
  EXC_EXPR=()
  for e in "${EXCLUDES[@]}"; do
    EXC_EXPR+=( -path "$START/$e" -o -name "$e" )
  done
  if [[ ${#EXC_EXPR[@]} -gt 0 ]]; then
    find "$START" \( "${EXC_EXPR[@]}" \) -prune -o -type f -name "$PATTERN_OR_GLOB" -print
  else
    find "$START" -type f -name "$PATTERN_OR_GLOB" -print
  fi
  exit 0
fi

# ===== Content search =====
case "$MODE" in
  simple) GREP_OPTS=(-r -n -F) ; MODE_LABEL="$MSG_MODE_SIMPLE" ;;
  eregex) GREP_OPTS=(-r -n -E) ; MODE_LABEL="$MSG_MODE_EREGEX" ;;
  pcre)   GREP_OPTS=(-r -n -P) ; MODE_LABEL="$MSG_MODE_PCRE" ;;
  *) echo "$MSG_ERR_INTERNAL: unknown mode '$MODE'"; exit 2 ;;
esac

GREP_CMD=(grep "${GREP_OPTS[@]}" --color=always --binary-files=without-match)
for g in "${INCLUDES[@]}"; do GREP_CMD+=(--include="$g"); done
for e in "${EXCLUDES[@]}"; do GREP_CMD+=(--exclude="$e" --exclude-dir="$e"); done
GREP_CMD+=("--" "$PATTERN_OR_GLOB" "$START")

echo "🔎 ${MSG_CONTENT_SEARCH} (${MODE_LABEL}) '${PATTERN_OR_GLOB}' ${MSG_IN} '$START'..."
echo "============================================================"
if ! "${GREP_CMD[@]}" 2>/dev/null; then
  echo "${MSG_NO_RESULTS} '${PATTERN_OR_GLOB}'."
fi
