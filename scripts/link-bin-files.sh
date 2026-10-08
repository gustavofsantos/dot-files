#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "Linking bin files..."
mkdir -p "$HOME/.bin"
# bin/ entries may themselves be symlinks (e.g. into .agents/skills/*/scripts); link the
# resolved original so ~/.bin points at the real file. Dangling links are reported, not linked.
find "$DOTFILES_DIR/bin" -mindepth 1 -maxdepth 1 \( -type f -o -type l \) | while read -r entry; do
  target="$(readlink -f "$entry")"
  if [ -f "$target" ]; then
    ln -sf "$target" "$HOME/.bin/$(basename "$entry")"
  else
    echo "  skipping $(basename "$entry"): link target missing" >&2
  fi
done
# prune dangling symlinks (source file removed or renamed in the dotfiles repo)
find "$HOME/.bin" -maxdepth 1 -type l | while read -r link; do
  [ -e "$link" ] || rm "$link"
done
echo "Linking bin files... OK"
