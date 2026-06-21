#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "Linking xdg config..."
mkdir -p "$HOME/.config"
for entry in "$DOTFILES_DIR"/config/*; do
  [ -e "$entry" ] || continue
  name=$(basename "$entry")
  [ "$name" == ".stowrc" ] && continue
  # -n: don't dereference an existing symlink to a dir (else a re-run nests the
  # link inside the already-linked repo dir, e.g. config/bat/bat -> config/bat).
  ln -sfn "$entry" "$HOME/.config/$name"
done
echo "Linking xdg config... OK"
