#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "Installing skills..."
mkdir -p "$HOME/.claude/skills"
for skill in "$DOTFILES_DIR"/.claude/skills/*/; do
  [ -f "$skill/SKILL.md" ] || continue
  name=$(basename "$skill")
  ln -sfn "${skill%/}" "$HOME/.claude/skills/$name"
done
# prune dangling skill symlinks (removed from dotfiles)
find "$HOME/.claude/skills" -maxdepth 1 -type l | while read -r link; do
  [ -e "$link" ] || rm "$link"
done
echo "Installing skills... OK"

echo "Syncing skills to other harnesses..."
ln -sf "$DOTFILES_DIR/.claude/harness-profiles.yml" "$HOME/.claude/harness-profiles.yml"
if command -v ruby >/dev/null 2>&1; then
  ruby "$DOTFILES_DIR/bin/skills-sync" \
    --source "$DOTFILES_DIR/.claude/skills" \
    --profiles "$DOTFILES_DIR/.claude/harness-profiles.yml" >/dev/null \
    && echo "Syncing skills to other harnesses... OK" \
    || echo "Syncing skills to other harnesses... FAILED (non-fatal)"
else
  echo "Syncing skills to other harnesses... skipped (no ruby)"
fi

echo "Generating Cursor hooks wiring..."
# Derive ~/.cursor/hooks.json from ~/.agent-hooks.yml (+ local overlay), so the
# unified registry drives Cursor's hooks the way skills-sync drives its skills.
# Reads the linked ~/.agent-hooks.yml (link-home-files.sh runs earlier), so local
# overlays are honoured; only our `hooks-runner cursor …` entries are touched.
if command -v ruby >/dev/null 2>&1; then
  ruby "$DOTFILES_DIR/bin/cursor-hooks-sync" >/dev/null \
    && echo "Generating Cursor hooks wiring... OK" \
    || echo "Generating Cursor hooks wiring... FAILED (non-fatal)"
else
  echo "Generating Cursor hooks wiring... skipped (no ruby)"
fi

echo "Installing custom subagents..."
mkdir -p "$HOME/.claude/agents"
for agent in "$DOTFILES_DIR"/.claude/agents/*; do
  [ -f "$agent" ] || continue
  name=$(basename "$agent")
  ln -sf "$agent" "$HOME/.claude/agents/$name"
done
# prune dangling agent symlinks (removed from dotfiles)
find "$HOME/.claude/agents" -maxdepth 1 -type l | while read -r link; do
  [ -e "$link" ] || rm "$link"
done
echo "Installing custom subagents... OK"

echo "Installing custom commands..."
mkdir -p "$HOME/.claude/commands"
for cmd in "$DOTFILES_DIR"/.claude/commands/*.md; do
  [ -f "$cmd" ] || continue
  name=$(basename "$cmd")
  ln -sf "$cmd" "$HOME/.claude/commands/$name"
done
echo "Installing custom commands... OK"

echo "Installing custom themes..."
mkdir -p "$HOME/.claude/themes"
for theme in "$DOTFILES_DIR"/.claude/themes/*.json; do
  [ -f "$theme" ] || continue
  name=$(basename "$theme")
  ln -sf "$theme" "$HOME/.claude/themes/$name"
done
echo "Installing custom themes... OK"

echo "Installing custom rules..."
mkdir -p "$HOME/.claude/rules"
for rule in "$DOTFILES_DIR"/.claude/rules/*.md; do
  [ -f "$rule" ] || continue
  name=$(basename "$rule")
  ln -sf "$rule" "$HOME/.claude/rules/$name"
done
echo "Installing custom rules... OK"

echo "Installing custom workflows..."
mkdir -p "$HOME/.claude/workflows"
for wf in "$DOTFILES_DIR"/.claude/workflows/*; do
  [ -f "$wf" ] || continue
  name=$(basename "$wf")
  ln -sf "$wf" "$HOME/.claude/workflows/$name"
done
echo "Installing custom workflows... OK"

echo "Merging Claude settings..."
DOTFILES_SETTINGS="$DOTFILES_DIR/.claude/settings.json"
GLOBAL_SETTINGS="$HOME/.claude/settings.json"

if [ ! -f "$DOTFILES_SETTINGS" ]; then
  echo "Merging Claude settings... skipped (no dotfiles settings.json)"
elif [ ! -f "$GLOBAL_SETTINGS" ]; then
  cp "$DOTFILES_SETTINGS" "$GLOBAL_SETTINGS"
  echo "Merging Claude settings... OK (installed fresh)"
else
  # Global wins on scalar/object conflicts; permission and hooks arrays are unioned.
  # .[0] = global (machine-specific), .[1] = dotfiles (baseline defaults).
  merged=$(jq -s '
    .[0] as $g |
    .[1] as $d |
    $d * $g |
    .permissions.allow = (($g.permissions.allow // []) + ($d.permissions.allow // []) | unique | sort) |
    .permissions.deny  = (($g.permissions.deny  // []) + ($d.permissions.deny  // []) | unique | sort) |
    .permissions.ask   = (($g.permissions.ask   // []) + ($d.permissions.ask   // []) | unique | sort) |
    .hooks = (
      ($g.hooks // {}) as $gh |
      ($d.hooks // {}) as $dh |
      (($gh | keys_unsorted) + ($dh | keys_unsorted) | unique) |
      map(. as $ev | {($ev): ((($gh[$ev] // []) + ($dh[$ev] // [])) | unique)}) |
      add // {}
    )
  ' "$GLOBAL_SETTINGS" "$DOTFILES_SETTINGS")
  echo "$merged" > "$GLOBAL_SETTINGS"
  echo "Merging Claude settings... OK"
fi
