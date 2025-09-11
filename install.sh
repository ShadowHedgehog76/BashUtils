#!/usr/bin/env bash
set -euo pipefail

# ======= CONFIG =======
RAW_BASE_DEFAULT="https://raw.githubusercontent.com/ShadowHedgehog76/BashUtils/main"
RAW_BASE="${RAW_BASE:-$RAW_BASE_DEFAULT}"

INSTALL_DIR="$HOME/.alias"
SEARCH_CMD="$INSTALL_DIR/search.sh"
UPDATE_CMD="$INSTALL_DIR/update.sh"

OS="$(uname -s || true)"

echo "🔧 Installation de BashUtils dans $INSTALL_DIR ..."

# ======= 1) Créer le dossier cible =======
mkdir -p "$INSTALL_DIR"

# ======= 2) Télécharger search.sh et update.sh =======
echo "⬇️  Téléchargement de search.sh ..."
curl -fsSL "$RAW_BASE/search.sh" -o "$SEARCH_CMD"
chmod +x "$SEARCH_CMD"

echo "⬇️  Téléchargement de update.sh ..."
if curl -fsSL "$RAW_BASE/update.sh" -o "$UPDATE_CMD"; then
  chmod +x "$UPDATE_CMD"
else
  echo "ℹ️  Pas de update.sh trouvé sur le repo."
fi

# ======= 3) Ajouter ~/.alias dans le PATH si besoin =======
for SHELLRC in "$HOME/.bashrc" "$HOME/.zshrc"; do
  if [ -f "$SHELLRC" ]; then
    if ! grep -q 'export PATH="$HOME/.alias:$PATH"' "$SHELLRC" 2>/dev/null; then
      echo 'export PATH="$HOME/.alias:$PATH"' >> "$SHELLRC"
      echo "✅ Ajout de ~/.alias au PATH dans $SHELLRC"
    fi
    if ! grep -q 'alias search=' "$SHELLRC" 2>/dev/null; then
      echo 'alias search="bash ~/.alias/search.sh"' >> "$SHELLRC"
      echo "✅ Ajout alias search dans $SHELLRC"
    fi
    if ! grep -q 'alias update=' "$SHELLRC" 2>/dev/null; then
      echo 'alias update="bash ~/.alias/update.sh"' >> "$SHELLRC"
      echo "✅ Ajout alias update dans $SHELLRC"
    fi
  fi
done

# ======= 4) Auto-update au démarrage =======
case "$OS" in
  Linux)
    CRON_LINE="@reboot bash ~/.alias/update.sh >/dev/null 2>&1"
    (crontab -l 2>/dev/null | grep -v -F "$CRON_LINE" || true; echo "$CRON_LINE") | crontab -
    echo "✅ Auto-update activé au démarrage (crontab @reboot)"
    ;;
  Darwin)
    LA_DIR="$HOME/Library/LaunchAgents"
    LA_PLIST="$LA_DIR/com.$USER.bashutils.update.plist"
    mkdir -p "$LA_DIR"
    cat > "$LA_PLIST" <<EOF2
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN"
 "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
 <dict>
   <key>Label</key>
   <string>com.$USER.bashutils.update</string>
   <key>ProgramArguments</key>
   <array><string>bash</string><string>$UPDATE_CMD</string></array>
   <key>RunAtLoad</key><true/>
   <key>StandardOutPath</key><string>$HOME/Library/Logs/bashutils-update.out.log</string>
   <key>StandardErrorPath</key><string>$HOME/Library/Logs/bashutils-update.err.log</string>
 </dict>
</plist>
EOF2
    launchctl unload "$LA_PLIST" >/dev/null 2>&1 || true
    launchctl load -w "$LA_PLIST"
    echo "✅ Auto-update activé au démarrage (launchd)"
    ;;
  *)
    echo "ℹ️  OS non reconnu ($OS). Ajoute manuellement au démarrage si besoin."
    ;;
esac

echo "🎉 Installation terminée."
echo "➡️  Ouvre un nouveau terminal OU exécute: source ~/.bashrc et source ~/.zshrc"
echo
echo "✅ Commandes prêtes :"
echo "   search \"mot\" [chemin]"
echo "   update"
