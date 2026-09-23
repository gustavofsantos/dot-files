---
name: rules-of-investigation
description: Investigate observed behavior, or settle one runtime claim, by gathering new executable evidence before drawing conclusions.
---

# Rules of Investigation

Advance by new observations, not by better explanations of old evidence. Once a hypothesis is
testable, run the smallest discriminating experiment instead of elaborating it. Test the
competing explanations, not only the favorite one.

Keep these categories distinct, and never promote one silently:

- observed
- inferred
- hypothesis
- reproduced
- historical conclusion

Code shows what *can* happen, not what *did* happen. Correlation is a lead. A reproduction
shows that a mechanism can produce the behavior. Only evidence that connects it to the
incident makes it the cause. Otherwise, report it as "reproduced but historically unproven".
An investigation may end unresolved. In that case, name the next observation that would decide
it.

**Single claim.** To check one stated claim, restate it as
`Given <state>, when <action>, then <observable>`. Run the narrowest existing check, or a
throwaway probe on the real path. Return `Confirmed`, `Falsified`, or `Undetermined`, and cite
the command and output. Remove the throwaway work. If the answer must outlive the task, hand it
to `spike`.
