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
echo "Creating local override files... OK"
