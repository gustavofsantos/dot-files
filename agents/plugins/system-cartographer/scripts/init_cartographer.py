#!/usr/bin/env python3
"""Scaffold a `.cartographer/` instance in the current repo.

Idempotent: never clobbers existing files. Writes the kernel meta-schema and
schema, an empty map, and an empty evolution log. Instance data (map.json)
grows freely; schema files are protected by the PreToolUse hook thereafter.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _kernel as K
import _lib as L


def main():
    root = os.getcwd()
    cdir = os.path.join(root, L.DIRNAME)
    os.makedirs(cdir, exist_ok=True)

    created, skipped = [], []

    def write_if_absent(name, writer):
        p = L.path(cdir, name)
        if os.path.exists(p):
            skipped.append(name)
        else:
            writer(p)
            created.append(name)

    write_if_absent(L.META_SCHEMA_FILE, lambda p: L.save_json(p, K.KERNEL_META_SCHEMA))
    write_if_absent(L.SCHEMA_FILE, lambda p: L.save_json(p, K.KERNEL_SCHEMA))
    write_if_absent(L.MAP_FILE, lambda p: L.save_json(p, K.EMPTY_MAP))
    write_if_absent(L.EVOLUTION_FILE,
                    lambda p: open(p, "w", encoding="utf-8").write(K.EVOLUTION_LOG_HEADER))
    # Keep transient handshake/staging files out of version control: an
    # interrupted /accept-schema-change must never leave a committable token.
    write_if_absent(".gitignore", lambda p: open(p, "w", encoding="utf-8").write(
        "\n".join([L.PENDING_FILE, L.STAGED_FILE, L.PROPOSED_FILE,
                   L.ACCEPT_CONTEXT_FILE]) + "\n"))

    print(f"Initialized .cartographer/ at {cdir}")
    if created:
        print("  created: " + ", ".join(created))
    if skipped:
        print("  kept (already present): " + ", ".join(skipped))
    print("\nNext: /map-add-node and /map-add-edge to start mapping.")


if __name__ == "__main__":
    main()
