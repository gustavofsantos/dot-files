---
name: rules-of-testing
description: Steer test level and strategy toward integration-first evidence, focused isolation, and design feedback from test friction.
disable-model-invocation: true
---

# Testing

- **Integration-first.** Start from the outermost test that exercises a real end-to-end path. Add unit tests only when a component is complex enough to warrant isolated verification.
- **Focused isolation.** Use unit tests for complex local logic or failure localization,
  not as a default substitute for an observable path. Test public behavior rather than
  private methods.
- **Friction is design feedback.** Difficult construction, excessive mocks, or dominant
  setup can reveal coupling or a misplaced responsibility. Reconsider the production
  boundary before adding more test machinery.
