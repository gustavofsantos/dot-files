---
name: issue
description: >
  Create or update a tracked work item in ~/engineering/issues/. Trigger only on
  explicit intent to file work: "create an issue", "file a bug", "track this as an issue",
  "new story", "new feature", "/issue", or when another skill says to invoke the issue skill.
  Does NOT trigger on casual code discussion that mentions the word "issue".
---

# issue

Create or update tracked work items in `~/engineering/issues/`.

## Operating loop

1. **Search first** — `rg -il 'term' ~/engineering/issues/ -l 2>/dev/null` — if a similar item exists, update it instead of creating a duplicate.
2. **Allocate ID** — find the next ID:
   ```bash
   ls ~/engineering/issues/ ~/engineering/issues/archive/ 2>/dev/null \
     | grep -oE '^[0-9]+' | sort -n | tail -1
   # increment by 1 and zero-pad to 3 digits
   ```
3. **Choose type** — `implementation`, `bug`, or `investigation`; infer from context, confirm if ambiguous.
4. **Fill missing fields conversationally** — ask only what cannot be inferred.
5. **Write** — if creating or updating a file, load [references/templates.md](references/templates.md) first and follow the matching template exactly.

## File location

`~/engineering/issues/NNN-Title Case.md` — Title Case, spaces, short imperative phrase.
