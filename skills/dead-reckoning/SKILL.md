---
name: dead-reckoning
description: >
  Structured analysis partner for complex legacy codebases. Use when the user wants to
  understand existing behavior, trace a call tree, investigate a bug, or answer a
  specific architectural question in a system that is hard to read (Clojure, verbose
  Java, Kotlin monorepos, or any poorly structured codebase). This skill drives the
  traversal session — enforcing a central question, managing a living knowledge base
  of axioms and theorems per system, producing explicit coverage evidence, and
  finalizing a spike document at the end. The human validates; the agent traverses
  and translates. Activate on phrases like "analisa esse código", "quero entender
  como funciona", "como isso está implementado", "me ajuda a traçar", "trace this
  call", "how is this built", "what does X do in production", or any request to
  investigate existing code before making a decision or raising a PR. Do not use
  for greenfield design, planning, or when the user wants to think through a problem
  without a codebase — use the thinking-partner skill for that.
---
 
# Legacy Analysis
 
---
 
## Storage layout
 
```
~/.config/shared-memory/work/
  stories/
    NNN-slug.md           ← spike work unit (IS the spike document — built incrementally)
  knowledge/
    {system}/
      knowledge-base.md   ← axioms and theorems, lives across sessions
 
{worktree}/
  .work/
    session.md            ← traversal state for this session (local, rewritten constantly)
```
 
The spike work unit file is both the work-management unit and the spike document.
`session.md` is shared with work-management — one file, one rewrite discipline.
 
See `assets/session-template.md` (spike variant), `assets/spike-template.md`,
and `assets/knowledge-base-template.md` for file formats.
 
---
 
## Session start
 
1. Read `.work/session.md` if it exists
   - References a spike unit → load it from shared-memory and continue
   - Interrupted session → ask "Continue or start fresh?"
2. If no session: the spike unit was created via work-management. Read it.
3. Load the knowledge base for this system if it exists. Read silently.
4. **Rewrite `.work/session.md`** with initial spike state before any tool call.
 
**If no system name is clear:** ask "What system is this?" before anything else.
 
---
 
## Phase 1 — Orient
 
**Identify the central question.** A topic is not a question. If the input is vague:
 
> "That's a topic, not a question. What would a good answer look like — something like
> 'Does X happen before Y?' or 'Who owns Z when W occurs?'"
 
A good central question has a factual or yes/no answer, narrow enough for one session.
Once confirmed, write it at the top of the spike unit file.
 
**Declare entry points.** Before touching code:
 
> "I'll start at {entry point} because {reason}. Does that make sense?"
 
Wait for confirmation or redirection.
 
**Rewrite `.work/session.md`** with Phase 1 complete. First recitation — central
question enters the context tail before any code is read.
 
---
 
## Phase 2 — Traverse
 
Core loop. Repeat until the central question is answered or a genuine edge is reached.
 
**Traverse one step.** Read code. Understand behavior, not syntax.
 
**Produce an affirmation** — a plain-language behavioral claim, not a code description:
 
```
[A{n}] {Behavioral claim at business or architecture level}
       ↳ Anchored at: {file:line or function name}
       ↳ Depends on: {AX-id or TH-id — omit if none}
```
 
**Pause and ask: "Does this hold?"** Wait for a real answer.
 
- Yes → mark as candidate theorem. Append to spike unit file.
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
 
**Reference axioms explicitly.** When relying on an axiom:
 
> "I'm relying on [AX-{id}] — '{axiom text}'. Is that still true?"
 
If invalidated: update knowledge base immediately. Treat dependent theorems as suspect.
 
**Rewrite `.work/session.md`** after every validated affirmation, scope/dynamic record,
and axiom confirmation or invalidation.
 
**Signal edges clearly:**
 
- *Scope edge* — chose not to go further: note in ignored scope, continue.
- *Knowledge edge* — cannot go further: say so explicitly, wait for human.
 
Never conflate these.
 
---
 
## Phase 3 — Promote theorems
 
For each candidate:
 
> "[Candidate] {statement} — anchored at {commit hash or file:line}. Record as theorem?"
 
If confirmed, write to knowledge base per `assets/knowledge-base-template.md`.
Prefer commit hash over file:line — a changed hash signals potential staleness.
Unconfirmed candidates are not theorems.
 
Update `.work/session.md` to reflect theorems promoted.
 
---
 
## Phase 4 — Finalize spike
 
1. Write the **Answer** section in the spike unit file — response to the central
   question, referencing affirmation and theorem ids
2. Write the **Open Questions** section — genuine unknowns reached but not resolved
   (not "we didn't look" — that's Ignored Scope)
3. Set `status: review` in the spike unit front-matter
4. Report to human: question answered or not, open questions, theorems promoted
5. Delete `.work/session.md` — state now lives in the spike unit and knowledge base
 
---
 
## What this skill does not do
 
- Does not begin traversal without a confirmed central question
- Does not continue past a rejected affirmation without resolution
- Does not append to `session.md` — always fully rewritten
- Does not guess at axioms — only the human asserts external truths
- Does not promote unconfirmed candidates to the knowledge base
