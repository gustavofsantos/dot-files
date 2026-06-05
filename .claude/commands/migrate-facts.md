# migrate-facts

Migrates `~/engineering/facts/` files into root-level Zettelkasten notes at `~/engineering/`.

The old format had structured frontmatter (`id:`, `subject:`, `## Statement`, `## Evidence`, `## Issues`).
The new format is plain prose: first sentence is the claim, body is the context, ending with `[[wikilinks]]`
and optionally `parent: [[note]]` for Folgezettel continuation.

## Step 1 — Inventory

List all files in `~/engineering/facts/`:

```bash
find ~/engineering/facts -name "*.md" | sort
```

For each file, read it and show a preview:
- The `subject:` frontmatter field (becomes the slug)
- The `## Statement` section (becomes the first sentence of the note)
- The `## Evidence` section (becomes inline context)
- Any `refs:` or `## Issues` links (become `[[wikilinks]]` at the end)

Present the full inventory before migrating anything.

## Step 2 — Confirm before proceeding

Ask: "Ready to migrate these N facts? I'll convert each to a root note and leave
the originals in place until you delete facts/ manually."

Do not migrate without explicit confirmation.

## Step 3 — Convert each fact

For each fact file, produce a root note at `~/engineering/<slug>.md`:

**Slug derivation:** use the `subject:` frontmatter field, lowercase, hyphenated.
If a file with that slug already exists at root, skip and warn.

**Body construction:**
1. First line: the `## Statement` content verbatim (1–2 sentences, present tense)
2. Blank line
3. Evidence inline: fold the `## Evidence` content into a second paragraph, prefixed
   with the source if it's a URL or file ref. Omit if the evidence is trivial or
   already implied by the statement.
4. Blank line (if notes or context follow)
5. Any `## Notes` content as a closing sentence (optional)
6. Blank line
7. Wikilinks: convert `## Issues` entries to `[[issue-NNN]]` links (slug = `issue-NNN`),
   and any `refs:` spike/issue paths to slug-form wikilinks.
8. No `parent:` line — leave Folgezettel structure for the user to add manually.

**Example conversion:**

Input `facts/001-gemini-hook-base-payload-no-model.md`:
```
id: FACT-001
subject: "Gemini CLI hook base payload has no top-level model field"
## Statement
The Gemini CLI hook base payload delivers exactly five fields...
## Evidence
Gemini CLI Hooks Reference — ...
## Notes
Model must be inferred from the JSONL transcript after the fact.
```

Output `gemini-cli-hook-base-payload-has-no-top-level-model-field.md`:
```
The Gemini CLI hook base payload delivers exactly five fields to every hook handler:
session_id, transcript_path, cwd, hook_event_name, and timestamp. None of the
session-lifecycle hooks add a top-level model field. Any code reading payload.model
will receive undefined.

Model must be inferred from the JSONL transcript after the fact.

source: https://geminicli.com/docs/hooks/reference/
[[gemini-hooks]] [[session-transcript]]
```

## Step 4 — Report

After migrating, report:
- N notes written to `~/engineering/`
- Any skipped (slug collision or empty statement)
- Reminder: `~/engineering/facts/` still exists — delete it manually once you've
  verified the migrated notes look right. Run `kb-index` to refresh INDEX.md.
