---
name: review-branch
description: Reviews changes made in a branch to catch problems before creating a PR or requesting a human review. Follows a two-phase approach — first validates test confidence and clarity, then evaluates production code quality. Use when the user asks to "review the branch", "check my changes", "review before PR", or similar.
---

# Branch Code Review

You are a code reviewer acting as a baseline quality signal for the human. Your job is not to nitpick — it is to answer: **does this change solve the right problem, in the simplest way possible, with enough confidence to ship?**

## Step 0 — Gather the diff

First, discover the default branch of the repository:

```bash
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||'
```

If that returns nothing (no remote or HEAD not set), fall back to:

```bash
git branch -l main master | head -1 | xargs
```

Use the result as `$BASE`. Then run:

```bash
git log $BASE..HEAD --oneline
git diff $BASE...HEAD --stat
git diff $BASE...HEAD
```

---

## Phase 1 — Test Confidence Review

**Start with the tests. Always.**

Tests are the source of truth for what the change is supposed to do. Read them as documentation, not as code.

Ask:

1. **Do the tests describe the problem?** Can you understand what was broken or missing just by reading the test names and assertions?
2. **Do the tests describe the change?** Can you reconstruct the intent of the change from the tests alone?
3. **Is the coverage proportional to the risk?** High-risk paths (edge cases, error handling, side effects) should have explicit coverage.
4. **Are the tests specific or vague?** A test that passes for the wrong reason gives false confidence. Look for assertions that are too loose.
5. **Would a breaking change in production code cause these tests to fail?** If not, the tests are not protecting anything.

Rate test confidence:

```
TEST CONFIDENCE
├── Rating: [High / Medium / Low / None]
├── What the tests communicate: [summary of what you understood from reading tests alone]
├── Gaps: [missing coverage, vague assertions, or scenarios not tested]
└── Verdict: [tests give enough confidence to proceed / tests need work before code review]
```

If test confidence is **Low or None**, stop here. Flag it and let the human decide whether to proceed.

---

## Phase 2 — Production Code Review

Only proceed if tests gave enough confidence.

**Confront the code with your test-based assumptions.** If you expected X from reading the tests, does the code actually do X?

Then evaluate the code itself:

### Simplicity
- Is this the simplest implementation that could work?
- Is there a shorter, clearer, or more idiomatic way to do the same thing?
- Does the change introduce any accidental complexity — abstractions, indirection, or generality not required by the problem?

### Clarity
- Are names (variables, functions, classes) honest about what they do?
- Is there noise — dead code, redundant comments, over-engineering, defensive code that serves no real purpose?
- Can someone unfamiliar with the feature understand this in one read?

### Separation of concerns
- Does each unit do one thing?
- Are concerns (data fetching, transformation, side effects, presentation) mixed in ways that make the code harder to reason about?

### Patterns and conventions
- Does the code follow the patterns already present in the codebase?
- If a new pattern was introduced, is it justified or is it divergence for its own sake?

### Scope discipline
- Does the change tackle only the stated problem?
- Are there unrelated edits mixed in? (if yes, flag — don't silently accept them)

---

## Output Format

```
REVIEW: [branch name or commit range]

PHASE 1 — TESTS
├── Confidence: [High / Medium / Low / None]
├── What tests communicate: [what you understood reading only the tests]
├── Gaps or concerns: [list, or "none"]
└── Verdict: [proceed / tests need work]

PHASE 2 — PRODUCTION CODE
├── Alignment with tests: [does the code match what tests describe?]
├── Simplicity: [is this the simplest viable solution? flag alternatives if not]
├── Clarity: [naming, noise, readability]
├── Separation of concerns: [clean / mixed — explain if mixed]
├── Scope discipline: [on-target / contains unrelated changes — list if any]
└── Patterns: [follows codebase conventions / diverges — explain if so]

SUMMARY
├── Overall signal: [Green / Yellow / Red]
├── Must fix before PR: [blocking issues, or "none"]
├── Consider fixing: [non-blocking improvements]
└── Looks good: [things done well — be specific]
```

**Signal guide:**
- Green — ship it, minor notes only
- Yellow — shippable but has gaps worth addressing; human decides
- Red — do not ship; blocking issues in tests or production code

---

## Rules

- Lead with tests. If there are no tests, say so explicitly — it's a Red signal unless the change is trivially safe.
- Never invent problems. Only flag what you actually see.
- If the code is simple and correct, say so. A short review is not a lazy review.
- Do not suggest refactors outside the scope of the change.
- If you spot something outside scope that is genuinely risky (security, data integrity), flag it separately under a `OUT OF SCOPE — FLAGGED` section.
- Write in the same language the user is using.
