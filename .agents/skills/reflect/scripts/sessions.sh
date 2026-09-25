#!/usr/bin/env bash
# sessions.sh — find agent transcripts not yet reflected on, digest them, record them.
#
#   sessions.sh pending                  harness, id, from, to, path per pending session
#   sessions.sh digest [--limit N] [--out DIR]
#                                        write digests + manifest.tsv, print DIR and a summary
#   sessions.sh commit DIR               record everything in DIR/manifest.tsv as analyzed
#   sessions.sh seed                     record every session on disk as analyzed
#
# The state is a set: one "harness<TAB>session-id<TAB>lines" row per analyzed session.
# Pending = sessions on disk that are not in the set, plus sessions in the set whose
# transcript has grown since (only the new lines are digested). No timestamps are used.
set -euo pipefail

CLAUDE_DIR="${REFLECT_CLAUDE_PROJECTS:-$HOME/.claude/projects}"
CURSOR_DIR="${REFLECT_CURSOR_PROJECTS:-$HOME/.cursor/projects}"
STATE="${REFLECT_STATE:-${XDG_STATE_HOME:-$HOME/.local/state}/reflect/analyzed.tsv}"
MAX_CHARS=1500      # assistant prose
MAX_USER_CHARS=4000 # user text, where domain explanations live
MIN_BYTES=80        # a digest body smaller than this is trivial

usage() {
  sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//' >&2
  exit 64
}

# harness, id, lines, path, project dir — for every top-level transcript on disk.
# Claude subagent transcripts live in <session>/subagents/ and are never matched.
inventory() {
  if [[ -d "$CLAUDE_DIR" ]]; then
    find "$CLAUDE_DIR" -mindepth 2 -maxdepth 2 -name '*.jsonl' -type f
  fi | while IFS= read -r f; do
    printf 'claude\t%s\t%s\t%s\t%s\n' "$(basename "$f" .jsonl)" "$(wc -l < "$f")" "$f" "$(dirname "$f")"
  done
  if [[ -d "$CURSOR_DIR" ]]; then
    find "$CURSOR_DIR" -mindepth 4 -maxdepth 4 -path '*/agent-transcripts/*/*.jsonl' -type f
  fi | while IFS= read -r f; do
    printf 'cursor\t%s\t%s\t%s\t%s\n' "$(basename "$f" .jsonl)" "$(wc -l < "$f")" "$f" "$(dirname "$(dirname "$(dirname "$f")")")"
  done
}

state_rows() { [[ -f "$STATE" ]] && cat "$STATE" || true; }

# harness, id, from, to, path, project dir — the set difference against the state.
# A transcript shorter than its recorded count was rewritten, so it is read again whole.
pending() {
  awk -F'\t' -v OFS='\t' '
    FILENAME == ARGV[1] { seen[$1 FS $2] = $3; next }
    {
      k = $1 FS $2
      if (!(k in seen))       from = 0
      else if ($3 > seen[k])  from = seen[k]
      else if ($3 < seen[k])  from = 0
      else                    next
      print $1, $2, from, $3, $4, $5
    }' <(state_rows) <(inventory) | sort -t$'\t' -k1,1 -k2,2
}

# Merge harness/id/lines rows from stdin into the state. The incoming count wins, since
# it is what was actually read. Written atomically.
record() {
  mkdir -p "$(dirname "$STATE")"
  local tmp
  tmp=$(mktemp "$STATE.XXXXXX")
  awk -F'\t' -v OFS='\t' '
    FILENAME == ARGV[1] { if (NF >= 3) row[$1 FS $2] = $3; next }
    NF >= 3   { row[$1 FS $2] = $3 }
    END       { for (k in row) print k, row[k] }' <(state_rows) - | sort > "$tmp"
  mv "$tmp" "$STATE"
}

truncate_jq='def cut_at($n): if length > $n then .[0:$n] + " …[+\(length - $n) chars]" else . end;
def cut: cut_at('"$MAX_CHARS"');
def ucut: cut_at('"$MAX_USER_CHARS"');
def flat: gsub("\\s*\n\\s*"; " ⏎ ");'

# Claude: user prompts, assistant prose, and each failed tool call paired with its input.
# Sidechains, meta lines, thinking, successful tool output and local-command noise are dropped.
claude_digest() {
  jq -rs "$truncate_jq"'
    (map(select(.type == "assistant") | .message.content[]? | select(.type == "tool_use") | {(.id): .})
      | add // {}) as $calls
    | .[]
    | select(.isSidechain != true and .isMeta != true and .isCompactSummary != true)
    | if .type == "user" then
        .message.content
        | if type == "string" then
            if startswith("<command-name>") then
              "**user:** " + ((capture("<command-name>(?<n>[^<]*)</command-name>").n)
                + " " + ((capture("<command-args>(?<a>[^<]*)</command-args>").a) // "")) + "\n"
            elif startswith("<local-command") or startswith("This session is being continued") then empty
            else "**user:** " + ucut + "\n" end
          else .[]
            | if .type == "text" and (.text | startswith("<") | not) then "**user:** " + (.text | ucut) + "\n"
              elif .type == "tool_result" and .is_error == true then
                ($calls[.tool_use_id] // {name: "?", input: {}}) as $c
                | "**tool failed:** " + $c.name + " `"
                  + (($c.input.command // $c.input.file_path // ($c.input | tojson)) | tostring | flat | .[0:300])
                  + "` → " + ((.content | if type == "array" then map(.text? // "") | join(" ") else tostring end) | flat | .[0:300])
                  + "\n"
              else empty end
          end
      elif .type == "assistant" then
        .message.content[]? | select(.type == "text") | "**assistant:** " + (.text | cut) + "\n"
      else empty end'
}

# Cursor transcripts hold prose and tool calls but no tool results.
cursor_digest() {
  jq -r "$truncate_jq"'
    .role as $r
    | .message.content[]? | select(.type == "text") | .text
    | if $r == "user" then
        gsub("<timestamp>[^<]*</timestamp>\\s*"; "")
        | (capture("<user_query>\\s*(?<q>[\\s\\S]*?)\\s*</user_query>").q // .)
        | "**user:** " + ucut + "\n"
      else "**assistant:** " + cut + "\n" end'
}

# Where the session ran, as a repository path when it can be resolved.
workdir() {
  local harness=$1 slice=$2 projdir=$3 wd=""
  case "$harness" in
    claude) wd=$(jq -r 'select(.cwd) | .cwd' <<< "$slice" | head -1) ;;
    cursor) wd=$(grep -o -m1 'workspacePath=[^ ]*' "$projdir/worker.log" 2>/dev/null | cut -d= -f2 || true) ;;
  esac
  [[ -z "$wd" ]] && { basename "$projdir"; return; }
  git -C "$wd" rev-parse --show-toplevel 2>/dev/null || echo "$wd"
}

cmd_digest() {
  local limit=0 out=""
  while (($#)); do
    case "$1" in
      --limit) limit=$2; shift 2 ;;
      --out)   out=$2; shift 2 ;;
      *)       usage ;;
    esac
  done
  if [[ -z "$out" ]]; then
    out=$(mktemp -d "${TMPDIR:-/tmp}/reflect.XXXXXX")
  else
    mkdir -p "$out"
  fi
  : > "$out/manifest.tsv"

  local n=0 kept=0 skipped=0 harness id from to path projdir slice status body
  while IFS=$'\t' read -r harness id from to path projdir; do
    ((limit > 0 && n >= limit)) && break
    n=$((n + 1))
    slice=$(sed -n "$((from + 1)),${to}p" "$path")
    status=digested
    if [[ "$(basename "$projdir")" == -tmp* || "$(basename "$projdir")" == tmp-* ]]; then
      status=skipped:scratch
    elif grep -Eq 'sessions\.sh (digest|commit)' "$path"; then
      status=skipped:reflect-run
    else
      body=$("${harness}_digest" <<< "$slice")
      # A whole session needs some substance; a continuation only needs something new.
      if [[ -z "$body" ]] || ((from == 0 && ${#body} < MIN_BYTES)); then status=skipped:trivial; fi
    fi
    printf '%s\t%s\t%s\t%s\n' "$harness" "$id" "$to" "$status" >> "$out/manifest.tsv"
    if [[ "$status" != digested ]]; then
      skipped=$((skipped + 1))
      continue
    fi
    kept=$((kept + 1))
    {
      printf '# %s session %s\n\n' "$harness" "$id"
      printf -- '- repo: %s\n- lines: %s-%s%s\n\n' "$(workdir "$harness" "$slice" "$projdir")" \
        "$((from + 1))" "$to" "$( ((from > 0)) && echo ' (continuation; earlier lines already analyzed)')"
      printf '%s\n' "$body"
    } > "$out/$harness-$id.md"
  done < <(pending)

  local left
  left=$(($(pending | wc -l) - n))
  echo "digest: $out"
  echo "sessions: $kept digested, $skipped skipped, $left still pending after this batch"
  for f in "$out"/*.md; do
    [[ -e "$f" ]] && printf '  %6s bytes  %s\n' "$(wc -c < "$f")" "$(basename "$f")"
  done
  return 0
}

cmd_commit() {
  local dir=${1:-}
  [[ -f "$dir/manifest.tsv" ]] || { echo "no manifest.tsv in '$dir'" >&2; exit 66; }
  cut -f1-3 "$dir/manifest.tsv" | record
  echo "recorded $(wc -l < "$dir/manifest.tsv") session(s) in $STATE"
}

cmd_seed() {
  inventory | cut -f1-3 | record
  echo "recorded $(wc -l < "$STATE") session(s) in $STATE"
}

case "${1:-}" in
  pending) pending ;;
  digest)  shift; cmd_digest "$@" ;;
  commit)  shift; cmd_commit "$@" ;;
  seed)    cmd_seed ;;
  *)       usage ;;
esac
