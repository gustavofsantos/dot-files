#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "Linking bin files..."
mkdir -p "$HOME/.bin"
find "$DOTFILES_DIR/bin" -type f -exec bash -c 'ln -sf "$1" "$HOME/.bin/$(basename "$1")"' _ {} \;
# agents/hooks/ holds hook scripts alongside per-harness config JSON
# (claude.settings.json, cursor.hooks.json) — only the executables go on PATH.
find "$DOTFILES_DIR/agents/hooks" -maxdepth 1 -type f -perm -u+x \
  -exec bash -c 'ln -sf "$1" "$HOME/.bin/$(basename "$1")"' _ {} \;
# prune dangling symlinks (source file removed or renamed in the dotfiles repo)
find "$HOME/.bin" -maxdepth 1 -type l | while read -r link; do
  [ -e "$link" ] || rm "$link"
done
echo "Linking bin files... OK"
