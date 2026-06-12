---
name: spike
description: >
  Capture a research result or investigation finding as a spike in ~/engineering/spikes/.
  Trigger on: "write a spike", "document this research", "spike for issue NNN",
  "capture findings", "/spike", or when a skill says to invoke the spike skill.
  Does NOT trigger on casual mentions of "investigation" or "research" in code discussion.
---

# spike

Capture research results in `~/engineering/spikes/`.

## Operating loop

1. **Search first** — `rg -il 'term' ~/engineering/spikes/ -l 2>/dev/null` — update an existing spike if the same question is already tracked.
2. **Determine ID**:
   - If tied to an issue: use that issue's ID as the spike prefix (multiple spikes per issue share the same NNN prefix — distinguish by slug).
   - If standalone: find the next ID from the combined max of issues and spikes:
     ```bash
     ls ~/engineering/issues/ ~/engineering/issues/archive/ ~/engineering/spikes/ 2>/dev/null \
       | grep -oE '^[0-9]+' | sort -n | tail -1
     # increment by 1 and zero-pad to 3 digits
     ```
3. **Fill missing fields conversationally** — ask only what cannot be inferred.
4. **Write** — if creating or updating a file, load [references/templates.md](references/templates.md) first and follow the template exactly.

## File location

`~/engineering/spikes/NNN-descriptive-slug.md` — lowercase-hyphenated slug, specific enough to distinguish from sibling spikes on the same issue.
