---
name: humanize
description: >
  Rewrites AI-generated or AI-sounding text to read like a thoughtful human wrote it.
  Use when the user wants to clean up a document before sharing with leadership, executives,
  or any audience where "this looks like ChatGPT wrote it" would be a credibility problem.
  Triggers on phrases like "humanize this", "rewrite this to not sound like AI",
  "clean up this doc for leadership", "make this less robotic", "remove AI slop",
  "polish this for the exec team", or when the user pastes text and asks it to read better.
---

# Humanize

Rewrites AI-sounding text into prose that reads like a thoughtful senior professional wrote it.
The target reader is leadership — executives, skip-levels, steering committees.
The target voice is direct, specific, and confident without being robotic or padded.

Read `references/patterns.md` before rewriting. It contains the specific patterns to
hunt and the replacement approach for each.

---

## Operating Loop

**1. Orient**

If the user hasn't said what kind of document this is, infer it from context. For anything
ambiguous — status update vs. proposal vs. incident report vs. exec summary — ask one question
before rewriting. The document type affects the level of formality and how much compression
is appropriate.

**2. Scan for AI-tells**

Before rewriting, run a fast internal pass to identify which patterns from `references/patterns.md`
are present. Do not show this scan to the user. Use it to calibrate where the text needs the
most work.

**3. Rewrite**

Apply the rewrite principles below. The substance of the original must survive intact.
The voice, structure, and surface of the text is fair game.

**4. Output**

Deliver the rewritten text, clean, ready to paste. No preamble, no explanation unless asked.

If the user asks what changed, summarize the main categories of edits in 2–3 lines. Do not
enumerate every change — that's noise.

---

## Rewrite Principles

### Voice
- Write like a senior engineer or PM talking to their skip-level. Not casual, not robotic.
- First person is fine. "We decided to..." reads better than "A decision was reached..."
- Active over passive. Always. "The team shipped X" not "X was shipped by the team."

### Structure
- Vary sentence length. AI text is rhythmically uniform. Mix short punchy sentences
  with longer analytical ones. Leadership docs should breathe.
- If the original has a wall of bullets, consider whether a paragraph would flow better.
  Bullets are for discrete items. Narrative belongs in prose.
- Don't reorder the logic of the original unless the structure is clearly broken.

### Specificity
- Replace vague abstractions with the concrete thing they describe.
  "Operational efficiency improvements" → "we cut the pipeline from 4 steps to 2"
  (only if the original supports it — don't invent specifics that aren't there).
- Keep numbers if they're in the original. They're usually the most credible part.

### Compression
- Cut anything that doesn't add information. AI text is padded by default.
- Remove setup paragraphs that just announce what the text is about to say.
- Remove conclusions that just restate what was already said.
- Shorter is almost always better for leadership. They're reading fast.

### Hedging
- Remove hedges that don't reflect actual uncertainty: "it may be worth considering",
  "one could argue", "it seems that", "in many cases".
- If the original IS uncertain, express it plainly: "we don't know yet" not
  "this remains an area of ongoing investigation."

---

## Dos and Don'ts

**Do:**
- Preserve the author's original point of view and any genuine uncertainty
- Keep domain-specific terminology if it's correct and necessary
- Ask before inventing specifics that aren't in the original
- Produce text the user can paste without modification

**Don't:**
- Add qualifiers or caveats that weren't in the original
- Make the text more formal than it needs to be
- Turn a direct statement into a diplomatic non-statement
- Explain your edits unprompted

---

## References

`references/patterns.md` — Full list of AI-tell patterns with replacement guidance.
Load this before every rewrite.
