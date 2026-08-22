#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
export DOTFILES_DIR

run_full_install() {
  # Every skill, agent, hook, and theme lives inside a plugin under
  # agents/plugins/<name>/ -- installing a plugin is the only way any of
  # them reaches either harness. Symlinking the whole plugin directory
  # (rather than compiling/transforming its contents) makes it a Claude
  # Code skills-directory plugin (`<name>@skills-dir`, discovered in place)
  # and a Cursor local plugin, both live-edited from the one source.
  echo "Installing plugins..."
  mkdir -p "$HOME/.claude/skills" "$HOME/.cursor/plugins/local"
  for plugin in "$DOTFILES_DIR"/agents/plugins/*/; do
    [ -f "$plugin/.claude-plugin/plugin.json" ] || continue
    name=$(basename "${plugin%/}")
    ln -sfn "${plugin%/}" "$HOME/.claude/skills/$name"
    ln -sfn "${plugin%/}" "$HOME/.cursor/plugins/local/$name"
  done
  # prune dangling plugin symlinks (removed from dotfiles)
  find "$HOME/.claude/skills" "$HOME/.cursor/plugins/local" -maxdepth 1 -type l | while read -r link; do
    [ -e "$link" ] || rm "$link"
  done
  echo "Installing plugins... OK"

  echo "Installing Codex hooks..."
  DOTFILES_CODEX_HOOKS="$DOTFILES_DIR/.codex/hooks.json"
  CODEX_CONFIG_DIR="${CODEX_HOME:-$HOME/.codex}"
  GLOBAL_CODEX_HOOKS="$CODEX_CONFIG_DIR/hooks.json"
  if [ ! -f "$DOTFILES_CODEX_HOOKS" ]; then
    echo "Installing Codex hooks... skipped (no dotfiles hooks.json)"
  else
    mkdir -p "$CODEX_CONFIG_DIR"
    if [ ! -f "$GLOBAL_CODEX_HOOKS" ]; then
      cp "$DOTFILES_CODEX_HOOKS" "$GLOBAL_CODEX_HOOKS"
      echo "Installing Codex hooks... OK (installed fresh)"
    else
      # Codex loads all hooks from the user-level file. Preserve unrelated
      # user hooks while replacing this hook's prior entry, so setup remains
      # idempotent. Write beside the destination and rename atomically.
      tmp=$(mktemp "$GLOBAL_CODEX_HOOKS.XXXXXX")
      if jq -s '
        .[0] as $g |
        .[1] as $d |
        ($g * $d) |
        .hooks = (($g.hooks // {}) * ($d.hooks // {})) |
        .hooks.PostToolUse = (
          (($g.hooks.PostToolUse // []) |
            map(select(([.hooks[]?.command] | index("hooks-vale-lint --harness codex")) == null)))
          + ($d.hooks.PostToolUse // [])
        )
      ' "$GLOBAL_CODEX_HOOKS" "$DOTFILES_CODEX_HOOKS" > "$tmp"; then
        mv "$tmp" "$GLOBAL_CODEX_HOOKS"
        echo "Installing Codex hooks... OK"
      else
        rm -f "$tmp"
        echo "Installing Codex hooks... FAILED" >&2
        exit 1
      fi
    fi
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
    # Hooks aren't part of this file at all anymore -- they live solely in
    # each plugin's hooks/hooks.json, loaded by Claude Code itself when the
    # plugin is installed, so whatever "hooks" key (if any) is already in
    # the global settings.json is left untouched here.
    # .[0] = global (machine-specific), .[1] = dotfiles (baseline defaults).
    # Written via a same-directory temp file + mv (atomic rename) rather than a
    # direct `>` redirect, so a concurrent reader (another setup.sh run, or
    # Claude Code itself persisting a setting) can never observe a truncated
    # file mid-write. Same directory as GLOBAL_SETTINGS keeps mv on one
    # filesystem, since a cross-filesystem mv falls back to non-atomic copy.
    tmp=$(mktemp "$GLOBAL_SETTINGS.XXXXXX")
    if jq -s '
      .[0] as $g |
      .[1] as $d |
      $d * $g |
      .permissions.allow = (($g.permissions.allow // []) + ($d.permissions.allow // []) | unique | sort) |
      .permissions.deny  = (($g.permissions.deny  // []) + ($d.permissions.deny  // []) | unique | sort) |
      .permissions.ask   = (($g.permissions.ask   // []) + ($d.permissions.ask   // []) | unique | sort)
    ' "$GLOBAL_SETTINGS" "$DOTFILES_SETTINGS" > "$tmp"; then
      mv "$tmp" "$GLOBAL_SETTINGS"
      echo "Merging Claude settings... OK"
    else
      rm -f "$tmp"
      echo "Merging Claude settings... FAILED" >&2
      exit 1
    fi
  fi
}

run_full_install
