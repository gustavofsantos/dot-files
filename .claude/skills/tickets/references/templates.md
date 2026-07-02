# Ticket templates

## Epic

> Large body of work spanning multiple sprints and stories.

```
Title: [Capability/Outcome]: [short description]

## Goal
We need to [achieve outcome] so that [business/user reason].

Context: [what motivated this epic; links to strategy docs or OKRs]

## Scope

IN scope:
- [capability 1]
- [capability 2]

OUT of scope (explicitly):
- [excluded item 1] — [reason]
- [excluded item 2] — [reason]

## Success criteria
- [measurable outcome 1]
- [measurable outcome 2]
- All child stories delivered and accepted
- Observability in place (metrics, logs, alerts)

## Dependencies and risks
Dependencies: [teams, systems, APIs, third parties]
Risks: [known technical/business risks and mitigation]
```

---

## User story

> Deliverable slice of user value, fits in one sprint.

```
Title: As a [user role], I want to [action] so that [benefit]

## Context
[Additional context, user research, screenshots, links to Figma/designs]

Parent epic: [PROJ-XXX]

## Acceptance criteria

Given [precondition]
When [action]
Then [observable outcome]

Given [precondition]
When [action]
Then [observable outcome]

Edge cases / error states:
- [error scenario and expected behavior]

## Definition of done
- Code reviewed and merged
- Unit and integration tests passing
- Acceptance criteria verified by PO
- Documentation updated (if applicable)
- Feature flag / rollout plan defined (if applicable)
```

---

## Task

> Technical or operational work — no direct user value on its own.

```
Title: [Verb] [object]: [short description]

## Why
[reason — technical debt, enabler for story X, prerequisite for Y]

Related story/epic: [PROJ-XXX]

## What / How
1. [step or subtask]
2. [step or subtask]
3. [step or subtask]

Technical notes / constraints:
- [relevant context, decisions, links to ADRs]

## Definition of done
- [specific deliverable or outcome]
- Code reviewed and merged
- No regressions in related tests
```

---

## Bug

> Unintended behavior that deviates from expected or specified behavior.

```
Title: [Component/Area]: [what happens] instead of [expected]

## Steps to reproduce
1. [precondition / setup]
2. [action]
3. [action]
4. Observed: [what actually happens]

Expected: [what should happen]
Actual: [what does happen]

## Impact
Who is affected: [all users / logged-in users / specific role / % of traffic]
Frequency: [always / intermittent — approximate rate]
Business impact: [data loss / revenue / UX degradation / none]
Workaround available: [yes — describe / no]

## Evidence
- Error message / stack trace: [paste or link]
- Log link: [Datadog / Sentry / CloudWatch]
- Screenshot / recording: [link]
- Affected environment: [production / staging / both]
- First seen: [date or deploy SHA]

## Definition of done
- Root cause identified and documented
- Fix merged and deployed to affected environments
- Regression test added
- Incident report filed (if severity >= S2)
```
