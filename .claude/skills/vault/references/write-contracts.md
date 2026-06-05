# Write contracts

## Fact

**Location:** `~/engineering/<claim>.md` — root only, never in subdirectories

**Filename rules:**
- Must be a claim, not a topic noun
- Must contain a verb
- ✅ `event-sourcing-decouples-write-from-read-models.md`
- ✅ `clojure-atoms-serialize-concurrent-state-updates.md`
- ❌ `event-sourcing.md`
- ❌ `clojure-atoms.md`

**Body structure:**
```
<First sentence restates the claim as a full statement.>

<Supporting sentences: evidence, context, tradeoffs. Prose only — no bullets,
no headers. Stay under 150 words total.>

[[link-to-related-fact]] [[another-related-fact]]

source: <optional — author, paper, or codebase>
```

**Constraints:**
- ≤ 150 words (body + links + source)
- At least one `[[wikilink]]`
- No markdown headers (`#`)
- No bullet points
- No code blocks unless the code IS the claim

**Example:**
```
Clojure atoms serialize concurrent state updates by applying functions
inside a compare-and-swap loop, retrying if another thread changed the
value first. This means update functions must be pure and free of side
effects — they may run more than once. Atoms are appropriate for
independent, uncoordinated state; use refs for coordinated changes across
multiple identities.

[[clojure-refs-coordinate-multiple-identity-updates]]
[[pure-functions-enable-safe-retry-semantics]]

source: clojure.org/reference/atoms
```

---

## Issue

**Location:** `~/engineering/issues/<id>-<short-title>.md`

**ID format:** sequential integer, zero-padded to 3 digits (`001`, `002`, …)

**Body structure:**
```markdown
# <id>: <Short problem statement>

## Context
<What situation or observation created this issue. 2–4 sentences.>

## Problem
<The specific, scoped problem. What is wrong or unknown. Be precise.>

## Status
open | in-progress | resolved

## Resolution
<If resolved: what was done or decided. Otherwise omit this section.>

## Links
- [[fact-that-led-to-this-issue]]
- spikes/001-related-investigation.md
```

---

## Spike

**Location:** `~/engineering/spikes/<id>-<short-title>.md`

**ID format:** sequential integer, zero-padded to 3 digits

**Body structure:**
```markdown
# <id>: <Investigation question>

## Question
<The specific unknown being investigated. One sentence.>

## Approach
<How the investigation was conducted. Optional — omit if trivial.>

## Findings
<What was discovered. Can be longer than a fact — this is a research artifact.>

## Conclusion
resolved | inconclusive | deferred

<One sentence summary of the conclusion.>

## Links
- issues/001-related-issue.md
- [[fact-produced-by-this-spike]]
```
