#!/usr/bin/env python3
"""
Cursor command hook: cljfmt + delimiter repair for Clojure files.

- afterFileEdit / afterTabFileEdit: run clj-paren-repair on disk (same as post-write).
- preToolUse (Write): if tool_input is a full-file write with content, repair/format
  the payload and return updated_input (Cursor replaces whole tool_input — we merge).

Docs: https://cursor.com/docs/hooks
Env: CLJ_PAREN_REPAIR (default: clj-paren-repair)
"""
from __future__ import annotations

import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any, Mapping

REPAIR_BIN = os.environ.get("CLJ_PAREN_REPAIR", "clj-paren-repair")

CLOJURE_SUFFIXES = (".clj", ".cljs", ".cljc", ".edn", ".bb", ".lpy")


def _read_stdin() -> dict[str, Any]:
    raw = sys.stdin.read()
    if not raw.strip():
        return {}
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return {}


def _is_clojure_path(path: str | None) -> bool:
    if not path:
        return False
    lower = path.lower()
    return any(lower.endswith(s) for s in CLOJURE_SUFFIXES)


def _run_repair_on_path(path: Path) -> None:
    try:
        subprocess.run(
            [REPAIR_BIN, str(path)],
            check=False,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    except OSError:
        pass


def _repair_string_via_tempfile(file_path_hint: str, text: str) -> str:
    suffix = Path(file_path_hint).suffix or ".clj"
    fd, tmpp = tempfile.mkstemp(suffix=suffix, prefix="cursor-clj-repair-")
    os.close(fd)
    try:
        p = Path(tmpp)
        p.write_text(text, encoding="utf-8")
        _run_repair_on_path(p)
        return p.read_text(encoding="utf-8")
    finally:
        try:
            Path(tmpp).unlink(missing_ok=True)
        except OSError:
            pass


def _normalize_tool_input(tool_input: Any) -> dict[str, Any]:
    if isinstance(tool_input, str):
        try:
            parsed = json.loads(tool_input)
            return dict(parsed) if isinstance(parsed, Mapping) else {}
        except json.JSONDecodeError:
            return {}
    if isinstance(tool_input, Mapping):
        return dict(tool_input)
    return {}


def _emit(obj: dict[str, Any]) -> None:
    sys.stdout.write(json.dumps(obj) + "\n")


def handle_after_file_edit(data: dict[str, Any]) -> None:
    path = data.get("file_path")
    if not path or not isinstance(path, str):
        _emit({})
        return
    fp = Path(path)
    if not fp.is_file() or not _is_clojure_path(path):
        _emit({})
        return
    _run_repair_on_path(fp)
    _emit({})


def handle_pre_tool_use(data: dict[str, Any]) -> None:
    if data.get("tool_name") != "Write":
        _emit({"permission": "allow"})
        return

    ti = _normalize_tool_input(data.get("tool_input"))
    file_path = ti.get("file_path") or ti.get("path")
    if not file_path or not isinstance(file_path, str):
        _emit({"permission": "allow"})
        return

    content_key = None
    if "content" in ti:
        content_key = "content"
    elif "contents" in ti:
        content_key = "contents"

    if content_key is None:
        # Patch-style write (e.g. old_string/new_string): cannot repair here; afterFileEdit covers disk.
        _emit({"permission": "allow"})
        return

    raw_content = ti.get(content_key)
    if not isinstance(raw_content, str) or not _is_clojure_path(file_path):
        _emit({"permission": "allow"})
        return

    fixed = _repair_string_via_tempfile(file_path, raw_content)
    if fixed == raw_content:
        _emit({"permission": "allow"})
        return

    updated = dict(ti)
    updated[content_key] = fixed
    _emit({"permission": "allow", "updated_input": updated})


def main() -> None:
    data = _read_stdin()
    event = str(data.get("hook_event_name") or "")

    if event == "preToolUse":
        handle_pre_tool_use(data)
    elif event in ("afterFileEdit", "afterTabFileEdit"):
        handle_after_file_edit(data)
    elif data.get("tool_name") == "Write" and "tool_input" in data:
        handle_pre_tool_use(data)
    elif "file_path" in data and "edits" in data:
        handle_after_file_edit(data)
    else:
        _emit({})


if __name__ == "__main__":
    main()

