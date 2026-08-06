---
name: reconcile
description: >-
  Cross-system data analysis, reconciliation, and record-level investigation. Use this skill
  whenever the task is to compare, audit, tie out, trace, or explain differences between two
  populations of records — invoices vs orders, ledger vs subledger, source system vs
  downstream, expected vs actual. Also use it for "why doesn't X match Y", "where did this
  record go", "is this number right", "what happened to contract N", and for any exploratory
  question about systems or tables whose relationships are not yet known. Reads and writes
  `model/`: entities.tsv (grain and keys), bridges.tsv (how ids map across systems),
  invariants.tsv + probes/ (claims that must hold), breaks.tsv (classified mismatches),
  traces/ (per-entity timelines). Requires a query adapter skill (e.g. `datalake`) to execute
  SQL. Use it even when the user only asks for a single number — the number is a probe.
---

# Reconcile

Don't trust, verify. A belief about the business is worth nothing until it is a zero-row
assertion.

## Adapter (port)

Executes nothing itself. Requires a command shaped like:

    <run-query> --description "<why>" --execute "<sql>" --output-format CSV

Resolve in order: `model/ADAPTER` → a query-running skill in this repo → ask. Never call the
raw client, never inline credentials, always state *why* in `--description`.

## States

| State | Given | Produce |
|---|---|---|
| **Frame** | a question | grain, keys, expectation, falsifier |
| **Discover** | an UNKNOWN key | an inclusion dependency → `references/discovery.md` |
| **Verify** | a claim | a zero-row assertion |
| **Trace** | one record | a bitemporal timeline → `references/traces.md` |

Name the state before acting.

## Frame

Read `model/*.tsv`; grep the adapter's query catalog for prior art. Then four lines, then stop
for confirmation:

    GRAIN      one row = ?
    KEYS       left.col -> right.col   (cite bridges.tsv, else UNKNOWN)
    EXPECT     "these rows must not exist"
    FALSIFIER  the query that refutes me

UNKNOWN is the session's real work. Resolve by measurement — a matching column name is not
evidence.

## Verify

A probe is a singular test: **the rows it returns are the failures**. Never an eyeballed count,
never a percentage the user must judge.

Every probe carries a watermark on transaction time, so late arrival is not read as absence:

    AND <cdc_ts> < current_timestamp - interval '<p99>' hour

p99 is measured per source, not assumed — `references/traces.md`.

## Breaks

Classify every returned row first:

    timing | in-transit | rounding | duplicate | missing-in-target | missing-in-source | misclassified

**An explainable class is a predicate, not a note.** Tighten the probe until only irreducible
breaks survive, then log those to `breaks.tsv`. Prose decays silently; predicates cannot.

## Promotion

On green only:

    key path            -> bridges.tsv
    grain / cardinality -> entities.tsv
    claim               -> invariants.tsv + probes/<id>.sql
    irreducible breaks  -> breaks.tsv

An unprobed row in entities.tsv or bridges.tsv is hearsay; `scripts/no-unproven-claims.sh`
fails closed on it.

Red is equally mandatory: a failing probe is a falsified belief or a changed rule. Mark it red
the moment it fails. Never delete a probe to green the suite.

## Reporting

Break counts by class, the two or three rows that matter, what was promoted. Never persist
result sets into `model/` or the query catalog.

## References

- `references/discovery.md` — inclusion dependency, fan-out, verdict rubric. Read before
  promoting any bridge.
- `references/traces.md` — bitemporal timelines, watermark measurement, precedence
  constraints.
- `assets/model/` — worked templates. Copy into the repo on first use.
