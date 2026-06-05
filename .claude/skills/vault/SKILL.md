---
name: vault
description: >
  Operating protocol for ~/engineering/ knowledge base. Use whenever writing,
  updating, or querying facts, issues, or spikes in the engineering vault.
  Activate on any mention of "fact", "issue", "spike", "vault", "~/engineering/",
  or when capturing engineering knowledge from a session.
---

# vault

Protocol for operating in `~/engineering/`. Read this fully before touching any file.

## Structure

```
~/engineering/
  <claim-titled-fact>.md    ← facts live at root
  issues/
    <id>-<short-title>.md
  spikes/
    <id>-<short-title>.md
```

## Operating loop

**Before writing anything:**
1. Search — `qmd <query>` or `rg -l <term> ~/engineering/` to find existing notes
2. If a relevant fact exists, update it. Don't duplicate.
3. Identify the type (fact / issue / spike) → load `references/write-contracts.md`
4. Write following the contract
5. Every fact needs at least one `[[wikilink]]` to an existing note

## Hard rules

- **Facts at root only** — never create subdirectories for facts
- **No write without search first** — always check for existing coverage
- **Validator must pass** — never commit a fact that fails validation
- **When in doubt, don't write** — propose the fact as a draft in the current issue instead
- **150 words max** per fact — if it needs more, it's two facts
