---
name: reconcile
description: >-
  Cross-system data analysis, reconciliation, and record-level investigation. Use this skill
  whenever the task is to compare, audit, tie out, trace, or explain differences between two
  populations of records — invoices vs orders, ledger vs subledger, source system vs
  downstream, expected vs actual. Also use it for "why doesn't X match Y", "where did this
  record go", "is this number right", "what happened to contract N", and for any exploratory
  question about systems or tables whose relationships are not yet known. Models the whole
  organization, not one repository — a monorepo can host several systems, and one system can
  span several repositories. Keeps what it learns in one org-wide knowledge vault under
  `reconcile/`: entities.tsv (grain and keys), bridges.tsv (how ids map across systems,
  including across repositories), invariants.tsv (claims that must hold), breaks.tsv
  (classified mismatches). Keeps the SQL that proves them in each repository under
  `model/probes/` and `model/traces/`, addressed as `<repo>/<id>` from the vault so a claim
  stays traceable to its proof wherever that proof lives. Requires a query adapter skill
  (e.g. `datalake`) to execute SQL. Use it even when the user only asks for a single number —
  the number is a probe.
---

# Reconcile

Do not trust, verify. A belief about the business is worth nothing until it is a zero-row
assertion.

## Where the work lives

Two homes, split by what the file is. This skill directory is never a home for either.

| File | Home | Why |
|---|---|---|
| entities.tsv, bridges.tsv, invariants.tsv, breaks.tsv | `${ENGINEERING_HOME:-$HOME/engineering}/reconcile/` | What you learned about the business. It outlives any one repository, and the business rarely fits in one. |
| probes/*.sql, traces/*.sql, `model/ADAPTER` | `model/` in each repository | Executable assertions. They version with the code they assert against. |

The vault holds one set of tables for the whole organization. A monorepo can hold two or more
systems. Name each system with its own `context` in entities.tsv. One system can also span two
or more repositories. Its bridges then cross repository lines, not only system lines.

The `probe` column holds `<repo>/<id>`. `repo` is the short name of the repository that owns
the SQL, for example `billing-service/INV-002`. This resolves to `model/probes/<id>.sql` in
that repository. Write the id bare, without a `<repo>/` prefix, only when you are certain that
no other repository will ever hold a probe with that id. In practice, always prefix it.

## Adapter (port)

Executes nothing itself. Requires a command shaped like:

    <run-query> --description "<why>" --execute "<sql>" --output-format CSV

Resolve in order: `model/ADAPTER` → a query-running skill in this repo → ask. A probe belongs
to the repository named in its `<repo>/<id>` prefix — run it from there, not from wherever the
question started. Never call the raw client, never inline credentials, always state *why* in
`--description`.

## States

| State | Given | Produce |
|---|---|---|
| **Frame** | a question | grain, keys, expectation, falsifier |
| **Discover** | an UNKNOWN key | an inclusion dependency → `references/discovery.md` |
| **Verify** | a claim | a zero-row assertion |
| **Trace** | one record | a bitemporal timeline → `references/traces.md` |

Name the state before acting.

## Frame

Read the vault tables. They span every repository. Search by `context` and by entity name, not
by which repository you happen to be sitting in. Grep the adapter's query catalog for prior
art. Then four lines, then stop for confirmation:

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
breaks survive, then log those to `breaks.tsv`. Prose decays silently. Predicates cannot.

## Promotion

On green only:

    key path            -> bridges.tsv          (probe: <repo>/<id>)
    grain / cardinality -> entities.tsv
    claim               -> invariants.tsv + <repo>/model/probes/<id>.sql
    irreducible breaks  -> breaks.tsv

The tables go to the org-wide vault. The SQL goes to the repository named in its `<repo>/`
prefix. An unprobed row in entities.tsv or bridges.tsv is hearsay. `scripts/no-unproven-claims.sh`
fails closed on it. That script can only verify that a probe exists in the repository you write
from. Promote a row only while you sit in the repository its probe id names.

Red is equally mandatory: a failing probe is a falsified belief or a changed rule. Mark it red
the moment it fails. Never delete a probe to green the suite.

## Reporting

Break counts by class, the two or three rows that matter, what was promoted. Never persist
result sets into the vault tables, into `model/`, or into the query catalog.

## References

- `references/discovery.md` — inclusion dependency, fan-out, verdict rubric. Read before
  promoting any bridge.
- `references/traces.md` — bitemporal timelines, watermark measurement, precedence
  constraints.
- `assets/model/` — worked templates for the four tables. Copy into
  `${ENGINEERING_HOME:-$HOME/engineering}/reconcile/` once, the first time this skill runs
  anywhere. Every repository after that appends to the same tables.
