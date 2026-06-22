---
description: Add a directed dependency edge (from depends on to) to the system map.
argument-hint: <from> <to> [sync|async]
allowed-tools: Bash
---

Add an edge to the map. Semantics: `from -> to` means **"from depends on to"**
(from calls / needs to). Arguments: `$ARGUMENTS`.

Determine `from`, `to`, and `interaction` (`sync` or `async`). The interaction
is the single most load-bearing edge attribute — if the user did not state it,
**ask**: "Is that call synchronous (caller blocks/fails with it) or asynchronous
(fire-and-forget / queued)?" It is the one thing a user can almost always
answer, so prompt for it rather than guessing.

Then run:

```
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/map_edit.py" add-edge --from "<from>" --to "<to>" --interaction "<sync|async>"
```

To set an EARNED attribute (only ones already in the schema), append
`--attr name=value` (repeatable). Do not invent attributes — unknown ones are
rejected; earn them first via `/map-analyze` + `/accept-schema-change`.

Both endpoints must already be nodes; the script refuses dangling edges. Report
the result, including any SPOF/cycle notes it surfaces.
