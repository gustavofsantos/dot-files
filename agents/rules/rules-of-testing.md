---
claude:
  paths:
    - "**/*test.{clj,kt,kts,java,py,ts,js,go,rb}"
    - "**/*IT.{kt,java}"
    - "**/*Test.{kt,java}"
cursor:
  globs: "**/*test.{clj,kt,kts,java,py,ts,js,go,rb},**/*IT.{kt,java},**/*Test.{kt,java}"
---

# Testing

- **Integration-first.** Start from the outermost test that exercises a real end-to-end path. Add unit tests only when a component is complex enough to warrant isolated verification.
- **BDD structure.** Given → When → Then. The test name alone should say what behavior broke.
- **One behavior per test.** No conditionals, loops, or helpers that obscure what is verified. Never test private methods.
- **Friction = redesign signal.** Hard to instantiate → too many dependencies. Many mocks → high coupling. Setup longer than assertion → wrong responsibility. Stop and redesign. Do not push through.

For naming tests as business promises rather than method mirrors, invoke `smelly-test`.
