# Fact Template

```markdown
---
id: "FACT-{id}"
subject: "{subject}"
created: {today}
updated: {today}
provenance:
  - repo: "{repo-name}"
    path: "{relative-path}"
    revision: "{git-commit-sha}"
---

## Statement
One or two sentences. What is true. Present tense, falsifiable.

## Evidence
Where this is grounded — `file:line`, commit hash, doc link, or `observed {date}`.

## Issues
Issues that rely on or established this fact:
- {issue-id} — {short reason}
```

## Field notes

**id** — `FACT-NNN`, allocated by the fact skill. The file is named `NNN-<slug>.md`;
the canonical reference is `FACT-NNN`, written inline as `[[FACT-NNN-slug]]`. That is
the exact form `survey` and `dead-reckoning` use for axioms and depends-on links, so
their wiki links resolve to real facts.

**Statement** — must be checkable. If it can't be sourced in `## Evidence`, it isn't a
fact yet — keep it as an `## Open questions` entry on an issue instead.

**Issues** — the back-link. Every issue listed here must list this fact in its own
`## Facts` section. Update both sides together (see the fact skill, Step 5).

**A fact is durable.** Unlike an issue, it is not archived when work completes — it
stays as long as it remains true. When it stops being true, update or delete it.
