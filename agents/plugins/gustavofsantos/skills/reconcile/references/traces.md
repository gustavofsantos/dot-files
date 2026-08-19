# Traces — timelines across systems

Read for "what happened to X", ordering questions, and to measure the watermark every probe
depends on.

## Bitemporality

Two clocks, never mixed:

- **valid time** — when the business fact happened (`created_at`, `issued_at`)
- **transaction time** — when the row became visible here (the CDC timestamp)

Order the story by valid time. Judge completeness by transaction time. Confusing the two
manufactures most false breaks in any CDC-fed reconciliation.

## The spine

One parameterized trace per entity type, not one query per investigation. Fold every context
into the same six columns:

```sql
-- ${ENGINEERING_HOME:-$HOME/engineering}/reconcile/traces/<repo>/<entity>.sql
-- replace :key
WITH ev AS (
  SELECT <key> AS k, <valid_ts> AS t, <cdc_ts> AS seen,
         '<context>' AS src, '<label>' AS event, cast(<id> AS varchar) AS ref
  FROM <table_a> WHERE <key> = :key
  UNION ALL
  ...
)
SELECT t, seen, date_diff('minute', t, seen) AS lag_min, src, event, ref
FROM ev ORDER BY t
```

Grow it by one `UNION ALL` per system as each proves relevant. Put status in the label
(`'invoice ' || status`) so state transitions appear as rows.

Read three full traces before writing any probe against a system you have never touched. It
outperforms documentation.

## Watermark

`interval '2' hour` is a placeholder until measured. Take the p99 of transaction-time lateness
per source — they differ by orders of magnitude.

```sql
SELECT src, approx_percentile(lag_min, 0.99) AS p99_lag_min, max(lag_min) AS worst
FROM (<trace over a key sample>) GROUP BY src ORDER BY 2 DESC
```

Record in `entities.tsv`. A probe inherits the watermark of the slowest source it touches.
Re-measure when a pipeline changes.

## Precedence constraints

Timelines yield the cheapest probes: happens-before relations that must always hold.

```sql
-- INV-030: an order never precedes its contract
SELECT o.id, o.created_at, c.created_at AS signed_at
FROM <orders> o JOIN <contracts> c ON c.<key> = o.<key>
WHERE o.created_at < c.created_at
```

Look for these, while reading a trace:

- effect before cause
- a terminal state followed by a non-terminal one
- mutually exclusive states overlapping
- a gap exceeding any plausible business duration
- a downstream event with no upstream origin

Each is one query, zero rows when healthy, and catches bugs no aggregate check will surface.

## Promotion

    p99 lateness per source   -> entities.tsv, and into every probe's watermark
    invariant ordering        -> invariants.tsv + probes/<repo>/<id>.sql
    new event source          -> another UNION ALL in the trace
