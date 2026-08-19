---
name: exhibit
description: >-
  Turn probe output, trace output, or any query result into a Mermaid exhibit — funnel,
  breaks, lateness, trace, drift. Use this skill whenever a data result would be easier to
  read as a picture: population attrition between systems, break counts by class, ingestion
  lag distribution, the timeline of one record across services, or a break rate trending over
  days. Also use for "chart this", "show me where the records are dying", "plot the lag",
  "draw the timeline for contract N", "is this getting worse". Pairs with the `reconcile`
  skill (which produces the probes) and a query adapter such as `datalake` (which runs them).
  Renders via scripts/exhibit.py — stdlib Python, no dependencies, Mermaid to stdout.
---

# Exhibit

An exhibit is evidence attached to a finding, not decoration. It carries its provenance and it
is numbered to a probe.

## The gate

**Only probed data gets an exhibit.** Input is the output of a reconcile-vault
`probes/<repo>/*.sql` or `traces/<repo>/*.sql`, piped through the adapter. Never write ad-hoc
SQL for the sake of a picture. A chart is the most persuasive artifact in the repo. An
unverified one is a lie with a legend.

If the user asks for a chart of something no probe covers: write the probe first (`reconcile`),
then render it.

## Closed set

Five verbs. Do not invent a sixth. If none fits, the question is not yet framed.

| Verb | Question | Mermaid |
|---|---|---|
| `funnel` | where do records die between systems? | `sankey-beta` |
| `breaks` | which class, concentrated where? | `xychart-beta` bar + share table |
| `lateness` | what is the real watermark? | quantile table + `xychart-beta` bar |
| `trace` | what happened to this one record? | `gantt`, sections = contexts, events = milestones |
| `drift` | is the break rate getting worse? | `xychart-beta` line + threshold |

## Invocation

```bash
scripts/exhibit.py <verb> [--file in.csv] \
  --probe INV-014 --grain "one issued invoice" --watermark 4h \
  --population "status = ISSUED"
```

Reads CSV on stdin by default, so it composes directly with the adapter:

```bash
<run-query> --description "breaks by class for INV-014" \
  --file "${ENGINEERING_HOME:-$HOME/engineering}/reconcile/probes/<repo>/INV-014.sql" \
  --output-format CSV \
  | scripts/exhibit.py breaks --probe INV-014 --grain "one issued invoice" --watermark 4h
```

Column names are overridable (`--count-col`, `--class-col`, `--lag-col`, `--time-col`, …). The
defaults match the shapes `reconcile` already emits.

## Provenance

The script stamps every exhibit with probe id, grain, population, watermark, row count, and
as-of. Never write that footer by hand and never strip it — exhibits get pasted into issues and
outlive their context by months. Pass `--probe`, `--grain`, `--watermark` on every call. A `-`
in the footer is a defect, not a default.

## Rules that survive being ignored by the model

- **Counts and money together** in `funnel`, via `--amount-col`. A fan-out inflates counts while
  the control total stays flat. One number alone hides it.
- **Never smooth.** The spike is the finding.
- **Never a pie chart of break classes.** Rank order is the information. Angle is not.
- **Zero baseline always.** `xychart-beta` starts at 0 here by construction — keep it.
- **One exhibit, one claim.** No dual axes, no two questions on one canvas.

## Escape hatch

Mermaid has no stacked bars, so class × time in a single view is the one shape it cannot do.
When that view is genuinely needed, and only then, fall back to matplotlib and emit a PNG.
Note in the caption that it is an off-Mermaid exhibit. Everything else stays dependency-free.
