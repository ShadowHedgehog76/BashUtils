#!/usr/bin/env bash
# setup-alias.sh — Setup script for creating BashUtils menu alias

# Main function
main() {
echo "🔧 BashUtils Menu Setup"
echo "======================="
echo

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MENU_PATH="$SCRIPT_DIR/menu.sh"

# Detect shell
SHELL_TYPE=""
if [[ -n "${BASH_VERSION:-}" ]]; then
    SHELL_TYPE="bash"
    RC_FILE="$HOME/.bashrc"
elif [[ -n "${ZSH_VERSION:-}" ]]; then
    SHELL_TYPE="zsh"
    RC_FILE="$HOME/.zshrc"
else
    echo "⚠️  Unable to detect shell type. Defaulting to bash."
    SHELL_TYPE="bash"
    RC_FILE="$HOME/.bashrc"
fi

echo "Detected shell: $SHELL_TYPE"
echo "RC file: $RC_FILE"
echo "Menu script: $MENU_PATH"
echo

# Check if menu.sh exists
if [[ ! -f "$MENU_PATH" ]]; then
    echo "❌ menu.sh not found at: $MENU_PATH"
    return 1
fi

# Make menu.sh executable
chmod +x "$MENU_PATH"

# Create the alias command
ALIAS_COMMAND="alias bashutils='cd \"$SCRIPT_DIR\" && ./menu.sh'"

echo "The following alias will be added to your $RC_FILE:"
echo "  $ALIAS_COMMAND"
echo

# Check if alias already exists
if grep -q "alias bashutils=" "$RC_FILE" 2>/dev/null; then
    echo "⚠️  BashUtils alias already exists in $RC_FILE"
    echo "Do you want to update it? (y/N)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        # Remove existing alias
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            sed -i '' '/alias bashutils=/d' "$RC_FILE"
        else
            # Linux
            sed -i '/alias bashutils=/d' "$RC_FILE"
        fi
        echo "✅ Removed existing alias"
    else
        echo "Setup cancelled."
        return 0
    fi
fi

# Add the alias
echo "$ALIAS_COMMAND" >> "$RC_FILE"

echo "✅ Alias added to $RC_FILE"
echo
echo "To use the menu immediately, run:"
echo "  source $RC_FILE"
echo "  bashutils"
echo
echo "Or open a new terminal and run:"
echo "  bashutils"
echo
echo "📋 Menu Commands:"
echo "  bashutils                    # Start interactive menu"
echo "  bashutils --direct \"sysinfo\" # Run command directly"
echo "  bashutils --help             # Show menu help"
echo
echo "🎉 Setup complete!"

# Make all scripts executable
echo "🔧 Making all scripts executable..."
for script in "$SCRIPT_DIR"/*.sh; do
    if [[ -f "$script" ]]; then
        chmod +x "$script"
        echo "  ✅ $(basename "$script")"
    fi
done

echo
echo "All scripts are now ready to use!"
}

# Call main function
main