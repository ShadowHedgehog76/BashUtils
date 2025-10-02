#!/usr/bin/env bash
set -euo pipefail

# update.sh — Update BashUtils scripts from GitHub repository
# Downloads latest versions of all scripts except install.sh and README files

REPO_URL="https://github.com/ShadowHedgehog76/BashUtils"
RAW_BASE_URL="https://raw.githubusercontent.com/ShadowHedgehog76/BashUtils/main"
INSTALL_DIR="$HOME/Documents/alias"
LANG_CODE="en"
SHOW_HELP=0
FORCE_UPDATE=false
DRY_RUN=false
BACKUP_OLD=true

# ===== i18n =====
set_lang() {
  case "$LANG_CODE" in
    en)
      MSG_USAGE='Usage:
  update.sh [--force] [--dry-run] [--no-backup] [--dir DIR] [--en|--fr|--jp] [-h|--help]

Update BashUtils scripts from GitHub repository.

Options:
  --force               Force update all files without version checking
  --dry-run             Show what would be updated without doing it
  --no-backup           Do not create backup of existing files
  --dir DIR             Installation directory (default: ~/Documents/alias)
  --en, --fr, --jp      Set language (default: en)
  -h, --help            Show this help

Examples:
  update.sh                    # Update scripts in default directory
  update.sh --force            # Force update all scripts
  update.sh --dry-run          # Preview what would be updated
  update.sh --dir /usr/local/bin --no-backup  # Update in custom dir without backup'
      MSG_UPDATER="BashUtils Updater"
      MSG_UPDATING="Updating BashUtils from GitHub"
      MSG_CHECKING="Checking for updates"
      MSG_DOWNLOADING="Downloading"
      MSG_BACKING_UP="Creating backup"
      MSG_SKIPPING="Skipping"
      MSG_UPDATED="updated successfully"
      MSG_UP_TO_DATE="already up to date"
      MSG_FAILED="Failed to download"
      MSG_COMPLETE="Update complete"
      MSG_DRY_RUN="DRY RUN - Would update"
      MSG_NO_CHANGES="No updates available"
      MSG_BACKUP_CREATED="Backup created"
      ;;
    fr)
      MSG_USAGE='Utilisation :
  update.sh [--force] [--dry-run] [--no-backup] [--dir DIR] [--en|--fr|--jp] [-h|--help]

Mettre à jour les scripts BashUtils depuis le dépôt GitHub.

Options :
  --force               Forcer la mise à jour de tous les fichiers sans vérification de version
  --dry-run             Montrer ce qui serait mis à jour sans le faire
  --no-backup           Ne pas créer de sauvegarde des fichiers existants
  --dir DIR             Répertoire d'installation - défaut: ~/Documents/alias
  --en, --fr, --jp      Définir la langue - défaut: en
  -h, --help            Afficher cette aide

Exemples :
  update.sh                    # Mettre à jour les scripts dans le répertoire par défaut
  update.sh --force            # Forcer la mise à jour de tous les scripts
  update.sh --dry-run          # Aperçu de ce qui serait mis à jour
  update.sh --dir /usr/local/bin --no-backup  # Mise à jour dans un répertoire personnalisé sans sauvegarde'
      MSG_UPDATER="Mise à Jour BashUtils"
      MSG_UPDATING="Mise à jour de BashUtils depuis GitHub"
      MSG_CHECKING="Vérification des mises à jour"
      MSG_DOWNLOADING="Téléchargement"
      MSG_BACKING_UP="Création de sauvegarde"
      MSG_SKIPPING="Ignorer"
      MSG_UPDATED="mis à jour avec succès"
      MSG_UP_TO_DATE="déjà à jour"
      MSG_FAILED="Échec du téléchargement"
      MSG_COMPLETE="Mise à jour terminée"
      MSG_DRY_RUN="SIMULATION - Mettrait à jour"
      MSG_NO_CHANGES="Aucune mise à jour disponible"
      MSG_BACKUP_CREATED="Sauvegarde créée"
      ;;
    jp)
      MSG_USAGE='使い方:
  update.sh [--force] [--dry-run] [--no-backup] [--dir DIR] [--en|--fr|--jp] [-h|--help]

GitHubリポジトリからBashUtilsスクリプトを更新します。

オプション:
  --force               バージョンチェックなしで全ファイルを強制更新
  --dry-run             実際に更新せずに何が更新されるかを表示
  --no-backup           既存ファイルのバックアップを作成しない
  --dir DIR             インストールディレクトリ - デフォルト: ~/Documents/alias
  --en, --fr, --jp      言語を設定 - デフォルト: en
  -h, --help            このヘルプを表示

例:
  update.sh                    # デフォルトディレクトリのスクリプトを更新
  update.sh --force            # 全スクリプトを強制更新
  update.sh --dry-run          # 更新プレビュー
  update.sh --dir /usr/local/bin --no-backup  # カスタムディレクトリでバックアップなし更新'
      MSG_UPDATER="BashUtils更新ツール"
      MSG_UPDATING="GitHubからBashUtilsを更新中"
      MSG_CHECKING="更新チェック中"
      MSG_DOWNLOADING="ダウンロード中"
      MSG_BACKING_UP="バックアップ作成中"
      MSG_SKIPPING="スキップ中"
      MSG_UPDATED="正常に更新されました"
      MSG_UP_TO_DATE="すでに最新版です"
      MSG_FAILED="ダウンロードに失敗"
      MSG_COMPLETE="更新完了"
      MSG_DRY_RUN="ドライラン - 更新予定"
      MSG_NO_CHANGES="更新はありません"
      MSG_BACKUP_CREATED="バックアップが作成されました"
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
    --force) FORCE_UPDATE=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    --no-backup) BACKUP_OLD=false; shift ;;
    --dir)
      [[ $# -lt 2 ]] && { echo "ERROR: --dir requires a directory path" >&2; exit 2; }
      INSTALL_DIR="$2"; shift 2 ;;
    -*) echo "ERROR: Unknown option: $1" >&2; print_usage; exit 2 ;;
    *) echo "ERROR: Unexpected argument: $1" >&2; print_usage; exit 2 ;;
  esac
done

if [[ "${SHOW_HELP:-0}" -eq 1 ]]; then print_usage; exit 0; fi
set_lang

# ===== File list to update =====
# All .sh files except install.sh, and no README files
FILES_TO_UPDATE=(
  "backup.sh"
  "cleanup.sh"
  "deploy.sh"
  "dns.sh"
  "envcheck.sh"
  "gitutils.sh"
  "logs.sh"
  "menu.sh"
  "monitor.sh"
  "network.sh"
  "organize.sh"
  "ports.sh"
  "search.sh"
  "secure.sh"
  "setup-alias.sh"
  "speedtest.sh"
  "sysinfo.sh"
  "update.sh"
  "webcheck.sh"
)

# ===== Helper functions =====
get_file_hash() {
  local file="$1"
  if [[ -f "$file" ]]; then
    if command -v sha256sum >/dev/null 2>&1; then
      sha256sum "$file" | cut -d' ' -f1
    elif command -v shasum >/dev/null 2>&1; then
      shasum -a 256 "$file" | cut -d' ' -f1
    else
      # Fallback to file size and modification time
      stat -c "%s-%Y" "$file" 2>/dev/null || stat -f "%z-%m" "$file" 2>/dev/null || echo "unknown"
    fi
  else
    echo "missing"
  fi
}

create_backup() {
  local file="$1"
  local backup_dir="$INSTALL_DIR/.backup-$(date +%Y%m%d-%H%M%S)"
  
  if [[ "$BACKUP_OLD" == true && -f "$file" ]]; then
    mkdir -p "$backup_dir"
    cp "$file" "$backup_dir/$(basename "$file")"
    echo "💾 $MSG_BACKUP_CREATED: $backup_dir/$(basename "$file")"
  fi
}

update_file() {
  local filename="$1"
  local url="$RAW_BASE_URL/$filename"
  local target_path="$INSTALL_DIR/$filename"
  local temp_file="/tmp/bashutils_${filename}.tmp"
  
  if [[ "$DRY_RUN" == true ]]; then
    echo "  📄 $MSG_DRY_RUN: $filename"
    return 0
  fi
  
  echo -n "  📄 $MSG_CHECKING $filename... "
  
  # Download to temp file first
  if command -v curl >/dev/null 2>&1; then
    if ! curl -fsSL "$url" -o "$temp_file" 2>/dev/null; then
      echo "$MSG_FAILED"
      rm -f "$temp_file"
      return 1
    fi
  elif command -v wget >/dev/null 2>&1; then
    if ! wget -q "$url" -O "$temp_file" 2>/dev/null; then
      echo "$MSG_FAILED"
      rm -f "$temp_file"
      return 1
    fi
  else
    echo "❌ ERROR: Neither curl nor wget is available"
    return 1
  fi
  
  # Compare with existing file
  local old_hash
  local new_hash
  old_hash=$(get_file_hash "$target_path")
  new_hash=$(get_file_hash "$temp_file")
  
  if [[ "$old_hash" == "$new_hash" && "$FORCE_UPDATE" != true ]]; then
    echo "$MSG_UP_TO_DATE"
    rm -f "$temp_file"
    return 0
  fi
  
  # Create backup if file exists
  create_backup "$target_path"
  
  # Move temp file to target
  mv "$temp_file" "$target_path"
  chmod +x "$target_path"
  echo "$MSG_UPDATED"
  return 0
}

check_dependencies() {
  local missing_deps=()
  
  if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
    missing_deps+=("curl or wget")
  fi
  
  if [[ ${#missing_deps[@]} -gt 0 ]]; then
    echo "❌ Missing dependencies:"
    printf "   - %s\n" "${missing_deps[@]}"
    echo
    echo "Please install the missing dependencies and try again."
    return 1
  fi
  
  return 0
}

# ===== Main execution =====
echo "🔄 $MSG_UPDATER" 
printf '%0.s=' {1..50}; echo

set_lang

# Check dependencies
if ! check_dependencies; then
  exit 1
fi

# Check if install directory exists
if [[ ! -d "$INSTALL_DIR" ]]; then
  echo "❌ Installation directory not found: $INSTALL_DIR"
  echo "Run install.sh first or specify correct directory with --dir"
  exit 1
fi

echo "$MSG_UPDATING..."
echo "Repository: $REPO_URL"
echo "Install directory: $INSTALL_DIR"
echo "Files to check: ${#FILES_TO_UPDATE[@]}"
echo

# Update all files
echo "🔍 $MSG_CHECKING..."
failed_updates=0
successful_updates=0
skipped_files=0

for file in "${FILES_TO_UPDATE[@]}"; do
  local target_path="$INSTALL_DIR/$file"
  
  # Skip files that don't exist locally (unless forced)
  if [[ ! -f "$target_path" && "$FORCE_UPDATE" != true ]]; then
    echo "  📄 $MSG_SKIPPING $file (not installed)"
    ((skipped_files++))
    continue
  fi
  
  if update_file "$file"; then
    ((successful_updates++))
  else
    ((failed_updates++))
  fi
done

echo
printf '%0.s=' {1..50}; echo

# Summary
if [[ "$DRY_RUN" == true ]]; then
  echo "📋 $MSG_DRY_RUN Summary:"
  echo "  Would check: ${#FILES_TO_UPDATE[@]} files"
  echo "  Target directory: $INSTALL_DIR"
else
  echo "📊 Update Summary:"
  echo "  ✅ Updated: $successful_updates"
  echo "  ⏭️  Up to date: $((${#FILES_TO_UPDATE[@]} - successful_updates - failed_updates - skipped_files))"
  if [[ $skipped_files -gt 0 ]]; then
    echo "  ⏸️  Skipped: $skipped_files"
  fi
  if [[ $failed_updates -gt 0 ]]; then
    echo "  ❌ Failed: $failed_updates"
  fi
  
  if [[ $successful_updates -gt 0 ]]; then
    echo
    echo "✅ $MSG_COMPLETE!"
    echo
    echo "🚀 Updates applied successfully. You can now use the updated scripts."
    
    # If menu.sh was updated, suggest restarting it
    if [[ -f "$INSTALL_DIR/menu.sh" ]]; then
      echo
      echo "💡 If you're using the menu system, restart it to use the updated version:"
      echo "   cd $INSTALL_DIR && ./menu.sh"
    fi
  elif [[ $successful_updates -eq 0 && $failed_updates -eq 0 ]]; then
    echo
    echo "✅ $MSG_NO_CHANGES - All scripts are up to date!"
  else
    echo "❌ Some updates failed. Please check your internet connection and try again."
    exit 1
  fi
fi