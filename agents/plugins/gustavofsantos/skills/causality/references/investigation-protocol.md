# Investigation protocol

Commands written as `causality ...` use the skill-bundled executable documented in
`SKILL.md`: `python3 <skill-dir>/scripts/causality ...`.

The investigation ledger is incident-specific memory. It preserves observation windows,
candidates, evidence, supported branches, and—most importantly—refuted branches without
changing global knowledge.

## Start or resume

Resolve the effect first, then use an explicit timezone in the observation window:

```bash
causality investigate start \
  --id <incident-id> \
  --effect <concept-id> \
  --direction increase \
  --from <ISO-8601-start> \
  --to <ISO-8601-end>

causality investigate status <incident-id>
```

If the investigation exists, read its status rather than creating another ID for the same
event. Make refuted candidates visible before proposing new work so prior dead ends are not
retested.

## Record candidates

Prefer a graph path when the mechanism is represented:

```bash
causality investigate candidate add <incident-id> \
  --id <candidate-id> \
  --path <cause>,<mediator>,<effect>
```

Use `--description "<falsifiable explanation>"` when no trusted path exists. Phrase the
description so one observation can support or refute it. A candidate is working state, not
trusted organizational knowledge.

When `--path` is supplied, the CLI verifies every concept, each directed trusted causal
edge, and that the last node is the investigation effect. It rejects an unmodeled or
reversed path; use `--description` for that hypothesis instead.

## Attach evidence

Run one narrow test through the available query adapter, save or reference its result in
the location owned by that workflow, then attach the reference and a factual summary:

```bash
causality investigate evidence add <incident-id> \
  --candidate <candidate-id> \
  --type query_result \
  --source <result-reference> \
  --summary "<what was observed>"
```

Do not turn interpretation into the evidence summary. Record actual values, timing,
baseline comparison, sample size, or query identity when available.

## Decide the branch

```bash
causality investigate refute <incident-id> <candidate-id> \
  --reason "<observation incompatible with this incident explanation>"

causality investigate support <incident-id> <candidate-id> \
  --reason "<temporally and mechanistically plausible observation>"
```

Support means the branch remains a plausible explanation for this incident; it does not
verify the global relation. Refute only when the observation genuinely discriminates
against the candidate. Otherwise leave it unresolved or inconclusive.

Attach at least one candidate-specific evidence record before either verdict. The only
exception is an explicit `--allow-without-evidence` override with a reason explaining why
the ledger must record a provisional decision.

## Expansion and stopping

After each verdict, run `causality investigate status <incident-id>`. Expand a single
unresolved branch with a one-hop upstream neighborhood. Stop when:

- a supported path explains the effect with appropriate temporal ordering;
- every practical branch is refuted;
- evidence is unavailable or non-discriminating, making the result inconclusive; or
- safe querying is blocked by missing grain, binding, partition, or validity metadata.

Report the observation, supported path if any, conspicuous refutations, remaining unknowns,
and the evidence references. Never reject a global causal relation merely because it did
not explain this incident.
