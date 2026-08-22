---
name: rules-of-testing
description: Steer test structure toward integration-first sequencing, BDD Given/When/Then naming, one behavior per test, and treating test friction (hard to instantiate, heavy mocking, long setup) as a signal to redesign production code rather than push through. Use whenever writing or reviewing a test file, choosing between an integration and a unit test, or noticing a test is hard to write. Pairs with `smelly-test` for how to name the test as a business promise.
---

# Testing

- **Integration-first.** Start from the outermost test that exercises a real end-to-end path. Add unit tests only when a component is complex enough to warrant isolated verification.
- **BDD structure.** Given → When → Then. The test name alone should say what behavior broke.
- **One behavior per test.** No conditionals, loops, or helpers that obscure what is verified. Never test private methods.
- **Friction = redesign signal.** Hard to instantiate → too many dependencies. Many mocks → high coupling. Setup longer than assertion → wrong responsibility. Stop and redesign. Do not push through.

For naming tests as business promises rather than method mirrors, invoke `smelly-test`.
