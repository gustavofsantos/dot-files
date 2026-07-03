---
name: create-business-skill
description: Creates a business-[name] skill by discovering domain knowledge from source code and conducting a focused interview. Use when the user wants to capture a bounded context, document a business domain as a skill, or extract domain knowledge from code. Trigger on phrases like "create business skill for", "capture the [X] domain", "document this bounded context", "business skill for [X]". Always run this skill rather than attempting to create a business skill manually.
argument-hint: "<domain name or 'auto' to discover>"
---

# Create Business Skill

Produces a `business-[name]` skill: a thin activation layer over live source truth.

The output is NOT a knowledge dump. It is a navigation index — pointers to where truth lives in code, not a copy of it.

**Done when** every item in the checklist below is confirmed by the user. Do not generate until then — the interview is the work; generation is mechanical once the checklist is confirmed.

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

---

## Phase 3: Generate

Once all checklist items are confirmed, read [references/generation.md](references/generation.md) and generate every file it specifies. No further questions unless the skill output path is unknown — ask once for that only.

Default output path: `~/.claude/skills/business-[name]/`

**Regeneration guard — never clobber memory.** If the target `business-[name]/` already exists, regenerate `SKILL.md`, `references/`, and `scripts/` freely, but treat `memory/` as append-only: never overwrite or delete existing `memory/*.md` notes. Create the `memory/` folder only when it is absent. The accumulated memory is the most valuable, least reproducible part of the skill.

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
