---
name: ticket
description: >
  Write a minimal ticket for an external tracker (Jira, Linear, GitHub Issues, or similar):
  a short context preamble plus an "Acceptance Criteria" list. Only when the user asks for
  a ticket to post somewhere, not for vault issues (that is the `issue` skill).
---

# ticket

A ticket tells a reader who was not in this session what must become true, and nothing
more. It has a title, a preamble, and an Acceptance Criteria list. No other sections.

## Steps

1. Take the problem from the conversation. Ask only for what you cannot infer, such as
   the target tracker or the scope when the session covered several things.
2. Write the ticket in the shape below.
3. Check each rule under "Rules". Cut anything that fails.
4. Show the ticket and wait. Post it only when the user tells you to, and only to the
   tracker they name.

## Shape

```markdown
# <Title>

<Preamble>

## Acceptance Criteria

- <Criterion>
- <Criterion>
```

- **Title**: at most 70 characters. Name the outcome, not the mechanism. No trailing period.
- **Preamble**: 1–3 sentences. What exists now, why it is a problem, and for whom. Do not
  describe the solution, the plan, or the history of the session.
- **Acceptance Criteria**: 2–6 bullets. Each bullet is one statement that holds true when
  the work is done.

## Rules

- **Each criterion is checkable.** A reviewer can say yes or no to it by looking at the
  system. "Is fast" fails; "The export of 10k rows completes in under 5 s" holds.
- **Each criterion states an outcome, not a task.** "The retry count is configurable per
  tenant", not "Add a config flag for retries".
- **One fact per criterion.** Split a bullet that contains "and" over two outcomes.
- **No implementation detail** unless it is a hard constraint the reader must keep (an
  API contract, a compliance rule). Then say why in a few words.
- **Include the edge that matters.** If the obvious path already works, the criterion is
  the edge case, error path, or limit that does not.
- **Nothing local-only.** No filesystem paths, `[[wikilinks]]`, local issue ids, session
  jargon, or code symbols a reader of the tracker cannot resolve. Public URLs and other
  ticket keys are fine.
- **Tracker format.** Default to Markdown. If the target tracker needs another markup
  (Jira wiki markup, for example), convert the same content; do not add sections.

## Example

```markdown
# Failed webhook deliveries are retried after a timeout

Webhook deliveries that time out are marked as failed and never retried. Partners miss
events and must ask support to replay them by hand.

## Acceptance Criteria

- A delivery that times out is retried up to 5 times with exponential backoff.
- A delivery that receives a 4xx response is not retried.
- After the last failed attempt, the delivery shows as "failed" in the partner dashboard.
- A retried delivery carries the same event id as the first attempt.
```
