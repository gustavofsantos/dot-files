#!/usr/bin/env python3
"""
work-session-create — create a session file and link it to a card

Usage:
    work-session-create --card 001 --repo api --branch feat/auth --worktree /abs/path
"""

import argparse
import json
import re
import sys
from datetime import date
from pathlib import Path

WORK_DIR = Path.home() / ".work"
CARDS_DIR = WORK_DIR / "cards"
SESSIONS_DIR = WORK_DIR / "sessions"


def find_card_path(card_id: str) -> Path | None:
    if not CARDS_DIR.exists():
        return None
    for path in CARDS_DIR.glob("*.md"):
        if path.stem == card_id or path.stem.startswith(f"{card_id}-"):
            return path
    return None


def read_text(path: Path) -> str:
    return path.read_text()


def write_text(path: Path, content: str) -> None:
    path.write_text(content)


def append_session_to_card(card_path: Path, session_path: Path) -> None:
    content = read_text(card_path)
    session_str = str(session_path)

    lines = content.splitlines()
    new_lines = []
    in_sessions = False

    for i, line in enumerate(lines):
        stripped = line.strip()

        if stripped.startswith("sessions:"):
            in_sessions = True
            if stripped == "sessions: []":
                new_lines.append("sessions:")
                new_lines.append(f"  - {session_str}")
                continue
            else:
                new_lines.append(line)
                continue

        if in_sessions:
            if stripped.startswith("- "):
                new_lines.append(line)
                next_line = lines[i + 1].strip() if i + 1 < len(lines) else ""
                if not next_line.startswith("- "):
                    new_lines.append(f"  - {session_str}")
                    in_sessions = False
                continue
            else:
                if in_sessions:
                    new_lines.append(f"  - {session_str}")
                    in_sessions = False
                new_lines.append(line)
                continue

        new_lines.append(line)

    updated_content = "\n".join(new_lines)
    today = date.today().isoformat()
    updated_content = re.sub(r"^updated: .+$", f"updated: {today}", updated_content, flags=re.MULTILINE)

    write_text(card_path, updated_content)


def build_session_content(session_id: str, card_id: str, repo: str, branch: str, worktree: str) -> str:
    return f"""---
id: {session_id}
card: "{card_id}"
repo: {repo}
branch: {branch}
worktree: {worktree}
tmux-session: {session_id}
---

## Current focus
<!-- What's being worked on right now in this repo front.
     Updated at every checkpoint — context switches, completed subtasks, blockers. -->
"""


def create_session(card_id: str, repo: str, branch: str, worktree_path: Path) -> dict:
    SESSIONS_DIR.mkdir(parents=True, exist_ok=True)

    card_path = find_card_path(card_id)
    if not card_path:
        print(f"error: card '{card_id}' not found in {CARDS_DIR}", file=sys.stderr)
        sys.exit(1)

    if not worktree_path.exists():
        print(f"error: worktree path does not exist: {worktree_path}", file=sys.stderr)
        print("create the worktree first, then run this script.", file=sys.stderr)
        sys.exit(1)

    session_id = f"{card_id}-{repo}"
    session_filename = f"{session_id}.md"
    session_path = SESSIONS_DIR / session_filename

    if session_path.exists():
        print(f"error: session file already exists: {session_path}", file=sys.stderr)
        sys.exit(1)

    content = build_session_content(session_id, card_id, repo, branch, str(worktree_path))
    write_text(session_path, content)

    append_session_to_card(card_path, session_path)

    return {
        "id": session_id,
        "card": card_id,
        "repo": repo,
        "branch": branch,
        "worktree": str(worktree_path),
        "tmux-session": session_id,
        "path": str(session_path),
    }


def main():
    parser = argparse.ArgumentParser(description="Create a work session file")
    parser.add_argument("--card", required=True, help="Card ID (e.g. 001)")
    parser.add_argument("--repo", required=True, help="Repo name (e.g. api)")
    parser.add_argument("--branch", required=True, help="Branch name")
    parser.add_argument("--worktree", required=True, help="Absolute path to the worktree")
    parser.add_argument(
        "--format",
        dest="fmt",
        default="json",
        choices=["json", "text"],
        help="Output format (default: json)",
    )
    args = parser.parse_args()

    worktree_path = Path(args.worktree).expanduser().resolve()
    session = create_session(args.card, args.repo, args.branch, worktree_path)

    if args.fmt == "json":
        print(json.dumps(session, indent=2))
    else:
        print(f"{session['id']}  {session['card']}  {session['repo']}  {session['branch']}")
        print(f"worktree: {session['worktree']}")
        print(f"path: {session['path']}")


if __name__ == "__main__":
    main()
