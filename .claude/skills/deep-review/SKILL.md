---
name: deep-review
description: >
  Two-phase code review: Phase 1 scope and safety (test confidence, scope discipline, risk
  signal), Phase 2 architectural depth on the core changed logic. Works on a branch diff,
  a single file, or a usage pattern.
metadata:
  effort: high
  argument-hint: "[target]"
  allowed-tools: Read Bash(rg:*) Bash(fd:*) Bash(git:*) Bash(cat:*)
---

# Deep Review — dispatch shim

Dispatches the heavy review to the **`deep-review` subagent** (`.claude/agents/deep-review.md`), which runs in isolation on `opus`, reads the diff plus the analytical references (simple-design-rules, metz-heuristics, dhh-expressiveness, code-smells, oop/fp-criteria), and returns a structured report. Keeping the references and per-file reads out of the main session is the whole point; concurrent Agent calls can review multiple targets in parallel.

## When triggered

1. **Identify the target** from `$ARGUMENTS` or recent conversation:
   - branch range (e.g., `main..HEAD`, `origin/main...feature/x`)
   - single file path
   - inline pattern provided by the user
   If the target is genuinely ambiguous, ask one short question first.

2. **Dispatch via the Agent tool:**
   ```
   Agent(
     subagent_type: "deep-review",
     description: "Deep review of <target>",
     prompt: <see template below>
   )
   ```

   Prompt template:
   > "Run the two-phase deep review protocol on the following target:
   > **<target>**.
   >
   > Reference files live in the `deep-review` skill's `references/`
   > directory. Locate them with `fd simple-design-rules.md ~/.claude`
   > (or `fd simple-design-rules.md` from the repo root) and read them
   > from that directory.
   >
   > [Any extra context the human gave, e.g. 'focus on the auth flow' or
   > 'I'm worried about edge case X' — pass through verbatim.]
   >
   > Return only the structured review report."

3. **Surface the subagent's report** to the human verbatim.

4. **Act on the chain pointer** in the report's summary:
   - **Green / Yellow** → ready to ship; the human (not the agent) archives the issue by moving it out of the issues directory (`vault` — an issue is active while it lives there).
   - **Red, fixable in scope** → run `design-constraints` in `refactor` mode, paste the block into the issue's `## Context`, then re-run `tdd`.
   - **Red, structural problems beyond scope** → propose a fresh tracked issue via `vault`.
