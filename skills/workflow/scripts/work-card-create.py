#!/usr/bin/env python3
"""
work-card-create — scaffold a new work card

Usage:
    work-card-create --title "Fix auth bug" [--status inbox] [--tags feature,api] [--branch feat/slug]
"""

import argparse
import json
import re
import sys
from datetime import date
from pathlib import Path

ENG_DIR = Path.home() / "engineering"
CARDS_DIR = ENG_DIR / "cards"
COUNTERS_DIR = ENG_DIR / ".counters"
VALID_STATUSES = {"inbox", "not-now", "active", "done"}


def next_id() -> str:
    COUNTERS_DIR.mkdir(parents=True, exist_ok=True)
    counter_path = COUNTERS_DIR / "cards"
    current = int(counter_path.read_text().strip()) if counter_path.exists() else 0
    next_val = current + 1
    counter_path.write_text(str(next_val))
    return f"{next_val:03d}"


def slugify(title: str) -> str:
    slug = title.lower()
    slug = re.sub(r"[^\w\s-]", "", slug)
    slug = re.sub(r"[\s_]+", "-", slug)
    slug = re.sub(r"-+", "-", slug)
    return slug.strip("-")


def parse_tags(tags_str: str) -> list[str]:
    if not tags_str:
        return []
    return [t.strip() for t in tags_str.split(",") if t.strip()]


def build_frontmatter(card_id: str, title: str, status: str, tags: list[str], branch: str | None) -> str:
    today = date.today().isoformat()
    tags_yaml = f"[{', '.join(tags)}]" if tags else "[]"
    branch_line = f"branch: {branch}" if branch else "branch:"
    return f"""---
id: "{card_id}"
title: "{title}"
status: {status}
{branch_line}
tags: {tags_yaml}
facts: []
spikes: []
created: {today}
updated: {today}
---
"""


def scaffold_body() -> str:
    return """## Objective

<!-- One sentence. What "done" looks like when this card closes. -->

## Scope

**In:** <!-- what is explicitly included -->

**Off-limits:** <!-- what will not be touched and why -->

## Context

<!-- Relevant background. Links to Jira, Sentry, docs, prior decisions.
     Design constraints (evolutionary-design, incremental-refactor) go here. -->

## Open questions

<!-- Questions that must be answered before or during execution.
     If non-empty when work begins, consider dead-reckoning before writing tasks. -->

- [ ] ?

## Tasks

<!-- - [ ] Task 1 -->
"""


def create_card(title: str, status: str, tags: list[str], branch: str | None) -> dict:
    CARDS_DIR.mkdir(parents=True, exist_ok=True)

    card_id = next_id()
    slug = slugify(title)
    filename = f"{card_id}-{slug}.md"
    card_path = CARDS_DIR / filename

    content = build_frontmatter(card_id, title, status, tags, branch) + "\n" + scaffold_body()
    card_path.write_text(content)

    return {
        "id": card_id,
        "title": title,
        "status": status,
        "branch": branch,
        "tags": tags,
        "path": str(card_path),
    }


def main():
    parser = argparse.ArgumentParser(description="Create a new work card")
    parser.add_argument("--title", required=True, help="Card title")
    parser.add_argument(
        "--status",
        default="inbox",
        choices=sorted(VALID_STATUSES),
        help="Initial status (default: inbox)",
    )
    parser.add_argument("--tags", default="", help="Comma-separated tags (e.g. feature,api)")
    parser.add_argument("--branch", default=None, help="Associated git branch (optional)")
    parser.add_argument(
        "--format",
        dest="fmt",
        default="json",
        choices=["json", "text"],
        help="Output format (default: json)",
    )
    args = parser.parse_args()

    tags = parse_tags(args.tags)
    card = create_card(args.title, args.status, tags, args.branch)

    if args.fmt == "json":
        print(json.dumps(card, indent=2))
    else:
        print(f"{card['id']}  {card['status']}  {card['title']}")
        print(f"path: {card['path']}")
        if card["branch"]:
            print(f"branch: {card['branch']}")


if __name__ == "__main__":
    main()
