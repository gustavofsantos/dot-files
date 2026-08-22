---
name: clear-writing
description: >
  Shape, review, verify, and finalize technical documents in English or Brazilian Portuguese.
  Optimize for factual correctness, semantic fidelity, clear structure, consistent terminology,
  readable prose, and concise presentation. Use for design docs, investigations, incident reports,
  ADRs, proposals, runbooks, technical reports, and similar company documents.
---

# Clear Writing

Use this skill when the user wants help writing, reviewing, reshaping, or validating a technical document.

The objective is:

> Make the document easier to understand without changing its truth, intent, or technical meaning.

## Priority order

Always optimize in this order:

1. Factual correctness
2. Semantic fidelity
3. Clear information structure
4. Correct and consistent terminology
5. Clear narrative
6. Readability
7. Brevity

Never improve a lower-priority property at the expense of a higher-priority property.

## Hard invariants

Do not invent missing facts.

Do not silently resolve contradictions.

Do not strengthen uncertainty, causality, requirements, scope, ownership, or conclusions.

Treat these as protected information unless the evidence explicitly supports a change:

- numbers and units
- percentages and percentage points
- dates and time ranges
- names
- system and component identifiers
- code symbols
- requirements
- negations
- conditions
- exceptions
- causal claims
- certainty and confidence levels
- ownership and responsibility

No evidence -> no new factual claim.

When evidence is insufficient, preserve uncertainty or identify the claim as requiring verification.

## Operating modes

Infer the mode from the request when possible.

### review

Find problems. Do not rewrite the document unless the user asks for examples.

Check:

- factual risks
- semantic ambiguity
- structure
- narrative
- terminology
- readability
- unsupported conclusions
- missing evidence
- contradictions

### edit

Improve local prose while preserving the existing structure.

Use this when the document organization is already acceptable.

### shape

Improve:

- information order
- section structure
- narrative flow
- terminology
- prose

Preserve factual and semantic meaning.

### verify

Audit factual claims against available evidence.

Do not rewrite unrelated prose.

### finalize

Run the complete workflow:

1. identify document purpose, audience, language, and type
2. identify important factual claims and semantic invariants
3. verify claims when evidence is available
4. improve document structure
5. normalize terminology
6. improve prose
7. validate that the rewrite did not change meaning
8. report unresolved factual risks

## Language selection

Detect the document language.

For English, read `references/english.md`.

For Brazilian Portuguese, read `references/portuguese-br.md`.

For mixed-language documents, keep intentional technical terms unchanged and apply the language rules to each prose segment.

This skill is STE-inspired, not ASD-STE100 compliant.

Do not claim ASD-STE100 compliance.

## Document type

Read `references/document-types.md` when the document has substantial structure or when using `shape` or `finalize`.

Infer the closest document type. Do not force a template when the existing document has a deliberate structure that works better.

## Factuality and semantic preservation

Read `references/factuality.md` for `verify`, `shape`, and `finalize`.

When repository files, internal documents, or supplied evidence are available, prefer them over model knowledge for project-specific claims.

Evidence priority:

1. sources explicitly supplied by the user
2. the document being edited
3. source code, configuration, schemas, tests, and data
4. company documentation
5. primary external documentation
6. general model knowledge

Use model knowledge mainly to improve language, explain general concepts, or identify claims that need verification.

Do not use general knowledge to fill gaps in company-specific facts.

If sources disagree:

- surface the contradiction
- identify the conflicting sources
- do not choose a winner without evidence

## Terminology

Read `references/terminology.md` for `shape` and `finalize`.

Prefer, in order:

1. project terminology
2. company terminology
3. industry terminology
4. generic language-profile preferences

Use one term for one concept.

Do not replace an established technical term only to make the prose sound more natural.

If `.clear-writing.yml` exists, treat it as project-specific policy.

## Output behavior

Unless the user asks for another format:

### review

Return:

1. summary of the main issues
2. findings ordered by severity
3. suggested next action

### edit / shape / finalize

Return:

1. the revised document
2. a short `Validation notes` section only when there are unresolved factual risks,
   contradictions, material assumptions, or important semantic changes that require attention

Do not add commentary about trivial wording changes.

### verify

Return:

1. verified claims
2. unsupported or weakly supported claims
3. contradictions
4. unknowns requiring confirmation

## Severity

Use these labels when reviewing:

- `critical`: likely factual error, semantic corruption, unsafe instruction, or unsupported high-impact claim
- `major`: ambiguity, contradiction, missing evidence, misleading structure, or terminology that can change interpretation
- `minor`: readability or consistency problem that does not materially change meaning

## Final validation

Before returning a rewritten document, check that you did not accidentally change:

- values
- units
- dates
- identifiers
- requirement strength
- negation
- conditions
- exceptions
- ownership
- certainty
- correlation into causation
- hypothesis into conclusion
- recommendation into decision

If any such change was intentional, it must be supported by evidence or explicitly called out.
