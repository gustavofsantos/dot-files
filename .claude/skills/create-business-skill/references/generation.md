# Generation templates — create-business-skill Phase 3

Generate every file below into the target `business-[name]/` folder. Honor the
regeneration guard in SKILL.md: `memory/` is append-only.

## Output: `SKILL.md`

```markdown
---
name: business-[name]
description: Business domain skill for [name]. Use when discussing [aggregate names], [operation names], or working with [key event names]. Activate on any mention of [domain synonyms, key nouns, operation verbs specific to this domain]. Always load this skill before modifying code in [source paths].
---

# [Domain Name]

[2–3 sentences: what this domain owns, its primary responsibility, what it explicitly does NOT own.]

## Activate when
- Working with: [aggregate list]
- Operations: [operation list]
- Source paths: [canonical path list]

## Load for depth

| Need | Source |
|---|---|
| Full domain model, events, ACL | `references/domain.md` |
| Source path index | `references/source-map.md` |
| Current inventory from source | `scripts/discover.sh` |
| Learned cases, gotchas, patterns | `memory/*.md` |

Read `references/domain.md` before making domain-model decisions.  
Run `scripts/discover.sh` to get the current state of the codebase.  
Read `memory/` before acting — see Memory below.

## Memory

This skill keeps what it learns about the [name] domain as local notes in `memory/`. The folder is the skill's own memory — it persists and grows across sessions independently of the domain model.

**Read — before acting in this domain:** scan the frontmatter of `memory/*.md` and open any note whose `triggers` match the task at hand. These are learned cases (what worked, what bit you), not the domain model — that lives in `references/domain.md`.

**Write — after any of these concrete moments**, record a note:
- a fix that took more than one attempt
- a constraint or behavior that surprised you
- a correction the user made to your approach
- a pattern worth repeating next time

Copy `references/memory_template.md` to `memory/<slug>.md` and fill it in — one case per file. Pick `triggers` from the words a future task would use. Don't restate the domain model here — only what you couldn't have known from reading it.
```

## Output: `references/domain.md`

```markdown
# [Domain Name] — Domain Model

## Aggregates
- **[Name]** — [one-line responsibility] — `[source path]`

## Domain Events
- **[EventName]** — [when it fires, what it signals] — `[source path]`

## ACL / External Integrations
- **[System]** — [what it provides to this domain] — `[adapter path]`

## Ubiquitous Language

| Term | Definition |
|---|---|
| [term] | [definition] |
```

## Output: `references/source-map.md`

```markdown
# [Domain Name] — Source Map

| Path | Role |
|---|---|
| `[path]` | Domain layer: aggregates, value objects, domain events |
| `[path]` | Application layer: use cases, command handlers, services |
| `[path]` | Infrastructure: adapters, repositories, external clients |

## Key files

[3–5 files most likely to be relevant during work in this domain]
```

## Output: `scripts/discover.sh`

Generate tuned to the detected language. Prints current aggregate / event / adapter inventory directly from source.

**Java:**
```bash
#!/bin/bash
# Live inventory: [Domain Name]
BASE="[canonical source path]"

echo "=== Events ==="
rg "class\s+\w+Event\b" "$BASE" --type java -l

echo "=== Aggregates / Entities ==="
rg "@Entity|@AggregateRoot|class.*Aggregate\b" "$BASE" --type java -l

echo "=== ACL / Adapters ==="
find "$BASE" -path "*/infrastructure*" -name "*.java" | head -20
```

**Clojure:**
```bash
#!/bin/bash
BASE="src/[domain-ns-path]"

echo "=== Events ==="
rg "->event|emit|dispatch" "$BASE" --type clj -l

echo "=== Namespaces ==="
find "$BASE" -name "*.clj" | sed 's|.*/src/||' | sort
```

After writing: `chmod +x scripts/discover.sh`

## Output: `references/memory_template.md`

The note schema the skill copies for each learned case. Shipping it as a file (rather than inlining it in `SKILL.md`) keeps the activation layer thin and gives the write step something concrete to copy.

```markdown
---
triggers: [keyword, keyword]
outcome: gotcha            # gotcha | pattern | decision
date: YYYY-MM-DD
---

# Short title of the case

- **Context:** when this applies
- **Observation:** what happened, or the approach that works
- **Why:** root cause or rationale
- **Apply:** what to do next time
```

## Output: `memory/`

Create the `memory/` folder (only if absent — see the regeneration guard). It starts **empty**: there are no learned cases yet. Do not seed placeholder notes — the read step scans `memory/*.md`, and an empty folder correctly yields nothing.

The read/write protocol ships in `SKILL.md`'s `## Memory` section and the note schema in `references/memory_template.md`, so the folder needs no README of its own.

```bash
mkdir -p memory
```

## Output: hook (conditional)

Only if the user confirmed hooks in the interview: create `.claude/hooks/business-[name]-watch.md` describing a PostToolUse hook that fires when files under the canonical paths are written:

```markdown
# Hook: business-[name]-watch

Event: PostToolUse (Write, Edit)
Condition: file path matches [canonical source paths]
Action: print "⚠️  [Domain Name] source changed — run scripts/discover.sh to refresh inventory"
```

Register it following the user's existing hook setup.
