---
name: reconcile
description: >-
  Reconcile records or numbers across systems with executable SQL evidence. Use for compare,
  audit, tie-out, missing-record, mismatch, lineage, and record-history questions such as
  "why doesn't X match Y?", "where did this record go?", "is this number right?", or "what
  happened to contract N?" Also use when exploring unknown joins between tables. Store shared
  knowledge and SQL evidence together in the org-wide reconcile vault. Requires an available
  query-running skill or adapter.
---

# Reconcile

Turn each expectation into a SQL **probe**. A probe returns only violating rows: zero rows
means the expectation currently holds. Do not accept matching totals or column names as proof.

## One home for all artifacts

Store everything produced by this skill under:

```text
${ENGINEERING_HOME:-$HOME/engineering}/reconcile/
├── entities.tsv
├── bridges.tsv
├── invariants.tsv
├── breaks.tsv
├── probes/<repo>/<id>.sql
└── traces/<repo>/<entity>.sql
```

The TSV files hold shared knowledge. `probes/` holds zero-row assertions. `traces/` holds
single-record timelines. `<repo>` is the short repository name used as a namespace, even
though the SQL lives in the vault.

On the first run, create the vault directory and copy missing TSV files from `assets/model/`.
Create `probes/` and `traces/` when needed. Never overwrite existing TSV files. Never store
query result sets in the vault or repository.

Identify a probe everywhere as `<repo>/<id>`, for example
`billing-service/INV-002`. Its only SQL file is
`${ENGINEERING_HOME:-$HOME/engineering}/reconcile/probes/billing-service/INV-002.sql`.
Do not create `model/probes/`, `model/traces/`, or other reconciliation artifacts in a code
repository.

## Follow this workflow

### 1. Read existing knowledge

Read all four vault TSV files. Search their `context`, entity, and probe columns for relevant
rows. Search the vault's `probes/` and `traces/` directories and the query adapter's catalog.
Reuse a matching probe rather than inventing another.

### 2. Write the four-line frame

Before querying, write:

```text
GRAIN      one row represents <business object>
KEYS       <left.column> -> <right.column>, or UNKNOWN
EXPECT     rows where <violation> must not exist
FALSIFIER  a query returning those violating rows
```

Ask for clarification only if the grain or expectation cannot be inferred. `UNKNOWN` is not
an error: it means the key relationship must be measured in step 3.

### 3. Choose one path

| Situation | Action |
|---|---|
| `KEYS` is `UNKNOWN` or a join is only guessed | Read `references/discovery.md`; measure candidate keys, coverage in both directions, and fan-out. |
| The question concerns one record or event order | Read `references/traces.md`; build or extend `traces/<repo>/<entity>.sql` in the vault. |
| A relevant probe already exists | Confirm its watermark is still valid, run it unchanged, and continue at step 5. |
| The join is proven and the expectation is clear | Continue at step 4. |

Never infer a relationship from similar names alone. Do not add it to the vault until a probe
proves it.

### 4. Create and run one probe

Write `probes/<repo>/<id>.sql` in the vault so every returned row is a failure. Exclude records
newer than the slowest source's measured p99 transaction-time lag:

```sql
AND <transaction_timestamp> < current_timestamp - interval '<measured p99>' hour
```

If lateness has not been measured, read `references/traces.md` and measure it first. Do not
guess a watermark.

Run SQL only through this adapter resolution order:

1. a query-running skill available for the data source;
2. ask the user which adapter to use.

The adapter must support the equivalent of:

```text
<run-query> --description "<why this query is needed>" --execute "<sql>" --output-format CSV
```

Never call a raw database client or place credentials in commands or files.

### 5. Handle the result

**If the probe returns zero rows:** promote only facts it proved:

- append a proven grain/cardinality to `entities.tsv`;
- append a proven key path to `bridges.tsv`;
- append the expectation and status to `invariants.tsv`;
- keep the SQL at `probes/<repo>/<id>.sql` in the vault.

Append only the applicable rows. For example, a probe that tests an existing join may prove
an invariant without proving a new entity or bridge.

Every promoted `entities.tsv`, `bridges.tsv`, or `invariants.tsv` row must name the probe as
`<repo>/<id>`. Run `scripts/no-unproven-claims.sh` as the configured write hook when available.

**If the probe returns rows:** first classify each failure as one of:

```text
timing | in-transit | rounding | duplicate | missing-in-target |
missing-in-source | misclassified
```

Turn each explainable class into a SQL predicate and rerun the probe. Append only remaining,
irreducible failures to `breaks.tsv`. Mark the invariant `red`; never delete or weaken a probe
merely to make it green.

### 6. Report

Report:

1. probe id and expectation;
2. watermark and why it is valid;
3. pass (zero rows) or failure counts by class;
4. two or three representative failures, when present;
5. files and vault rows created or updated.

## References

- Read `references/discovery.md` before promoting any new bridge.
- Read `references/traces.md` to trace one record, measure lateness, or test event ordering.
