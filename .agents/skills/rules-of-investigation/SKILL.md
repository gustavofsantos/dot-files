---
name: rules-of-investigation
description: Investigate observed behavior, or settle one runtime claim, by gathering new executable evidence before drawing conclusions.
---

# Rules of Investigation

Advance by new observations, not by better explanations of old evidence. Once a hypothesis is testable, run the smallest discriminating experiment instead of elaborating it. Test the competing explanations, not only the favorite one.

Keep these categories distinct, and never promote one silently:

- observed
- inferred
- hypothesis
- reproduced
- historical conclusion

Code shows what *can* happen, not what *did* happen. Correlation is a lead. A reproduction shows that a mechanism can produce the behavior. Only evidence that connects it to the incident makes it the cause. Otherwise, report it as "reproduced but historically unproven". An investigation may end unresolved. In that case, name the next observation that would decide it.

**Competing hypotheses.** Before reading code or logs in depth, write down every plausible cause and, for each, one observation that would falsify it. Run those experiments together, not one after another. Ask workers for an executable reproduction or a decisive log query in the first brief, not after a code-reading round.

**Test the code that ran.** Pin the commit, build, and flag values that were live when the behavior happened. Code from the current branch can hide the defect or the loop. For each finding, name the version you checked.

**Start from what is known.** Before reading code or logs in depth, read what is available on the area: the project brief, `workflows/`, `spikes/`, and the repository's docs. Record what they say as a claim, `documented` or `inferred`, never as `observed`. A document older than the code may be stale, so observe it again.

**Single claim.** To check one stated claim, restate it as `Given <state>, when <action>, then <observable>`. Run the narrowest existing check, or a throwaway probe on the real path. Return `Confirmed`, `Falsified`, or `Undetermined`, and cite the command and output. Remove the throwaway work. If the answer must outlive the task, hand it to `spike`.
