#!/usr/bin/env python3
"""
work-session-log — PostToolUse hook for Claude Code and Cursor.

Appends mechanical capture entries to ~/.work/sessions/<id>.log.jsonl
automatically, without requiring agent attention.

Captures:
  - File writes/edits: file path + timestamp
  - Shell: git operations and test runs only (filtered)
  - Compaction events (Cursor only): marker with context stats

Exits silently with code 0 in all cases — never blocks agents.

─── Claude Code registration (.claude/settings.local.json) ───────────────

    {
      "hooks": {
        "PostToolUse": [
          {
            "matcher": "Write|Edit|MultiEdit|Bash",
            "hooks": [
              {
                "type": "command",
                "command": "python3 ~/.claude/skills/workflow/scripts/work-session-log.py"
              }
            ]
          }
        ]
      }
    }

─── Cursor registration (~/.cursor/hooks.json) ───────────────────────────

    {
      "version": 1,
      "hooks": {
        "postToolUse": [
          {
            "command": "python3 ~/.claude/skills/workflow/scripts/work-session-log.py",
            "matcher": "Write|Shell"
          }
        ],
        "afterFileEdit": [
          {
            "command": "python3 ~/.claude/skills/workflow/scripts/work-session-log.py"
          }
        ],
        "afterShellExecution": [
          {
            "command": "python3 ~/.claude/skills/workflow/scripts/work-session-log.py"
          }
        ],
        "preCompact": [
          {
            "command": "python3 ~/.claude/skills/workflow/scripts/work-session-log.py"
          }
        ]
      }
    }

Note: postToolUse and afterFileEdit/afterShellExecution may both fire for the
same action in Cursor. Duplicate suppression uses (ts_minute, file_or_cmd) as
key — entries within the same minute for the same target are deduplicated on
read, not on write, to avoid race conditions on the log file.
"""

import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

WORK_DIR = Path.home() / ".work"
SESSIONS_DIR = WORK_DIR / "sessions"

GIT_PREFIX = "git "
TEST_PATTERNS = [
    "lein test",
    "clj -M:test",
    "clj -X:test",
    "pytest",
    "npm test",
    "yarn test",
    "npx jest",
    "cargo test",
    "go test",
    "mix test",
    "rspec",
    "mvn test",
    "gradle test",
    "./gradlew test",
]


def read_stdin_event() -> dict:
    try:
        if not sys.stdin.isatty():
            return json.loads(sys.stdin.read())
    except (json.JSONDecodeError, OSError):
        pass
    return {}


def parse_frontmatter(path: Path) -> dict:
    try:
        content = path.read_text()
    except OSError:
        return {}

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


def current_git_branch(cwd: Path) -> str | None:
    try:
        result = subprocess.run(
            ["git", "-C", str(cwd), "rev-parse", "--abbrev-ref", "HEAD"],
            capture_output=True, text=True, timeout=3,
        )
        branch = result.stdout.strip()
        return branch if branch and branch != "HEAD" else None
    except Exception:
        return None


def find_session_log_path(candidates: list[Path]) -> Path | None:
    """
    Find the session log path by matching candidate directories against
    worktree paths in session files. Branch match wins; otherwise the
    highest-numbered (most recent) worktree match is used.
    """
    if not SESSIONS_DIR.exists():
        return None

    resolved_candidates = []
    for c in candidates:
        try:
            resolved_candidates.append(c.resolve())
        except Exception:
            pass

    if not resolved_candidates:
        return None

    branch = current_git_branch(resolved_candidates[0])

    worktree_matches: list[Path] = []
    for path in SESSIONS_DIR.glob("*.md"):
        fm = parse_frontmatter(path)
        worktree = fm.get("worktree", "")
        if not worktree:
            continue
        try:
            worktree_resolved = Path(worktree).expanduser().resolve()
            for cwd_resolved in resolved_candidates:
                if cwd_resolved == worktree_resolved or cwd_resolved.is_relative_to(worktree_resolved):
                    if branch and fm.get("branch") == branch:
                        return path.parent / (path.stem + ".log.jsonl")
                    worktree_matches.append(path)
                    break
        except Exception:
            continue

    if not worktree_matches:
        return None
    best = max(worktree_matches)
    return best.parent / (best.stem + ".log.jsonl")


def ts() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def classify_bash(cmd: str) -> dict | None:
    stripped = cmd.strip()

    if stripped.startswith(GIT_PREFIX):
        parts = stripped.split()
        subcommand = parts[1] if len(parts) > 1 else "unknown"
        return {"type": "git", "subcommand": subcommand, "cmd": stripped[:200]}

    lower = stripped.lower()
    for pattern in TEST_PATTERNS:
        if lower.startswith(pattern):
            return {"type": "test", "cmd": stripped[:200]}

    return None


# ── Entry builders ─────────────────────────────────────────────────────────────

def entry_from_claude_code_post_tool_use(event: dict) -> dict | None:
    tool_name = event.get("tool_name", "")
    tool_input = event.get("tool_input", {})
    now = ts()

    if tool_name in ("Write", "Edit", "MultiEdit"):
        file_path = (
            tool_input.get("file_path")
            or tool_input.get("path")
            or tool_input.get("new_path")
        )
        if not file_path:
            return None
        return {"ts": now, "source": "claude-code", "tool": tool_name, "file": file_path}

    if tool_name == "Bash":
        cmd = tool_input.get("command", "")
        if not cmd:
            return None
        classified = classify_bash(cmd)
        if classified is None:
            return None
        return {"ts": now, "source": "claude-code", "tool": "Bash", **classified}

    return None


def entry_from_cursor_post_tool_use(event: dict) -> dict | None:
    """
    Cursor postToolUse fires for all tools. afterFileEdit and afterShellExecution
    are more specific and preferred. This handler only covers Write-type tools
    that afterFileEdit may not catch (e.g. create-new-file operations).
    """
    tool_name = event.get("tool_name", "")
    tool_input = event.get("tool_input", {})
    now = ts()

    if tool_name in ("Write", "Edit", "MultiEdit"):
        file_path = (
            tool_input.get("file_path")
            or tool_input.get("path")
        )
        if not file_path:
            return None
        return {"ts": now, "source": "cursor", "tool": tool_name, "file": file_path}

    if tool_name == "Shell":
        cmd = tool_input.get("command", "")
        if not cmd:
            return None
        classified = classify_bash(cmd)
        if classified is None:
            return None
        return {"ts": now, "source": "cursor", "tool": "Shell", **classified}

    return None


def entry_from_cursor_after_file_edit(event: dict) -> dict | None:
    file_path = event.get("file_path", "")
    if not file_path:
        return None
    return {"ts": ts(), "source": "cursor", "tool": "afterFileEdit", "file": file_path}


def entry_from_cursor_after_shell_execution(event: dict) -> dict | None:
    cmd = event.get("command", "")
    if not cmd:
        return None
    classified = classify_bash(cmd)
    if classified is None:
        return None
    return {"ts": ts(), "source": "cursor", "tool": "afterShellExecution", **classified}


def entry_from_cursor_pre_compact(event: dict) -> dict:
    """
    Always log compaction events — they mark context resets.
    This is the signal that prior reasoning is no longer in the window.
    Logged regardless of content, because the absence of a preCompact entry
    in the log means the window was never compacted during that session.
    """
    return {
        "ts": ts(),
        "source": "cursor",
        "tool": "preCompact",
        "type": "compaction",
        "trigger": event.get("trigger", "unknown"),
        "context_usage_pct": event.get("context_usage_percent"),
        "context_tokens": event.get("context_tokens"),
        "is_first": event.get("is_first_compaction"),
    }


# ── Routing ────────────────────────────────────────────────────────────────────

def build_entry(event: dict) -> dict | None:
    hook_event = event.get("hook_event_name", "")

    if hook_event == "PostToolUse":
        return entry_from_claude_code_post_tool_use(event)

    if hook_event == "postToolUse":
        return entry_from_cursor_post_tool_use(event)

    if hook_event == "afterFileEdit":
        return entry_from_cursor_after_file_edit(event)

    if hook_event == "afterShellExecution":
        return entry_from_cursor_after_shell_execution(event)

    if hook_event == "preCompact":
        return entry_from_cursor_pre_compact(event)

    return None


def resolve_search_paths(event: dict) -> list[Path]:
    """
    Build candidate directories for session matching.
    Cursor provides workspace_roots (most reliable); both provide cwd.
    """
    paths = []

    for root in event.get("workspace_roots", []):
        if root:
            paths.append(Path(root))

    raw_cwd = event.get("cwd") or os.getcwd()
    if raw_cwd:
        paths.append(Path(raw_cwd))

    return paths


def append_entry(log_path: Path, entry: dict) -> None:
    log_path.parent.mkdir(parents=True, exist_ok=True)
    with log_path.open("a") as f:
        f.write(json.dumps(entry) + "\n")


def main():
    event = read_stdin_event()

    if not event:
        sys.exit(0)

    entry = build_entry(event)
    if not entry:
        sys.exit(0)

    search_paths = resolve_search_paths(event)
    if not search_paths:
        sys.exit(0)

    log_path = find_session_log_path(search_paths)
    if not log_path:
        sys.exit(0)

    try:
        append_entry(log_path, entry)
    except OSError:
        pass

    sys.exit(0)


if __name__ == "__main__":
    main()
