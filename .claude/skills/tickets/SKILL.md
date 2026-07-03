---
name: tickets
description: >
  Turns context into a well-structured Jira ticket (epic, story, task, or bug)
  following the team's templates.
disable-model-invocation: true
---

# Tickets

Turns context into well-structured Jira tickets following the team's conventions. Read `references/templates.md` before drafting — it has the full template per type (epic, story, task, bug).

## Principles

- **No fabrication** — use only what the user provided. If critical information is missing, ask before drafting.
- **Real content only** — omit empty sections instead of leaving placeholders.
- **Specific titles** — no vague language ("general improvements", "system adjustments"). Always concrete.

---

## Protocol

### 1. Identify the type

If the user didn't specify, infer from context:

| Signal | Likely type |
|---|---|
| "user can't", "it's breaking", "error" | Bug |
| "as a user I want", "feature", "functionality" | Story |
| "refactor", "migrate", "configure", "document" | Task |
| "initiative", "quarter", "large capability" | Epic |

Unsure between story and task: ask whether there is direct value to the end user.

### 2. Collect missing information

Check that critical fields are present before drafting:

| Type | Critical fields |
|---|---|
| Bug | Steps to reproduce + expected vs. actual behavior |
| Story | Who the user is + what the benefit is |
| Task | Why now + what exactly needs to be done |
| Epic | Goal + scope (what's out is as important as what's in) |

If something critical is missing, ask **one direct question** before drafting.

### 3. Draft

Read `references/templates.md` and use the template for the identified type.
Output as a markdown code block for easy copy-paste into Jira.

### 4. Confirm

After drafting, ask: "Want to adjust any field, or is this ready to copy?"
