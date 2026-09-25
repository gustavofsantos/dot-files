---
name: reflect
description: Mine the current thread, or every agent session not yet analyzed, for durable lessons and record the approved ones in their existing owners.
disable-model-invocation: true
---

# Reflect

Use only when the user asks to reflect. Two scopes share one routing and one approval:

- **Current thread** (default): read this conversation.
- **Backlog** (the user says "backlog", "all sessions", or "catch up"): read every Claude and
  Cursor session not yet analyzed. Load `references/backlog.md` and follow it to get the
  input, then continue here.

## Find

Keep only lessons that would prevent a likely repeat or save a rediscovery:

- **Repeated explanation** — the user told agents the same thing in more than one place.
  This is the strongest signal.
- **Correction** — an agent asserted X and the user corrected it to Y.
- **Domain fact** — the user stated how a business process, rule, or term works.
- **Established finding** — an agent worked out how a rule, process, or repository behaves
  from evidence it names (file, schema, test, query result), and the session relied on it.
  The user often forgets to ask for these to be documented.
- **Failed then fixed** — a command or assumption failed and a working alternative followed.

Drop generic advice, one-off task details, and anything already present at the destination.
Drop agent claims with no evidence behind them. Mark each surviving item as documented,
verified, or inference; an inference never becomes an invariant.

## Route

| Lesson | Owner |
|---|---|
| Repository-driving fact (check command, layout, convention) | That repository's `AGENTS.local.md` |
| Business process or system workflow | `biz-workflows` skill |
| Missing or wrong detail in a domain capability | `domain-skill-creator`, updating the matching `~/.claude/skills/domain-*` skill or creating one |
| Stable project context | `project` skill |
| Cross-project term or alias | `vocabulary` skill |
| A question nobody answered | Offer a `spike`; do not record a guess |

Only real `domain-*` directories under `~/.claude/skills/` are domain skills. Never edit a
symlink there; those point back into the dotfiles repository.

A lesson with no owner is reported, not written.

## Approve

Present one numbered checklist and wait. Each item carries everything needed to decide
without opening a transcript:

```
1. [ ] ~/Projects/app/AGENTS.local.md — AGENTS.local.md
       Add: "Run checks with `make check`; there is no npm test."
       Evidence (user, verified): "no, this repo uses make check" (claude 0a35…, cursor 7e0f…)
2. [ ] domain-settlement — via domain-skill-creator
       Add invariant: "A settlement retries once, from the consumer only."
       Evidence (agent, verified): read ledger/settle.clj `settle!` (claude 9d6c…)
```

The user answers once, for example "all", "all but 3", or "1, 4, 5 and reword 2 as …".
Approval is the explicit request that `project`, `vocabulary`, `biz-workflows`, and
`domain-skill-creator` require: hand each approved item to its owner skill instead of
editing that owner's files directly.

## Apply

Apply approved items. Preserve unrelated text. Report what changed, what was dropped, and
any lesson that lacked an owner.
