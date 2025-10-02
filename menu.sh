#!/usr/bin/env bash
set -euo pipefail

# menu.sh — Interactive menu system for BashUtils
# Single entry point for all utilities with command-line interface

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LANG_CODE="en"
SHOW_HELP=0
DIRECT_COMMAND=""

# ===== Script definitions =====

# ===== Script definitions =====
declare -A SCRIPTS=(
  # Core Utilities
  ["search"]="search.sh:Text search with pattern matching and filtering"
  ["network"]="network.sh:Network device discovery and port scanning"
  ["update"]="update.sh:Update BashUtils scripts from GitHub repository"
  ["install"]="install.sh:Install BashUtils scripts from GitHub repository"
  
  # System Monitoring
  ["sysinfo"]="sysinfo.sh:Comprehensive system information dashboard"
  ["monitor"]="monitor.sh:Real-time system monitoring with alerts"
  
  # Network Tools
  ["ports"]="ports.sh:Port scanner and service detector"
  ["speedtest"]="speedtest.sh:Network speed testing with logging"
  ["dns"]="dns.sh:DNS lookup and benchmarking tool"
  ["webcheck"]="webcheck.sh:Website health monitoring and uptime checks"
  
  # File Management
  ["cleanup"]="cleanup.sh:Smart cleanup for temp files and duplicates"
  ["backup"]="backup.sh:Automated backup with compression and rotation"
  ["organize"]="organize.sh:File organizer by type, date, and size"
  
  # Development Tools
  ["gitutils"]="gitutils.sh:Git helper with batch operations"
  ["deploy"]="deploy.sh:Deployment automation with rollback capabilities"
  ["envcheck"]="envcheck.sh:Development environment validator"
  
  # Security & Maintenance
  ["secure"]="secure.sh:Security auditor for permissions, ports, logins"
  ["logs"]="logs.sh:Log analyzer with filtering and alerting"
)

declare -A CATEGORIES=(
  ["Core Utilities"]="search network update install"
  ["System Monitoring"]="sysinfo monitor"
  ["Network Tools"]="ports speedtest dns webcheck"
  ["File Management"]="cleanup backup organize"
  ["Development Tools"]="gitutils deploy envcheck"
  ["Security & Maintenance"]="secure logs"
)

# ===== Functions =====
print_usage() {
  cat << 'EOF'
Usage:
  menu.sh [--direct "command args"] [--en|--fr|--jp] [-h|--help]

Interactive menu system for BashUtils scripts with auto-refresh.

Options:
  --direct "cmd args"   Execute command directly and exit
  --en, --fr, --jp      Set language (default: en)
  -h, --help            Show this help

Interactive Commands:
  help, h               Show available commands
  list, ls              List all scripts with descriptions
  exit, quit, q         Exit the menu completely
  clear, cls            Clear screen and refresh menu
  lang [en|fr|jp]       Change language
  
  Any script name with arguments (e.g. "sysinfo --cpu", "network --scan")
  
Features:
  • Menu automatically refreshes after each command
  • Commands wait for user confirmation before returning to menu
  • Clean exit with goodbye message
  
Examples:
  menu.sh                           # Start interactive menu
  menu.sh --direct "sysinfo --cpu"  # Run command directly
  menu.sh --fr                      # Start menu in French
EOF
}

print_header() {  
  clear
  echo "╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗"
  echo "║                                                                                                                        ║"
  echo "║           _nnnn_                            888888b.                     888      888     888 888    d8b 888           ║"
  echo "║          dGGGGMMb                           888  \"88b                    888      888     888 888    Y8P 888           ║"
  echo "║         @p~qp~~qMb                          888  .88P                    888      888     888 888        888           ║"
  echo "║         M|@||@) M|                          8888888K.   8888b.  .d8888b  88888b.  888     888 888888 888 888 .d8888b   ║"
  echo "║         @,----.JM|                          888  \"Y88b     \"88b 88K      888 \"88b 888     888 888    888 888 88K       ║"
  echo "║        JS^\\__/  qKL                         888    888 .d888888 \"Y8888b. 888  888 888     888 888    888 888 \"Y8888b.  ║"
  echo "║       dZP        qKRb                       888   d88P 888  888      X88 888  888 Y88b. .d88P Y88b.  888 888      X88  ║"
  echo "║      dZP          qKKb                      8888888P\"  \"Y888888  88888P' 888  888  \"Y88888P\"   \"Y888 888 888  88888P'  ║"
  echo "║     fZP            SMMb                                                                                                ║"
  echo "║     HZM            MMMM                                                                                                ║"
  echo "║     FqM            MMMM                                                                                                ║"
  echo "║   __| \".        |\\dS\\\"qML                                                                                              ║"
  echo "║   |    \`.       | '\\Zq                                                                                                 ║"
  echo "║  _)      \\\\.___.,|     .'                                                                                              ║"
  echo "║  \\\\____   )MMMMMP|   .'                                                                                                ║"
  echo "║       \`-'       \`--'                          Welcome to BashUtils! Type a command or \"help\" for available commands.   ║"
  echo "║                                                                                                                        ║"
  echo "╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝"
  echo
}

print_welcome() {
  echo ""
  echo
}

wait_for_user() {
  echo
  echo "Press Enter to continue..."
  read -r
}

print_help() {
  echo "Available Commands:"
  echo
  
  # Print by categories
  for category in "Core Utilities" "System Monitoring" "Network Tools" "File Management" "Development Tools" "Security & Maintenance"; do
    echo "📁 $category:"
    local scripts="${CATEGORIES[$category]}"
    for script in $scripts; do
      if [[ -n "${SCRIPTS[$script]:-}" ]]; then
        local script_info="${SCRIPTS[$script]}"
        local script_file="${script_info%%:*}"  
        local description="${script_info##*:}"
        printf "  %-12s - %s\n" "$script" "$description"
      fi
    done
    echo
  done
  
  echo "📋 Menu Commands:"
  echo "  help, h       - Show this help"
  echo "  list, ls      - List all scripts with file names"
  echo "  clear, cls    - Clear screen and refresh menu"
  echo "  lang [code]   - Change language (en/fr/jp)"
  echo "  exit, quit, q - Exit BashUtils menu"
  echo
  echo "Examples:"
  echo "  sysinfo --cpu        # Show CPU information"
  echo "  network --scan       # Scan network devices"
  echo "  backup --create /home # Create backup of /home"
  echo "  logs -a --severity error # Analyze logs for errors"
  echo
  echo "💡 Tip: Menu will refresh automatically after each command completes."
}

print_list() {
  echo "All available scripts:"
  echo
  for script in "${!SCRIPTS[@]}"; do
    local script_info="${SCRIPTS[$script]}"
    local script_file="${script_info%%:*}"
    local description="${script_info##*:}"
    printf "%-12s (%s) - %s\n" "$script" "$script_file" "$description"
  done | sort
  echo
}

execute_script() {
  local command="$1"
  shift
  local args=("$@")
  
  # Check if command exists in our scripts
  if [[ -n "${SCRIPTS[$command]:-}" ]]; then
    local script_info="${SCRIPTS[$command]}"
    local script_file="${script_info%%:*}"
    local script_path="$SCRIPT_DIR/$script_file"
    
    if [[ -x "$script_path" ]]; then
      echo "Executing: $script_file ${args[*]}"
      echo "------------------------------------------------------------"
      
      # Execute the script with provided arguments
      if [[ ${#args[@]} -gt 0 ]]; then
        "$script_path" "${args[@]}"
      else
        "$script_path"
      fi
      
      local exit_code=$?
      echo "------------------------------------------------------------"
      
      if [[ $exit_code -eq 0 ]]; then
        echo "SUCCESS: Command completed successfully"
      else
        echo "ERROR: Command failed with exit code: $exit_code"
      fi
      
      # Wait for user acknowledgment before returning to menu
      wait_for_user
      
    else
      echo "ERROR: Script not found or not executable: $script_path"
      wait_for_user
    fi
  else
    echo "ERROR: Command not found: $command"
    echo "Type \"help\" to see available commands"
    wait_for_user
  fi
}

process_command() {
  local input="$1"
  
  # Parse command and arguments
  read -ra cmd_parts <<< "$input"
  local command="${cmd_parts[0]}"
  local args=("${cmd_parts[@]:1}")
  
  case "$command" in
    "help"|"h")
      print_help
      wait_for_user
      clear
      print_header
      ;;
    "list"|"ls")
      print_list
      wait_for_user
      clear
      print_header
      ;;
    "clear"|"cls")
      clear
      print_header
      ;;
    "lang")
      if [[ ${#args[@]} -gt 0 ]]; then
        case "${args[0]}" in
          "en"|"fr"|"jp")
            LANG_CODE="${args[0]}"
            echo "✅ Language changed to: ${args[0]}"
            ;;
          *)
            echo "❌ Invalid language. Use: en, fr, or jp"
            ;;
        esac
      else
        echo "Current language: $LANG_CODE"
        echo "Available languages: en, fr, jp"
      fi
      wait_for_user
      clear
      print_header
      ;;
    "exit"|"quit"|"q")
      clear
      echo "👋 Goodbye! Thanks for using BashUtils!"
      exit 0
      ;;
    "")
      # Empty command, just show prompt again - no action needed
      return 0
      ;;
    *)
      execute_script "$command" "${args[@]}"
      echo
      echo "🔄 Returning to main menu..."
      sleep 1
      clear
      print_header
      ;;
  esac
}

# ===== Parse command line options =====  
while (( $# )); do
  case "${1:-}" in
    -h|--help) SHOW_HELP=1; shift ;;
    --en) LANG_CODE="en"; shift ;;
    --fr) LANG_CODE="fr"; shift ;;
    --jp) LANG_CODE="jp"; shift ;;
    --direct)
      [[ $# -lt 2 ]] && { echo "ERROR: --direct requires a command" >&2; exit 2; }
      DIRECT_COMMAND="$2"; shift 2 ;;
    -*) echo "ERROR: Unknown option: $1" >&2; print_usage; exit 2 ;;
    *) echo "ERROR: Unexpected argument: $1" >&2; print_usage; exit 2 ;;
  esac
done

if [[ "${SHOW_HELP:-0}" -eq 1 ]]; then print_usage; exit 0; fi

# ===== Main execution =====

# Check if running in direct mode
if [[ -n "$DIRECT_COMMAND" ]]; then
  process_command "$DIRECT_COMMAND"
  exit $?
fi

# Interactive mode
print_header

# Check if all script files exist and make them executable
missing_scripts=()
for script in "${!SCRIPTS[@]}"; do
  script_info="${SCRIPTS[$script]}"
  script_file="${script_info%%:*}"
  script_path="$SCRIPT_DIR/$script_file"
  
  if [[ ! -f "$script_path" ]]; then
    missing_scripts+=("$script_file")
  elif [[ ! -x "$script_path" ]]; then
    echo "🔧 Making $script_file executable..."
    chmod +x "$script_path" 2>/dev/null || echo "❌ Failed to make $script_file executable"
  fi
done

if [[ ${#missing_scripts[@]} -gt 0 ]]; then
  echo "⚠️  Warning: Some scripts are missing:"
  printf "   - %s\n" "${missing_scripts[@]}"
  echo
fi

# Main interactive loop
while true; do
  echo -n "bashutils> "
  read -r user_input
  
  if [[ -n "$user_input" ]]; then
    echo
    process_command "$user_input"
  fi
done