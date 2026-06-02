#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "Installing custom skills..."
for skill in "$DOTFILES_DIR"/.claude/skills/*/; do
  [ -d "$skill" ] || continue
  name=$(basename "$skill")
  ln -sfn "$skill" "$HOME/.claude/skills/$name"
done
echo "Installing custom skills... OK"

echo "Installing custom subagents..."
for agent in "$DOTFILES_DIR"/.claude/agents/*; do
  name=$(basename "$agent")
  ln -sf "$agent" "$HOME/.claude/agents/$name"
done
echo "Installing custom subagents... OK"
