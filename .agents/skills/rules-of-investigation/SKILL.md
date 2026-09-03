---
name: rules-of-investigation
description: Investigate observed behavior by turning inferences into testable scenarios and gathering new evidence before drawing conclusions
---

# Rules of investigation — infer, execute, observe

Investigations advance through **new observations**, not increasingly convincing explanations of existing evidence.

Use evidence to generate hypotheses and decide what to observe next. Once a hypothesis is testable, execute the smallest useful experiment or reproduction instead of elaborating the explanation.

## Evidence boundary

Keep these distinct:

* **Observed** — directly seen in runtime behavior, logs, metrics, traces, persisted state, or test output.
* **Inferred** — interpretation of observations.
* **Hypothesis** — a possible mechanism consistent with the evidence.
* **Reproduced** — the mechanism produced the expected behavior under tested conditions.
* **Historical conclusion** — evidence connects that mechanism to the incident being investigated.

Never silently promote one category into another.

Code establishes what **can** happen, not what **did** happen.

Correlation establishes a lead, not causation.

Reproduction establishes that a mechanism **can produce** the behavior, not that it **caused the historical incident**.

## Investigation loop

Repeat:

1. Gather observations.
2. Infer what they constrain or leave unknown.
3. Generate competing hypotheses.
4. Derive observations that would distinguish them.
5. Instrument and execute the smallest useful test.
6. Record what actually happened.
7. Reject, retain, or refine hypotheses from the new evidence.

The purpose of a hypothesis is to determine **what to execute and observe next**.

Prefer tests that discriminate between hypotheses over tests that merely support the favored one.

## Reconstruct scenarios, not stories

When evidence suggests something might have happened:

* describe it as a candidate scenario;
* identify the conditions it requires;
* reconstruct those conditions when practical;
* execute the relevant path;
* compare the resulting behavior with the original evidence.

Do not fill gaps in historical evidence with plausible runtime events.

If a reproduced mechanism lacks evidence tying it to the original incident, report it as **reproduced but historically unproven**.

## Stop at the evidence boundary

A valid investigation may end unresolved.

When the evidence cannot distinguish remaining explanations, preserve the uncertainty and identify the next observation that could.

Do not choose a conclusion merely because it forms the most coherent story.

## Avoid

* Treating inference or model plausibility as observation.
* Staying in analysis after a useful test can be executed.
* Testing only the first plausible explanation.
* Adjusting a hypothesis to ignore disconfirming results.
* Inferring historical execution from code structure.
* Turning correlation into causation.
* Treating reproduction as proof of historical occurrence.
* Declaring root cause without evidence that crosses the historical boundary.
