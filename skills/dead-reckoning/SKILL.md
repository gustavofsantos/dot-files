---
name: dead-reckoning
description: >
  Structured analysis partner for complex legacy codebases. Use when the user wants to
  understand existing behavior, trace a call tree, investigate a bug, or answer a
  specific architectural question in a system that is hard to read (Clojure, verbose
  Java, Kotlin monorepos, or any poorly structured codebase). This skill drives the
  traversal session — enforcing a central question, managing a living knowledge base
  of axioms and theorems per system, producing explicit coverage evidence, and
  generating a spike document at the end. The human validates; the agent traverses
  and translates. Activate on phrases like "analisa esse código", "quero entender
  como funciona", "como isso está implementado", "me ajuda a traçar", "trace this
  call", "how is this built", "what does X do in production", or any request to
  investigate existing code before making a decision or raising a PR. Do not use
  for greenfield design, planning, or when the user wants to think through a problem
  without a codebase — use the thinking-partner skill for that.
---

# Legacy Analysis

## What this skill is for

Complex codebases are hard to traverse. The cognitive load of reading call trees in
unfamiliar or poorly structured code leaves less bandwidth for noticing what isn't
being questioned. Two failure modes emerge: coverage gaps (the traversal didn't go
far enough) and blind spots (the analyst didn't know to question a particular point).

This skill addresses the first. The second is addressed by the validation cycle.

Your role is to traverse code and translate it into business and architecture
affirmations — statements about behavior, ownership, constraints, or data flow that
the human can validate without reading the code themselves. The human's role is to
validate those affirmations and correct your traversal direction. A rejected
affirmation is a redirect, not a failure. That's the cycle.

You produce evidence of coverage, not just findings. Showing what you traversed
matters as much as showing what you found.

---

## Three artefacts

**Knowledge base** — one per system, lives across sessions:
```
~/.config/shared-memory/analysis/{system}/knowledge-base.md
```
Contains axioms (external truths the human asserts) and theorems (truths you
confirmed in code, anchored to a commit hash). Read at session start. Updated
when theorems are promoted or axioms are invalidated.

**Spike** — one per central question, built incrementally during the session:
```
~/.config/shared-memory/analysis/{system}/spikes/{slug}.md
```
The deliverable. Answers exactly one question. Affirmations and coverage records
are appended to it as they are produced. Never rewritten — only appended.

**Session state** — one active file per system, fully rewritten after every state
change:
```
~/.config/shared-memory/analysis/{system}/session-state.md
```
A compact snapshot of current progress. Its purpose is to keep the central question
and protocol state visible in the most recent portion of the context window, where
transformer attention is strongest. Long sessions accumulate many tool calls and file
reads, pushing earlier content into the context's middle — the zone with the weakest
attention. Rewriting this file after every meaningful step counteracts that drift.
This is not a log. The spike is the log. The session state is always current state.

---

## Session flow

The session has four phases. Move through them in order. Do not collapse them.

### Phase 1 — Orient

**Load the knowledge base.** Check if one exists for this system. If it does, read
it silently — do not narrate the load or summarize it unprompted. You now have
axioms and theorems available. If no system name was given, ask: "What system is
this?" before doing anything else.

If a session state file already exists for this system, read it. It means a previous
session was interrupted. Ask the human: "There's a previous session state here.
Do you want to continue it or start fresh?" If continuing, orient yourself from the
state file and pick up where the spike left off.

**Identify the central question.** Do not begin traversal on a vague input. If the
human gives you a topic instead of a question, say so and reframe it:

> "That's a topic, not a question. What would a good answer look like? Something
> like: 'Does X happen before Y?' or 'Who owns Z when W occurs?' — which direction
> should we go?"

A good central question has a factual or yes/no answer. It is narrow enough to be
answered in a single session. Once confirmed, write it at the top of the spike file.
Do not deviate from it. If a tangent surfaces during traversal, name it, set it
aside explicitly, and continue.

**Declare entry points.** Before touching any code, state where you intend to start
and why:

> "I'll start at {entry point} because {reason}. Does that make sense?"

Wait for confirmation or redirection. This is the first record in the traversal map.

**Initialize the session state.** Write the initial session-state.md (see format
below). This is the first recitation — the central question enters the context tail
before any tool calls fill it.

---

### Phase 2 — Traverse

This is the core loop. Repeat until you reach an edge or the central question is
answered.

**Traverse one meaningful step.** Read the code. Understand what it does in terms
of behavior, not syntax.

**Produce an affirmation.** An affirmation is a plain-language claim about what the
code does at a business or architecture level. It is not a code description ("this
function calls that function"). It is a behavioral claim ("the order is validated
for idempotency before the gateway is called").

Format:
```
[A{n}] {Behavioral claim in plain language}
       ↳ Anchored at: {file:line or function name}
       ↳ Depends on: {AX-id or TH-id, if any — omit if none}
```

**Pause and ask: "Does this hold?"**

This question is not a formality. It is the mechanism by which cognitive load shifts
from traversal (your job) to validation (the human's job). Wait for a real answer.

- If yes: mark the affirmation as a candidate theorem. Append it to the spike.
- If no: stop. Ask what's wrong specifically. Correct the affirmation or the
  traversal direction. Do not continue until the affirmation is resolved or the
  human explicitly says "set it aside and keep going." Append the correction to the
  spike.

**Record ignored scope.** Every time you decide not to go deeper into a branch,
record it in the spike before moving on:

```
[SCOPE-{n}] Did not traverse: {branch or function}
             Reason: {out of scope for this spike | would be a separate spike | depth limit}
             Risk: {what we might be missing by not going here}
```

**Flag dynamic paths.** When you encounter feature toggles, runtime dispatch,
reflection, or any branch that cannot be resolved statically:

```
[DYNAMIC-{n}] Dynamic branch at: {location}
               Cannot resolve statically. Human verification required via runtime or config.
```

**Reference axioms explicitly.** When a traversal step relies on an axiom, surface it:

> "I'm relying on [AX-{id}] here — '{axiom text}'. Is that still true?"

Do not assume axioms are current. Every use is a confirmation request. If the human
says it's no longer true, invalidate it in the knowledge base immediately and check
which theorems depend on it. Those theorems are now suspect.

**Rewrite session state.** After every validated affirmation, every scope/dynamic
record, and every axiom confirmation or invalidation — rewrite session-state.md
completely. Not appended. Fully rewritten from scratch with current state.

This rewrite is what keeps the central question and protocol visible. The write
operation itself places them at the tail of the context. No additional mechanism
is needed — the write is the recitation.

**Signal edges clearly.** There are two kinds of edges and they mean different things.

A *scope edge* means you chose not to go further:
> "Stopping here — this is outside the spike's central question. Noting it in
> ignored scope."

A *knowledge edge* means you cannot go further with available information:
> "I can't resolve this statically. The path is dynamic / behind an abstraction /
> in a system I don't have access to. This needs human verification before I can
> continue."

Never conflate these. Conflating them hides real uncertainty behind the appearance
of a deliberate decision.

---

### Phase 3 — Promote theorems

When traversal is done (central question answered or a genuine knowledge edge
reached), review the candidate theorems accumulated during the session.

For each candidate, present it to the human for confirmation before writing it to
the knowledge base:

> "[Candidate] {statement} — anchored at {commit hash or file:line}. Does this hold
> well enough to record as a theorem?"

If confirmed, write it to the knowledge base:

```
### TH-{id} — {Short label}
{Statement}
**Anchored at:** {commit hash} ({file:line})
**Depends on axioms:** {AX-id list, or "none"}
**Confirmed:** {date}
**Status:** valid
```

Commit hash is strongly preferred over file:line because a changed hash is a
staleness signal — the theorem may no longer hold and should be revalidated.

An unconfirmed candidate is not a theorem. Do not write it to the knowledge base.

Update the session state to reflect theorems promoted.

---

### Phase 4 — Produce the spike

The spike file has been built incrementally during the session. Now finalize it:
add the Answer section (the response to the central question, supported by
affirmation and theorem references), and the Open Questions section. The evidence
sections (Traversal Map, Affirmations, Ignored Scope, Axioms Used, Theorems) were
appended during traversal and are already there.

After producing the spike, delete session-state.md. The session is complete. Its
state is now captured in the spike and the knowledge base.

---

## Session state format

This file is always fully rewritten — never appended. Keep it compact. Its purpose
is to be present at the tail of the context, not to be comprehensive. The spike
holds the full record.

```markdown
# Session State — {System} — {Central Question (abbreviated)}
**Last updated:** {timestamp}
**Spike:** ~/.config/shared-memory/analysis/{system}/spikes/{slug}.md

---

## CENTRAL QUESTION
{The central question, stated in full. Repeat it here on every rewrite.
This is the anchor. Do not let traversal drift from it.}

## Protocol
- [x] Central question confirmed
- [x] Entry points declared
- [ ] Traversal complete
- [ ] Theorems promoted
- [ ] Spike finalized

## Affirmations
{One line each. Show all of them.}
[A1] ✓ {brief label} — {file:line}
[A2] ✗→revised [A2b] ✓ {brief label} — {file:line}
[A3] pending

## Candidates for promotion
[A1], [A2b]

## Ignored scope
[SCOPE-1] {branch} — risk: {brief}
[DYNAMIC-1] {location}

## Axioms this session
[AX-001] "{label}" — confirmed {date}
[AX-002] "{label}" — NOT YET CONFIRMED THIS SESSION

## Next step
{One sentence. What the traversal does next.}
```

---

## Spike format

The spike is built incrementally. Create the file at the end of Phase 1 with the
header and Central Question. Append to it throughout Phase 2. Finalize in Phase 4.

```markdown
# Spike — {Central Question}

**System:** {system name}
**Date:** {date}
**Knowledge base:** ~/.config/shared-memory/analysis/{system}/knowledge-base.md

---

## Central Question

{One sentence. Exactly as confirmed in Phase 1.}

## Answer

{Written in Phase 4. The answer, stated plainly. Reference affirmation IDs and
theorem IDs that support it. If the question could not be fully answered, say so
and explain why.}

## Evidence

### Traversal Map

{An ordered outline or Mermaid diagram of what was traversed. Each node references
an affirmation ID, a SCOPE record, or a DYNAMIC record.}

### Affirmations

{Appended during Phase 2. All [A{n}] records in traversal order, including
revisions.}

### Ignored Scope

{Appended during Phase 2. All [SCOPE-{n}] and [DYNAMIC-{n}] records.}

### Axioms Used

{Each axiom referenced, with confirmation status: confirmed | not confirmed |
invalidated}

### Theorems Promoted This Session

{Written in Phase 3.}

### Theorems Validated This Session

{Written in Phase 3.}

---

## Open Questions

{Written in Phase 4. Genuine unknowns the traversal surfaced but could not resolve.
Not "we didn't look" — that's in Ignored Scope. These are things the traversal
reached and could not answer with available information.}
```

---

## Knowledge base format

```markdown
# Knowledge Base — {System Name}

**Last updated:** {date}

---

## Axioms

External truths asserted by the human. The agent cannot discover these in code.
Confirm at every use — familiarity breeds confirmation bias, which is the exact
failure mode this process is designed to prevent.

### AX-{id} — {Short label}
{Statement}
**Asserted by:** {name}
**Last confirmed:** {date}

---

## Theorems

Truths confirmed during analysis. Anchored to a commit hash. If the repo has
moved past that hash, revalidate before relying on this theorem.

### TH-{id} — {Short label}
{Statement}
**Anchored at:** {commit hash} ({file:line})
**Depends on axioms:** {AX-id list, or "none"}
**Confirmed:** {date}
**Status:** valid | stale | invalidated

---

## Invalidated

Axioms and theorems that no longer hold. Preserved for history.

### {id} — {label} [INVALIDATED {date}]
{Original statement}
**Reason:** {what changed or was discovered}
**Cascade:** {theorems that fell with it, if any}
```

---

## What this skill does not do

**Does not start traversal without a confirmed central question.** Vague inputs
produce unfocused traversal, which produces unvalidatable affirmations, which
produces a spike nobody trusts.

**Does not continue past a rejected affirmation without resolution.** The validation
cycle only works if rejection actually stops the traversal. Continuing anyway makes
the cycle theater.

**Does not append to session state.** The value of the session state file comes from
rewriting it completely. An append-only log defeats the purpose — it grows large and
the central question sinks into the middle of it, which is exactly the failure mode
the mechanism is designed to prevent.

**Does not guess at axioms.** Only the human can assert external truths — team
conventions, business rules, operational context. If it feels like an axiom but
isn't certain, it needs team confirmation before being recorded as one.

**Does not promote unconfirmed candidates.** A candidate that "probably holds" is
not a theorem. The knowledge base is worth maintaining only if its entries are
trustworthy.

**Does not guarantee discovery of unknown unknowns.** The coverage record shows
what was and wasn't explored. The rest lives in ceremonies — refinement, planning,
alignment with product. This skill covers what exists and is statically analyzable.
