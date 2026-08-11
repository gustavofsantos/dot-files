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
or "falsified" when code *ran* and the system *showed* the behavior. Reasoning about the
code is how you form the hypothesis — never how you conclude it.

**Prefer running code over reading it.** Writing the smallest thing that makes the system
answer is faster and cheaper. The alternative is pulling legacy code into context to
reason about, and that cost grows in a large or messy codebase. Read only enough to find where to drive the
behavior. The moment a read turns into reasoning about what *would* happen, stop and make
it happen — write the probe and run it.

## Loop — cheapest evidence first

1. **Frame it falsifiably.** Rewrite the hypothesis as one sentence with a concrete,
   observable outcome: *"Given <input/state>, when <action>, then <measurable result>."*
   If it cannot be phrased this way, say so and stop — it is not empirically testable.

2. **Check memory.** `rg -il 'keyword' "${ENGINEERING_HOME:-$HOME/engineering}/artifacts/"
   2>/dev/null`. If this hypothesis was already settled and nothing about the code or data
   has changed, reuse that verdict — cite the recorded date and result, skip to step 5.

3. **Run the existing test.** A quick `rg` for one that already exercises this path (the
   behavior, the endpoint, the entity). Prefer the outermost end-to-end test. Run the
   narrowest target and read the *actual* output — values, side effects — not what you
   expect. If you do not find one in a couple of searches, do not keep digging — go to 4.

4. **No test observes it? Write and run a probe.** Reach for the fastest executable form
   that drives the real path and prints the observable outcome — a throwaway integration
   test, a script, or a REPL / `-main` snippet. Ground the scenario in real data first: if
   a production/staging store is reachable (DB, warehouse, logs, read-only console),
   **query it read-only** — never write — for the real distributions and edge cases the
   hypothesis must cover. If unreachable, note the assumption you substitute. In a
   GitButler repo, spin the probe on its own virtual branch (via the `gitbutler-provenance`
   skill) — cheap to keep as a running prototype or throw away.

5. **Report the verdict from evidence.**
   - **Confirmed** / **Falsified** — cite the test and the observed result that decided it.
   - **Undetermined** — the observation was inconclusive or unreproducible. Say exactly
     what blocked it. Never upgrade this to a verdict by reasoning.

6. **Record it in the vault.** One verdict is one artifact. Write it to
   `${ENGINEERING_HOME:-$HOME/engineering}/artifacts/<YYYY-MM-DD>-<slug>.md`. Never keep
   the verdict in this skill directory, and never keep it in the repository under test.

   ```markdown
   ---
   kind: hypothesis
   verdict: Confirmed
   created: 2026-07-03
   ---

   # <the falsifiable hypothesis>

   **Verdict** — Confirmed. <one sentence.>

   **Evidence** — <test path + the observed result that decided it.>
   ```

   Link the artifact from the issue that prompted the hypothesis, if one exists.

## Constraints

- One hypothesis, one narrow observation. Do not build a suite or refactor test infra.
- Reading is for finding where to drive, not reconstructing behavior. A run beats a read.
- Do not fix the system here. A falsified hypothesis is a finding — report it and stop.
- One verdict is one artifact. Do not edit an old artifact. If the verdict changes, write
  a new artifact and link the old one.
