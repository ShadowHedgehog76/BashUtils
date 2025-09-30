#!/usr/bin/env bash
set -euo pipefail


# === Config ===
# Where scripts will live
INSTALL_DIR="${INSTALL_DIR:-$HOME/Documents/alias}"
# Repo coordinates (override with env vars if you need another branch/fork)
OWNER="${OWNER:-ShadowHedgehog76}"
REPO="${REPO:-BashUtils}"
BRANCH="${BRANCH:-main}"
TARBALL_URL="https://codeload.github.com/${OWNER}/${REPO}/tar.gz/refs/heads/${BRANCH}"


# Messages
echo "⬇️ Mise à jour depuis ${OWNER}/${REPO}@${BRANCH} ..."
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


# Sync everything except README files (case-insensitive) and VCS/CI metadata
# If rsync exists, use it for robust syncing; otherwise fall back to find/cp.
if command -v rsync >/dev/null 2>&1; then
rsync -a --delete \
--exclude='README' --exclude='README.*' --exclude='readme' --exclude='readme.*' \
--exclude='.git/' --exclude='.github/' --exclude='.gitignore' \
"$ROOT_DIR"/ "$INSTALL_DIR"/
else
# Manual copy excluding README* and VCS files
( cd "$ROOT_DIR" && \
find . \
-path './.git*' -prune -o \
-path './.github*' -prune -o \
-iname 'README*' -prune -o \
-type f -print0 | \
xargs -0 -I{} sh -c 'mkdir -p "${0%/*}"; cp -f "${1}" "$INSTALL_DIR/${0#./}"' '{}' '{}' )
fi


# Ensure all .sh are executable
find "$INSTALL_DIR" -maxdepth 1 -type f -name '*.sh' -exec chmod +x {} +


echo "🎉 Mise à jour terminée dans $INSTALL_DIR"


# Cleanup
rm -rf "$TMPDIR"