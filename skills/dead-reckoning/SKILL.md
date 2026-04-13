---
name: dead-reckoning
description: >
  Structured analysis partner for complex legacy codebases. Use when the user wants to
  understand existing behavior, trace a call tree, investigate a bug, or answer a
  specific architectural question in a system that is hard to read (Clojure, verbose
  Java, Kotlin monorepos, or any poorly structured codebase). This skill drives the
  traversal session — enforcing a central question, managing a living knowledge base
  of facts and spikes, producing explicit coverage evidence, and finalizing a spike
  document at the end. The human validates; the agent traverses and translates.
  Activate on phrases like "analisa esse código", "quero entender como funciona",
  "como isso está implementado", "me ajuda a traçar", "trace this call",
  "how is this built", "what does X do in production", or any request to investigate
  existing code before making a decision or raising a PR. Do not use for greenfield
  design or planning without a codebase — use thinking-partner for that.
---

# Dead Reckoning — Legacy Analysis

---

## Storage layout

```
~/.knowledge/
  facts/
    FACT-NNN-slug.md      ← validated facts, global, permanent
  spikes/
    NNN-slug.md           ← this session's spike document

{worktree}/
  .session.md             ← traversal state, local, rewritten constantly
```

The spike document is the narrative output of this skill.
Facts are atoms promoted from the spike into the permanent library.
`.session.md` is ephemeral — it anchors the agent during the session.

See the `knowledge` skill for fact format and promotion protocol.

---

## Session start

1. Read `.session.md` if it exists.
   - References an ongoing spike → load it from `~/.knowledge/spikes/` and continue.
   - Interrupted session → ask "Continue or start fresh?"
2. If no session: check the card's `spikes:` field for a prior spike on this topic.
   If found, load it silently and orient from where it left off.
3. Run knowledge retrieval:
   ```bash
   qmd query "<investigation topic>" --min-score 0.5 -n 6 --files
   ```
   Load relevant facts silently. If a fact is directly relevant to the central question,
   surface it to the human before traversal begins:
   > "FACT-007 covers auth token refresh in this system. Should I treat it as an axiom
   > for this session, or do you want to verify it fresh?"
4. Rewrite `.session.md` with initial spike state before any tool call.

**If no system name is clear:** ask "What system is this?" before anything else.

---

## Phase 1 — Orient

**Identify the central question.** A topic is not a question. If the input is vague:

> "That's a topic, not a question. What would a good answer look like — something like
> 'Does X happen before Y?' or 'Who owns Z when W occurs?'"

A good central question has a factual or yes/no answer, narrow enough for one session.
Once confirmed, write it at the top of the spike document.

**Declare entry points.** Before touching code:

> "I'll start at {entry point} because {reason}. Does that make sense?"

Wait for confirmation or redirection.

**Rewrite `.session.md`** with Phase 1 complete.

---

## Phase 2 — Traverse

Core loop. Repeat until the central question is answered or a genuine edge is reached.

**Traverse one step.** Read code. Understand behavior, not syntax.

**Produce an affirmation** — a plain-language behavioral claim, not a code description:

```
[A{n}] {Behavioral claim at business or architecture level}
       ↳ Anchored at: {file:line or function name}
       ↳ Depends on: {FACT-NNN or prior affirmation — omit if none}
```

**Pause and ask: "Does this hold?"** Wait for a real answer.

- Yes → mark as candidate for promotion. Append to spike document.
- No → stop. Ask what's wrong. Correct and re-ask. Do not continue until resolved,
  or human explicitly says "set it aside and keep going."

**Record ignored scope** before moving past any branch:

```
[SCOPE-{n}] Did not traverse: {branch or function}
             Reason: {out of scope | separate spike | depth limit}
             Risk: {what we might be missing}
```

**Flag dynamic paths:**

```
[DYNAMIC-{n}] Dynamic branch at: {location}
               Cannot resolve statically. Human verification required.
```

**Reference existing facts explicitly.** When relying on a loaded fact:

> "I'm relying on FACT-007 — '{fact statement}'. Is that still accurate?"

If invalidated: update the fact per the `knowledge` skill protocol immediately.
Treat dependent affirmations as suspect until re-verified.

**Lens triggers.** During traversal, two situations warrant offering a lens:

- An affirmation reveals something recurring — the same pattern appearing in multiple
  places, or a fix that feels like a patch on a deeper issue:
  > "This looks structural — the same problem appearing in three different places.
  > Want to run the Iceberg lens before we continue?"

- An architectural decision is encountered — a design choice about coupling, boundaries,
  or how two parts of the system interact:
  > "This is a design decision worth examining. Want to run 'What Is Braided Here?'
  > on how these two concerns are coupled?"

Do not run lenses automatically. Offer them. Wait for the human to decide.

**Rewrite `.session.md`** after every validated affirmation, scope/dynamic record,
and fact confirmation or invalidation.

**Signal edges clearly:**

- *Scope edge* — chose not to go further: note in ignored scope, continue.
- *Knowledge edge* — cannot go further: say so explicitly, wait for human.

Never conflate these.

---

## Phase 3 — Promote to facts

For each candidate affirmation:

> "Candidate: '{statement}' — anchored at {commit hash or file:line}.
> Promote to a permanent fact?"

If confirmed, invoke the `knowledge` skill promotion protocol.
Unconfirmed candidates stay in the spike as narrative — not promoted.

Update `.session.md` to reflect facts promoted.

---

## Phase 4 — Finalize spike

1. Write the **Answer** section in the spike document — response to the central
   question, referencing affirmation IDs and fact IDs.
2. Write the **Open Questions** section — genuine unknowns reached but not resolved.
   (Not "we didn't look" — that's Ignored Scope.)
3. Add the spike path to the originating card's `spikes:` field.
4. Report to human: question answered or not, open questions, facts promoted.
5. Delete `.session.md` — state now lives in the spike and the knowledge library.

---

## Spike document format

```markdown
# {Investigation title}

**Central question:** {One sentence.}
**Date:** YYYY-MM-DD
**Card:** {card id if applicable}

## Answer

{Response to the central question. References [A-n] and FACT-NNN.}

## Traversal map

{Entry points and path taken.}

## Affirmations

[A1] ...
[A2] ...

## Ignored scope

[SCOPE-1] ...

## Dynamic paths

[DYNAMIC-1] ...

## Facts promoted this session

- FACT-NNN — {one-line summary}

## Open questions

{Genuine unknowns not resolved.}
```

---

## What this skill does not do

- Does not begin traversal without a confirmed central question.
- Does not continue past a rejected affirmation without resolution.
- Does not append to `.session.md` — always fully rewritten.
- Does not invent facts — only the human confirms external truths.
- Does not promote unconfirmed candidates to the knowledge library.
- Does not run thinking lenses automatically — offers them at the right moment.
