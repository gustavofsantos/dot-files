#!/usr/bin/env bash
# Idempotently initialise ~/engineering as a git repo so the vault can be
# auto-committed at every agent turn end (see bin/engineering-autocommit).
set -euo pipefail

ENG_DIR="${ENGINEERING_HOME:-$HOME/engineering}"

if [[ ! -d "$ENG_DIR" ]]; then
  echo "Engineering vault $ENG_DIR not found — skipping repo init."
  exit 0
fi

echo "Preparing engineering vault git repo..."

if ! git -C "$ENG_DIR" rev-parse --is-inside-work-tree &>/dev/null; then
  git -C "$ENG_DIR" init --quiet
  echo "  git init $ENG_DIR"
fi

GITIGNORE="$ENG_DIR/.gitignore"
if [[ ! -f "$GITIGNORE" ]]; then
  cat > "$GITIGNORE" <<'EOF'
# Volatile / regenerable — kept out of vault auto-commit history.
.trash/
.obsidian/workspace*.json
.obsidian/cache
.DS_Store
EOF
  echo "  wrote $GITIGNORE"
fi

# Seed history with one clean snapshot so the first auto-commit isn't a 200-file
# genesis dump. No-op once the repo already has commits.
if ! git -C "$ENG_DIR" rev-parse --verify HEAD &>/dev/null; then
  git -C "$ENG_DIR" add -A
  git -C "$ENG_DIR" commit --quiet -m "chore: initial vault snapshot" && \
    echo "  committed initial vault snapshot"
fi

echo "Preparing engineering vault git repo... OK"
