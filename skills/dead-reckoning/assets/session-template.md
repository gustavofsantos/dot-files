# Session template — choose format by type

---

## For type: story | bug | task

```markdown
---
unit: "NNN-slug"
type: story | bug | task
agent: claude-code | cursor | gemini
started: YYYY-MM-DD
updated: YYYY-MM-DDTHH:MM:SS
---

# Session: TITLE

## Active task
- [ ]

## Remaining tasks


## Completed this session


## Working context


## Blockers / questions

```

---

## For type: spike

```markdown
---
unit: "NNN-slug"
type: spike
agent: claude-code | cursor | gemini
started: YYYY-MM-DD
updated: YYYY-MM-DDTHH:MM:SS
---

# Session: TITLE

## Central question
{Stated in full. Repeated on every rewrite.}

## Protocol
- [ ] Central question confirmed
- [ ] Entry points declared
- [ ] Traversal complete
- [ ] Theorems promoted
- [ ] Spike finalized

## Affirmations


## Candidates for promotion


## Ignored scope


## Axioms this session


## Next step

```
