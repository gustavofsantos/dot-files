#!/usr/bin/env bats

# Tests for the library script, alongside it.
#
# Isolation: LIBRARY_HOME and HOME point into a fresh tmpdir, so the real library
# and the real home are never touched. Sources are real files in that tmpdir.

SCRIPT="$BATS_TEST_DIRNAME/library"

setup() {
  TEST_HOME=$(mktemp -d)
  export HOME="$TEST_HOME"
  export LIBRARY_HOME="$TEST_HOME/library"
  export WORKFLOWS_HOME="$TEST_HOME/workflows"
  SRC="$TEST_HOME/settle.clj"
  echo '(defn settle [batch] ...)' > "$SRC"
}

teardown() {
  rm -rf "$TEST_HOME"
}

entry() { # entry <title> [extra frontmatter lines...]
  local title="$1"; shift
  printf -- '---\ntitle: %s\nsummary: A batch groups payments that settle together.\nconfidence: documented\n' "$title"
  printf 'source: %s\n' "$SRC"
  for l in "$@"; do printf '%s\n' "$l"; done
  printf -- '---\nBody line.\n'
}

put() { entry "$@" | "$SCRIPT" put "$ID"; }

# ── Writing ────────────────────────────────────────────────────────────────────

@test "an entry is stored under its id" {
  ID=settlement-batch
  run put "Settlement batch"
  [ "$status" -eq 0 ]
  [ "$output" = "$LIBRARY_HOME/settlement-batch.md" ]
}

@test "a source file is pinned to its content and the entry is stamped with today" {
  ID=settlement-batch
  put "Settlement batch"
  grep -q "^source: $SRC sha=[0-9a-f]\{12\}$" "$LIBRARY_HOME/$ID.md"
  grep -q "^verified: $(date +%F)$" "$LIBRARY_HOME/$ID.md"
}

@test "a hash typed by the author is replaced by the real one" {
  ID=settlement-batch
  entry "Settlement batch" | sed "s|^source: .*|source: $SRC sha=000000000000|" | "$SCRIPT" put "$ID"
  ! grep -q 'sha=000000000000' "$LIBRARY_HOME/$ID.md"
}

@test "an entry without a source is refused" {
  ID=nosource
  run bash -c "printf -- '---\ntitle: X\nsummary: s\nconfidence: inferred\n---\nbody\n' | '$SCRIPT' put $ID"
  [ "$status" -eq 1 ]
  [[ "$output" == *"no source, no entry"* ]]
  [ ! -e "$LIBRARY_HOME/$ID.md" ]
}

@test "a confidence label outside the three is refused" {
  ID=x
  run bash -c "$(declare -f entry); SRC='$SRC'; entry 'X' | sed 's/documented/sure/' | '$SCRIPT' put $ID"
  [ "$status" -eq 1 ]
  [[ "$output" == *"confidence must be"* ]]
}

@test "an unknown frontmatter key is refused" {
  ID=x
  run put "X" "mood: hopeful"
  [ "$status" -eq 1 ]
  [[ "$output" == *"unknown key 'mood'"* ]]
}

@test "a body past the limit is refused with advice to split" {
  ID=big
  run bash -c "$(declare -f entry); SRC='$SRC'; { entry 'Big'; seq 1 60; } | '$SCRIPT' put $ID"
  [ "$status" -eq 1 ]
  [[ "$output" == *"one concept each"* ]]
}

@test "an existing entry is not overwritten without --update" {
  ID=settlement-batch
  put "Settlement batch"
  run put "Settlement batch"
  [ "$status" -eq 1 ]
  [[ "$output" == *"--update"* ]]
}

@test "--update replaces an existing entry" {
  ID=settlement-batch
  put "Settlement batch"
  entry "Settlement batch" | sed 's/Body line./Changed./' | "$SCRIPT" put "$ID" --update
  grep -q '^Changed\.$' "$LIBRARY_HOME/$ID.md"
}

@test "a second entry cannot take a name another entry already has" {
  ID=settlement-batch
  put "Settlement batch" "aliases: batch, SB"
  ID=batch-two
  run put "Other thing" "aliases: sb"
  [ "$status" -eq 1 ]
  [[ "$output" == *"already names entry 'settlement-batch'"* ]]
}

# ── Reading ────────────────────────────────────────────────────────────────────

@test "search finds an entry by an alias and ranks it above a body mention" {
  ID=settlement-batch; put "Settlement batch" "aliases: sweep"
  ID=ledger-entry
  entry "Ledger entry" | sed 's/Body line./A sweep happens nightly./' | "$SCRIPT" put "$ID"
  run "$SCRIPT" search sweep
  [ "$status" -eq 0 ]
  [[ "${lines[0]}" == settlement-batch* ]]
  [[ "${lines[1]}" == ledger-entry* ]]
}

@test "search reports a miss in words instead of staying silent" {
  ID=settlement-batch; put "Settlement batch"
  run "$SCRIPT" search chargeback
  [ "$status" -eq 0 ]
  [[ "$output" == "no entry matches: chargeback" ]]
}

@test "search on a library that does not exist yet says so" {
  run "$SCRIPT" search anything
  [ "$status" -eq 0 ]
  [[ "$output" == "library is empty"* ]]
}

@test "search matches part of a word, so 'settle' finds 'settlement'" {
  ID=settlement-batch; put "Settlement batch"
  run "$SCRIPT" search settle
  [[ "${lines[0]}" == settlement-batch* ]]
}

@test "show prints the entry and the state of each source" {
  ID=settlement-batch; put "Settlement batch"
  run "$SCRIPT" show "$ID"
  [ "$status" -eq 0 ]
  [[ "$output" == *"title: Settlement batch"* ]]
  [[ "$output" == *"-- flag: ok"* ]]
  [[ "$output" == *"-- source ok: $SRC"* ]]
}

@test "show of an unknown id fails and points to search" {
  run "$SCRIPT" show nope
  [ "$status" -eq 1 ]
  [[ "$output" == *"library search"* ]]
}

# ── Staying aligned with the sources ───────────────────────────────────────────

@test "a changed source flags the entry stale in search and show" {
  ID=settlement-batch; put "Settlement batch"
  echo '(defn settle [batch opts] ...)' > "$SRC"
  run "$SCRIPT" search batch
  [[ "$output" == *$'\tstale\t'* ]]
  run "$SCRIPT" show "$ID"
  [[ "$output" == *"-- flag: stale"* ]]
  [[ "$output" == *"-- source changed: $SRC"* ]]
}

@test "a deleted source flags the entry stale" {
  ID=settlement-batch; put "Settlement batch"
  rm "$SRC"
  run "$SCRIPT" check
  [ "$status" -eq 1 ]
  [[ "$output" == *"stale  settlement-batch  missing"* ]]
}

@test "check passes on a library whose sources are untouched" {
  ID=settlement-batch; put "Settlement batch"
  run "$SCRIPT" check
  [ "$status" -eq 0 ]
  [[ "$output" == "1 entries, 0 problems" ]]
}

@test "reverify accepts the new state of a changed source" {
  ID=settlement-batch; put "Settlement batch"
  echo changed > "$SRC"
  "$SCRIPT" reverify "$ID"
  run "$SCRIPT" check
  [ "$status" -eq 0 ]
}

@test "a URL source is never called stale, only unchecked" {
  ID=wiki
  entry "Wiki thing" | sed "s|^source: .*|source: https://wiki.example/settlement|" | "$SCRIPT" put "$ID"
  run "$SCRIPT" check
  [ "$status" -eq 0 ]
  run "$SCRIPT" search wiki
  [[ "$output" == *$'\tunchecked\t'* ]]
}

@test "a related link to a missing entry is reported" {
  ID=settlement-batch; put "Settlement batch" "related: ghost"
  run "$SCRIPT" check
  [ "$status" -eq 1 ]
  [[ "$output" == *"broken-link  settlement-batch  related: ghost"* ]]
}

@test "a deprecated entry says so in search" {
  ID=old; put "Old thing" "status: deprecated"
  run "$SCRIPT" search old
  [[ "$output" == *$'\tdeprecated\t'* ]]
}

# ── Workflows ──────────────────────────────────────────────────────────────────

diagram() { # diagram <file> — a panorama in the shape the contract asks for
  printf 'flowchart TB\n  subgraph Checkout\n    A[Order placed] --> B[Payment captured]\n  end\n  B --> C[Settled]\n' > "$1"
}

@test "a workflow is an entry plus a diagram stored under the workflows folder" {
  ID=checkout; diagram "$TEST_HOME/d.mermaid"
  entry "Checkout" | "$SCRIPT" put "$ID" --diagram "$TEST_HOME/d.mermaid"
  [ -f "$WORKFLOWS_HOME/checkout.mermaid" ]
  grep -q '^diagram: checkout.mermaid sha=[0-9a-f]\{12\}$' "$LIBRARY_HOME/$ID.md"
}

@test "show prints the diagram after the entry" {
  ID=checkout; diagram "$TEST_HOME/d.mermaid"
  entry "Checkout" | "$SCRIPT" put "$ID" --diagram "$TEST_HOME/d.mermaid"
  run "$SCRIPT" show "$ID"
  [[ "$output" == *"-- diagram: $WORKFLOWS_HOME/checkout.mermaid"* ]]
  [[ "$output" == *"B --> C[Settled]"* ]]
}

@test "show --raw prints the entry and nothing else, ready to edit and put back" {
  ID=checkout; diagram "$TEST_HOME/d.mermaid"
  entry "Checkout" | "$SCRIPT" put "$ID" --diagram "$TEST_HOME/d.mermaid"
  "$SCRIPT" show --raw "$ID" > "$TEST_HOME/raw.md"
  ! grep -q '^--' "$TEST_HOME/raw.md"
  sed -i.bak 's/Body line./Edited./' "$TEST_HOME/raw.md"
  "$SCRIPT" put "$ID" --update < "$TEST_HOME/raw.md"
  grep -q '^Edited\.$' "$LIBRARY_HOME/$ID.md"
}

@test "search and list mark a workflow" {
  ID=checkout; diagram "$TEST_HOME/d.mermaid"
  entry "Checkout" | "$SCRIPT" put "$ID" --diagram "$TEST_HOME/d.mermaid"
  run "$SCRIPT" search checkout
  [[ "$output" == *"Checkout [workflow]"* ]]
  run "$SCRIPT" list
  [[ "$output" == *"Checkout [workflow]"* ]]
}

@test "a diagram edited by hand makes the entry stale until it is reverified" {
  ID=checkout; diagram "$TEST_HOME/d.mermaid"
  entry "Checkout" | "$SCRIPT" put "$ID" --diagram "$TEST_HOME/d.mermaid"
  echo '  C --> D[Reconciled]' >> "$WORKFLOWS_HOME/checkout.mermaid"
  run "$SCRIPT" check
  [ "$status" -eq 1 ]
  [[ "$output" == *"stale  checkout  changed  $WORKFLOWS_HOME/checkout.mermaid"* ]]
  "$SCRIPT" reverify "$ID"
  run "$SCRIPT" check
  [ "$status" -eq 0 ]
}

@test "an existing diagram is adopted by naming it, without copying" {
  ID=checkout; mkdir -p "$WORKFLOWS_HOME"; diagram "$WORKFLOWS_HOME/orders-panorama.mermaid"
  put "Checkout" "diagram: orders-panorama.mermaid"
  grep -q '^diagram: orders-panorama.mermaid sha=' "$LIBRARY_HOME/$ID.md"
  [ ! -e "$WORKFLOWS_HOME/checkout.mermaid" ]
}

@test "naming a diagram that does not exist is refused" {
  ID=checkout
  run put "Checkout" "diagram: ghost.mermaid"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Pass the file with --diagram"* ]]
}

@test "a diagram name cannot leave the workflows folder" {
  ID=checkout
  run put "Checkout" "diagram: ../../etc/passwd.mermaid"
  [ "$status" -eq 1 ]
  [[ "$output" == *"no directory"* ]]
}

@test "a diagram wrapped in a code fence is refused" {
  ID=checkout
  printf '```mermaid\nflowchart TB\n  A --> B\n```\n' > "$TEST_HOME/d.mermaid"
  run bash -c "$(declare -f entry); SRC='$SRC'; entry 'Checkout' | '$SCRIPT' put $ID --diagram '$TEST_HOME/d.mermaid'"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Mermaid source only"* ]]
  [ ! -e "$WORKFLOWS_HOME/checkout.mermaid" ]
}

@test "prose in place of a diagram is refused" {
  ID=checkout
  echo "The order goes to payment." > "$TEST_HOME/d.mermaid"
  run bash -c "$(declare -f entry); SRC='$SRC'; entry 'Checkout' | '$SCRIPT' put $ID --diagram '$TEST_HOME/d.mermaid'"
  [ "$status" -eq 1 ]
  [[ "$output" == *"not a Mermaid diagram type"* ]]
}

@test "an unknown option is refused" {
  ID=x
  run bash -c "$(declare -f entry); SRC='$SRC'; entry 'X' | '$SCRIPT' put $ID --force"
  [ "$status" -eq 64 ]
}

# ── Where the library lives ────────────────────────────────────────────────────

@test "the library stays out of the engineering vault even when ENGINEERING_HOME is set" {
  unset LIBRARY_HOME WORKFLOWS_HOME
  export ENGINEERING_HOME="$TEST_HOME/engineering"
  ID=checkout; diagram "$TEST_HOME/d.mermaid"
  run bash -c "$(declare -f entry); SRC='$SRC'; entry 'Checkout' | '$SCRIPT' put $ID --diagram '$TEST_HOME/d.mermaid'"
  [ "$status" -eq 0 ]
  [ "$output" = "$HOME/librarian/library/checkout.md" ]
  [ -f "$HOME/librarian/workflows/checkout.mermaid" ]
  [ ! -e "$TEST_HOME/engineering" ]
}

@test "a diagram from outside the diagrams folder is copied in and the original is left alone" {
  ID=checkout; mkdir -p "$TEST_HOME/engineering/workflows"; diagram "$TEST_HOME/engineering/workflows/old.mermaid"
  entry "Checkout" | "$SCRIPT" put "$ID" --diagram "$TEST_HOME/engineering/workflows/old.mermaid"
  cmp "$TEST_HOME/engineering/workflows/old.mermaid" "$WORKFLOWS_HOME/checkout.mermaid"
}
