---
name: deslop
description: Remove AI-generated slop introduced by the current branch diff without changing behavior.
disable-model-invocation: true
---

# Deslop

Remove the slop that this branch's diff introduced: narrating comments, docstrings that repeat
the name, defensive code that doesn't match the path's existing patterns, style-fighting
nesting, and off-convention names. Keep comments that explain domain *why*.

Find the real base branch from GitButler state rather than assuming `master`. Match the
surrounding file. Leave pre-existing slop alone and report suspected bugs separately. Fix the
clearest cases, then summarize in 1–3 sentences.
