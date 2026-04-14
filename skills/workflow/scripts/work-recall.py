#!/usr/bin/env python3
"""
work-recall — Claude Code PostToolUse hook script.

Reads the session file for the current worktree and injects the
## Current focus section (Done / In progress / Next) into Claude's
context after each tool call.

Exits silently with code 0 if no session is found — never blocks Claude.

Hook registration (.claude/settings.local.json):
    {
      "hooks": {
        "PostToolUse": [
          {
            "matcher": "Bash|Read",
            "hooks": [
              {
                "type": "command",
                "command": "python3 ~/.claude/skills/workflow/scripts/work-recall.py"
              }
            ]
          }
        ]
      }
    }
"""

import json
import os
import re
import sys
from pathlib import Path

WORK_DIR = Path.home() / ".work"
SESSIONS_DIR = WORK_DIR / "sessions"


def read_stdin_event() -> dict:
    try:
        if not sys.stdin.isatty():
            return json.loads(sys.stdin.read())
    except (json.JSONDecodeError, OSError):
        pass
    return {}


def parse_frontmatter(path: Path) -> dict:
    content = path.read_text()
    if not content.startswith("---"):
        return {}

    end = content.find("---", 3)
    if end == -1:
        return {}

    fm_block = content[3:end].strip()
    fields = {}
    for line in fm_block.splitlines():
        if ":" not in line:
            continue
        key, _, value = line.partition(":")
        fields[key.strip()] = value.strip().strip('"').strip("'")

    return fields


def extract_current_focus(path: Path) -> str | None:
    content = path.read_text()

    # Extract the full ## Current focus block (until next ## or end of file)
    match = re.search(
        r"^## Current focus\s*\n(.*?)(?=^##|\Z)",
        content,
        re.MULTILINE | re.DOTALL,
    )
    if not match:
        return None

    focus_body = match.group(1).strip()

    # Ignore empty or placeholder-only sections
    if not focus_body or all(
        line.strip().startswith("<!--") or not line.strip()
        for line in focus_body.splitlines()
    ):
        return None

    # Strip HTML comments (<!-- ... -->) from the output
    focus_body = re.sub(r"<!--.*?-->", "", focus_body, flags=re.DOTALL).strip()

    if not focus_body:
        return None

    # Format for injection: prepend the section header for clarity
    return f"## Current focus\n\n{focus_body}"


def find_session_by_worktree(cwd: Path) -> Path | None:
    if not SESSIONS_DIR.exists():
        return None

    cwd_resolved = cwd.resolve()

    for path in sorted(SESSIONS_DIR.glob("*.md")):
        fm = parse_frontmatter(path)
        worktree = fm.get("worktree", "")
        if not worktree:
            continue
        try:
            worktree_resolved = Path(worktree).expanduser().resolve()
            if cwd_resolved == worktree_resolved or cwd_resolved.is_relative_to(worktree_resolved):
                return path
        except Exception:
            continue

    return None


def main():
    event = read_stdin_event()
    hook_event = event.get("hook_event_name", "PostToolUse")

    raw_cwd = event.get("cwd") or os.getcwd()
    cwd = Path(raw_cwd)

    session_path = find_session_by_worktree(cwd)

    if not session_path:
        sys.exit(0)

    focus = extract_current_focus(session_path)

    if not focus:
        sys.exit(0)

    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": hook_event,
            "additionalContext": focus,
        }
    }))


if __name__ == "__main__":
    main()
