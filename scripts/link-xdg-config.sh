#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "Linking xdg config..."
mkdir -p "$HOME/.config"
for entry in "$DOTFILES_DIR"/config/*; do
  [ -e "$entry" ] || continue
  name=$(basename "$entry")
  [ "$name" == ".stowrc" ] && continue
  ln -sf "$entry" "$HOME/.config/$name"
done
echo "Linking xdg config... OK"
