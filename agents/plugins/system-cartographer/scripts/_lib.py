"""Shared helpers for system-cartographer scripts.

Pure stdlib. Locates the per-repo `.cartographer/` instance, loads/saves its
files, and provides the canonical-JSON hashing used by the acceptance-token
handshake (see hooks/pretooluse_guard.py and scripts/propose_apply.py).
"""
import hashlib
import json
import os

DIRNAME = ".cartographer"
SCHEMA_FILE = "schema.json"
META_SCHEMA_FILE = "meta-schema.json"
MAP_FILE = "map.json"
EVOLUTION_FILE = "schema-evolution.md"
PENDING_FILE = ".pending-accept.json"
STAGED_FILE = ".staged-schema.json"
PROPOSED_FILE = ".proposed-extension.json"
ACCEPT_CONTEXT_FILE = ".accept-context.json"


def find_dir(start=None):
    """Walk up from `start` (default cwd) to find an existing `.cartographer/`."""
    cur = os.path.abspath(start or os.getcwd())
    while True:
        candidate = os.path.join(cur, DIRNAME)
        if os.path.isdir(candidate):
            return candidate
        parent = os.path.dirname(cur)
        if parent == cur:
            return None
        cur = parent


def require_dir(start=None):
    d = find_dir(start)
    if d is None:
        raise SystemExit(
            "No .cartographer/ found. Run /cartographer-init in your repo first."
        )
    return d


def path(cdir, name):
    return os.path.join(cdir, name)


def load_json(p):
    with open(p, "r", encoding="utf-8") as fh:
        return json.load(fh)


def save_json(p, obj):
    with open(p, "w", encoding="utf-8") as fh:
        json.dump(obj, fh, indent=2, ensure_ascii=False)
        fh.write("\n")


def canonical_hash(obj):
    """Order-/whitespace-independent hash of a JSON *object*.

    The handshake compares the SEMANTIC content of the schema, not its bytes,
    so the agent can format schema.json however it likes — only the parsed
    object must equal what the human accepted.
    """
    canonical = json.dumps(obj, sort_keys=True, separators=(",", ":"),
                           ensure_ascii=False)
    return hashlib.sha256(canonical.encode("utf-8")).hexdigest()
