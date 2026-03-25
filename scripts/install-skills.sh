#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "Installing custom skills..."
mkdir -p "$HOME/.claude/skills"
mkdir -p "$HOME/.cursor/skills"
for skill in "$DOTFILES_DIR"/skills/*/; do
  [ -d "$skill" ] || continue
  name=$(basename "$skill")
  # Claude Code: symlinks work
  ln -sfn "$skill" "$HOME/.claude/skills/$name"
  # Cursor: symlinks are broken for global skills (known bug), use copies
  rm -rf "$HOME/.cursor/skills/$name"
  cp -R "$skill" "$HOME/.cursor/skills/$name"
done
echo "Installing custom skills... OK"
