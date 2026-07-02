---
name: biz-review
description: >
  Apply platform-engineering business optics to a spike document in ~/engineering/spikes/.
  Evaluates the spike's finding across five platform dimensions: leverage multiplier,
  adoption risk, cognitive load delta, TCO, and build/buy/adopt/do-nothing positioning.
  Trigger on: "business review", "biz review", "review this spike for business value",
  "platform optic", "/biz-review", or when asked to evaluate whether a spike finding is
  worth acting on from a platform perspective.
  Does NOT trigger on general code or architecture discussion not involving a specific spike.
disable-model-invocation: true
---

# Business Review — Platform Optic

Review a spike through platform-engineering business optics. The central thesis:
**platforms create value indirectly, through leverage.** A platform ships no end-user feature;
it multiplies the teams that do. Every business question is therefore mediated by that multiplier.

## Operating procedure

### Step 1 — Locate and read the spike

If the user names a spike ID or title, find it:
```bash
rg -il '<term>' ~/engineering/spikes/ -l 2>/dev/null
```

Read the whole document — do not hardcode section names. Extract:
- **Finding** — what the spike concluded or failed to conclude
- **Status** — `resolved`, `inconclusive`, or `deferred` (from frontmatter or inferred)
- **Evidence quality** — is the claim anchored to primary sources, observation, or inference?
- **Implied recommendation** — what action the spike seems to point toward, if any

### Step 2 — Evidence confidence gate

Before proceeding to business review, rate evidence confidence:

| Status | Evidence | Confidence |
|---|---|---|
| `resolved` + primary-source anchors | High | Can recommend with caveats |
| `resolved` + inferred / thin evidence | Medium | Can frame decision, not commit |
| `inconclusive` or `deferred` | Low | Outline decision frame only — do not manufacture conviction |

State confidence explicitly. Do not issue a business recommendation from a low-confidence spike.

### Step 3 — Apply the five platform dimensions

Load [references/platform-optic.md](references/platform-optic.md) — it contains the five lens protocols.

For **each dimension**, state in two parts:
1. **From the spike** — what the spike's evidence actually supports on this dimension
2. **Inputs still needed** — what data, estimates, or context is absent (flag as `[ASSUMPTION: ...]` if you proceed without it)

Never fabricate team counts, cost figures, adoption rates, or DORA metrics. If the spike doesn't contain them, name what's missing.

### Step 4 — Produce the review

Output the structured review inline (see output format below). After presenting it, offer to append a `## Business Review` section to the spike file.

---

## Output format

```
## Business Review: <spike title>

**Evidence confidence:** [High / Medium / Low] — <one-sentence reason>
**Finding:** <one-sentence extract from spike>

---

### Leverage multiplier
<what the spike supports> | <inputs still needed>

### Adoption risk
<what the spike supports> | <inputs still needed>

### Cognitive load delta
<what the spike supports> | <inputs still needed>

### TCO
<what the spike supports> | <inputs still needed>

### Build / Buy / Adopt-OSS / Do-nothing
<position the finding here>

---

**Recommendation:** [Act / Defer / Needs more research]
<one paragraph — if Low confidence, frame the decision rather than deciding>

**Assumptions flagged:** <list of [ASSUMPTION: ...] items, or "none — all inputs present">
**Inputs still needed:** <list of missing data points required to sharpen the recommendation>
```
