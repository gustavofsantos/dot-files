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

## Loop

1. **State it falsifiably.** Rewrite the hypothesis as one sentence with a concrete,
   observable outcome: *"Given <input/state>, when <action>, then <measurable result>."*
   If it can't be phrased this way, say so and stop — it isn't empirically testable.

2. **Ground the scenario in real data.** Before inventing inputs, look for the real
   shape. If a production/staging data store is reachable (DB, warehouse, logs, API,
   read-only console), **query it read-only** to learn the actual distributions, edge
   cases, and states the hypothesis must cover. Build the scenario from what exists, not
   what you imagine. No write access, ever — observation only. If unreachable, note the
   assumption you're substituting.

3. **Look for existing evidence first — cheapest wins.** Search the integration tests
   for one that already exercises this path (`rg` the behavior, the endpoint, the
   entity). Prefer the outermost test that drives a real end-to-end path over unit
   tests. If one exists, run just it and read what it asserts.

4. **Run it.** Execute the narrowest test target that observes the behavior. Read the
   actual output — pass/fail, values, side effects — not what you expect it to be.

5. **If nothing observes it, write a probe.** Add a temporary integration test whose
   only job is to *watch the system as a whole* under the hypothesis scenario — mirror
   the existing integration-test setup, drive the real path, assert the observable
   outcome. Keep it minimal and clearly throwaway. Run it.

6. **Report the verdict from evidence.**
   - **Confirmed** / **Falsified** — cite the test and the observed result that decided it.
   - **Undetermined** — the observation was inconclusive or the scenario couldn't be
     reproduced; say exactly what blocked it. Never upgrade this to a verdict by reasoning.

## Keep it low-effort

- One hypothesis, one narrow observation. Don't build a suite; don't refactor test infra.
- Reach for the existing integration harness before writing anything new.
- A probe test is disposable — offer to delete it (or keep it) once the verdict is in.
- Don't fix the system here. A falsified hypothesis is a finding; report it and stop.
