---
name: reflect
description: Review the current thread for reusable agent mistakes and record only the durable lessons in their existing owners.
disable-model-invocation: true
---

# Reflect

Use only when the user asks to reflect on the current thread.

Find mistakes such as failed commands, wrong repository assumptions, schema errors, or a
misread request. Keep only lessons that would prevent a likely repeat.

Route each lesson:

- Put a repository-driving fact, such as the correct check command, in that repository's
  `CLAUDE.md`.
- Return stable project or domain context to the `project` skill. Do not edit the project
  brief directly.
- Do not record generic advice or facts already present at the destination.

Preserve unrelated text. Report what changed and any lesson that lacked a valid owner.
