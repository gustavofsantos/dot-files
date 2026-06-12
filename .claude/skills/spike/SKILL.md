---
name: spike
description: >
  Capture a research result or investigation finding as a spike in ~/engineering/spikes/.
  Trigger on: "write a spike", "document this research", "spike for issue NNN",
  "capture findings", "/spike", or when a skill says to invoke the spike skill.
  Does NOT trigger on casual mentions of "investigation" or "research" in code discussion.
---

# spike

Capture research results in `~/engineering/spikes/`. Read this before writing.

## Operating loop

1. **Search first** — `rg -il 'term' ~/engineering/spikes/ -l 2>/dev/null` — update an existing spike if the same question is already tracked.
2. **Determine ID**:
   - If tied to an issue: use that issue's ID as the spike prefix (multiple spikes per issue share the same NNN prefix — distinguish by slug).
   - If standalone research: find the next ID from the combined max of issues and spikes:
     ```bash
     ls ~/engineering/issues/ ~/engineering/issues/archive/ ~/engineering/spikes/ 2>/dev/null \
       | grep -oE '^[0-9]+' | sort -n | tail -1
     # increment by 1 and zero-pad to 3 digits
     ```
3. **Fill missing fields conversationally** — ask only what cannot be inferred.
4. **Write** — follow the contract below.

## File location

`~/engineering/spikes/NNN-descriptive-slug.md` — lowercase-hyphenated slug, specific enough to distinguish from sibling spikes on the same issue.

## Frontmatter schema

```yaml
---
id: "NNN"
title: "Question being investigated"
status: resolved             # resolved | inconclusive | deferred
created: YYYY-MM-DD
related-issue: "NNN"         # optional — omit if standalone
---
```

## Body

```markdown
## Question
The question the spike is intended to answer.

## Context
What prompted this spike. 2–4 sentences.

## Answer
One sentence summary of the conclusion.

## Evidence
What was discovered. Prose. Link to files, commits, or docs.

## Links
- issues/NNN-Related Issue.md
- [[Note Produced By Spike]]
```
