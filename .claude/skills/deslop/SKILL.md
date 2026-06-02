---
name: deslop
description: Checks the diff against master and removes AI-generated slop specific to SeuBarriga's Clojure codebase. Use when cleaning up a branch before merge or when the user asks to remove AI slop from the diff.
---

# Diff Slop Cleanup

## Goal

Inspect the branch diff against `master` and apply minimal edits to remove AI-generated cruft **only in changed code** while keeping behavior unchanged, following SeuBarriga's Clojure conventions.

## Workflow

1. **Get the diff**: `git diff master...HEAD` (or `git diff master -- <paths>` for specific files).
2. **Identify changed code**: Only lines marked with `+` (added) or `-` (removed) in the diff are in scope. Lines without `+` or `-` are existing code — ignore them completely.
3. **Scan for slop**: Apply the SeuBarriga-specific checklist **only to changed lines**; fix only what clearly qualifies.
4. **Edit minimally**: One logical change per edit (e.g., remove one comment block, or flatten one nesting in added code). Avoid broad rewrites.
5. **Run formatting**: After edits, run `lein cljstyle fix` on modified files.
6. **Run linting**: Run `git changed --branch | grep ".clj$" | lint` to ensure no linting errors.
7. **Summarize**: 1–3 sentences describing what was removed or simplified.

## SeuBarriga-Specific Focus Areas

### Comments
- **Remove** comments that:
  - State the obvious (e.g., `;; Check if invoice is open`, `;; Loop through items`, `;; Return result`)
  - Narrate what the code does line-by-line
  - Explain basic Clojure syntax or standard library functions
  - Are verbose block comments where the file uses terse line comments or none
  - Reference Jira tickets or ticket IDs (these belong in commit messages, not code)
- **Keep** comments that:
  - Carry real domain context (e.g., business rule explanations, date-based decisions)
  - Explain non-obvious business rules or edge cases
  - Describe "why" something is done, not "what" is being done

### Docstrings
- **Keep** docstrings that explain complex return structures or business logic (e.g., the return map of `invoice-recalculate-eligibility`)
- **Remove or shorten** docstrings that:
  - Merely restate the function name (e.g., `"Returns the invoice"` for `get-invoice`)
  - Explain obvious parameters
  - Are verbose when a concise version suffices

### Defensive Code
- **Remove** try/catch, nil checks, or "safety" branches that:
  - Are not used elsewhere on the same code path
  - Don't match existing patterns in the same module/feature
  - Guard against impossible states (e.g., nil check after a `filter` that guarantees non-nil)
- **Keep** defensive checks that:
  - Mirror existing patterns in the codebase
  - Are required for correctness (external inputs, database results, API responses)

### Structure & Nesting
- **Flatten** deeply nested `if`/`let`/`when` by using:
  - Early returns with `when` or `when-not` at the top level
  - `cond` with flat branches (align with SeuBarriga's `cond` style in `common.clj`)
  - `let` bindings to break complex expressions into named steps
- **Simplify** callback chains or threading macros that create excessive nesting
- **Match** the flatness and style of the surrounding file — look at how existing `cond` expressions are structured

### Naming & Conventions
- **Align** with existing naming patterns in the file:
  - Namespace aliases (e.g., `seubarriga.domain.invoice.core` → `invoice`)
  - Function naming (predicate functions end in `?`, e.g., `bill?`, `fund-transfer?`)
  - Keyword namespacing (e.g., `:invoice/status`, `:payment/status`)
- **Prefer** `if-let`/`when-let` over nested `let` + `if`
- **Prefer** `cond` with explicit clauses over nested `if-else` chains

### Midje Test Patterns
- **Remove** comments in tests that:
  - Explain obvious `fact` assertions
  - Narrate the test setup
- **Keep** test descriptions in `fact` strings that explain the scenario
- **Remove** redundant `provided` stubs or unused test bindings

## Guardrails

- **Changed code only**: Review and edit **only lines added or removed in this diff** (marked with `+` or `-`). Existing code that appears in the diff context (unchanged lines) is not in scope — leave it as-is.
- **Behavior**: Do not change behavior except when fixing an obvious bug (e.g., wrong condition, off-by-one). No "improvements" that alter semantics.
- **Scope**: Prefer small, targeted edits. If many instances exist, fix the clearest cases first; avoid rewriting whole functions or files.
- **Formatting**: Always run `lein cljstyle fix` after edits to ensure formatting matches project standards.
- **Linting**: Ensure `clj-kondo` passes on all modified files.
- **Summary**: Keep the final summary to 1–3 sentences (e.g., "Removed redundant comments and flattened nesting in X; simplified defensive checks in Y.")

## What to Leave Alone

- **Any existing code** not changed in this diff — even if it contains slop, do not touch it
- Comments that carry real domain context (business rule explanations, date-based decisions)
- Defensive checks that mirror the rest of the codebase or are required for correctness
- Structure that is already consistent with the file (even if verbose)
- Any change that would alter observable behavior without fixing a clear bug
- Docstrings on complex functions that explain return values or business logic
- Test descriptions that explain the scenario being tested
