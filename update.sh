#!/usr/bin/env bash
update_rc_file() {
# removes old managed block and appends a fresh one
local rc="$1"
touch "$rc"
local tmp
tmp="$(mktemp)"
awk -v s="$BLOCK_START" -v e="$BLOCK_END" '
BEGIN{in=0}
$0==s{in=1; next}
$0==e{in=0; next}
!in{print}
' "$rc" > "$tmp"
mv "$tmp" "$rc"
build_alias_block >> "$rc"
}


msg "⬇️ Mise à jour depuis ${OWNER}/${REPO}@${BRANCH} ..."
mkdir -p "$INSTALL_DIR"
TMPDIR="$(mktemp -d)"
TARBALL="$TMPDIR/repo.tar.gz"


# Download tarball
if ! curl -fsSL "$TARBALL_URL" -o "$TARBALL"; then
echo "⚠️ Impossible de récupérer le tarball : $TARBALL_URL" >&2
exit 1
fi


# Extract
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
(
cd "$ROOT_DIR" && \
find . \
-path './.git*' -prune -o \
-path './.github*' -prune -o \
-iname 'README*' -prune -o \
-type f -print0 | \
xargs -0 -I{} sh -c 'mkdir -p "$INSTALL_DIR/$(dirname "${0#./}")"; cp -f "${0}" "$INSTALL_DIR/${0#./}"' '{}'
)
fi


# Ensure all .sh are executable
find "$INSTALL_DIR" -type f -name '*.sh' -exec chmod +x {} +


# Rebuild aliases for all *.sh and update shell config files
update_rc_file "$HOME/.bashrc"
update_rc_file "$HOME/.zshrc"


# Also regenerate activate.sh to match
{
echo "# Recharge rapide des alias/chemins pour bash et zsh"
build_alias_block | sed -e "1d" -e "$ d" # strip the markers in activate.sh
} > "$ACTIVATE"


# Hint
CURRENT_SHELL="$(ps -p $$ -o comm= 2>/dev/null || echo "")"
case "$CURRENT_SHELL" in
*zsh*) RELOAD_HINT='source ~/.zshrc' ;;
*bash*) RELOAD_HINT='source ~/.bashrc' ;;
*) RELOAD_HINT='source ~/.bashrc # ou source ~/.zshrc' ;;
esac


msg "🎉 Mise à jour terminée dans $INSTALL_DIR"
msg "➡️ Pour recharger vos alias maintenant : $RELOAD_HINT"


# Cleanup
rm -rf "$TMPDIR"