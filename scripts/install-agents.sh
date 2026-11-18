#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
export DOTFILES_DIR

# link_all SRC_DIR DEST_DIR [VIA_DIR]: link each entry of SRC_DIR into DEST_DIR
# (pointing at VIA_DIR/<name> instead when given), then
# remove links in DEST_DIR that point into this repo and no longer resolve.
# A real file or directory already at a destination is reported and left alone.
link_all() {
  local src="$1" dest="$2" via="${3:-$1}" entry name target
  mkdir -p "$dest"
  for entry in "$src"/*; do
    [ -e "$entry" ] || continue
    name=$(basename "$entry")
    if [ -e "$dest/$name" ] && [ ! -L "$dest/$name" ]; then
      echo "  skipping $dest/$name: a real file or directory is in the way" >&2
      continue
    fi
    ln -sfn "$via/$name" "$dest/$name"
  done
  find "$dest" -maxdepth 1 -type l | while read -r link; do
    target=$(readlink "$link")
    case "$target" in
      "$DOTFILES_DIR/"*|"$HOME/.agents/skills/"*) [ -e "$link" ] || rm "$link" ;;
    esac
  done
}

run_full_install() {
  # Shared: skills every harness reads from ~/.agents/skills/. Claude Code
  # only reads ~/.claude/skills/, so each skill is linked there too, through
  # the ~/.agents link.
  echo "Installing skills..."
  link_all "$DOTFILES_DIR/.agents/skills" "$HOME/.agents/skills"
  link_all "$DOTFILES_DIR/.agents/skills" "$HOME/.claude/skills" "$HOME/.agents/skills"
  echo "Installing skills... OK"

  # Claude only: subagents and mods (mods load through CLAUDE_CODE_PLUGIN_DIRS
  # in .claude/settings.json).
  echo "Installing Claude agents and mods..."
  link_all "$DOTFILES_DIR/.claude/agents" "$HOME/.claude/agents"
  link_all "$DOTFILES_DIR/.claude/mods" "$HOME/.claude/mods"
  echo "Installing Claude agents and mods... OK"

  # Cursor only: subagents.
  echo "Installing Cursor agents..."
  link_all "$DOTFILES_DIR/.cursor/agents" "${CURSOR_HOME:-$HOME/.cursor}/agents"
  echo "Installing Cursor agents... OK"

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
  mkdir -p "$HOME/.claude"

  if [ ! -f "$DOTFILES_SETTINGS" ]; then
    echo "Merging Claude settings... skipped (no dotfiles settings.json)"
  elif [ ! -f "$GLOBAL_SETTINGS" ]; then
    cp "$DOTFILES_SETTINGS" "$GLOBAL_SETTINGS"
    echo "Merging Claude settings... OK (installed fresh)"
  else
    # Global wins on scalar/object conflicts; permission arrays are unioned.
    # This repo's settings.json carries no "hooks" key, so whatever "hooks"
    # key is already in the global settings.json is left untouched here.
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
