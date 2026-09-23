---
name: clear-writing
description: >
  Review, edit, shape, verify, or finalize a technical document in English or Brazilian
  Portuguese without changing its truth, intent, or technical meaning.
disable-model-invocation: true
---

# Clear Writing

Make the document easier to understand without changing its truth, intent, or technical
meaning. Infer the mode from the request: `review` (findings only), `edit` (local prose),
`shape` (structure, flow, terminology), `verify` (audit claims against evidence), or
`finalize` (all of them).

Priority: factual correctness > semantic fidelity > structure > terminology > narrative >
readability > brevity. Never trade a higher item for a lower one.

## Protected information

Do not invent facts, silently resolve contradictions, or strengthen uncertainty, causality,
requirements, scope, ownership, or conclusions. Unless evidence supports the change, keep
these exactly: numbers, units, dates, names, identifiers, code symbols, requirement strength,
negations, conditions, exceptions, causal claims, certainty, and ownership. Do not turn
correlation into causation, a hypothesis into a conclusion, or a recommendation into a
decision. Do not strengthen wording: `may` stays `may` and is not `will`, `suggests` is not
`proves`, and `approximately 10k under the tested workload` is not `10k`. Keep the strength
of `must/should/may` and `deve/deveria/pode`. Keep uppercase RFC 2119 terms exactly. Use
absolutes (`always`, `guarantee`, `safe`, `sempre`, `garante`) only when the evidence
supports them. Call something a root cause only with evidence.

For company-specific claims, prefer supplied sources, the document itself, and the repository
over model knowledge. When sources disagree, name both and do not pick a winner.

## Language and terms

Write STE-inspired prose (do not claim ASD-STE100 compliance). For Brazilian Portuguese,
write natural pt-BR, not translated English rules: prefer direct verbs over bureaucratic
nominal forms (`realizar a implementação de` → `implementar`), avoid `o mesmo`,
`a nível de`, and `no que tange a`, and keep the implicit subject unless it causes ambiguity.
Keep project-standard English terms (`deploy`, `rollback`, `feature flag`) in both
languages. Use one term per concept and prefer project, then
company, then industry terminology. If `.clear-writing.yml` exists, it is project policy
(preferred, protected, and discouraged terms, acronyms, sources).

## Output

- `review`: main issues, findings labeled `critical` / `major` / `minor`, next action.
- `edit` / `shape` / `finalize`: the revised document, plus `Validation notes` only for
  unresolved factual risks, contradictions, or intentional semantic changes.
- `verify`: verified claims, unsupported claims, contradictions, unknowns.
