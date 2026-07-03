---
name: hypothesize
description: >
  Confirm or falsify a stated hypothesis about how the system behaves — cheaply, with
  empirical evidence from the application's own tests (integration tests first). Trigger
  when the user proposes a claim to check: "I think X happens when Y", "does the system
  do Z?", "verify that…", "my hypothesis is…", "is it true that…", "confirm/falsify…",
  or any assertion about runtime behavior that can be settled by observation rather than
  reasoning. If no existing test observes the behavior, write a throwaway one that does.
---

# hypothesize

Settle a hypothesis by **observation, not argument**. A hypothesis is only "confirmed"
or "falsified" when a test *ran* and the system *showed* the behavior. Reasoning about
the code is how you form the hypothesis — never how you conclude it.

## Loop — cheapest evidence first

1. **Frame it falsifiably.** Rewrite the hypothesis as one sentence with a concrete,
   observable outcome: *"Given <input/state>, when <action>, then <measurable result>."*
   If it can't be phrased this way, say so and stop — it isn't empirically testable.

2. **Check memory.** `rg -i 'keyword' ~/engineering/hypotheses.md 2>/dev/null`. If this
   hypothesis was already settled and nothing about the code or data has changed, reuse
   that verdict — cite the recorded date and result, skip to step 5.

3. **Run the existing test.** Search the integration tests for one that already exercises
   this path (`rg` the behavior, the endpoint, the entity); prefer the outermost
   end-to-end test over unit tests. Run the narrowest target and read the *actual* output
   — pass/fail, values, side effects — not what you expect.

4. **No test observes it? Build a probe.** First ground the scenario in real data: if a
   production/staging store is reachable (DB, warehouse, logs, read-only console),
   **query it read-only** — never write — for the real distributions, edge cases, and
   states the hypothesis must cover; if unreachable, note the assumption you substitute.
   Then add a minimal, clearly throwaway integration test that drives the real path under
   that scenario, and run it.

5. **Report the verdict from evidence.**
   - **Confirmed** / **Falsified** — cite the test and the observed result that decided it.
   - **Undetermined** — the observation was inconclusive or unreproducible; say exactly
     what blocked it. Never upgrade this to a verdict by reasoning.

6. **Record it.** Append one row to `~/engineering/hypotheses.md`, creating the file from
   this skeleton if missing:

   ```markdown
   # Hypotheses tested

   Empirical verdicts from the `hypothesize` skill — Claude's caching memory.

   | Date | Hypothesis | Verdict | Evidence |
   |------|------------|---------|----------|
   | 2026-07-03 | <the falsifiable hypothesis> | Confirmed | <test path + observed result> |
   ```

## Constraints

- One hypothesis, one narrow observation. Don't build a suite or refactor test infra.
- Don't fix the system here. A falsified hypothesis is a finding — report it and stop.
- The memory file is a flat append log: one row per verdict, never reorganized.
