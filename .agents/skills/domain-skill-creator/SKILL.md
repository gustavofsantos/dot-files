---
name: domain-skill-creator
description: Create a compact private skill that orients coding agents to one bounded legacy business capability across projects. Not for behavioral or technical-method skills.
disable-model-invocation: true
---

# Domain Skill Creator

Build a map legend, not documentation. Include only what a competent agent would likely get
wrong without it:

- local vocabulary
- the smallest conceptual model
- a few stable invariants
- ownership boundaries: source of truth, decision owner, derived state, repair paths
- plausible but wrong interpretations
- a few evidence entry points

Encode conclusions that are expensive to rediscover. Link evidence that is cheap to fetch.

Bound the capability with the user. Treat code names as claims. Prefer authoritative evidence
at decision boundaries: schemas, transaction functions, events, integration tests, ADRs. Keep
documented fact, verified behavior, and inference distinct. Never promote an inference to an
invariant. Leave out method, workflow, walkthroughs, history, and exhaustive file lists.

Conventions:

- Name it `domain-<capability>` in lowercase hyphen-case, with a matching folder. Add a
  qualifier only to split one term with two meanings (`domain-ledger-settlement`).
- Install it only at a target the caller gives. Otherwise, produce a portable folder.
- Write the description to activate the skill across projects.
- Sections, each only if it earns its place: frame (1–3 sentences), `Model`, `Invariants`,
  `Important boundaries`, `Do not infer`, `Start here`. Qualify each `Start here` entry with
  its repository and a repository-relative path.
- Aim for a few hundred words.
