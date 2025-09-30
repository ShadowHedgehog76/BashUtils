#!/usr/bin/env bash


TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT
TARBALL="$TMPDIR/repo.tar.gz"


if [[ -z "$TARBALL_URL" ]]; then
echo "⚠️ URL du tarball vide — vérifie OWNER/REPO/BRANCH" >&2
exit 1
fi


# Download tarball
echo "→ Téléchargement du tarball ..."
if ! curl -fsSL "$TARBALL_URL" -o "$TARBALL"; then
echo "⚠️ Impossible de récupérer le tarball : $TARBALL_URL" >&2
exit 1
fi


# Extract
echo "→ Extraction ..."
mkdir -p "$TMPDIR/extracted"
tar -xzf "$TARBALL" -C "$TMPDIR/extracted"
ROOT_DIR="$(find "$TMPDIR/extracted" -maxdepth 1 -mindepth 1 -type d | head -n1)"


# Sync everything except README* and VCS/CI metadata
echo "→ Synchronisation vers $INSTALL_DIR ..."
if command -v rsync >/dev/null 2>&1; then
rsync -a --delete \
--exclude='README' --exclude='README.*' --exclude='readme' --exclude='readme.*' \
--exclude='.git/' --exclude='.github/' --exclude='.gitignore' \
"$ROOT_DIR"/ "$INSTALL_DIR"/
else
(
cd "$ROOT_DIR"
while IFS= read -r -d '' path; do
rel="${path#./}"
dir="$(dirname "$rel")"
mkdir -p "$INSTALL_DIR/$dir"
cp -f "$rel" "$INSTALL_DIR/$rel"
done < <(find . \
-path './.git*' -prune -o \
-path './.github*' -prune -o \
-iname 'README*' -prune -o \
-type f -print0)
)
fi


# Ensure all .sh are executable
echo "→ Mise en exécutable des scripts .sh ..."
find "$INSTALL_DIR" -type f -name '*.sh' -exec chmod +x {} +


# Rebuild aliases and inject into rc files
echo "→ Mise à jour des alias dans ~/.bashrc et ~/.zshrc ..."
update_rc_file "$HOME/.bashrc"
update_rc_file "$HOME/.zshrc"


# Regenerate activate.sh to match (no markers)
{
echo "# Recharge rapide des alias/chemins pour bash et zsh"
build_alias_lines
} > "$ACTIVATE"


# Hint for reloading current shell
# Pre-set a safe default to avoid set -u "unbound variable"
RELOAD_HINT='source ~/.bashrc # ou source ~/.zshrc'
CURRENT_SHELL="$(ps -p $$ -o comm= 2>/dev/null || echo "")"
case "$CURRENT_SHELL" in
*zsh*) RELOAD_HINT='source ~/.zshrc' ;;
*bash*) RELOAD_HINT='source ~/.bashrc' ;;
*) : ;; # keep default
esac


echo "🎉 Mise à jour terminée dans $INSTALL_DIR"
echo "➡️ Pour recharger vos alias maintenant : $RELOAD_HINT"