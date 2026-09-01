---
name: domain-skill-creator
description: >-
  Create compact private Agent Skills that orient coding agents to a bounded
  legacy business capability before code interpretation. Use when domain
  vocabulary, conceptual models, ownership boundaries, invariants, misleading
  interpretations, and evidence must travel across projects. Do not use for
  general behavioral or technical-method skills.
---

# Domain Skill Creator

Create a portable domain orientation layer: a map legend, not documentation. It
answers what an agent must know about this capability before reading unfamiliar
code. Assume general investigation, coding, testing, and refactoring skills
compose separately.

## Reconstruct the frame

Bound the capability with the user, then inspect repository and supplied
evidence. Treat code names and repository structure as claims, not necessarily
the domain truth. Prefer authoritative domain material and evidence at decision
boundaries: maintained docs or diagrams, schemas, transaction functions, event
definitions, integration tests, reconciliation jobs, queries, and ADRs.

Use this selection rule:

> Encode conclusions that are expensive or unreliable to rediscover. Reference
> evidence that is cheap to retrieve.

Include only content whose absence would make a competent agent reasonably
likely to build the wrong conceptual model:

- essential vocabulary with local or non-obvious meanings.
- the smallest useful model of the capability and its semantic relationships.
- a few stable, high-leverage business or system invariants.
- ownership boundaries: sources of truth, decision owners, orchestrators,
  observers, derived state, compatibility layers, and repair mechanisms.
- plausible but wrong interpretations suggested by names, namespaces, tests,
  duplicated data, or recovery-looking paths.
- a small set of concrete evidence entry points, with why each matters when that
  is not obvious.

Distinguish documented domain facts, verified implementation behavior, and
inference. Verify consequential claims across evidence when possible. Never
promote an inference or current implementation choice into an invariant. Mark
material uncertainty and point to the evidence needed to resolve it, or omit it.

## Keep the skill declarative

Write facts, constraints, semantic relationships, corrections, and navigation.
Exclude generic agent behavior, investigation or testing methods, code-quality
rules, Git workflow, and broad architecture advice. Also exclude call-stack
walkthroughs, exhaustive file lists, history, edge-case catalogs, and facts that
are clear in one obvious source. Do not summarize each section of existing docs.

## Name and package

Name every generated skill `domain-<capability>`. Normalize the capability to
lowercase hyphen-case. The folder and frontmatter name must match. For example,
use `domain-settlement` and `domain-payment-reconciliation`.

Do not add a repository or service name only because the capability spans many
services. If one domain term has distinct meanings, add a stable qualifier to
the capability, as in `domain-ledger-settlement`.

Leave the installation location deliberately unspecified. Do not infer a
user-level, project-level, or harness-specific path. Use a target only when the
caller or active harness provides one. Otherwise, produce a portable skill
folder and leave installation to the caller. If a provided target exists,
inspect it first. Update it only when it represents the same capability.

Make the frontmatter description activation-oriented rather than a compressed
copy of the skill. Describe when the domain knowledge applies across projects,
not only which repository owns its evidence.

Use only sections that earn their context cost. A useful default is:

```markdown
---
name: domain-<capability>
description: <when this domain orientation is relevant>
---

# <Capability>

<one to three sentences establishing the conceptual frame>

## Model
## Invariants
## Important boundaries
## Do not infer
## Start here
```

Omit empty or low-value sections. In `Start here`, use concrete paths, symbols,
namespaces, schemas, queries, or diagrams.

Qualify each entry with its owning repository or service. Prefer a stable
repository identifier plus a repository-relative path or link. Do not assume
that the agent's current project owns the evidence. These entries provide
evidence and navigation. They do not replace domain conclusions that belong in
the skill.

## Final compression pass

Challenge every sentence:

- Is it stable?
- Is it domain semantics rather than an implementation walkthrough?
- Is it hard or risky to rediscover?
- Does it avoid duplicating another skill?
- Would removing it materially increase wrong-model risk?

Delete or replace anything that fails. The finished artifact should normally be
a few hundred words and private by default.
