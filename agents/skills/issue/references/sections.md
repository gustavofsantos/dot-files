# Section vocabulary

Optional sections. Compose what the work needs; ignore the rest. This is a
vocabulary, not a closed set — add a section that isn't here when the work calls
for it.

Typical compositions, for orientation only:

| Kind of work | Kernel plus |
|---|---|
| bug | Reproduction, Root Cause |
| investigation | Questions, Method, Findings |
| prototype | Hypothesis, Scope, Findings, Decision |
| characterization | Target, Behaviors Captured |
| implementation | Scope |

---

# Diagram vocabulary

Mermaid, always. One diagram answers one question — split rather than merging into
a single large picture. Label edges; an unlabelled arrow is prose avoidance.

| Content | Diagram |
|---|---|
| Interaction between components over time | `sequenceDiagram` |
| Lifecycle, allowed transitions, where a thing can get stuck | `stateDiagram-v2` |
| Branching logic, decision points, error paths | `flowchart` |
| Data shape, aggregates, relationships | `erDiagram` |
| What talks to what, sync vs async | `flowchart` with labelled edges |

For a change, prefer two small diagrams side by side (before / after) over one
diagram with the change annotated inside it. The diff should be visible without
reading labels.

Do not diagram: rationale, trade-offs, hypotheses, decisions, anything whose
content is a judgment rather than a structure.

---

## Scope
Use when the work has a tempting edge — something nearby that could be changed but
shouldn't be.

```markdown
## Scope
**In:** what will be touched
**Off-limits:** what will not change, and why
```

## Reproduction
Use when the work starts from a defect. Steps must be runnable by someone who has
not seen the system.

```markdown
## Reproduction
1. Step one
2. Step two

**Expected:** what should happen
**Actual:** what happens instead
```

The `## Model` diagram for a defect is the failing path as a `sequenceDiagram`,
with the point of divergence marked.

## Root Cause
Use alongside Reproduction. Starts as a hypothesis; rewritten once confirmed.
Mark which it currently is. Name the node or edge in the `## Model` diagram where
it lives rather than re-describing the path in prose.

## Questions
Use when the work is answering something rather than changing something. Each
question carries the evidence that would settle it in either direction — a
question with no falsifying signal is a topic, not a question.

```markdown
## Questions
- **Q1:** {specific unknown}
  - Confirming: {signal}
  - Falsifying: {signal}
```

## Method
Use with Questions. How the investigation will proceed and what each approach
reveals.

> **Optional pre-step — scratch refactoring:** if the code is illegible, do an
> aggressive throwaway refactor on a temp branch to understand it before
> investigating. Nothing is committed. The branch may be kept as a readable
> reference but is never merged.

## Hypothesis
Use when building something to learn rather than to keep. The belief being tested,
plus what would confirm and what would falsify it.

## Target
Use when characterizing existing behavior. The module, function, or service under
characterization.

## Behaviors Captured
Filled during execution — do not pre-populate. What the tests now pin down,
including behavior that looks like a bug but is being preserved.

## Findings
Filled during execution — do not pre-populate. Append as they arrive; do not
rewrite earlier findings, supersede them.

## Decision
Filled after evaluation — do not pre-populate.

```markdown
## Decision
**Outcome:** {what was chosen}
**Rationale:** {one paragraph}
```

## Blocked
Added when the agent cannot proceed alone. Removed once answered — the answer
moves into Context or Findings.

```markdown
## Blocked
### Needs input
{the precise question or decision the agent cannot make}
```

## Resolution
Added at close, before archiving.

```markdown
## Resolution
PR: {url, if any}
{one paragraph: what was done, and anything the next reader needs}

### Open questions
- [ ] {what remains unanswered}
```
