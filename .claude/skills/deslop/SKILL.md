---
name: deslop
description: Checks the diff against master and removes AI-generated slop from this codebase. Use when cleaning up a branch before merge or when the user asks to remove AI slop from the diff.
---

# Diff Slop Cleanup

Remove AI-generated cruft from the branch diff against `master`, touching **only changed lines** (`+`/`-`), without altering behavior.

## Workflow

`git diff master...HEAD` → scan only added/removed lines → fix clearest cases → summarize in 1–3 sentences.

## What counts as slop here

- **Comments** that narrate the code, restate syntax, or reference Jira tickets. Keep comments that carry domain *why*.
- **Docstrings** that merely restate the function name. Keep ones explaining complex returns or business logic.
- **Defensive code** (try/catch, nil checks, impossible-state guards) that doesn't mirror an existing pattern on the same path. Keep checks required for external inputs, DB results, API responses.
- **Nesting** that fights the file's style — flatten toward the surrounding file's `cond`/`when`/`if-let` idiom.
- **Naming** that breaks local conventions — predicate `?` suffix, keyword namespacing (`:entity/status`), existing namespace aliases.
- **Midje tests** — drop narrating comments and unused `provided` stubs; keep the scenario string in `fact`.

## Guardrails

- Match the surrounding file rather than imposing a global style; consistency over verbosity.
- No behavior changes except an obvious bug fix (wrong condition, off-by-one).
- When many instances exist, fix the clearest and stop — no whole-function rewrites.
