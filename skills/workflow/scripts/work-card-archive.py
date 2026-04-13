#!/usr/bin/env python3
"""
work-card-archive — move a done card to the archive directory.
Also moves all associated session files to ~/.work/sessions/archive/.

Usage:
    work-card-archive --card 001
    work-card-archive --card 001 --force   # skip status check
"""

import argparse
import json
import re
import shutil
import sys
from pathlib import Path

WORK_DIR = Path.home() / ".work"
CARDS_DIR = WORK_DIR / "cards"
ARCHIVE_DIR = CARDS_DIR / "archive"
SESSIONS_DIR = WORK_DIR / "sessions"
SESSIONS_ARCHIVE_DIR = SESSIONS_DIR / "archive"


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
        key = key.strip()
        value = value.strip()

        if key == "sessions":
            if value.startswith("["):
                inner = re.sub(r"^\[|\]$", "", value)
                fields["sessions"] = [s.strip() for s in inner.split(",") if s.strip()]
            else:
                fields["sessions"] = []
        elif key in ("tags", "spikes", "facts"):
            inner = re.sub(r"^\[|\]$", "", value)
            fields[key] = [t.strip() for t in inner.split(",") if t.strip()]
        else:
            fields[key] = value.strip('"').strip("'")

    return fields


def collect_multiline_sessions(path: Path) -> list[str]:
    content = path.read_text()
    lines = content.splitlines()
    sessions = []
    in_sessions = False

    for line in lines:
        stripped = line.strip()
        if stripped.startswith("sessions:"):
            in_sessions = True
            inline = stripped[len("sessions:"):].strip()
            if inline.startswith("[") and inline != "[]":
                inner = re.sub(r"^\[|\]$", "", inline)
                return [s.strip() for s in inner.split(",") if s.strip()]
            continue
        if in_sessions:
            if stripped.startswith("- "):
                sessions.append(stripped[2:].strip())
            elif stripped and not stripped.startswith("#"):
                break
    return sessions


def find_card_path(card_id: str) -> Path | None:
    if not CARDS_DIR.exists():
        return None
    for path in CARDS_DIR.glob("*.md"):
        if path.stem == card_id or path.stem.startswith(f"{card_id}-"):
            return path
    return None


def archive_card(card_id: str, force: bool) -> dict:
    card_path = find_card_path(card_id)
    if not card_path:
        print(f"error: card '{card_id}' not found in {CARDS_DIR}", file=sys.stderr)
        sys.exit(1)

    fm = parse_frontmatter(card_path)
    status = fm.get("status", "")

    if not force and status != "done":
        print(f"error: card status is '{status}', expected 'done'.", file=sys.stderr)
        print("set the card status to 'done' first, or use --force to override.", file=sys.stderr)
        sys.exit(1)

    ARCHIVE_DIR.mkdir(parents=True, exist_ok=True)
    SESSIONS_ARCHIVE_DIR.mkdir(parents=True, exist_ok=True)

    session_paths = collect_multiline_sessions(card_path)

    archived_sessions = []
    skipped_sessions = []

    for session_ref in session_paths:
        session_path = Path(session_ref).expanduser()
        if not session_path.exists():
            skipped_sessions.append(str(session_path))
            continue
        dest = SESSIONS_ARCHIVE_DIR / session_path.name
        shutil.move(str(session_path), str(dest))
        archived_sessions.append(str(dest))

    dest_card = ARCHIVE_DIR / card_path.name
    shutil.move(str(card_path), str(dest_card))

    return {
        "id": card_id,
        "status": "archived",
        "card": str(dest_card),
        "sessions_archived": archived_sessions,
        "sessions_skipped": skipped_sessions,
    }


def main():
    parser = argparse.ArgumentParser(description="Archive a done work card")
    parser.add_argument("--card", required=True, help="Card ID (e.g. 001)")
    parser.add_argument(
        "--force",
        action="store_true",
        help="Archive even if status is not 'done'",
    )
    parser.add_argument(
        "--format",
        dest="fmt",
        default="json",
        choices=["json", "text"],
        help="Output format (default: json)",
    )
    args = parser.parse_args()

    result = archive_card(args.card, args.force)

    if args.fmt == "json":
        print(json.dumps(result, indent=2))
    else:
        print(f"{result['id']}  archived")
        print(f"card:     {result['card']}")
        if result["sessions_archived"]:
            print("sessions archived:")
            for s in result["sessions_archived"]:
                print(f"  {s}")
        if result["sessions_skipped"]:
            print("sessions not found (skipped):")
            for s in result["sessions_skipped"]:
                print(f"  {s}")


if __name__ == "__main__":
    main()
