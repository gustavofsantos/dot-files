---
name: smelly-code
description: Steer production code toward code where the business rule is visible and named. Use whenever writing or reviewing production code that carries domain logic (calculations, invariants, state transitions, validation, policy). Trigger even on a bare "implement this" or "clean this up" — the steer is that the rule a domain expert cares about should be readable in one place, in domain words, not reconstructed from control flow. Pairs with smelly-test: smelly-test asserts the promise, smelly-code names it. Skip for pure plumbing (wiring, config, adapters, serialization) with no rule inside.
---

# Smelly Code

You already know how to write code. This skill only redirects the *target*: make the **business rule** the most visible thing in the file, so a domain expert reading it recognizes their own policy — not a sequence of steps that happens to produce the right number.

Apply one filter to every unit of production code: **can I point to the line that *is* the rule?** If the rule only exists as an emergent property of five branches, it isn't named — and it will be duplicated, drifted, and violated.

## The steer

**Name the concept, not the step.** If a rule has a name in the business ("overdrawn", "within return window", "eligible for loyalty tier"), that name must exist in the code as a function, predicate, or type. A `boolean` returned from an inline comparison is a rule the domain never got to name.

**One rule, one home.** Each rule lives in exactly one place. If a threshold, a rate, or a condition appears twice, one of them will be wrong later. The duplication is not a style issue — it's a second, unmaintained copy of the policy.

**Separate deciding from doing.** The rule (pure, testable, nameable) is not the same as the effect (persisting, charging, emailing). When they're braided, the rule can't be read without reading the IO — and can't be tested without mocking it. Functional core, imperative shell: the core decides, the shell obeys.

**Make the illegal state unrepresentable where cheap.** A validation you must remember to call is a rule that will be forgotten. A type or constructor that refuses the bad value is a rule that cannot be.

## Reviewing

Scan for the gap that matters most: a rule the business *has* that the code *doesn't name*. Read the branches, ask "what would a domain expert call this condition?", and check whether that word appears anywhere. If it doesn't, the concept is missing — the code enforces the rule by accident of arrangement, and the next change will break it silently.

For the catalogue of smells with before/after rewrites, see `references/smells.md`.
