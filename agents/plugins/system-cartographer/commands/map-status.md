---
description: Report map size, validity, earned extensions, and backfill gaps.
allowed-tools: Bash
---

Report the state of the system map. Run:

```
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/status.py"
```

Relay the result. Pay attention to **backfill gaps** (e.g. "8 edges lack
failure_mode") — these are known-unknowns, not errors. If gaps exist, you may
offer to help the user fill them, which sharpens future analysis.
