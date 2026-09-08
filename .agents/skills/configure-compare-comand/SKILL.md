---
name: configure-compare-comand
description: Configure a repository validation command to run at a hooks-compare release boundary. Use only when the user explicitly invokes configure-compare-comand or asks to configure snapshot-based validation through hooks-compare.
disable-model-invocation: true
---

# Configure Compare Command

Configure an existing validation command behind a capture/release hook pair. Do not create
a new validator unless the user asks for one.

1. Run `hooks-compare setup` and inspect the repository's existing agent hook settings.
2. Inspect the validator's input contract. Prove how it reads standard input from its help,
   source, or tests; do not infer from its name.
3. Select exactly one release representation:
   - `--files` for one changed path per line.
   - `--diff` for a unified Git patch.
4. Add paired hook commands for each harness requested by the user:
   - capture: `AGENT=<harness> hooks-compare capture`
   - release: `AGENT=<harness> hooks-compare release <representation> -- <validator>`
5. Preserve unrelated hooks and the native settings shape of each harness.
6. Exercise the pair in a disposable Git worktree: capture, make a representative change,
   release, and verify both the validator input and harness feedback.
7. Report the settings changed, the chosen input shape, and the exact verification command.

If the validator accepts neither newline-delimited paths nor a unified patch on standard
input, stop and explain the incompatibility. Do not introduce an environment-variable or
temporary-file adapter without user approval.
