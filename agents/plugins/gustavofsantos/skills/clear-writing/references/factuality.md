# Factuality and Semantic Preservation

Technical editing must preserve the document's epistemic state.

## Classify important statements

Use these categories during review:

- **Fact**: directly supported by evidence.
- **Inference**: derived from evidence.
- **Hypothesis**: possible explanation that still needs verification.
- **Assumption**: accepted temporarily without sufficient evidence.
- **Decision**: an explicit choice already made.
- **Recommendation**: a proposed action or judgment.
- **Unknown**: missing, contradictory, or unverified information.

Do not silently promote a statement to a stronger category.

Examples of forbidden strengthening:

- `may` -> `will`
- `likely` -> `certainly`
- `suggests` -> `proves`
- `some` -> `all`
- `often` -> `always`
- correlation -> causation
- recommendation -> requirement
- hypothesis -> root cause

## Claims that need extra scrutiny

Check these carefully:

- causal claims
- performance claims
- security claims
- reliability claims
- financial impact
- percentages
- timelines
- ownership
- guarantees
- comparisons such as "faster", "safer", "best", or "largest"

Prefer qualified wording when evidence is limited.

## Numbers

Preserve:

- exact vs approximate values
- ranges
- units
- denominators
- percentile notation
- percentage vs percentage-point differences

Do not turn:

`approximately 10k requests/minute under the tested workload`

into:

`10k requests/minute`

## Requirements

Treat these as semantic tokens:

English:
- must
- should
- may
- can
- required
- recommended
- optional

Portuguese:
- deve
- deveria
- pode
- obrigatório
- recomendado
- opcional

Do not change their strength for style.

If the document explicitly follows RFC 2119 / RFC 8174 semantics, preserve uppercase normative terms exactly unless the user asks otherwise.

## Contradictions

When two authoritative sources disagree:

1. state the contradiction
2. identify both sources
3. avoid inventing reconciliation
4. ask for or recommend verification only if needed

## Missing evidence

If the document contains a plausible but unsupported statement, prefer:

- preserving the original uncertainty
- marking it as unverified
- converting it into a question or explicit assumption when appropriate

Do not fabricate citations, measurements, dates, incidents, decisions, or implementation details.
