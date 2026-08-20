# Query safety

Commands written as `causality ...` use the skill-bundled executable documented in
`SKILL.md`: `python3 <skill-dir>/scripts/causality ...`.

`causality query-plan` plans analysis; it does not execute SQL. Use its output as a hard
preflight gate before handing a statement to the available query adapter.

## Preflight checklist

1. **Validity:** the selected binding covers the full requested window. Split the query by
   binding interval when a migration occurs inside the window.
2. **Time:** use the declared time column and an explicit bounded predicate. Do not replace
   event time with ingestion or update time without stating why.
3. **Partitioning:** when `require_partition_filter` is true, constrain at least one listed
   partition key. A predicate on a non-partition timestamp is not a substitute.
4. **Scale:** compare estimated rows and bytes with the requested window. Honor the
   recommended time window; widen it in measured increments only when necessary.
5. **Grain:** state what one row represents. Aggregate or deduplicate before joining when
   grains differ. Never infer join cardinality from similar column names.
6. **Population:** for rates and ratios, preserve the declared numerator, denominator, and
   eligible population across comparisons.
7. **Keys:** use the declared entity key or a separately proven bridge. Measure fan-out and
   coverage before trusting an unfamiliar join.
8. **Nulls:** apply null-rate hints to assess selection bias and denominator loss. Do not
   silently filter nulls that represent a business state.
9. **Physical hints:** use cluster keys to narrow scans where useful, but do not mistake
   clustering for a guaranteed uniqueness or relationship constraint.
10. **Reference:** prefer the canonical query reference when present and explain necessary
    deviations.

## Blockers

Stop and report the missing metadata instead of drafting a plausible query when:

- no binding covers the requested dates;
- a required partition predicate cannot be supplied;
- the query would scan a large table without partition metadata;
- grain or eligible population is unknown for a consequential join or comparison;
- entity keys are absent or join cardinality is unproven; or
- the required timestamp semantics are ambiguous.

The safe response is a narrower investigation, a metadata proposal, or a request for human
clarification—not an unbounded exploratory scan.

## Adapter boundary

Causality does not execute the company's SQL dispatcher. Use the available query-running
skill or adapter and include a short description of why the query is needed. Never place
credentials in commands or files, never use writes for investigation, and never bypass an
approved adapter with a raw database client.
