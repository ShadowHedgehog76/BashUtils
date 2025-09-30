#!/usr/bin/env bash
set -euo pipefail


# === Robust defaults ===
HOME="${HOME:-$(getent passwd "$(id -u)" 2>/dev/null | cut -d: -f6)}"
: "${HOME:?HOME not set}"
OWNER="${OWNER:-ShadowHedgehog76}"
REPO="${REPO:-BashUtils}"
BRANCH="${BRANCH:-main}"
TARBALL_URL="https://codeload.github.com/${OWNER}/${REPO}/tar.gz/refs/heads/${BRANCH}"
INSTALL_DIR="${INSTALL_DIR:-$HOME/Documents/alias}"
ACTIVATE="$INSTALL_DIR/activate.sh"


BLOCK_START="# >>> BashUtils aliases (managed) >>>"
BLOCK_END="# <<< BashUtils aliases (managed) <<<"


build_alias_lines() {
echo "export PATH=\"$HOME/Documents/alias:\$PATH\""
while IFS= read -r -d '' f; do
base="$(basename "$f")"
name="${base%.sh}"
echo "alias ${name}=\"bash $INSTALL_DIR/${base}\""
done < <(find "$INSTALL_DIR" -maxdepth 1 -type f -name '*.sh' -print0 | sort -z)
}


build_alias_block() {
echo "$BLOCK_START"
build_alias_lines
echo "$BLOCK_END"
}


update_rc_file() {
local rc="$1"
mkdir -p "$(dirname "$rc")" || true
touch "$rc"
local tmp; tmp="$(mktemp)"
awk -v s="$BLOCK_START" -v e="$BLOCK_END" '
BEGIN{in=0}
$0==s{in=1; next}
$0==e{in=0; next}
!in{print}
' "$rc" > "$tmp"
mv "$tmp" "$rc"
build_alias_block >> "$rc"
}


echo "🔧 Installation de ${OWNER}/${REPO} (branche ${BRANCH}) dans $INSTALL_DIR ..."
mkdir -p "$INSTALL_DIR"


TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT
TARBALL="$TMPDIR/repo.tar.gz"


if [[ -z "$TARBALL_URL" ]]; then
echo "⚠️ URL du tarball vide — vérifie OWNER/REPO/BRANCH" >&2
exit 1
fi


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
EOF