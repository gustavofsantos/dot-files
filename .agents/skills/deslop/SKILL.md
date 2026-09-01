---
name: deslop
description: Removes AI-generated slop from the current branch diff. Use when cleaning up a branch before merge or when the user asks to remove AI slop from the diff.
disable-model-invocation: true
---

# Diff Slop Cleanup

Remove AI-generated cruft introduced by the branch diff without altering behavior.

## Workflow

1. Determine the base branch for the current branch. It is often `master`, but not always — this repo uses GitButler, so consult GitButler state to find the real base rather than assuming.
2. Get the diff of the current branch against that base.
3. Use added and removed lines to identify slop introduced by this diff.
4. Fix the clearest cases, then summarize in 1–3 sentences.

## What counts as slop here

- **Comments** that narrate the code, restate syntax, or reference tickets. Keep comments that carry domain *why*.
- **Docstrings** that merely restate the function name. Keep ones explaining complex returns or business logic.
- **Defensive code** (try/catch, nil checks, impossible-state guards) that does not mirror an existing pattern on the same path. Keep checks required for external inputs, DB results, API responses.
- **Nesting** that fights the file's style — flatten toward the surrounding file's idioms.
- **Naming** that breaks local conventions — drop or rename to match what the file/namespace already uses.
- **Tests** — drop narrating comments and unused stubs/mocks. Keep the scenario descriptions that explain intent.

## Guardrails

- Match the surrounding file rather than imposing a global style.
- Do not change behavior. Report a suspected bug separately.
- Edit nearby unchanged lines only when the smallest behavior-preserving cleanup of
  diff-introduced slop requires it. Do not clean pre-existing slop.
- When many instances exist, fix the clearest and stop — no whole-function rewrites.
