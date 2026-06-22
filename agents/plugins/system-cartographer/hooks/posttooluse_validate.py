#!/usr/bin/env python3
"""PostToolUse validator — surfaces map problems after an instance write.

Runs after a successful Write/Edit. If the written file is map.json, run the
referential-integrity validator and feed any problems back to the agent
(exit 2 -> stderr to Claude). Non-blocking: the write already happened; this
just makes integrity breakage visible so it can be fixed. Anything else: no-op.
"""
import json
import os
import subprocess
import sys

PLUGIN_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def main():
    try:
        event = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    file_path = (event.get("tool_input") or {}).get("file_path", "")
    norm = os.path.normpath(file_path) if file_path else ""
    if os.path.basename(norm) != "map.json" or \
            os.path.basename(os.path.dirname(norm)) != ".cartographer":
        sys.exit(0)

    proc = subprocess.run(
        [sys.executable, os.path.join(PLUGIN_ROOT, "scripts", "validate_integrity.py")],
        cwd=os.path.dirname(norm), capture_output=True, text=True)

    if proc.returncode != 0:
        sys.stderr.write("system-cartographer: map integrity problems after this "
                         "write:\n" + proc.stdout + proc.stderr)
        sys.exit(2)

    # Pass informational notes (SPOFs, cycles) through to the transcript.
    if proc.stdout.strip():
        print(proc.stdout.strip())
    sys.exit(0)


if __name__ == "__main__":
    main()
