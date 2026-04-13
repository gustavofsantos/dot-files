#!/usr/bin/env python3
"""
work-session-restore — restore dead tmux sessions from work session files.
Does not attach. Use work-session-attach to attach after restoring.

Usage:
    work-session-restore --session 001-api
    work-session-restore --all
"""

import argparse
import json
import subprocess
import sys
from pathlib import Path

WORK_DIR = Path.home() / ".work"
SESSIONS_DIR = WORK_DIR / "sessions"


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

    fields["path"] = str(path)
    return fields


def tmux_session_exists(session_name: str) -> bool:
    result = subprocess.run(
        ["tmux", "has-session", "-t", session_name],
        capture_output=True,
    )
    return result.returncode == 0


def restore_session(fm: dict) -> dict:
    session_name = fm.get("tmux-session") or fm.get("id")
    worktree = fm.get("worktree", "")
    session_id = fm.get("id", "?")

    if not session_name:
        return {"id": session_id, "status": "error", "reason": "missing tmux-session field"}

    if not worktree:
        return {"id": session_id, "status": "error", "reason": "missing worktree field"}

    worktree_path = Path(worktree).expanduser().resolve()
    if not worktree_path.exists():
        return {
            "id": session_id,
            "status": "error",
            "reason": f"worktree path does not exist: {worktree_path}",
        }

    if tmux_session_exists(session_name):
        return {"id": session_id, "status": "skipped", "reason": "tmux session already alive"}

    try:
        subprocess.run(
            ["tmux", "new-session", "-d", "-s", session_name, "-c", str(worktree_path)],
            check=True,
            capture_output=True,
        )
        return {"id": session_id, "status": "restored", "tmux-session": session_name, "worktree": str(worktree_path)}
    except subprocess.CalledProcessError as e:
        return {"id": session_id, "status": "error", "reason": e.stderr.decode().strip()}


def find_session_path(session_id: str) -> Path | None:
    candidate = SESSIONS_DIR / f"{session_id}.md"
    if candidate.exists():
        return candidate
    return None


def load_all_sessions() -> list[dict]:
    if not SESSIONS_DIR.exists():
        return []
    sessions = []
    for path in sorted(SESSIONS_DIR.glob("*.md")):
        fm = parse_frontmatter(path)
        if fm:
            sessions.append(fm)
    return sessions


def main():
    parser = argparse.ArgumentParser(description="Restore dead work tmux sessions")
    parser.add_argument("--session", help="Session ID to restore (e.g. 001-api)")
    parser.add_argument("--all", action="store_true", help="Restore all dead sessions")
    parser.add_argument(
        "--format",
        dest="fmt",
        default="json",
        choices=["json", "text"],
        help="Output format (default: json)",
    )
    args = parser.parse_args()

    if not args.session and not args.all:
        print("error: provide --session <id> or --all", file=sys.stderr)
        sys.exit(1)

    if args.session and args.all:
        print("error: --session and --all are mutually exclusive", file=sys.stderr)
        sys.exit(1)

    if args.session:
        session_path = find_session_path(args.session)
        if not session_path:
            print(f"error: session file not found for '{args.session}' in {SESSIONS_DIR}", file=sys.stderr)
            sys.exit(1)
        fm = parse_frontmatter(session_path)
        results = [restore_session(fm)]
    else:
        sessions = load_all_sessions()
        results = [restore_session(fm) for fm in sessions] if sessions else []

    if args.fmt == "json":
        print(json.dumps(results, indent=2))
    else:
        if not results:
            print("no sessions found.")
        for r in results:
            status = r.get("status", "?")
            sid = r.get("id", "?")
            reason = r.get("reason", "")
            suffix = f"  ({reason})" if reason else ""
            print(f"{sid:<20}  {status}{suffix}")


if __name__ == "__main__":
    main()
