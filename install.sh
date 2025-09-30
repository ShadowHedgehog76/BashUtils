#!/usr/bin/env bash
TMPDIR="$(mktemp -d)"
TARBALL="$TMPDIR/repo.tar.gz"


echo "⬇️ Téléchargement du dépôt complet (tarball) ..."
if ! curl -fsSL "$TARBALL_URL" -o "$TARBALL"; then
echo "⚠️ Échec du téléchargement : $TARBALL_URL" >&2
exit 1
fi


echo "📦 Extraction ..."
mkdir -p "$TMPDIR/extracted"
tar -xzf "$TARBALL" -C "$TMPDIR/extracted"
ROOT_DIR="$(find "$TMPDIR/extracted" -maxdepth 1 -mindepth 1 -type d | head -n1)"


# Sync everything except README* and VCS/CI metadata
if command -v rsync >/dev/null 2>&1; then
rsync -a --delete \
--exclude='README' --exclude='README.*' --exclude='readme' --exclude='readme.*' \
--exclude='.git/' --exclude='.github/' --exclude='.gitignore' \
"$ROOT_DIR"/ "$INSTALL_DIR"/
else
( cd "$ROOT_DIR" && \
find . \
-path './.git*' -prune -o \
-path './.github*' -prune -o \
-iname 'README*' -prune -o \
-type f -print0 | \
xargs -0 -I{} sh -c 'mkdir -p "$INSTALL_DIR/$(dirname "${0#./}")"; cp -f "${0}" "$INSTALL_DIR/${0#./}"' '{}' )
fi


# Ensure all .sh are executable
find "$INSTALL_DIR" -type f -name '*.sh' -exec chmod +x {} +


# Prepare PATH + dynamic aliases for each script (basename without .sh)
ADD_PATH='export PATH="$HOME/Documents/alias:$PATH"'


# Build alias lines dynamically from current repo contents
ALIAS_FILE_LINES=()
while IFS= read -r -d '' f; do
base="$(basename "$f")"
name="${base%.sh}"
# Skip install/update scripts themselves if you wish to avoid recursion; here we keep both.
ALIAS_FILE_LINES+=("alias ${name}=\"bash $INSTALL_DIR/${base}\"")
done < <(find "$INSTALL_DIR" -maxdepth 1 -type f -name '*.sh' -print0)


# Write/append to shell rc files
for SHELLRC in "$HOME/.bashrc" "$HOME/.zshrc"; do
touch "$SHELLRC"
grep -qF "$ADD_PATH" "$SHELLRC" || echo "$ADD_PATH" >> "$SHELLRC"
for L in "${ALIAS_FILE_LINES[@]}"; do
grep -qF "$L" "$SHELLRC" || echo "$L" >> "$SHELLRC"
done
done


# Create activate.sh to quickly source the env
{
echo "# Recharge rapide des alias/chemins pour bash et zsh"
echo "$ADD_PATH"
for L in "${ALIAS_FILE_LINES[@]}"; do echo "$L"; done
} > "$ACTIVATE"


# Hint for reloading current shell
CURRENT_SHELL="$(ps -p $$ -o comm= 2>/dev/null || echo "")"
case "$CURRENT_SHELL" in
*zsh*) RELOAD_HINT='source ~/.zshrc' ;;
*bash*) RELOAD_HINT='source ~/.bashrc' ;;
*) RELOAD_HINT='source ~/.bashrc # ou source ~/.zshrc' ;;
esac


cat <<EOF


🎉 Installation terminée dans $INSTALL_DIR.
ℹ️ Limitation Unix : un script lancé via 'curl | bash' ne peut pas modifier le shell en cours.
➡️ Pour activer immédiatement dans ce terminal, exécute :
$RELOAD_HINT
# ou :
source "$ACTIVATE"


✅ Exemples :
search "hello" ~/Documents
update
EOF


# Cleanup
rm -rf "$TMPDIR"