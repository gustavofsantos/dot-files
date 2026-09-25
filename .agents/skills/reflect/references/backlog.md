# Backlog input

`scripts/sessions.sh` keeps the set of analyzed sessions in
`${XDG_STATE_HOME:-~/.local/state}/reflect/analyzed.tsv`. A session is pending when it is
on disk but not in the set, or when its transcript grew since it was recorded; then only
the new lines are read.

1. Digest a batch:

   ```bash
   bash scripts/sessions.sh digest --limit 20
   ```

   It prints the digest directory, counts, and one file per session with its size. Each
   file names the session's repository and holds user prompts, assistant prose, and failed
   tool calls. Scratch, trivial, and earlier reflect sessions are recorded without a digest.

2. If nothing was digested and nothing is pending, report that and stop without a checklist.

3. Read the digests. When they total more than about 150 KB, use a subagent per chunk of
   files, each returning candidate lessons with a quoted user line as evidence. Merge
   candidates across sessions before routing: the same lesson from several sessions is one
   item with several evidence sources.

4. Return to `SKILL.md` for routing, the checklist, and applying.

5. After the checklist is resolved — even when every item was dropped — record the batch:

   ```bash
   bash scripts/sessions.sh commit <digest-dir>
   ```

   If the user leaves without resolving the checklist, do not commit. The batch stays
   pending for the next run.

6. If the digest reported sessions still pending, offer another batch.

The current session is skipped automatically because it runs this script. Run the backlog
from a fresh session, so the work of a long session is not skipped with it.

To start from now, ignoring older sessions, run `sessions.sh seed` once. Only do so when
the user asks.
