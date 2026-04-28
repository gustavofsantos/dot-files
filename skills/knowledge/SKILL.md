---
name: knowledge
description: >
  Manages the knowledge library — atomic facts and spike narratives that accumulate
  across all work. Use this skill when a validated discovery should be preserved beyond
  a single session, when promoting a dead-reckoning theorem to a permanent fact, when
  querying for prior knowledge before starting work, or when maintaining the qmd index.
  Triggers on phrases like "save this as a fact", "do we know anything about X",
  "promote this theorem", "what do we know about Y", or when the workflow skill's
  session start protocol runs knowledge retrieval.
---

# Knowledge

The knowledge library is the long-term memory of the system. It survives issue completion,
session endings, and context window pressure. It is queried automatically at session start
and written to whenever a validated fact is discovered.

---

## Environment detection

Before any operation, determine which environment you are running in:

- **Claude Code**: bash tool is available. Use CLI commands and direct file access for
  all operations. This is the full-capability path.
- **Claude Desktop**: no bash tool. Use the qmd MCP server for queries. Fact writes
  require generating the markdown for the user to save manually — state this clearly.

To check: attempt to use the bash tool. If unavailable, you are on Claude Desktop.

---

## Storage layout

```
~/engineering/
  facts/
    FACT-001-auth-token-refresh-window.md
    FACT-002-billing-cycle-immutability.md
  spikes/
    001-auth-investigation.md
    002-payment-flow-traversal.md
  .counters/
    facts    ← sequential ID counter
    spikes   ← sequential ID counter
```

Facts are global — not scoped to a system or repo.
Spikes are narratives produced by `dead-reckoning`. They reference facts but do not contain them.

---

## Fact format

```markdown
---
id: FACT-NNN
title: "Short label — what this fact says"
confidence: asserted | validated
created: YYYY-MM-DD
confirmed: YYYY-MM-DD
tags: [auth, clojure, seubarriga]
refs:
  - spike: "[[001-auth-investigation]]"
  - issue: "007"
  - commit: abc1234
---

## Statement

One paragraph. Plain language. Behavioral claim, not code description.
What is true, not how it is implemented.

## Evidence

What anchors this fact. File and line, commit hash, or test name.
Prefer commit hash over file:line — a changed hash signals staleness.

## Depends on

- [[FACT-NNN-slug]] (if this fact builds on another)

## Notes

Optional. Caveats, edge cases, conditions under which this might not hold.
```

**Confidence levels:**
- `asserted` — stated by the human as external truth. Not yet verified in code.
- `validated` — confirmed through traversal or testing. Anchored to evidence.

Never invent a fact. Never assert confidence higher than the evidence supports.

---

## Spike format

Spikes live in `~/engineering/spikes/`. They are produced by `dead-reckoning`.
Their format is defined in the `dead-reckoning` skill.

A spike references facts by wiki link. It never contains the fact content.

```markdown
This confirms that auth token refresh happens before expiry validation.
→ [[FACT-007-auth-token-refresh-window]]

The billing cycle is immutable once created — updates are not possible,
only replacements.
→ [[FACT-012-billing-cycle-immutability]], [[FACT-013-billing-replacement-flow]]
```

---

## Querying facts

### Claude Code

```bash
# Semantic search
qmd query "auth token expiry behavior" -n 5

# Keyword + semantic combined
qmd query $'lex: auth token\nvec: token refresh before expiry check' -n 5

# Exact keyword / ID lookup
qmd search "FACT-007" --full

# Read a specific fact (when you know the ID)
cat ~/engineering/facts/FACT-007-*.md
```

### Claude Desktop (qmd MCP server)

Use the qmd MCP server tools directly. The server exposes search and retrieval
over the same collection. Use it for queries at session start and during investigation.
Fact writes are not available via MCP — see "Creating a fact" below.

---

## Creating a fact

### Claude Code

1. Check for duplicates:
   ```bash
   qmd query "<proposed fact statement>" -n 5
   ```
   If a related fact exists, extend it rather than creating a duplicate.

2. Allocate an ID and scaffold the file:
   ```bash
   NEXT=$(cat ~/engineering/.counters/facts 2>/dev/null || echo 0)
   NEXT=$((NEXT + 1))
   echo $NEXT > ~/engineering/.counters/facts
   ID="FACT-$(printf '%03d' $NEXT)"
   SLUG="<short-slug>"
   FILE=~/engineering/facts/${ID}-${SLUG}.md
   ```

3. Write the scaffolded file:
   ```bash
   cat > "$FILE" << 'EOF'
   ---
   id: FACT-NNN
   title: ""
   confidence: asserted
   created: YYYY-MM-DD
   tags: []
   refs: []
   ---

   ## Statement

   ## Evidence

   ## Depends on

   ## Notes
   EOF
   ```
   Then fill in the body.

4. Index:
   ```bash
   qmd update && qmd embed
   ```

5. Add the wiki link to the originating issue's `facts:` field.

### Claude Desktop

Fact writes require filesystem access. Generate the complete markdown in chat using
the format above, state clearly that the user must save it to
`~/engineering/facts/FACT-NNN-<slug>.md` with the correct sequential ID, and then
run `qmd update && qmd embed` in a terminal to index it.

---

## Updating a fact

### Claude Code

To update front-matter fields without touching the body, use `sed` or read-modify-write:

```bash
# Read the fact
cat ~/engineering/facts/FACT-007-*.md

# Edit in place (example: set confidence to validated)
FILE=$(ls ~/engineering/facts/FACT-007-*.md)
# Use your preferred editor or sed to update the YAML front-matter field
```

To update the body, read the file and rewrite it.

After any write: `qmd update && qmd embed`

### Claude Desktop

Read via qmd MCP server. For writes, generate the updated markdown and instruct
the user to apply it.

---

## Promoting a theorem from dead-reckoning

When `dead-reckoning` produces a confirmed theorem:

1. The theorem has: a statement, an anchor (commit hash or file:line), and human confirmation.

2. **Claude Code** — scaffold with `confidence: "validated"`, fill refs and confirmed date,
   then `qmd update && qmd embed`. In the spike document, replace the full theorem text
   with `→ [[FACT-NNN-slug]]`.

3. **Claude Desktop** — generate the full fact markdown with `confidence: validated`,
   instruct the user to save it and run `qmd update && qmd embed`.

---

## Invalidating a fact

### Claude Code

```bash
FILE=$(ls ~/engineering/facts/FACT-007-*.md)
# Update confidence: invalidated in front-matter
# Append an ## Invalidated section with date and reason
qmd update && qmd embed
```

### Claude Desktop

Generate the updated markdown with `confidence: invalidated` and an `## Invalidated`
section. Instruct the user to apply and index it.

Do not delete invalidated facts. The history of what was believed is useful.
Identify any facts that `## Depends on` the invalidated one and review them.

---

## Session start protocol (automatic)

### Claude Code

```bash
qmd query "<issue title> <issue objective>" -n 8
```

Load results above score 0.5. Ignore the rest.

### Claude Desktop

Use the qmd MCP server query tool with the issue title and objective as the query.
Same threshold: load above 0.5, ignore the rest.

---

## qmd collection setup (one-time, Claude Code only)

```bash
qmd collection add ~/engineering --name engineering
qmd context add qmd://engineering "Engineering memory — issues, sessions, facts, and spike narratives"
qmd embed
```

Run once when setting up a new machine.

---

## Rules

- One fact per atomic claim. If a fact needs two paragraphs, it contains two claims — split it.
- Facts are global. Never scope them to a system when the claim is universal.
- Never copy fact content into an issue or spike. Reference by wiki link only.
- A fact exists to be found. If it cannot be found by query, it does not exist.
  Always run `qmd update && qmd embed` after writing.
- Confidence is a property of the evidence, not of how certain you feel.
  Asserted = human said so. Validated = code confirms it.
- On Claude Desktop, never silently skip a write operation. Always surface the
  markdown to the user and explain what they need to do.
