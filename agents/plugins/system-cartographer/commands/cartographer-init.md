---
description: Scaffold a .cartographer/ system map in the current repo (kernel schema, empty map, evolution log).
allowed-tools: Bash
---

Initialize the system-cartographer instance for this repo.

Run:

```
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/init_cartographer.py"
```

Then briefly tell the user what was created and that they can start mapping with
`/map-add-node` and `/map-add-edge`. Do not edit any file under `.cartographer/`
by hand — the schema is protected and the map has dedicated commands.
