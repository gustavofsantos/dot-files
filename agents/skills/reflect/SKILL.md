---
name: reflect
description: Analyzes thread history for agent mistakes (failed commands, schema misunderstandings, user confusion) and records each learning where it belongs — a mechanical one in the repository CLAUDE.md, a contextual one in the knowledge vault through the project skill — to prevent future failures.
---

# Reflect

Review the current thread to identify agent failures and update project documentation to prevent them.

## When to Use

- After completing a task with stumbles
- When the user says "reflect" or asks to learn from mistakes
- Periodically to improve project-specific guidance

## Steps

1. **Analyze Thread History** - Review the conversation for:
   - Failed shell commands (non-zero exit codes, errors)
   - Schema/structure misunderstandings (wrong column names, missing fields, incorrect associations)
   - Misinterpreted user intent (doing the wrong thing, needing clarification)
   - Incorrect assumptions about the codebase (wrong file locations, missing dependencies, outdated patterns)

2. **Extract Learnings** - For each failure, identify:
   - What went wrong
   - What the correct approach was
   - A concise rule or hint that would prevent it

3. **Sort each learning by kind** - A learning is mechanical or contextual. The kind names
   the destination. Never keep a learning in this skill directory.

   | Kind | Example | Destination |
   |---|---|---|
   | Mechanical - how to drive this repository | "Use `bundle exec rspec`, not `rspec`" | The repository `CLAUDE.md` |
   | Contextual - how the system or the domain works | "A settlement row is one payout, not one order" | The vault, through the `project` skill |

4. **Write it** - Add each mechanical learning to `CLAUDE.md`, creating the file if it does
   not exist. For each contextual learning, invoke the `project` skill, which owns the brief
   in `${ENGINEERING_HOME:-$HOME/engineering}/projects/`. Do not write the brief yourself.
   - Write concise, actionable guidance (not verbose explanations - use ASD-STE100 Simplified Technical English)
   - Avoid duplicating information already in the file

## Output Format

After updating, summarize:
- Number of issues found
- What was added
- Any issues that couldn't be captured as guidance

## Guidelines

- Be selective: only add learnings that will genuinely help future sessions
- Keep entries concise: one line per learning when possible
- Use specific examples: "Use `bundle exec rspec` not `rspec`" beats "run tests correctly"
- Don't add obvious things the agent should already know
