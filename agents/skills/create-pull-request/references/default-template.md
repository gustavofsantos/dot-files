# Default PR body template

Use when the repository has no GitHub PR template.

```markdown
## Why

[One or two sentences: what problem existed or what was missing. Frame it from the
perspective of the user or system, not the codebase.]

## What Changed

[Two to four bullets at the conceptual level — capabilities gained, behaviors removed,
constraints lifted. No mention of function names, file paths, or implementation choices.]

[Optional Mermaid diagram if a flow, state machine, or architecture shift communicates
better than text alone. Only include when the diagram reduces ambiguity or replaces a
paragraph.]

## How to Test

[Focused, observable steps. What to do and what to look for — not "run the tests".]
```

## Mermaid guidance

Include a diagram when it replaces a confusing paragraph, not as decoration. Good
candidates: a changed flow between components, a before/after state machine, a new
sequence of interactions between services. Skip for single-file changes or pure
refactors with no behavioral shift.

GitHub mermaid quirks: node labels with special characters need quotes
(`A["label with (parens)"]`); `graph TD` and `sequenceDiagram` are the most reliably
rendered.
