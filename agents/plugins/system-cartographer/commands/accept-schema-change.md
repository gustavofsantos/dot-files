---
description: Review and accept a proposed schema extension — the only sanctioned path that may change the schema.
allowed-tools: Bash, Read, Write, AskUserQuestion
---

You are the human gate on schema evolution. Adding map data is cheap and
reversible; changing the schema's *shape* is high-leverage and semi-permanent,
so it requires an explicit, typed human `yes`. Follow these steps **in order**.
Do not reorder them — the acceptance token must be minted only *after* the user
confirms.

1. **Load the proposal.** Read `.cartographer/.proposed-extension.json` (walk up
   from cwd to find `.cartographer/`). If it is missing, tell the user there is
   no pending proposal — they earn one by running an analysis (`/map-analyze`)
   that the current schema cannot support — and stop.

2. **Present it exactly.** Show the user the `target`, `name`, `shape` (and its
   parameters, e.g. enum values), the `reason`, and which reasoning mode
   triggered it. State plainly that this permanently extends the schema (by
   accretion — existing entries stay valid; the new attribute is optional).

3. **Get an explicit yes** via `AskUserQuestion`: "Apply this schema extension?"
   with options "Yes, apply" and "No, cancel". If the user cancels, delete
   `.cartographer/.proposed-extension.json` and stop. Do not proceed on a vague
   conversational "ok" — require the typed selection.

4. **Mint the token (only after yes).** Run:

   ```
   python3 "${CLAUDE_PLUGIN_ROOT}/scripts/propose_apply.py"
   ```

   This validates the extension against the meta-schema, stages the exact new
   schema to `.cartographer/.staged-schema.json`, and writes the single-use
   acceptance token. If it prints `REJECTED:`, relay why and stop.

5. **Apply it.** Read `.cartographer/.staged-schema.json` and use the `Write`
   tool to write its exact contents to `.cartographer/schema.json`. The
   PreToolUse guard verifies the token against this content and then consumes
   it. (The hash is over the JSON object, not the bytes, so formatting need not
   be byte-identical — but write the staged structure faithfully.) If the write
   is denied, the content did not match what was accepted; re-run step 4.

6. **Record the decision.** Run:

   ```
   python3 "${CLAUDE_PLUGIN_ROOT}/scripts/record_evolution.py"
   ```

   This appends a dated entry (when / why / triggering mode / declaration) to
   `schema-evolution.md` and cleans up the staging files.

7. **Report.** Confirm the new attribute, and remind the user that existing
   entries now have a visible backfill gap (`/map-status`) they can fill over
   time to sharpen analysis.
