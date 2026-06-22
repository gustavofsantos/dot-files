#!/usr/bin/env python3
"""Append an accepted schema extension to the evolution log.

Run by /accept-schema-change AFTER schema.json has been successfully written
(the guard consumed the token). Reads `.accept-context.json` (which survives
token consumption), appends a dated decision entry to schema-evolution.md, and
cleans up the staging files. The log records WHEN, WHY, and WHICH reasoning
mode triggered the change — it is a decision record, not a changelog.
"""
import datetime
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _lib as L


def main():
    cdir = L.require_dir()
    ctx_path = L.path(cdir, L.ACCEPT_CONTEXT_FILE)
    if not os.path.exists(ctx_path):
        raise SystemExit("No .accept-context.json — nothing to record. "
                         "Did the schema write succeed first?")
    ctx = L.load_json(ctx_path)

    # Sanity: the attribute should now actually be in the active schema.
    schema = L.load_json(L.path(cdir, L.SCHEMA_FILE))
    decl = ctx["declaration"]
    if decl["name"] not in schema.get(decl["target"], {}).get("attributes", {}):
        raise SystemExit(
            f"{decl['target']}.{decl['name']} is not present in schema.json — the "
            "protected write did not complete. Not recording. Re-run "
            "/accept-schema-change.")

    ts = datetime.datetime.now().astimezone().isoformat(timespec="seconds")
    decl_json = json.dumps(decl, indent=2, ensure_ascii=False)
    entry = (
        f"\n## {ts} — {decl['target']}.{decl['name']} "
        f"({decl.get('shape')})\n\n"
        f"- **Triggered by:** {ctx.get('triggered_by') or 'unspecified'} reasoning\n"
        f"- **Why:** {ctx.get('reason') or 'unspecified'}\n"
        f"- **Declaration:**\n\n"
        f"```json\n{decl_json}\n```\n"
    )
    with open(L.path(cdir, L.EVOLUTION_FILE), "a", encoding="utf-8") as fh:
        fh.write(entry)

    # Clean up staging artifacts.
    for name in (L.ACCEPT_CONTEXT_FILE, L.PROPOSED_FILE, L.STAGED_FILE):
        p = L.path(cdir, name)
        if os.path.exists(p):
            os.remove(p)

    print(f"Recorded schema evolution: {decl['target']}.{decl['name']} "
          f"({decl.get('shape')}) -> {L.EVOLUTION_FILE}")


if __name__ == "__main__":
    main()
