#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"

# Symlink every file matching $1 into dir $2, then remove any symlink in $2
# whose source no longer exists (a file removed from the dotfiles repo).
install_and_prune_symlinks() {
  local glob="$1" dest="$2" file name
  mkdir -p "$dest"
  for file in $glob; do
    [ -f "$file" ] || continue
    name=$(basename "$file")
    ln -sf "$file" "$dest/$name"
  done
  find "$dest" -maxdepth 1 -type l | while read -r link; do
    [ -e "$link" ] || rm "$link"
  done
}

echo "Compiling rules..."
"$DOTFILES_DIR/bin/rules-sync" >/dev/null \
  && echo "Compiling rules... OK" \
  || echo "Compiling rules... FAILED (non-fatal)"

echo "Compiling agents and commands..."
"$DOTFILES_DIR/bin/agents-sync" >/dev/null \
  && echo "Compiling agents and commands... OK" \
  || echo "Compiling agents and commands... FAILED (non-fatal)"

echo "Compiling hooks..."
"$DOTFILES_DIR/bin/hooks-sync" >/dev/null \
  && echo "Compiling hooks... OK" \
  || echo "Compiling hooks... FAILED (non-fatal)"

echo "Installing skills..."
mkdir -p "$HOME/.claude/skills"
for skill in "$DOTFILES_DIR"/agents/skills/*/; do
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
    --source "$DOTFILES_DIR/agents/skills" \
    --profiles "$DOTFILES_DIR/.claude/harness-profiles.yml" >/dev/null \
    && echo "Syncing skills to other harnesses... OK" \
    || echo "Syncing skills to other harnesses... FAILED (non-fatal)"
else
  echo "Syncing skills to other harnesses... skipped (no ruby)"
fi

echo "Installing custom subagents..."
install_and_prune_symlinks "$DOTFILES_DIR/.claude/agents/*" "$HOME/.claude/agents"
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
install_and_prune_symlinks "$DOTFILES_DIR/.claude/rules/*.md" "$HOME/.claude/rules"
echo "Installing custom rules... OK"

echo "Installing custom workflows..."
mkdir -p "$HOME/.claude/workflows"
for wf in "$DOTFILES_DIR"/.claude/workflows/*; do
  [ -f "$wf" ] || continue
  name=$(basename "$wf")
  ln -sf "$wf" "$HOME/.claude/workflows/$name"
done
echo "Installing custom workflows... OK"

echo "Installing Cursor rules..."
install_and_prune_symlinks "$DOTFILES_DIR/.cursor/rules/*.mdc" "$HOME/.cursor/rules"
echo "Installing Cursor rules... OK"

echo "Installing Cursor hooks..."
mkdir -p "$HOME/.cursor"
if [ -f "$DOTFILES_DIR/.cursor/hooks.json" ]; then
  ln -sf "$DOTFILES_DIR/.cursor/hooks.json" "$HOME/.cursor/hooks.json"
  echo "Installing Cursor hooks... OK"
else
  echo "Installing Cursor hooks... skipped (no .cursor/hooks.json)"
fi

echo "Merging Claude settings..."
DOTFILES_SETTINGS="$DOTFILES_DIR/.claude/settings.json"
GLOBAL_SETTINGS="$HOME/.claude/settings.json"

if [ ! -f "$DOTFILES_SETTINGS" ]; then
  echo "Merging Claude settings... skipped (no dotfiles settings.json)"
elif [ ! -f "$GLOBAL_SETTINGS" ]; then
  cp "$DOTFILES_SETTINGS" "$GLOBAL_SETTINGS"
  echo "Merging Claude settings... OK (installed fresh)"
else
  # Global wins on scalar/object conflicts; permission arrays are unioned.
  # Hooks are compiled output (hooks-sync), not hand-edited per machine, so
  # dotfiles fully replaces global hooks per event rather than unioning —
  # a union can never drop an entry a rename superseded, so renaming a hook
  # in the repo would otherwise leave the old, now-broken command duplicated
  # in every machine's global settings.json forever.
  # .[0] = global (machine-specific), .[1] = dotfiles (baseline defaults).
  merged=$(jq -s '
    .[0] as $g |
    .[1] as $d |
    $d * $g |
    .permissions.allow = (($g.permissions.allow // []) + ($d.permissions.allow // []) | unique | sort) |
    .permissions.deny  = (($g.permissions.deny  // []) + ($d.permissions.deny  // []) | unique | sort) |
    .permissions.ask   = (($g.permissions.ask   // []) + ($d.permissions.ask   // []) | unique | sort) |
    .hooks = ($d.hooks // {})
  ' "$GLOBAL_SETTINGS" "$DOTFILES_SETTINGS")
  echo "$merged" > "$GLOBAL_SETTINGS"
  echo "Merging Claude settings... OK"
fi
