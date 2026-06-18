#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "Installing custom skills..."
for skill in "$DOTFILES_DIR"/.claude/skills/*/; do
  [ -d "$skill" ] || continue
  name=$(basename "$skill")
  ln -sfn "$skill" "$HOME/.cursor/skills/$name"
done
# prune dangling skill symlinks (removed from dotfiles)
find "$HOME/.cursor/skills" -maxdepth 1 -type l | while read -r link; do
  [ -e "$link" ] || rm "$link"
done
echo "Installing custom skills... OK"

echo "Installing custom subagents..."
for agent in "$DOTFILES_DIR"/.claude/agents/*; do
  name=$(basename "$agent")
  cp "$agent" "$HOME/.cursor/agents/$name"
done
echo "Installing custom subagents... OK"

echo "Installing custom commands..."
mkdir -p "$HOME/.cursor/commands"
for cmd in "$DOTFILES_DIR"/.claude/commands/*.md; do
  [ -f "$cmd" ] || continue
  name=$(basename "$cmd")
  ln -sf "$cmd" "$HOME/.cursor/commands/$name"
done
echo "Installing custom commands... OK"

echo "Merging Cursor hooks..."
BASELINE="$DOTFILES_DIR/.cursor/hooks.json"
GLOBAL="$HOME/.cursor/hooks.json"

if ! command -v jq &>/dev/null; then
  echo "Merging Cursor hooks... skipped (jq not found)"
  exit 0
fi
if [ ! -f "$BASELINE" ]; then
  echo "Merging Cursor hooks... skipped (no baseline .cursor/hooks.json)"
  exit 0
fi

mkdir -p "$HOME/.cursor"

# Cursor spawns hooks as child processes with a minimal PATH, so commands must
# be absolute. Expand a leading ~/ in the baseline to $HOME at install time.
expanded=$(jq --arg home "$HOME" '
  .hooks |= map_values(
    map(.command |= (if startswith("~/") then $home + .[1:] else . end))
  )
' "$BASELINE")

if [ ! -f "$GLOBAL" ]; then
  echo "$expanded" > "$GLOBAL"
  echo "Merging Cursor hooks... OK (installed fresh)"
else
  # Preserve the user's existing (hand-managed) hooks; union each event's
  # command array, deduped by command. .[0] = global, .[1] = baseline.
  merged=$(jq -s '
    .[0] as $g |
    .[1] as $d |
    {
      version: ($g.version // $d.version // 1),
      hooks: (
        ((($g.hooks // {}) | keys_unsorted) + (($d.hooks // {}) | keys_unsorted) | unique)
        | map(. as $ev | {
            ($ev): ((($g.hooks[$ev] // []) + ($d.hooks[$ev] // [])) | unique_by(.command))
          })
        | add // {}
      )
    }
  ' "$GLOBAL" <(echo "$expanded"))
  echo "$merged" > "$GLOBAL"
  echo "Merging Cursor hooks... OK"
fi
