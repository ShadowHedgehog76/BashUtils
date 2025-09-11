#!/usr/bin/env bash
set -euo pipefail

RAW_BASE_DEFAULT="https://raw.githubusercontent.com/ShadowHedgehog76/BashUtils/main"
RAW_BASE="${RAW_BASE:-$RAW_BASE_DEFAULT}"

INSTALL_DIR="$HOME/Documents/alias"
SEARCH_CMD="$INSTALL_DIR/search.sh"
UPDATE_CMD="$INSTALL_DIR/update.sh"

echo "🔧 Installation de BashUtils dans $INSTALL_DIR ..."
mkdir -p "$INSTALL_DIR"

# 1) Télécharger les scripts
echo "⬇️  search.sh"
curl -fsSL "$RAW_BASE/search.sh" -o "$SEARCH_CMD"
chmod +x "$SEARCH_CMD"

echo "⬇️  update.sh"
if curl -fsSL "$RAW_BASE/update.sh" -o "$UPDATE_CMD"; then
  chmod +x "$UPDATE_CMD"
else
  # facultatif: bootstrap minimal si pas présent sur le repo
  cat > "$UPDATE_CMD" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
RAW_BASE="${RAW_BASE:-https://raw.githubusercontent.com/ShadowHedgehog76/BashUtils/main}"
INSTALL_DIR="$HOME/Documents/alias"
mkdir -p "$INSTALL_DIR"
for f in search.sh update.sh; do
  curl -fsSL "$RAW_BASE/$f" -o "$INSTALL_DIR/$f" && chmod +x "$INSTALL_DIR/$f" || true
done
echo "✅ Update terminé"
EOF
  chmod +x "$UPDATE_CMD"
fi

# 2) Préparer lignes à ajouter
ADD_PATH='export PATH="$HOME/Documents/alias:$PATH"'
ADD_ALIAS_SEARCH='alias search="bash ~/Documents/alias/search.sh"'
ADD_ALIAS_UPDATE='alias update="bash ~/Documents/alias/update.sh"'

# 3) Injecter dans ~/.bashrc et ~/.zshrc si absent
for SHELLRC in "$HOME/.bashrc" "$HOME/.zshrc"; do
  touch "$SHELLRC"
  grep -qF "$ADD_PATH"        "$SHELLRC" || echo "$ADD_PATH" >> "$SHELLRC"
  grep -qF "$ADD_ALIAS_SEARCH" "$SHELLRC" || echo "$ADD_ALIAS_SEARCH" >> "$SHELLRC"
  grep -qF "$ADD_ALIAS_UPDATE" "$SHELLRC" || echo "$ADD_ALIAS_UPDATE" >> "$SHELLRC"
done

# 4) Script d’activation à sourcer rapidement
ACTIVATE="$INSTALL_DIR/activate.sh"
cat > "$ACTIVATE" <<EOF
# Recharge rapides des alias/chemins pour bash et zsh
$ADD_PATH
$ADD_ALIAS_SEARCH
$ADD_ALIAS_UPDATE
EOF

# 5) Détection du shell courant pour l’instruction finale
CURRENT_SHELL="$(ps -p $$ -o comm= 2>/dev/null || echo "")"
RELOAD_HINT=""
case "$CURRENT_SHELL" in
  *zsh*)
    RELOAD_HINT='source ~/.zshrc'
    ;;
  *bash*)
    RELOAD_HINT='source ~/.bashrc'
    ;;
  *)
    # inconnu : proposer les deux + activate
    RELOAD_HINT='source ~/.bashrc  # ou  source ~/.zshrc'
    ;;
esac

echo
echo "🎉 Installation terminée."
echo "ℹ️ Limitation Unix : un script lancé via 'curl | bash' ne peut pas modifier TON shell en cours."
echo "➡️ Pour activer tout de suite dans ce terminal, exécute :"
echo "   $RELOAD_HINT"
echo "   # ou :"
echo "   source ~/Documents/alias/activate.sh"
echo
echo "✅ Tu peux ensuite utiliser :"
echo '   search "hello" ~/Documents'
echo "   update"
