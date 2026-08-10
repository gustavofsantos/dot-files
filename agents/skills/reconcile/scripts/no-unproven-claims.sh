#!/usr/bin/env bash
# Reject any write to entities.tsv or bridges.tsv whose last column does not name an
# existing probe file. A claim without a probe is a rumour.
#
# The tables live in the knowledge vault, under reconcile/<repo>/. The probes live in the
# repository, under model/probes/. This script runs from the repository, so it resolves the
# probe id against the working directory.
#
# Install as a PreToolUse hook on Write|Edit in .claude/settings.json:
#
#   { "hooks": { "PreToolUse": [ {
#       "matcher": "Write|Edit",
#       "hooks": [ { "type": "command",
#                    "command": ".claude/skills/reconcile/scripts/no-unproven-claims.sh" } ]
#   } ] } }

set -euo pipefail

input=$(cat)
path=$(jq -r '.tool_input.file_path // ""' <<<"$input")

case "$path" in
  */reconcile/*/entities.tsv|*/reconcile/*/bridges.tsv) ;;
  *) exit 0 ;;
esac

content=$(jq -r '.tool_input.content // .tool_input.new_string // ""' <<<"$input")

# last non-empty, non-header, non-comment line; last tab-separated field
probe=$(printf '%s\n' "$content" \
        | grep -v '^[[:space:]]*$' \
        | grep -v '^#' \
        | tail -n 1 \
        | awk -F'\t' '{print $NF}' \
        | tr -d ' \r')

case "$probe" in
  probe|UNKNOWN|-) exit 0 ;;   # header row, or an honestly declared unknown
esac

if [ -f "model/probes/${probe}.sql" ]; then
  exit 0
fi

cat >&2 <<EOF
blocked: claim without a probe.

The last column of a row in $path must name a probe that exists in this repository
as model/probes/<id>.sql, or be literally UNKNOWN if the relationship has not been
measured yet.

Got: '${probe}' (model/probes/${probe}.sql does not exist)

Measure coverage first (references/discovery.md), write the probe, then promote.
EOF
exit 2
