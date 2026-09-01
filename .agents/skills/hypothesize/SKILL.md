---
name: hypothesize
description: >
  Confirm or falsify one stated runtime-behavior claim with executable evidence. Use for an
  explicit hypothesis check, not for open-ended debugging or a historical root-cause claim.
---

# Hypothesize

Settle one claim by observation. Code reading can shape the probe, but it cannot decide the
verdict.

## Loop

1. Rewrite the claim as `Given <state>, when <action>, then <observable result>`.
   If no executable observation could falsify it, return `Undetermined` and explain why.
2. Find the narrowest existing test or executable path that observes the result. Run it and
   inspect the actual output and side effects.
3. If no existing check observes the claim, write the smallest throwaway test, script, or
   REPL probe that drives the real path. Use read-only production-shaped data when access is
   safe and authorized. Otherwise state the substitute assumptions.
4. Return one verdict to the caller:
   - `Confirmed`: the observation matched the claim.
   - `Falsified`: the observation contradicted the claim.
   - `Undetermined`: the observation or environment could not decide it.
5. Cite the command or probe and the result that decided the verdict. Remove throwaway work.

Reproducing a mechanism proves that it can cause the observed behavior under the tested
conditions. It does not prove that the mechanism caused a past incident. A historical claim
needs evidence that connects the reproduction to that incident.

Do not fix the system, build a lasting suite, or create a durable artifact by default. Hand
the question to `spike` when it needs independent exploration or when the answer must outlive
the current task.
