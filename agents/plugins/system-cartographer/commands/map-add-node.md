---
description: Add a component (node) to the system map.
argument-hint: <id> <role description>
allowed-tools: Bash
---

Add a node to the map. Arguments: `$ARGUMENTS` — the first token is the node
`id` (stable, kebab-case), the rest is the free-text `role` (what it does / what
it is the source of truth for).

Parse an id and a role from the arguments, then run:

```
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/map_edit.py" add-node --id "<id>" --role "<role>"
```

If the role is missing, ask the user for one short sentence — the role is what
makes later failure analysis meaningful. The script validates and writes; report
its result. It refuses duplicate ids.
