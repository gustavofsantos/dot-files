#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "Linking bin files..."
mkdir -p "$HOME/.bin"
find "$DOTFILES_DIR/bin" -type f -exec bash -c 'ln -sf "$1" "$HOME/.bin/$(basename "$1")"' _ {} \;
echo "Linking bin files... OK"
