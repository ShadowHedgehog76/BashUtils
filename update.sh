#!/usr/bin/env bash
set -euo pipefail


# ========= Robust defaults =========
# Ensure HOME is set
HOME="${HOME:-$(getent passwd $(id -u) | cut -d: -f6)}"
: "${HOME:?HOME not set}"


OWNER="${OWNER:-ShadowHedgehog76}"
REPO="${REPO:-BashUtils}"
BRANCH="${BRANCH:-main}"
INSTALL_DIR_DEFAULT="$HOME/Documents/alias"
INSTALL_DIR="${INSTALL_DIR:-$INSTALL_DIR_DEFAULT}"
[[ -z "$INSTALL_DIR" ]] && INSTALL_DIR="$INSTALL_DIR_DEFAULT"


TARBALL_URL="https://codeload.github.com/${OWNER}/${REPO}/tar.gz/refs/heads/${BRANCH}"


BLOCK_START="# >>> BashUtils aliases (managed) >>>"
BLOCK_END="# <<< BashUtils aliases (managed) <<<"
ACTIVATE="$INSTALL_DIR/activate.sh"


# ========= Helpers =========
build_alias_block() {
local add_path='export PATH="$HOME/Documents/alias:$PATH"'
local lines=()
while IFS= read -r -d '' f; do
local base name
base="$(basename "$f")"
name="${base%.sh}"
lines+=("alias ${name}=\"bash $INSTALL_DIR/${base}\"")
done < <(find "$INSTALL_DIR" -maxdepth 1 -type f -name '*.sh' -print0 | sort -z)


printf "%s
" "$BLOCK_START"
printf "%s
" "$add_path"
for L in "${lines[@]}"; do printf "%s
" "$L"; done
printf "%s
" "$BLOCK_END"
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


# ========= Begin =========
echo "⬇️ Mise à jour depuis ${OWNER}/${REPO}@${BRANCH} ..."
mkdir -p "$INSTALL_DIR"


TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT
TARBALL="$TMPDIR/repo.tar.gz"


if [[ -z "$TARBALL_URL" ]]; then
echo "➡️ Pour recharger vos alias maintenant : $RELOAD_HINT"