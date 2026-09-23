---
name: smelly-spec
description: Review a natural-language change specification as a contract and expose where it fails to constrain implementation.
disable-model-invocation: true
---

# Smelly Spec

Read the spec as a contract. Find the places where an implementer could satisfy every word
and still build the wrong thing. Look for:

- postconditions that nothing can check ("gracefully", "as needed")
- unstated or unreachable preconditions
- invariants that no change owns
- mechanism where outcome belongs
- load-bearing domain terms that are never defined
- rules with no example
- one spec that does several things

Calibration is the discipline. Tag each finding by reach:

- **In-document**: visible in the text. State it plainly.
- **Needs-context**: depends on the system or the domain. Ask it as a question.
- **Out-of-reach**: cannot be assessed from here. Name it and stop.

Never dress a guess as an in-document finding. Lead with in-document findings. For each, quote
the smallest span and give the concrete tightening. Do not pad. If the spec is tight, say so
and name the one thing you would still pin down.
