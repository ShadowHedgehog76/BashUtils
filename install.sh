#!/usr/bin/env bash
set -euo pipefail

# install.sh — Install BashUtils from GitHub repository
# Downloads all scripts except install.sh itself and README files

REPO_URL="https://github.com/ShadowHedgehog76/BashUtils"
RAW_BASE_URL="https://raw.githubusercontent.com/ShadowHedgehog76/BashUtils/main"
INSTALL_DIR="$HOME/Documents/alias"
LANG_CODE="en"
SHOW_HELP=0
FORCE_INSTALL=false
DRY_RUN=false

# ===== i18n =====
set_lang() {
  case "$LANG_CODE" in
    en)
      MSG_USAGE='Usage:
  install.sh [--force] [--dry-run] [--dir DIR] [--en|--fr|--jp] [-h|--help]

Install BashUtils scripts from GitHub repository.

Options:
  --force               Overwrite existing files without prompting
  --dry-run             Show what would be installed without doing it
  --dir DIR             Installation directory (default: ~/Documents/alias)
  --en, --fr, --jp      Set language (default: en)
  -h, --help            Show this help

Examples:
  install.sh                           # Install to default directory
  install.sh --dir /usr/local/bin      # Install to custom directory
  install.sh --force --dry-run         # Preview forced installation'
      MSG_INSTALLER="BashUtils Installer"
      MSG_INSTALLING="Installing BashUtils from GitHub"
      MSG_CHECKING="Checking"
      MSG_DOWNLOADING="Downloading"
      MSG_CREATING_DIR="Creating directory"
      MSG_SKIPPING="Skipping"
      MSG_OVERWRITING="Overwriting"
      MSG_INSTALLED="installed successfully"
      MSG_ALREADY_EXISTS="already exists"
      MSG_FAILED="Failed to download"
      MSG_COMPLETE="Installation complete"
      MSG_SETUP_ALIAS="Setting up alias"
      MSG_DRY_RUN="DRY RUN - Would install"
      MSG_FILES_TO_INSTALL="files to install"
      ;;
    fr)
      MSG_USAGE='Utilisation :
  install.sh [--force] [--dry-run] [--dir DIR] [--en|--fr|--jp] [-h|--help]

Installer les scripts BashUtils depuis le dépôt GitHub.

Options :
  --force               Écraser les fichiers existants sans demander
  --dry-run             Montrer ce qui serait installé sans le faire
  --dir DIR             Répertoire d'installation - défaut: ~/Documents/alias
  --en, --fr, --jp      Définir la langue - défaut: en
  -h, --help            Afficher cette aide

Exemples :
  install.sh                           # Installer dans le répertoire par défaut
  install.sh --dir /usr/local/bin      # Installer dans un répertoire personnalisé
  install.sh --force --dry-run         # Aperçu de l'installation forcée'
      MSG_INSTALLER="Installateur BashUtils"
      MSG_INSTALLING="Installation de BashUtils depuis GitHub"
      MSG_CHECKING="Vérification"
      MSG_DOWNLOADING="Téléchargement"
      MSG_CREATING_DIR="Création du répertoire"
      MSG_SKIPPING="Ignorer"
      MSG_OVERWRITING="Écrasement"
      MSG_INSTALLED="installé avec succès"
      MSG_ALREADY_EXISTS="existe déjà"
      MSG_FAILED="Échec du téléchargement"
      MSG_COMPLETE="Installation terminée"
      MSG_SETUP_ALIAS="Configuration de l'alias"
      MSG_DRY_RUN="SIMULATION - Installerait"
      MSG_FILES_TO_INSTALL="fichiers à installer"
      ;;
    jp)
      MSG_USAGE='使い方:
  install.sh [--force] [--dry-run] [--dir DIR] [--en|--fr|--jp] [-h|--help]

GitHubリポジトリからBashUtilsスクリプトをインストールします。

オプション:
  --force               既存ファイルを確認なしで上書き
  --dry-run             実際にインストールせずに何がインストールされるかを表示
  --dir DIR             インストールディレクトリ - デフォルト: ~/Documents/alias
  --en, --fr, --jp      言語を設定 - デフォルト: en
  -h, --help            このヘルプを表示

例:
  install.sh                           # デフォルトディレクトリにインストール
  install.sh --dir /usr/local/bin      # カスタムディレクトリにインストール
  install.sh --force --dry-run         # 強制インストールのプレビュー'
      MSG_INSTALLER="BashUtilsインストーラー"
      MSG_INSTALLING="GitHubからBashUtilsをインストール中"
      MSG_CHECKING="チェック中"
      MSG_DOWNLOADING="ダウンロード中"
      MSG_CREATING_DIR="ディレクトリ作成中"
      MSG_SKIPPING="スキップ中"
      MSG_OVERWRITING="上書き中"
      MSG_INSTALLED="正常にインストールされました"
      MSG_ALREADY_EXISTS="すでに存在します"
      MSG_FAILED="ダウンロードに失敗しました"
      MSG_COMPLETE="インストール完了"
      MSG_SETUP_ALIAS="エイリアス設定中"
      MSG_DRY_RUN="ドライラン - インストール予定"
      MSG_FILES_TO_INSTALL="インストールするファイル"
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
    --force) FORCE_INSTALL=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    --dir)
      [[ $# -lt 2 ]] && { echo "ERROR: --dir requires a directory path" >&2; exit 2; }
      INSTALL_DIR="$2"; shift 2 ;;
    -*) echo "ERROR: Unknown option: $1" >&2; print_usage; exit 2 ;;
    *) echo "ERROR: Unexpected argument: $1" >&2; print_usage; exit 2 ;;
  esac
done

if [[ "${SHOW_HELP:-0}" -eq 1 ]]; then print_usage; exit 0; fi
set_lang

# ===== File list to download =====
# All .sh files except install.sh, and no README files
FILES_TO_DOWNLOAD=(
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
download_file() {
  local filename="$1"
  local url="$RAW_BASE_URL/$filename"
  local target_path="$INSTALL_DIR/$filename"
  
  if [[ "$DRY_RUN" == true ]]; then
    echo "  📄 $MSG_DRY_RUN: $filename"
    return 0
  fi
  
  echo -n "  📄 $MSG_DOWNLOADING $filename... "
  
  # Check if file exists and handle accordingly
  if [[ -f "$target_path" && "$FORCE_INSTALL" != true ]]; then
    echo "$MSG_ALREADY_EXISTS - $MSG_SKIPPING"
    return 0
  fi
  
  # Download the file
  if command -v curl >/dev/null 2>&1; then
    if curl -fsSL "$url" -o "$target_path" 2>/dev/null; then
      chmod +x "$target_path"
      echo "$MSG_INSTALLED"
    else
      echo "$MSG_FAILED"
      return 1
    fi
  elif command -v wget >/dev/null 2>&1; then
    if wget -q "$url" -O "$target_path" 2>/dev/null; then
      chmod +x "$target_path"
      echo "$MSG_INSTALLED"
    else
      echo "$MSG_FAILED"
      return 1
    fi
  else
    echo "❌ ERROR: Neither curl nor wget is available"
    return 1
  fi
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

setup_menu_alias() {
  local install_dir="$1"
  local alias_name="menu"
  local menu_path="$install_dir/menu.sh"
  
  if [[ ! -f "$menu_path" ]]; then
    echo "⚠️  Warning: menu.sh not found at $menu_path"
    return 1
  fi
  
  echo "🔗 Setting up '$alias_name' alias..."
  
  # Detect shell and appropriate config file
  local shell_config=""
  local current_shell=$(basename "${SHELL:-/bin/bash}")
  
  case "$current_shell" in
    bash)
      if [[ -f "$HOME/.bashrc" ]]; then
        shell_config="$HOME/.bashrc"
      elif [[ -f "$HOME/.bash_profile" ]]; then
        shell_config="$HOME/.bash_profile"
      else
        shell_config="$HOME/.bashrc"
        touch "$shell_config"
      fi
      ;;
    zsh)
      if [[ -f "$HOME/.zshrc" ]]; then
        shell_config="$HOME/.zshrc"
      else
        shell_config="$HOME/.zshrc"
        touch "$shell_config"
      fi
      ;;
    *)
      # Default to bashrc for unknown shells
      shell_config="$HOME/.bashrc"
      if [[ ! -f "$shell_config" ]]; then
        touch "$shell_config"
      fi
      ;;
  esac
  
  # Create the alias command
  local alias_cmd="alias $alias_name='cd \"$install_dir\" && ./menu.sh'"
  
  # Check if alias already exists
  if grep -q "alias $alias_name=" "$shell_config" 2>/dev/null; then
    echo "   📝 Updating existing '$alias_name' alias in $shell_config"
    # Remove old alias and add new one
    grep -v "alias $alias_name=" "$shell_config" > "$shell_config.tmp" && mv "$shell_config.tmp" "$shell_config"
  else
    echo "   📝 Adding '$alias_name' alias to $shell_config"
  fi
  
  # Add the alias
  echo "" >> "$shell_config"
  echo "# BashUtils menu alias - added by install.sh" >> "$shell_config"
  echo "$alias_cmd" >> "$shell_config"
  
  echo "   ✅ Alias '$alias_name' added successfully!"
  echo "   📋 Usage: Open a new terminal and type '$alias_name'"
  
  return 0
}

# ===== Main execution =====
echo "📦 $MSG_INSTALLER"
printf '%0.s=' {1..50}; echo

set_lang

# Check dependencies
if ! check_dependencies; then
  exit 1
fi

echo "$MSG_INSTALLING..."
echo "Repository: $REPO_URL"
echo "Install directory: $INSTALL_DIR"
echo "Files to install: ${#FILES_TO_DOWNLOAD[@]}"
echo

# Create installation directory
if [[ "$DRY_RUN" != true ]]; then
  if [[ ! -d "$INSTALL_DIR" ]]; then
    echo "📁 $MSG_CREATING_DIR: $INSTALL_DIR"
    mkdir -p "$INSTALL_DIR" || {
      echo "❌ Failed to create directory: $INSTALL_DIR"
      exit 1
    }
  fi
fi

# Download all files
echo "📥 $MSG_DOWNLOADING files..."
failed_downloads=0
successful_downloads=0

for file in "${FILES_TO_DOWNLOAD[@]}"; do
  if download_file "$file"; then
    ((successful_downloads++)) || true
  else
    ((failed_downloads++)) || true
  fi
done

echo
printf '%0.s=' {1..50}; echo

# Summary
if [[ "$DRY_RUN" == true ]]; then
  echo "📋 $MSG_DRY_RUN Summary:"
  echo "  Would install: ${#FILES_TO_DOWNLOAD[@]} $MSG_FILES_TO_INSTALL"
  echo "  Target directory: $INSTALL_DIR"
else
  echo "📊 Installation Summary:"
  echo "  ✅ Successful: $successful_downloads"
  if [[ $failed_downloads -gt 0 ]]; then
    echo "  ❌ Failed: $failed_downloads"
  fi
  
  if [[ $successful_downloads -gt 0 ]]; then
    echo
    echo "✅ $MSG_COMPLETE!"
    echo
    
    # Automatically setup menu alias
    if setup_menu_alias "$INSTALL_DIR"; then
      echo
      echo "🚀 Quick start:"
      echo "1. Reload your shell:"
      echo "   source ~/.bashrc   # or source ~/.zshrc for zsh"
      echo
      echo "2. Start using BashUtils:"
      echo "   menu              # Opens the interactive menu"
      echo
      echo "3. Optional - Add to PATH for direct script access:"
      echo "   echo 'export PATH=\"$INSTALL_DIR:\$PATH\"' >> ~/.bashrc"
    else
      echo
      echo "🚀 Manual setup required:"
      echo "1. Add alias manually:"
      echo "   echo 'alias menu=\"cd $INSTALL_DIR && ./menu.sh\"' >> ~/.bashrc"
      echo
      echo "2. Reload your shell:"
      echo "   source ~/.bashrc"
      echo
      echo "3. Start using BashUtils:"
      echo "   menu"
    fi
    
    echo
    echo "📋 Alternative access:"
    echo "   cd $INSTALL_DIR && ./menu.sh"
  else
    echo "❌ Installation failed. Please check your internet connection and try again."
    exit 1
  fi
fi