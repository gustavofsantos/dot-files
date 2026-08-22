#!/usr/bin/env bash
# Reject any write to entities.tsv or bridges.tsv whose last column does not name an
# existing probe file. A claim without a probe is a rumour.
#
# The tables and probes live in one org-wide vault under reconcile/. A probe id
# <repo>/<id> resolves to reconcile/probes/<repo>/<id>.sql. The repository name is only a
# namespace; the hook works from any current directory.
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
  */reconcile/entities.tsv|*/reconcile/bridges.tsv) ;;
  *) exit 0 ;;
esac

content=$(jq -r '.tool_input.content // .tool_input.new_string // ""' <<<"$input")

# last non-empty, non-header, non-comment line; last tab-separated field
field=$(printf '%s\n' "$content" \
        | grep -v '^[[:space:]]*$' \
        | grep -v '^#' \
        | tail -n 1 \
        | awk -F'\t' '{print $NF}' \
        | tr -d ' \r')

case "$field" in
  probe|UNKNOWN|-) exit 0 ;;   # header row, or an honestly declared unknown
esac

if [[ "$field" != */* ]]; then
  cat >&2 <<EOF
blocked: probe id has no repository namespace.

The last column must be '<repo>/<id>', for example 'billing-service/INV-002'. Got: '${field}'.
EOF
  exit 2
fi

vault="${path%/*}"
probe_path="$vault/probes/$field.sql"

if [ -f "$probe_path" ]; then
  exit 0
fi

cat >&2 <<EOF
blocked: claim without a probe.

The last column of a row in $path must be '<repo>/<id>' naming a probe in the org-wide vault,
or be literally UNKNOWN if the relationship has not been measured yet.

Got: '${field}' (${probe_path} does not exist)

Measure coverage first (references/discovery.md), write the probe, then promote.
EOF
exit 2
