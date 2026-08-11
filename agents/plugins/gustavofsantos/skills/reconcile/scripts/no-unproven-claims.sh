#!/usr/bin/env bash
# Reject any write to entities.tsv or bridges.tsv whose last column does not name an
# existing probe file. A claim without a probe is a rumour.
#
# The tables live in one org-wide knowledge vault, under reconcile/ — not one per repo, since
# the business rarely fits in one repository. The probes live in the repository named in the
# probe id itself: <repo>/<id> resolves to model/probes/<id>.sql. This script can only see the
# working directory it runs in, so it checks that <repo> is the repository you are writing
# from — promote a row while sitting in the repository whose probe it names.
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

# field is "<repo>/<id>" (preferred) or a bare "<id>" (only when no repo will ever collide).
repo=""
probe="$field"
if [[ "$field" == */* ]]; then
  repo="${field%/*}"
  probe="${field##*/}"
fi

here=$(basename "$PWD")
if [ -n "$repo" ] && [ "$repo" != "$here" ]; then
  cat >&2 <<EOF
blocked: probe names a different repository than this one.

The probe '${field}' in $path names repository '${repo}', but this is '${here}'. Promote
the row from inside '${repo}', where model/probes/${probe}.sql actually lives.
EOF
  exit 2
fi

if [ -f "model/probes/${probe}.sql" ]; then
  exit 0
fi

cat >&2 <<EOF
blocked: claim without a probe.

The last column of a row in $path must be '<repo>/<id>' naming a probe that exists in that
repository as model/probes/<id>.sql, or be literally UNKNOWN if the relationship has not been
measured yet.

Got: '${field}' (model/probes/${probe}.sql does not exist here)

Measure coverage first (references/discovery.md), write the probe, then promote.
EOF
exit 2
