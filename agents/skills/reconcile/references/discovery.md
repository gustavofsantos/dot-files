# Discovery — relationships you don't know yet

Read when `bridges.tsv` says UNKNOWN, a new system enters scope, or the question has no claim
behind it. This is schema-agnostic data profiling: three measurements, in order.

## 1. Candidates — metadata only

```sql
SELECT table_name, column_name, data_type
FROM <catalog>.information_schema.columns
WHERE table_schema = '<schema>'
  AND (column_name LIKE '%<entity>%' OR column_name LIKE '%ref%' OR column_name LIKE '%_id')
ORDER BY table_name, ordinal_position
```

Compare type *and* value shape — zero-padding, prefixes, length. `C-000123` and a bigint are
not the same key however they are named. Name similarity is a hint, never a justification.

## 2. Inclusion dependency — the measurement that decides

Does `left.k ⊆ right.k` hold? Measure it, in both directions — coverage is rarely symmetric,
and the asymmetry is itself a business fact.

```sql
WITH l AS (SELECT DISTINCT <left_key> AS v FROM <left> WHERE <recent> LIMIT 2000),
     r AS (SELECT DISTINCT <right_key> AS v FROM <right>)
SELECT count(*) AS sampled, count(r.v) AS matched,
       round(100.0 * count(r.v) / count(*), 2) AS pct
FROM l LEFT JOIN r ON r.v = l.v
```

## 3. Fan-out — which fixes the grain

```sql
SELECT max(n) AS max_per_key, avg(n) AS avg_per_key, count(*) AS keys
FROM (SELECT <right_key>, count(*) AS n FROM <right> GROUP BY 1)
```

`max_per_key > 1` breaks every downstream sum. Record cardinality in `entities.tsv` as part of
the grain.

## Verdict

| Coverage | Verdict | Action |
|---|---|---|
| 100% | exact inclusion dependency | promote, write the probe |
| 95–99.9% | inclusion with a carve-out | **name the carve-out first**, then promote |
| 30–95% | conditional relation | a predicate is missing — keep hunting |
| < 10% | coincidence | discard, and record the discard |

## The 95–99.9% band

This is where the business is learned. The residual is always a rule nobody wrote down —
cancelled before first billing, migrated legacy prefix, internal tenant excluded upstream.

Case-control diff: 20 unmatched keys against 20 matched, column by column, until one field
separates the populations. State it as a sentence, then encode the sentence as the probe's
`WHERE` predicate. Coverage should reach 100% of the population the probe claims.

Only then promote. A bridge promoted at 97% emits the same false breaks forever and trains
everyone to ignore the suite.

## Recording

```
left              right            join                                 probe
billing.invoice   cart.contract    invoice.contract_id = contract.id    INV-002
```

If a carve-out was needed, it lives in the probe and the bridge points at it. Never record a
half-true join and rely on the reader remembering the exception.
