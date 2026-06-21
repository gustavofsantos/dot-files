#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "Installing personal plugins..."
# Cursor (2.5+) loads local plugins from ~/.cursor/plugins/local/<name>.
# Symlinking the plugin dir there keeps edits live (no copy). Reload Cursor to
# pick up changes.
mkdir -p "$HOME/.cursor/plugins/local"
for plugin in "$DOTFILES_DIR"/agents/plugins/*/; do
  [ -d "$plugin" ] || continue
  [ -d "$plugin/.cursor-plugin" ] || continue
  name=$(basename "$plugin")
  ln -sfn "${plugin%/}" "$HOME/.cursor/plugins/local/$name"
done
# prune dangling local-plugin symlinks (plugins removed from dotfiles)
find "$HOME/.cursor/plugins/local" -maxdepth 1 -type l | while read -r link; do
  [ -e "$link" ] || rm "$link"
done
echo "Installing personal plugins... OK"

# Remove stale skill symlinks left by the old .claude/skills install.
if [ -d "$HOME/.cursor/skills" ]; then
  find "$HOME/.cursor/skills" -maxdepth 1 -type l | while read -r link; do
    target=$(readlink "$link")
    case "$target" in
      "$DOTFILES_DIR"/.claude/skills/*) rm "$link" ;;
      *) [ -e "$link" ] || rm "$link" ;;
    esac
  done
fi

echo "Installing custom subagents..."
mkdir -p "$HOME/.cursor/agents"
for agent in "$DOTFILES_DIR"/.claude/agents/*; do
  [ -f "$agent" ] || continue
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
