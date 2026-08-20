# Model semantics

## Symbols and bindings

A phenomenon is a stable symbolic business or technical concept. A binding is evidence for
how that concept is observed in a physical lake representation. Table names are not the
ontology: a symbol can survive ingestion renames, pipeline migrations, and historical
storage changes.

Use aliases and descriptions only to resolve a phrase. Once resolved, reason with the
concept ID. Select a binding whose validity interval covers the investigation window; do
not assume the current canonical table represents historical data.

## Relation kinds

| Kind | Meaning | Permitted inference |
|---|---|---|
| `causal` | A hypothesized or supported mechanism of influence | Follow causally while respecting status, evidence, direction, and lag. |
| `statistical` | Variables were observed to move together | Generate a candidate or comparison; do not infer direction or mechanism. |
| `temporal` | Ordering or co-occurrence | Check timing; do not infer cause. |
| `structural` | Entity, ownership, or system dependency | Understand topology; do not convert dependency into influence. |
| `semantic` | Conceptual relationship | Resolve meaning; do not use as an operational path. |
| `lineage` | Data derivation or physical provenance | Trace values; `A derived_from B` does not mean `B causes A`. |

Default neighborhood retrieval should remain causal and trusted. Include other kinds only
for a stated reason, using the corresponding CLI flag. Use `--include-proposed` only when
the investigation explicitly needs unreviewed hypotheses, and label them as proposed in
all reasoning.

## Status and evidence

Global relation statuses progress through `candidate`, `hypothesis`, `supported`, and
human-reviewed `verified`, with `disputed` and `rejected` for contrary review outcomes.
Status is not a numeric probability. Evidence should identify its source and type; measured
statistics should retain the metric, value, and sample size.

Treat `candidate` and `hypothesis` edges as ideas to test. Treat `supported` as usable but
revisable knowledge. Treat `verified` as protected organizational knowledge, not permission
to ignore scope, time, or contradictory incident evidence.

## Time and feedback

Relation time modes may be synchronous, asynchronous, cumulative, or unknown. Respect
minimum and maximum lag when choosing observation windows. For cumulative relations,
inspect both exposure and effect windows. A positive-lag feedback loop can be coherent
because its nodes occur at different times; never collapse it into a same-time cycle.

## Proposals

Proposals are untrusted source records. Query commands exclude them by default. Create a
proposal when an investigation discovers a repeatable relationship worth human review,
but preserve its evidence reference and never move or rewrite trusted model files as part
of the proposal workflow.
