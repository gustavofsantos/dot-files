#!/usr/bin/env python3
"""PreToolUse guard — the structural throttle on schema evolution.

Gate on IRREVERSIBILITY, not volume. Instance data (map.json) is cheap and
reversible, so it flows freely. The schema's *shape* is high-leverage and
semi-permanent, so a write to it requires an explicit human `yes` — recorded
here as an acceptance token that this hook verifies.

Deny-by-default: any Write/Edit to `.cartographer/{schema,meta-schema}.json`
is rejected UNLESS a valid, unexpired, content-matched acceptance token is
present (minted only by /accept-schema-change AFTER the user confirms).

The handshake (see scripts/propose_apply.py):
  - The command, only after the human confirms, stages the exact new schema
    object and writes `.pending-accept.json` = {sha256(canonical(new)), nonce,
    expires}. The hash is over the CANONICAL JSON (sorted keys, no whitespace)
    so the agent may format schema.json freely — only the parsed object must
    equal what was accepted.
  - This hook hashes the incoming write the same way. Match + unexpired ->
    allow, and the token is consumed (single-use) so it can't authorize a
    later, different write.

Everything that is NOT a protected schema file: this hook stays out of the way
(exit 0, no output) so the user's normal permission flow is untouched. Any
exception while evaluating a PROTECTED file fails CLOSED (deny).
"""
import hashlib
import json
import os
import sys
import time

PROTECTED_BASENAMES = {"schema.json", "meta-schema.json"}
CARTOGRAPHER_DIR = ".cartographer"
PENDING_FILE = ".pending-accept.json"
STAGED_FILE = ".staged-schema.json"


def deny(reason):
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }))
    sys.exit(0)


def allow(reason):
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "allow",
            "permissionDecisionReason": reason,
        }
    }))
    sys.exit(0)


def passthrough():
    # No decision -> normal permission flow proceeds for this write.
    sys.exit(0)


def canonical_hash(obj):
    canonical = json.dumps(obj, sort_keys=True, separators=(",", ":"),
                           ensure_ascii=False)
    return hashlib.sha256(canonical.encode("utf-8")).hexdigest()


def is_protected(file_path):
    if not file_path:
        return False
    norm = os.path.normpath(file_path)
    base = os.path.basename(norm)
    parent = os.path.basename(os.path.dirname(norm))
    return base in PROTECTED_BASENAMES and parent == CARTOGRAPHER_DIR


def main():
    try:
        event = json.load(sys.stdin)
    except Exception:
        # Can't parse the event at all — don't interfere with normal flow.
        passthrough()

    tool_name = event.get("tool_name", "")
    tool_input = event.get("tool_input") or {}
    file_path = tool_input.get("file_path", "")

    if not is_protected(file_path):
        passthrough()

    # From here on we are guarding a protected schema file: fail CLOSED.
    try:
        if tool_name == "Edit":
            deny("Schema files cannot be edited in place. Schema evolution must "
                 "go through /accept-schema-change, which writes the full, "
                 "accepted schema. (Gate on irreversibility — see the README.)")

        if tool_name != "Write":
            # Some other tool targeting the schema file — deny by default.
            deny(f"{tool_name} is not an allowed way to modify a protected "
                 "schema file. Use /accept-schema-change.")

        cdir = os.path.dirname(os.path.normpath(file_path))
        pending_path = os.path.join(cdir, PENDING_FILE)

        if not os.path.exists(pending_path):
            deny("This schema file is protected. It only grows by ACCEPTED "
                 "extension. Do not write it directly — run /accept-schema-change "
                 "so the change is human-confirmed and recorded in the evolution "
                 "log.")

        with open(pending_path, "r", encoding="utf-8") as fh:
            token = json.load(fh)

        if time.time() > float(token.get("expires", 0)):
            os.remove(pending_path)
            deny("The pending schema-change acceptance expired. Re-run "
                 "/accept-schema-change to re-confirm.")

        try:
            incoming = json.loads(tool_input.get("content", ""))
        except Exception:
            deny("The content being written to the schema is not valid JSON.")

        if canonical_hash(incoming) != token.get("sha256"):
            deny("This write does not match the schema change the user accepted. "
                 "Write the exact staged schema, or re-run /accept-schema-change.")

        # Valid, content-matched, unexpired -> consume single-use token + staged.
        try:
            os.remove(pending_path)
        except OSError:
            pass
        staged = os.path.join(cdir, STAGED_FILE)
        if os.path.exists(staged):
            try:
                os.remove(staged)
            except OSError:
                pass

        allow("Acceptance token verified — this exact schema change was "
              "confirmed by the user via /accept-schema-change.")
    except SystemExit:
        raise
    except Exception as exc:  # fail closed for protected files
        deny(f"Guard error while evaluating a protected schema write ({exc}). "
             "Denying by default. Use /accept-schema-change.")


if __name__ == "__main__":
    main()
