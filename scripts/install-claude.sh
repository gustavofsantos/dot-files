#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "Installing personal plugins..."
# Skills now ship as plugins under agents/plugins/, registered via a local
# "directory" marketplace. `plugin install` COPIES each plugin into
# ~/.claude/plugins/cache/personal/<name>/<version>/ from the repo's committed
# HEAD (not the working tree), so `marketplace update` + `plugin update` are run
# to refresh the cache after a *committed* change. Uncommitted edits are not
# loaded. All four commands are idempotent.
MARKETPLACE="$DOTFILES_DIR/agents/plugins"
PLUGINS=(bruno clojure engineering productivity)
if command -v claude &>/dev/null; then
  claude plugin marketplace add "$MARKETPLACE" >/dev/null 2>&1 || true
  claude plugin marketplace update personal >/dev/null 2>&1 || true
  for p in "${PLUGINS[@]}"; do
    claude plugin install "$p@personal" >/dev/null 2>&1 || true
    claude plugin update  "$p@personal" >/dev/null 2>&1 || true
  done
  echo "Installing personal plugins... OK"
else
  echo "Installing personal plugins... skipped (claude not on PATH)"
fi

# Remove stale skill symlinks left by the old .claude/skills install.
if [ -d "$HOME/.claude/skills" ]; then
  find "$HOME/.claude/skills" -maxdepth 1 -type l | while read -r link; do
    target=$(readlink "$link")
    case "$target" in
      "$DOTFILES_DIR"/.claude/skills/*) rm "$link" ;;
      *) [ -e "$link" ] || rm "$link" ;;
    esac
  done
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
