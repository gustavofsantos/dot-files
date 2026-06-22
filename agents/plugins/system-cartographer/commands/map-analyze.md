---
description: Run a failure-analysis mode over the map (blast-radius, degradation, cascade, hidden-coupling, spof).
argument-hint: <mode> [node]
allowed-tools: Bash
---

Run a reasoning mode over the system map. Arguments: `$ARGUMENTS` — a `mode`
(`blast-radius` | `degradation` | `cascade` | `hidden-coupling` | `spof`) and,
for `blast-radius`/`degradation`, a target node id.

Run:

```
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/analyze.py" <mode> [node]
```

Then **use the `reasoning` skill** to interpret the output for the user.

Critical: if the output contains a `SCHEMA INSUFFICIENT — PROPOSAL` block, the
current schema cannot support this analysis. Do **not** guess an answer and do
**not** edit the schema yourself. Follow the `upgrade-protocol` skill: present
the staged proposal to the user and tell them to run `/accept-schema-change` if
they want to earn that attribute. The proposal has already been staged to
`.cartographer/.proposed-extension.json`; nothing has changed yet.
