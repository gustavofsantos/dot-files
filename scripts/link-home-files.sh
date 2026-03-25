#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "Linking home files..."
ln -sf "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"
ln -sf "$DOTFILES_DIR/.githelpers" "$HOME/.githelpers"
ln -sf "$DOTFILES_DIR/.gitmessage" "$HOME/.gitmessage"
ln -sf "$DOTFILES_DIR/.gitthemes" "$HOME/.gitthemes"
ln -sf "$DOTFILES_DIR/.ideavimrc" "$HOME/.ideavimrc"
ln -sf "$DOTFILES_DIR/.psqlrc" "$HOME/.psqlrc"
ln -sf "$DOTFILES_DIR/.zprofile" "$HOME/.zprofile"
ln -sf "$DOTFILES_DIR/.zshenv" "$HOME/.zshenv"
ln -sf "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
ln -sf "$DOTFILES_DIR/.todo.cfg" "$HOME/.todo.cfg"
echo "Linking home files... OK"
