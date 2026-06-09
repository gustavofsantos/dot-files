# Test Philosophy

- **Integration-first.** Start from the outermost test that exercises a real end-to-end path. Add unit tests only when a component is complex enough to warrant isolated verification.
- **BDD structure.** Given → When → Then. The test name alone should say what behavior broke.
- **One behavior per test.** No conditionals, loops, or helpers that obscure what's verified. Never test private methods.
- **Friction = redesign signal.** Hard to instantiate → too many dependencies. Many mocks → high coupling. Setup longer than assertion → wrong responsibility. Stop and redesign; don't push through.
