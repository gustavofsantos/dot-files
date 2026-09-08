---
name: way-of-work
description: Sequence one approved behavior slice from a failing acceptance test through red-green implementation and a behavior commit.
---

# Way of Work

Own sequencing for one approved slice. Do not choose architecture or load code-quality steers on the user's behalf.

1. Take one approved slice from `way-of-planning`, or one direct behavior change that does not need slicing.
2. Write an acceptance test for the observable behavior. Run it and confirm that it fails for the expected reason before changing production code.
3. If the approved workflow calls for an acceptance checkpoint, show the test and its asserted behavior to the user. Wait for approval and apply requested changes.
4. Drive a red-green loop within the approved intent. Add the smallest failing implementation-facing test needed for the next step and make it pass. If the next step requires new intent or changes the agreed approach, return control to the user.
5. When the acceptance test and relevant checks pass, commit the behavior change.
6. Stop after the requested slice. Structural refactoring is optional and starts only after the behavior commit. If the user selected `rules-of-refactoring`, hand off to it for a separate behavior-preserving commit.

Do not start another slice, expand the feature, or mix structural cleanup into the behavior commit.
