#!/usr/bin/env python3
"""
work-recall — Claude Code PostToolUse hook script.

Reads the session file for the current worktree and injects the
## Current focus section into Claude's context after each tool call.

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

Alternatively, register as a SessionStart hook to inject context once per
session instead of after every tool call (more efficient):

    {
      "hooks": {
        "SessionStart": [
          {
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
    """Read the hook event JSON from stdin. Return empty dict if unavailable."""
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
    match = re.search(r"^## Current focus\s*\n(.*?)(?=^##|\Z)", content, re.MULTILINE | re.DOTALL)
    if not match:
        return None

    focus = match.group(1).strip()

    # Ignore placeholder comments
    if not focus or focus.startswith("<!--"):
        return None

    return focus


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

    # hook_event_name is provided by Claude Code in the stdin JSON.
    # Needed to set the correct hookEventName in output — PostToolUse and
    # SessionStart both support additionalContext via hookSpecificOutput,
    # but the hookEventName field must match the actual event.
    hook_event = event.get("hook_event_name", "PostToolUse")

    # Prefer cwd from the event payload; fall back to process cwd.
    raw_cwd = event.get("cwd") or os.getcwd()
    cwd = Path(raw_cwd)

    session_path = find_session_by_worktree(cwd)

    if not session_path:
        sys.exit(0)

    focus = extract_current_focus(session_path)

    if not focus:
        sys.exit(0)

    # Per Claude Code hook docs, additionalContext must be nested inside
    # hookSpecificOutput with a hookEventName field matching the event.
    # Top-level {"additionalContext": ...} is not the correct format.
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": hook_event,
            "additionalContext": focus,
        }
    }))


if __name__ == "__main__":
    main()
