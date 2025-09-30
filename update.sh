#!/usr/bin/env bash
set -euo pipefail


# ========= Robust defaults =========
HOME="${HOME:-$(getent passwd "$(id -u)" 2>/dev/null | cut -d: -f6)}"
: "${HOME:?HOME not set}"


OWNER="${OWNER:-ShadowHedgehog76}"
REPO="${REPO:-BashUtils}"
BRANCH="${BRANCH:-main}"
INSTALL_DIR_DEFAULT="$HOME/Documents/alias"
INSTALL_DIR="${INSTALL_DIR:-$INSTALL_DIR_DEFAULT}"
if [[ -z "$INSTALL_DIR" ]]; then INSTALL_DIR="$INSTALL_DIR_DEFAULT"; fi


TARBALL_URL="https://codeload.github.com/${OWNER}/${REPO}/tar.gz/refs/heads/${BRANCH}"


BLOCK_START="# >>> BashUtils aliases (managed) >>>"
BLOCK_END="# <<< BashUtils aliases (managed) <<<"
ACTIVATE="$INSTALL_DIR/activate.sh"


# ========= Helpers =========
build_alias_lines() {
printf 'export PATH="%s/Documents/alias:$PATH"
' "$HOME"
while IFS= read -r -d '' f; do
base="$(basename "$f")"
name="${base%.sh}"
printf 'alias %s="bash %s/%s"
' "$name" "$INSTALL_DIR" "$base"
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


# ========= Begin =========
echo "⬇️ Mise à jour depuis ${OWNER}/${REPO}@${BRANCH} ..."
mkdir -p "$INSTALL_DIR"


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
echo "➡️ Pour recharger vos alias maintenant : $RELOAD_HINT"