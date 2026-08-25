#!/usr/bin/env bats

# Tests for bin/review — the per-workspace review comment queue.
#
# The guarantees worth pinning down, because the nvim plugin and whatever agent
# is running both lean on them:
#   * a pulled comment LEAVES the queue — no agent works the same note twice
#   * ids are stable and never reused, so the (stateless) editor can act by id
#   * workspaces are isolated, and a git worktree/subdir resolves to its root
#   * lane scoping is STRICT — one tree carries several branches at once
#     (GitButler), so a pinned pull must never swallow another lane's comments
#   * every comment ends in a recorded decision, attributed to whoever made it
#   * every failure is one `review: ...` line on stderr, exit 1
#
# Isolation strategy:
#   REVIEW_HOME → fresh tmpdir (the queue store)
#   WORKSPACE   → fresh tmpdir git repo, cwd for every run

REVIEW="$BATS_TEST_DIRNAME/../bin/review"

setup() {
  TEST_ROOT=$(mktemp -d)
  export REVIEW_HOME="$TEST_ROOT/store"
  unset REVIEW_LANE
  export REVIEW_AUTHOR=tester
  WORKSPACE="$TEST_ROOT/proj"
  mkdir -p "$WORKSPACE"
  git -C "$WORKSPACE" init -q
  printf 'one\ntwo\nthree\nfour\n' >"$WORKSPACE/app.py"
  printf 'alpha\nbeta\n' >"$WORKSPACE/other.rb"
  cd "$WORKSPACE" || exit 1
}

teardown() {
  cd / || true
  rm -rf "$TEST_ROOT"
}

# Enqueue a comment. Args: file, lines, text
queue() {
  "$REVIEW" add --file "$1" --lines "$2" --comment "$3" --format ids </dev/null
}

# ── enqueue ───────────────────────────────────────────────────────────────────

@test "add: enqueues a comment and prints its id" {
  run queue app.py 1-2 "rename this"
  [ "$status" -eq 0 ]
  [ "$output" = "r1" ]

  run "$REVIEW" count
  [ "$output" = "1" ]
}

@test "add: snapshots exactly the requested lines and guesses the fence language" {
  queue app.py 2-3 "look here"
  run "$REVIEW" list --format json
  [ "$status" -eq 0 ]
  [ "$(jq -r '.reviews[0].code' <<<"$output")" = "$(printf 'two\nthree')" ]
  [ "$(jq -r '.reviews[0].filetype' <<<"$output")" = "python" ]
  [ "$(jq -r '.reviews[0].file' <<<"$output")" = "app.py" ]
}

@test "add: a single line is stored as a one-line range" {
  queue app.py 3 "typo"
  run "$REVIEW" list
  [[ "$output" == *"app.py:3"* ]]
}

@test "add: --code-file - snapshots the editor buffer, not what is on disk" {
  printf 'UNSAVED-1\nUNSAVED-2\nUNSAVED-3\n' |
    "$REVIEW" add --file app.py --lines 2-3 --code-file - --comment "from the buffer"
  run "$REVIEW" list --format json
  [ "$(jq -r '.reviews[0].code' <<<"$output")" = "$(printf 'UNSAVED-2\nUNSAVED-3')" ]
}

@test "add: reads the comment from stdin when --comment is absent" {
  echo "piped note" | "$REVIEW" add --file app.py --lines 1
  run "$REVIEW" list
  [[ "$output" == *"piped note"* ]]
}

@test "add: keeps multi-line comment text intact" {
  queue app.py 1 "$(printf 'first line\nsecond line')"
  run "$REVIEW" show r1
  [[ "$output" == *"first line"* ]]
  [[ "$output" == *"second line"* ]]
}

@test "add: refuses an empty comment" {
  run "$REVIEW" add --file app.py --lines 1 --comment "   " </dev/null
  [ "$status" -eq 1 ]
  [[ "$output" == "review: a review comment needs text"* ]]
}

@test "add: refuses a range past the end of the file" {
  run "$REVIEW" add --file app.py --lines 99 --comment x </dev/null
  [ "$status" -eq 1 ]
  [[ "$output" == *"past the end of"* ]]
}

@test "add: refuses a file that does not exist without a snapshot" {
  run "$REVIEW" add --file ghost.py --lines 1 --comment x </dev/null
  [ "$status" -eq 1 ]
  [[ "$output" == *"does not exist"* ]]
}

# ── the core guarantee: pulling drains the queue ──────────────────────────────

@test "submit: records one review over the selected comments" {
  queue app.py 1 "first finding"
  queue app.py 2 "second finding"

  run "$REVIEW" submit --id r1 --id r2 \
    --decision request-changes \
    --summary "Fix both findings before merging." \
    --format json
  [ "$status" -eq 0 ]
  [ "$(jq -r '.id' <<<"$output")" = "rv1" ]
  [ "$(jq -r '.decision' <<<"$output")" = "request-changes" ]
  [ "$(jq -r '.summary' <<<"$output")" = "Fix both findings before merging." ]
  [ "$(jq -r '.comment_ids | join(",")' <<<"$output")" = "r1,r2" ]
}

@test "pull: hands over every pending comment and empties the queue" {
  queue app.py 1 "first"
  queue app.py 2 "second"

  run "$REVIEW" pull
  [ "$status" -eq 0 ]
  [[ "$output" == *"first"* ]]
  [[ "$output" == *"second"* ]]

  run "$REVIEW" count
  [ "$output" = "0" ]
}

@test "a submitted review hands its decision, summary, and comments over together" {
  queue app.py 1 "first finding"
  queue app.py 2 "second finding"

  run "$REVIEW" submit --id r1 --id r2 \
    --decision request-changes \
    --summary "The error path must be fixed before merging." \
    --format ids
  [ "$status" -eq 0 ]
  [ "$output" = "rv1" ]

  run "$REVIEW" pull
  [ "$status" -eq 0 ]
  [[ "$output" == *"Request changes"* ]]
  [[ "$output" == *"The error path must be fixed before merging."* ]]
  [[ "$output" == *'`app.py:1` (r1'* ]]
  [[ "$output" == *'`app.py:2` (r2'* ]]

  run "$REVIEW" pull
  [ "$status" -eq 0 ]
  [[ "$output" != *"The error path must be fixed before merging."* ]]
  [[ "$output" != *"first finding"* ]]
  [[ "$output" != *"second finding"* ]]
}

@test "pull: a second pull returns nothing — a comment is never handed over twice" {
  queue app.py 1 "only once"
  "$REVIEW" pull >/dev/null

  run "$REVIEW" pull
  [ "$status" -eq 0 ]
  [[ "$output" == "No pending review comments for"* ]]
  [[ "$output" != *"only once"* ]]
}

@test "pull: --peek leaves the queue intact" {
  queue app.py 1 "still mine"
  run "$REVIEW" pull --peek
  [[ "$output" == *"still mine"* ]]

  run "$REVIEW" count
  [ "$output" = "1" ]
}

@test "pull: --limit takes the oldest comments only" {
  queue app.py 1 "first"
  queue app.py 2 "second"

  run "$REVIEW" pull --limit 1 --format ids
  [ "$output" = "r1" ]

  run "$REVIEW" list --format ids
  [ "$output" = "r2" ]
}

@test "pull: --id takes named comments only" {
  queue app.py 1 "first"
  queue app.py 2 "second"
  queue app.py 3 "third"

  run "$REVIEW" pull --id r2 --format ids
  [ "$output" = "r2" ]

  run "$REVIEW" list --format ids
  [ "$output" = "$(printf 'r1\nr3')" ]
}

@test "pull: rejects an id that is not pending" {
  queue app.py 1 "first"
  run "$REVIEW" pull --id r9
  [ "$status" -eq 1 ]
  [[ "$output" == *"not pending in this workspace: r9"* ]]
}

@test "pull: markdown carries the location, code and comment an agent needs" {
  queue app.py 2-3 "tighten this"
  run "$REVIEW" pull
  [[ "$output" == *'`app.py:2-3` (r1'* ]]
  [[ "$output" == *'```python'* ]]
  [[ "$output" == *"two"* ]]
  [[ "$output" == *"> tighten this"* ]]
}

@test "pull: json is a workspace envelope around the records" {
  queue app.py 1 "note"
  run "$REVIEW" pull --format json
  [ "$(jq -r '.count' <<<"$output")" = "1" ]
  [ "$(jq -r '.workspace' <<<"$output")" = "$WORKSPACE" ]
  [ "$(jq -r '.reviews[0].status' <<<"$output")" = "pulled" ]
  [ "$(jq -r '.reviews[0].pulled_at' <<<"$output")" != "null" ]
}

@test "pull: pulled comments stay readable as an archive" {
  queue app.py 1 "note"
  "$REVIEW" pull >/dev/null

  run "$REVIEW" list --status pulled --format ids
  [ "$output" = "r1" ]
  run "$REVIEW" list --status all --format count
  [ "$output" = "1" ]
}

# ── ids, listing, editing ─────────────────────────────────────────────────────

@test "ids are never reused after a pull or a drop" {
  queue app.py 1 "first"
  "$REVIEW" pull >/dev/null
  run queue app.py 2 "second"
  [ "$output" = "r2" ]

  "$REVIEW" drop r2
  run queue app.py 3 "third"
  [ "$output" = "r3" ]
}

@test "list: --file scopes to one file, which is how the editor draws its signs" {
  queue app.py 1 "on app"
  queue other.rb 1 "on other"

  run "$REVIEW" list --file other.rb --format ids
  [ "$output" = "r2" ]

  run "$REVIEW" list --file "$WORKSPACE/app.py" --format count
  [ "$output" = "1" ]
}

@test "list: reports an empty queue on stderr, not as a failure" {
  run "$REVIEW" list
  [ "$status" -eq 0 ]
  [[ "$output" == "review: no review comments for"* ]]
}

@test "edit: replaces the text and keeps the id, file and range" {
  queue app.py 2-3 "old text"
  run "$REVIEW" edit r1 --comment "new text"
  [ "$status" -eq 0 ]

  run "$REVIEW" list --format json
  [ "$(jq -r '.reviews[0].id' <<<"$output")" = "r1" ]
  [ "$(jq -r '.reviews[0].comment' <<<"$output")" = "new text" ]
  [ "$(jq -r '.reviews[0].start_line' <<<"$output")" = "2" ]
}

@test "edit: refuses to blank out a comment" {
  queue app.py 1 "keep me"
  run "$REVIEW" edit r1 --comment "  " </dev/null
  [ "$status" -eq 1 ]
  run "$REVIEW" show r1
  [[ "$output" == *"keep me"* ]]
}

@test "edit: rejects an unknown id" {
  run "$REVIEW" edit r9 --comment x </dev/null
  [ "$status" -eq 1 ]
  [[ "$output" == *"no review 'r9'"* ]]
}

@test "drop: removes comments by id without handing them over" {
  queue app.py 1 "first"
  queue app.py 2 "second"
  run "$REVIEW" drop r1
  [ "$status" -eq 0 ]

  run "$REVIEW" list --format ids
  [ "$output" = "r2" ]
  run "$REVIEW" list --status all --format count
  [ "$output" = "1" ]
}

@test "drop: rejects an unknown id and changes nothing" {
  queue app.py 1 "first"
  run "$REVIEW" drop r1 r9
  [ "$status" -eq 1 ]
  run "$REVIEW" count
  [ "$output" = "1" ]
}

@test "clear: empties the pending queue but spares the archive" {
  queue app.py 1 "pulled one"
  "$REVIEW" pull >/dev/null
  queue app.py 2 "pending one"

  run "$REVIEW" clear
  [ "$status" -eq 0 ]
  [[ "$output" == "cleared 1 pending review comment(s)"* ]]

  run "$REVIEW" count
  [ "$output" = "0" ]
  run "$REVIEW" list --status pulled --format count
  [ "$output" = "1" ]
}

@test "clear: --status all wipes the workspace" {
  queue app.py 1 "pulled one"
  "$REVIEW" pull >/dev/null
  queue app.py 2 "pending one"

  "$REVIEW" clear --status all
  run "$REVIEW" list --status all --format count
  [ "$output" = "0" ]
}

# ── workspaces ────────────────────────────────────────────────────────────────

@test "workspace: a subdirectory resolves to the git root, so one repo is one queue" {
  queue app.py 1 "from the root"
  mkdir -p "$WORKSPACE/deep/nested"
  cd "$WORKSPACE/deep/nested"

  run "$REVIEW" count
  [ "$output" = "1" ]
  run "$REVIEW" path --workspace-only
  [ "$output" = "$WORKSPACE" ]
}

@test "workspace: a git worktree is its own queue" {
  git -C "$WORKSPACE" -c user.email=t@t -c user.name=t add -A
  git -C "$WORKSPACE" -c user.email=t@t -c user.name=t commit -qm init
  git -C "$WORKSPACE" worktree add -q -b side "$TEST_ROOT/side"
  queue app.py 1 "on main tree"

  cd "$TEST_ROOT/side"
  run "$REVIEW" count
  [ "$output" = "0" ]
}

@test "workspace: queues in different repos never mix" {
  queue app.py 1 "note-from-the-repo"
  other="$TEST_ROOT/elsewhere"
  mkdir -p "$other"
  printf 'x\n' >"$other/f.txt"
  "$REVIEW" add --workspace "$other" --file "$other/f.txt" --lines 1 \
    --comment "note-from-elsewhere" </dev/null >/dev/null

  cd "$other"
  run "$REVIEW" list
  [[ "$output" == *"note-from-elsewhere"* ]]
  [[ "$output" != *"note-from-the-repo"* ]]

  cd "$WORKSPACE"
  run "$REVIEW" list
  [[ "$output" == *"note-from-the-repo"* ]]
  [[ "$output" != *"note-from-elsewhere"* ]]
}

@test "workspace: --workspace and \$REVIEW_WORKSPACE both retarget the queue" {
  queue app.py 1 "here"
  cd "$TEST_ROOT"

  run "$REVIEW" --workspace "$WORKSPACE" count
  [ "$output" = "1" ]

  REVIEW_WORKSPACE="$WORKSPACE" run "$REVIEW" count
  [ "$output" = "1" ]
}

@test "workspaces: lists only workspaces holding pending comments" {
  queue app.py 1 "here"
  run "$REVIEW" workspaces
  [[ "$output" == *"1 pending  $WORKSPACE"* ]]

  "$REVIEW" pull >/dev/null
  run "$REVIEW" workspaces
  [[ "$output" != *"$WORKSPACE"* ]]

  run "$REVIEW" workspaces --all --format json
  [ "$(jq -r '.[0].pulled' <<<"$output")" = "1" ]
}

# ── lanes: one tree, several branches at once ────────────────────────────────

@test "lane: a comment records the lane it was raised on" {
  "$REVIEW" add --file app.py --lines 1 --comment "on auth" --lane auth </dev/null
  run "$REVIEW" list --format json
  [ "$(jq -r '.reviews[0].lane' <<<"$output")" = "auth" ]
}

@test "lane: \$REVIEW_LANE stamps an add and scopes a read" {
  REVIEW_LANE=auth "$REVIEW" add --file app.py --lines 1 --comment "on auth" </dev/null
  "$REVIEW" add --file app.py --lines 2 --comment "on payments" --lane payments </dev/null

  run env REVIEW_LANE=auth "$REVIEW" list --format ids
  [ "$output" = "r1" ]
  run env REVIEW_LANE=payments "$REVIEW" list --format ids
  [ "$output" = "r2" ]
}

@test "lane: a pinned pull never swallows another lane's comments" {
  "$REVIEW" add --file app.py --lines 1 --comment "on auth" --lane auth </dev/null
  "$REVIEW" add --file app.py --lines 2 --comment "on payments" --lane payments </dev/null

  run "$REVIEW" pull --lane auth --format ids
  [ "$output" = "r1" ]

  # the other lane is untouched and still pullable by its own session
  run "$REVIEW" list --format ids
  [ "$output" = "r2" ]
  run "$REVIEW" pull --lane payments --format ids
  [ "$output" = "r2" ]
}

@test "lane: an unlaned comment is not picked up by a pinned pull" {
  "$REVIEW" add --file app.py --lines 1 --comment "belongs to nobody" </dev/null
  run "$REVIEW" pull --lane auth --format ids
  [[ "$output" != *"r1"* ]]

  run "$REVIEW" count
  [ "$output" = "1" ]
}

@test "lane: an empty pinned pull says comments are waiting elsewhere" {
  "$REVIEW" add --file app.py --lines 1 --comment "on payments" --lane payments </dev/null
  run "$REVIEW" pull --lane auth
  [ "$status" -eq 0 ]
  [[ "$output" == *"1 pending in other lanes: payments"* ]]
}

@test "lane: --all-lanes overrides a pinned session" {
  "$REVIEW" add --file app.py --lines 1 --comment "on auth" --lane auth </dev/null
  "$REVIEW" add --file app.py --lines 2 --comment "on payments" --lane payments </dev/null

  run env REVIEW_LANE=auth "$REVIEW" list --all-lanes --format ids
  [ "$output" = "$(printf 'r1\nr2')" ]
  run env REVIEW_LANE=auth "$REVIEW" count --all-lanes
  [ "$output" = "2" ]
}

@test "lane: an unpinned session sees every lane, which is what the editor does" {
  "$REVIEW" add --file app.py --lines 1 --comment "on auth" --lane auth </dev/null
  "$REVIEW" add --file app.py --lines 2 --comment "on payments" --lane payments </dev/null

  run "$REVIEW" list --format count
  [ "$output" = "2" ]
}

# ── authorship and the recorded decision ─────────────────────────────────────

@test "author: \$REVIEW_AUTHOR names who raised a comment" {
  REVIEW_AUTHOR=reviewer-agent "$REVIEW" add --file app.py --lines 1 --comment "note" </dev/null
  run "$REVIEW" list --format json
  [ "$(jq -r '.reviews[0].author' <<<"$output")" = "reviewer-agent" ]

  run "$REVIEW" list
  [[ "$output" == *"@reviewer-agent"* ]]
}

@test "author: --author beats the environment" {
  REVIEW_AUTHOR=env-name "$REVIEW" add --file app.py --lines 1 --comment "note" \
    --author flag-name </dev/null
  run "$REVIEW" list --format json
  [ "$(jq -r '.reviews[0].author' <<<"$output")" = "flag-name" ]
}

@test "author: the markdown handed to an agent carries the attribution" {
  "$REVIEW" add --file app.py --lines 1 --comment "note" --author gustavo --lane auth </dev/null
  run "$REVIEW" pull
  [[ "$output" == *"(r1 · @gustavo #auth)"* ]]
}

@test "resolve: records what became of a comment, and who decided" {
  queue app.py 1 "rename this"
  "$REVIEW" pull >/dev/null

  run env REVIEW_AUTHOR=impl-agent "$REVIEW" resolve r1 --note "renamed, test added"
  [ "$status" -eq 0 ]

  run "$REVIEW" list --status done --format json
  [ "$(jq -r '.reviews[0].status' <<<"$output")" = "done" ]
  [ "$(jq -r '.reviews[0].resolved_by' <<<"$output")" = "impl-agent" ]
  [ "$(jq -r '.reviews[0].resolution_note' <<<"$output")" = "renamed, test added" ]
  [ "$(jq -r '.reviews[0].resolved_at' <<<"$output")" != "null" ]
}

@test "reject: demands a reason — a silent decline is the thing being prevented" {
  queue app.py 1 "change this"
  run "$REVIEW" reject r1
  [ "$status" -ne 0 ]
  [[ "$output" == *"--note"* ]]

  run "$REVIEW" reject r1 --note "intentional: the caller validates"
  [ "$status" -eq 0 ]
  run "$REVIEW" list --status rejected --format ids
  [ "$output" = "r1" ]
}

@test "resolve: a decided comment cannot be quietly re-decided" {
  queue app.py 1 "note"
  "$REVIEW" resolve r1 --note "done it"

  run "$REVIEW" resolve r1 --note "no, again"
  [ "$status" -eq 1 ]
  [[ "$output" == *"already done"* ]]

  run "$REVIEW" reject r1 --note "changed my mind"
  [ "$status" -eq 1 ]
}

@test "resolve: rejects an unknown id" {
  run "$REVIEW" resolve r9
  [ "$status" -eq 1 ]
  [[ "$output" == *"no review 'r9'"* ]]
}

@test "status: open is everything raised but not yet decided" {
  queue app.py 1 "still queued"
  queue app.py 2 "handed over"
  queue app.py 3 "finished"
  "$REVIEW" pull --id r2 --id r3 >/dev/null
  "$REVIEW" resolve r3 --note "done"

  run "$REVIEW" list --status open --format ids
  [ "$output" = "$(printf 'r1\nr2')" ]
  run "$REVIEW" count --status open
  [ "$output" = "2" ]
}

@test "show: prints the decision alongside the comment" {
  queue app.py 1 "rename this"
  "$REVIEW" resolve r1 --note "renamed to first()" --author impl-agent

  run "$REVIEW" show r1
  [[ "$output" == *"[done]"* ]]
  [[ "$output" == *"done by @impl-agent"* ]]
  [[ "$output" == *"renamed to first()"* ]]
}

@test "a decided comment survives a clear of the pending queue" {
  queue app.py 1 "decided"
  "$REVIEW" resolve r1 --note "done"
  queue app.py 2 "still pending"

  "$REVIEW" clear
  run "$REVIEW" list --status done --format ids
  [ "$output" = "r1" ]
}

# ── shape of the tool itself ──────────────────────────────────────────────────

@test "count: prints 0 for an untouched workspace instead of failing" {
  run "$REVIEW" count
  [ "$status" -eq 0 ]
  [ "$output" = "0" ]
}

@test "the store lives under \$REVIEW_HOME, one directory per workspace" {
  queue app.py 1 "note"
  run "$REVIEW" path
  [[ "$output" == "$REVIEW_HOME/"*"/queue.json" ]]
  [ -f "$output" ]
}

@test "--help works for the tool and every subcommand" {
  run "$REVIEW" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"per-workspace queue of code review comments"* ]]

  for sub in add list pull show edit resolve reject drop clear count workspaces path; do
    run "$REVIEW" "$sub" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"usage: review $sub"* ]]
  done
}

@test "bare invocation prints help instead of failing" {
  run "$REVIEW"
  [ "$status" -eq 0 ]
  [[ "$output" == *"COMMAND"* ]]
}

@test "concurrent adds do not lose comments" {
  for i in 1 2 3 4 5 6 7 8; do
    "$REVIEW" add --file app.py --lines 1 --comment "note $i" </dev/null >/dev/null &
  done
  wait

  run "$REVIEW" count
  [ "$output" = "8" ]
  run "$REVIEW" list --format ids
  [ "$(sort -u <<<"$output" | wc -l)" -eq 8 ]
}
