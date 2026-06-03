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

This skill dispatches the heavy review work to the **`deep-review` subagent**
(defined in `.claude/agents/deep-review.md`). The subagent runs in an
isolated context, reads the diff and the analytical reference files
(simple-design-rules, metz-heuristics, dhh-expressiveness, code-smells,
oop-criteria / fp-criteria), and returns a structured review report.

The dispatch is necessary because Phase 2 references alone are ~400 lines
plus the diff itself — running inline pollutes the main session with content
that's only useful for the review itself.

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
   - **Green / Yellow** → tell the human the issue is ready to ship; the human
     (not the agent) archives the issue by moving it out of the issues
     directory (see the `issue` skill — an issue is active while it lives there).
   - **Red, fixable in scope** → invoke the `design-constraints` skill in
     `refactor` mode and paste the resulting block into the issue's
     `## Context` for a constrained fix pass, then re-run `tdd`.
   - **Red, structural problems beyond scope** → propose tracking it via the
     `issue` skill (a fresh issue with its own scenarios).

## Why a subagent

- Phase 2 loads 5 reference files (~400 lines) — kept out of main context.
- Diff scanning + per-file reads stay isolated in the subagent.
- Multiple files / branches can be reviewed in parallel via concurrent
  Agent calls.
- Subagent runs on `opus` for the high-effort analysis while main can stay
  on a faster model.
