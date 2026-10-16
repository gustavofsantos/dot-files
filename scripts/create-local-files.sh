#!/usr/bin/env bash
set -euo pipefail

echo "Creating local override files..."
touch "$HOME/.gitconfig.local"
touch "$HOME/.zshlocal"

# Global checks registry: enrolls the repos that run checks after each agent
# turn. Seeded once with a commented example; never overwritten.
if [ ! -f "$HOME/.checks.yml" ]; then
  cat > "$HOME/.checks.yml" <<'EOF'
# ~/.checks.yml — repositories that run checks after each agent turn.
#
# Each repo is matched by `path` (its main working tree); every worktree of a
# registered repo is covered automatically. Each check is a name + a command,
# run with the repo as cwd. Machine-specific checks go in ~/.checks.local.yml
# (same shape), overlaid by check name.
#
# repositories:
#   - path: ~/dot-files
#     checks:
#       - name: settings-json
#         command: jq -e . .claude/settings.json >/dev/null
repositories: []
EOF
fi
# Project list for tmux-sessionizer / project-dirs. Seeded once; never
# overwritten.
if [ ! -f "$HOME/.projects" ]; then
  cat > "$HOME/.projects" <<'EOF'
# ~/.projects — the repositories tmux-sessionizer (and Doom) offer.
#
# One directory per line; `~` is expanded, `#` starts a comment, and a glob
# (`~/Workplace/*`) adds every directory it matches. Each git repo is listed
# with its worktrees (git-add-worktree puts them under ~/.worktrees).
~/dot-files
EOF
fi
# One-time migration: rename ~/.claude-sessions/ → ~/.agent-sessions/
if [[ -d "$HOME/.claude-sessions" && ! -d "$HOME/.agent-sessions" ]]; then
  mv "$HOME/.claude-sessions" "$HOME/.agent-sessions"
  echo "Migrated ~/.claude-sessions → ~/.agent-sessions"
fi

echo "Creating local override files... OK"
