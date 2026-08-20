---
name: causality
description: >
  Use Causality before company data analysis, forensic or root-cause investigation,
  unfamiliar metric interpretation, cross-domain reasoning, or data-lake exploration.
  Trigger for questions such as "why did metric X change?", "what affects X?", "where is
  X stored?", "how should I query X safely?", and investigations that must preserve tested
  or refuted explanations. Retrieve a small local graph, inspect physical bindings before
  querying data, and keep statistical, lineage, structural, temporal, and causal claims
  distinct.
---

# Causality

Causality is the semantic, physical-grounding, and causal-reasoning layer for a company
data lake. Use its CLI before inferring unfamiliar dataset semantics or cross-domain
relationships. It complements the query-running tool: Causality plans and records the
investigation; the query adapter observes the data.

The CLI is bundled with this skill. Invoke it as:

```bash
python3 <skill-dir>/scripts/causality <command> [arguments]
```

In the examples below, `causality ...` is shorthand for that bundled command. Resolve
`<skill-dir>` to this skill's installed directory; do not assume a separately installed or
PATH-visible `causality` binary exists.

## Retrieval rule

Never load the complete model unless the user explicitly requires it. Operational commands
read the compiled SQLite index, not TOML source. Start from the observed concept, retrieve
a bounded local neighborhood, and expand only when evidence requires another reasoning
step. JSON is the default CLI format; preserve IDs for follow-up calls. If the index is
missing, stop and run the verification/compile sequence below; never bypass it by parsing
model files in an investigation.

## Investigation loop

1. Resolve the observed phrase with `causality resolve "<phrase>"`.
2. Confirm the concept with `causality show <concept>`.
3. Inspect one upstream hop:
   `causality neighborhood <concept> --direction upstream --depth 1`.
4. Start or resume an investigation. Record each plausible explanation as a candidate.
5. Pick one unresolved branch. Before querying physical data, run
   `causality binding <concept>` or
   `causality query-plan <concept> --from <start> --to <end>`. If it requires a
   partition predicate, re-run with a declared `--partition-key` before querying.
6. Proceed only when `query-plan` reports `safety.safe_to_query: true`. Treat every
   returned blocker as a hard stop; split a `binding_resolution: SPLIT_REQUIRED` window.
   Check grain, population, temporal validity, time column, entity key, table scale,
   partition requirements, null-rate hints, and the canonical query reference.
7. Use the available query-running skill or adapter to test that branch. Never call a raw
   database client when an approved adapter exists.
8. Attach the result as investigation evidence, then explicitly support, refute, or leave
   the candidate inconclusive. A refutation applies to this incident, not to the global
   relation.
9. Expand only unresolved branches by one hop and repeat.
10. Put newly discovered relationships in `causality propose ...`; never promote them to
    trusted knowledge yourself.

Read `references/investigation-protocol.md` for exact ledger commands and stopping rules.

## Semantic guardrails

- Statistical association is not causation.
- Temporal ordering alone is not causation.
- Structural dependency is not causation.
- Lineage or derivation is not causation.
- Relation status is epistemic state; measured evidence is not a made-up confidence score.
- Positive-lag feedback may be valid. Do not invent a zero-lag mechanism to close a cycle.

Read `references/model-semantics.md` when interpreting relation kinds, statuses, evidence,
or historical bindings.

## Query-safety gate

Do not draft or dispatch a physical query until its binding is known. If a canonical
binding requires a partition filter, the planned query must constrain a listed partition
key. Treat mismatched grains, invalid binding dates, missing join keys, and an unbounded
large-table scan as blockers rather than warnings to hand-wave away.

Read `references/query-safety.md` before querying a large table, joining bindings, or
selecting a historical representation.

## Trust boundary

You may query the trusted model, maintain investigations, attach evidence, support or
refute investigation candidates, and create proposals. Proposals are independently
validated and indexed only when valid; an invalid proposal is reported by `validate` or
`compile` but never blocks trusted retrieval. Do not replace canonical bindings, rewrite
trusted metric definitions, modify verified relations, edit generated SQLite, or promote a
proposal into trusted model source. Agents propose; humans promote.

After an explicitly human-reviewed trusted-model source change, run in order:

```bash
python3 <skill-dir>/scripts/causality validate
python3 <skill-dir>/scripts/causality test
python3 <skill-dir>/scripts/causality compile
```

Do not use a generated model when any verification step fails.
