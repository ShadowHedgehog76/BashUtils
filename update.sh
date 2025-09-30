#!/usr/bin/env bash
set -euo pipefail

# Chemin d'installation (le même que dans install.sh)
INSTALL_DIR="$HOME/Documents/alias"

# Repo source
RAW_BASE="${RAW_BASE:-https://raw.githubusercontent.com/ShadowHedgehog76/BashUtils/main}"

echo "⬇️ Mise à jour des scripts depuis $RAW_BASE ..."
mkdir -p "$INSTALL_DIR"

# Liste des scripts à mettre à jour (ajoute ici si tu en crées d’autres)
FILES=(
  "search.sh"
  "network.sh"
  "update.sh"
)

for FILE in "${FILES[@]}"; do
  echo "→ Téléchargement de $FILE ..."
  if curl -fsSL "$RAW_BASE/$FILE" -o "$INSTALL_DIR/$FILE"; then
    chmod +x "$INSTALL_DIR/$FILE"
    echo "✅ $FILE mis à jour"
  else
    echo "⚠️ Impossible de récupérer $RAW_BASE/$FILE" >&2
  fi
done

echo "🎉 Mise à jour terminée !"
