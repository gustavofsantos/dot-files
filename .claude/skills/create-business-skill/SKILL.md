---
name: create-business-skill
description: Creates a business-[name] skill by discovering domain knowledge from source code and conducting a focused interview. Use when the user wants to capture a bounded context, document a business domain as a skill, or extract domain knowledge from code. Trigger on phrases like "create business skill for", "capture the [X] domain", "document this bounded context", "business skill for [X]". Always run this skill rather than attempting to create a business skill manually.
argument-hint: "<domain name or 'auto' to discover>"
---

# Create Business Skill

Produces a `business-[name]` skill: a thin activation layer over live source truth.

The output is NOT a knowledge dump. It is a navigation index — pointers to where truth lives in code, not a copy of it.

**Done when** every item in the checklist below is confirmed by the user. Do not generate until then.

---

## Checklist

- [ ] Domain name
- [ ] Primary aggregates (≥ 1)
- [ ] Key operations (≥ 1)
- [ ] Domain events (≥ 1, or "none" explicitly confirmed)
- [ ] External ACL / integrations (≥ 1, or "none" explicitly confirmed)
- [ ] Canonical source paths (≥ 2)
- [ ] Ubiquitous language (3–10 terms, or "standard terminology" confirmed)

---

## Phase 1: Discovery

Run **before** speaking to the user. Build an internal map. Never show raw output to the user.

### Detect language and layout

```bash
ls -la
find . -maxdepth 4 -type f \( -name "*.java" -o -name "*.clj" -o -name "*.kt" \) 2>/dev/null | head -5
cat README.md 2>/dev/null | head -40
```

### Java / Kotlin signals

```bash
# Package tree (look for domain boundary signals)
find src -type d 2>/dev/null | sort | head -40

# Aggregates / entities
rg "@Entity|@AggregateRoot|class.*Aggregate\b" --type java -l 2>/dev/null

# Events
rg "class\s+\w+Event\b" --type java -l 2>/dev/null

# Ports, repositories
rg "interface\s+\w+(Repository|Port|Gateway)\b" --type java -l 2>/dev/null

# Adapters / ACL / infrastructure
find src -type d \( -name "adapter*" -o -name "infrastructure*" -o -name "acl" \) 2>/dev/null
```

### Clojure signals

```bash
# Namespace tree
find src -name "*.clj" 2>/dev/null | sed 's|.*/src/||' | cut -d/ -f1-3 | sort -u | head -30

# Events and dispatch
rg "defmulti|defmethod|emit|dispatch|->event" --type clj -l 2>/dev/null

# External integrations
rg "http/|jdbc|kafka|rabbitmq|sqs|client" --type clj -l 2>/dev/null | head -10
```

### Docs

```bash
find . \( -name "README*" -o -name "*.md" -path "*/docs/*" -o -name "*.md" -path "*/adr/*" \) 2>/dev/null | head -10
```

After discovery, compile an internal map with best-guess answers for each checklist item. Partial or uncertain answers are fine — the interview corrects them.

---

## Phase 2: Interview

**Rules — enforce on every exchange without exception:**

- At most 5 items per message
- Exactly one question per exchange
- Format: brief finding → one question
- If a list has > 5 items: show top 5, note how many remain
- Never show raw file paths or code output directly

Confirm each topic before moving to the next. Go in order.

---

### Topic 1 — Domain name

State your best inference:

> "Top-level package is `com.example.payments`. Domain name → **payments**?"

If nothing found: "What's this domain called?"

---

### Topic 2 — Aggregates

> "Aggregate candidates I found:
> - `Payment`
> - `Refund`
>
> Core aggregates for this domain?"

---

### Topic 3 — Key operations

From service / use-case / command handler class names:

> "Key operations:
> - `ProcessPayment`
> - `RequestRefund`
> - `IssueCreditNote`
>
> Right?"

---

### Topic 4 — Domain events

> "Events I found:
> - `PaymentProcessed`
> - `RefundRequested`
>
> All events this domain owns?"

If none found:

> "Didn't find explicit event definitions. Does this domain publish events?"

---

### Topic 5 — External ACL / integrations

> "External integrations I see:
> - `StripeAdapter` — payment gateway
> - `NotificationServiceClient` — external service
>
> Anything missing or wrong?"

If none found:

> "Does this domain call external systems or other domains?"

---

### Topic 6 — Canonical source paths

> "Core paths:
> - `src/main/java/com/example/payments/domain/`
> - `src/main/java/com/example/payments/application/`
>
> Right? Any paths to add?"

---

### Topic 7 — Ubiquitous language

Extract candidate terms from class/method names:

> "Terms I see in code: `Payment`, `Refund`, `Chargeback`, `Settlement`.
>
> Any of these need a definition a new engineer wouldn't infer?"

Collect brief definitions only for non-obvious terms. If all are obvious: "Any domain-specific terms worth defining?"

---

### Optional — Hooks

After checklist is complete, ask once:

> "Should this skill react to file changes in the domain paths (e.g., to flag stale knowledge when domain files are modified)?"

If yes, generate a hook. If no, skip.

---

## Phase 3: Generate

Once all checklist items are confirmed, generate all files. No further questions unless the skill output path is unknown — ask once for that only.

Default output path: `~/.claude/skills/business-[name]/`

**Regeneration guard — never clobber memory.** If the target `business-[name]/` already exists, regenerate `SKILL.md`, `references/`, and `scripts/` freely, but treat `memory/` as append-only: never overwrite or delete existing `memory/*.md` notes. Create the `memory/` folder only when it is absent. The accumulated memory is the most valuable, least reproducible part of the skill.

---

### Output: `SKILL.md`

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

---

### Output: `references/domain.md`

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

---

### Output: `references/source-map.md`

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

---

### Output: `scripts/discover.sh`

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

---

### Output: `references/memory_template.md`

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

---

### Output: `memory/`

Create the `memory/` folder (only if absent — see the regeneration guard). It starts **empty**: there are no learned cases yet. Do not seed placeholder notes — the read step scans `memory/*.md`, and an empty folder correctly yields nothing.

The read/write protocol ships in `SKILL.md`'s `## Memory` section and the note schema in `references/memory_template.md`, so the folder needs no README of its own. The skill writes its first note the first time it hits one of the concrete write moments while working in this domain.

```bash
mkdir -p memory
```

---

### Output: hook (conditional)

If the user confirmed hooks, create `.claude/hooks/business-[name]-watch.md` describing a PostToolUse hook that fires when files under the canonical paths are written. Content:

```markdown
# Hook: business-[name]-watch

Event: PostToolUse (Write, Edit)
Condition: file path matches [canonical source paths]
Action: print "⚠️  [Domain Name] source changed — run scripts/discover.sh to refresh inventory"
```

Register it following the user's existing hook setup.

---

## Completion

After all files are created, one message only:

> "`business-[name]` ready at `~/.claude/skills/business-[name]/`:
> - `SKILL.md` — activation layer
> - `references/domain.md` — domain model
> - `references/source-map.md` — source index
> - `references/memory_template.md` — schema for learned-case notes
> - `scripts/discover.sh` — live inventory
> - `memory/` — learned cases (starts empty; grows as the skill works the domain)
>
> Install it where your other skills live."

Do not summarize skill content. The user can read the files.
