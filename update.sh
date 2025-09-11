#!/usr/bin/env bash
set -euo pipefail

RAW_BASE="${RAW_BASE:-https://raw.githubusercontent.com/ShadowHedgehog76/BashUtils/main}"
INSTALL_DIR="$HOME/Documents/alias"

echo "⬇️ Mise à jour des scripts depuis $RAW_BASE ..."
mkdir -p "$INSTALL_DIR"

# Liste des fichiers à mettre à jour (ajoute ici tous tes .sh si tu en crées d'autres)
FILES=(
  "search.sh"
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
