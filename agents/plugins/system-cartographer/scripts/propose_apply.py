#!/usr/bin/env python3
"""Stage an accepted schema extension and mint its acceptance token.

Invoked by /accept-schema-change ONLY AFTER the human has confirmed. Reads the
proposal staged by the reasoning/upgrade-protocol skill at
`.cartographer/.proposed-extension.json`, validates it against the meta-schema
(the change must be one of the four legal shapes, optional, non-shadowing),
computes the exact new schema object, and:

  - writes `.staged-schema.json`  (the bytes the agent should write to schema.json)
  - writes `.pending-accept.json` (sha256 of canonical(new schema) + nonce + expiry)
  - writes `.accept-context.json` (decision metadata for the evolution log)

It deliberately does NOT write schema.json — the agent does, and the PreToolUse
guard verifies this token before allowing that write. The token is minted only
on this path, so "a token exists" implies "the human said yes just now."
"""
import argparse
import copy
import os
import secrets
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _lib as L

TTL_SECONDS = 900


def fail(msg):
    raise SystemExit(f"REJECTED: {msg}")


def validate_extension(ext, meta, schema):
    rules = meta["extension_rules"]
    target = ext.get("target")
    name = ext.get("name")
    shape = ext.get("shape")

    if target not in rules["allowed_targets"]:
        fail(f"target must be one of {rules['allowed_targets']}, got {target!r}.")
    if not name or not isinstance(name, str):
        fail("extension 'name' is required and must be a string.")
    if name in rules["reserved_attribute_names"]:
        fail(f"attribute name {name!r} is reserved by the kernel.")
    if name in schema[target]["attributes"]:
        fail(f"{target} already has an attribute named {name!r}; "
             "schema accretes, it never redefines.")
    if shape not in rules["allowed_shapes"]:
        fail(f"shape must be one of {list(rules['allowed_shapes'])}, got {shape!r}.")

    attr = {"shape": shape, "origin": "extension", "optional": True}

    if shape == "enum":
        values = ext.get("values")
        if not isinstance(values, list) or not values or \
                not all(isinstance(v, str) for v in values):
            fail("enum extension needs a non-empty 'values' list of strings.")
        attr["values"] = values
    elif shape == "scalar":
        typ = ext.get("type")
        allowed = rules["allowed_shapes"]["scalar"]["allowed_types"]
        if typ not in allowed:
            fail(f"scalar extension needs 'type' in {allowed}, got {typ!r}.")
        attr["type"] = typ
    elif shape == "ref":
        ref = ext.get("ref")
        if not ref:
            fail("ref extension needs a 'ref' target (e.g. 'node').")
        attr["ref"] = ref
    elif shape == "tag":
        pass  # no params

    vi = ext.get("visual_intent")
    if vi is not None:
        # Carried, unused in v1. Don't hard-fail on an unknown hint; just keep it.
        attr["visual_intent"] = vi

    return attr


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--proposal", help="path to a proposal JSON "
                    "(default: .cartographer/.proposed-extension.json)")
    args = ap.parse_args()

    cdir = L.require_dir()
    meta = L.load_json(L.path(cdir, L.META_SCHEMA_FILE))
    schema = L.load_json(L.path(cdir, L.SCHEMA_FILE))

    proposal_path = args.proposal or L.path(cdir, L.PROPOSED_FILE)
    if not os.path.exists(proposal_path):
        fail(f"no proposal found at {proposal_path}. The reasoning skill stages "
             "one when an analysis needs an attribute the schema lacks.")
    ext = L.load_json(proposal_path)

    attr = validate_extension(ext, meta, schema)
    target, name = ext["target"], ext["name"]

    new_schema = copy.deepcopy(schema)
    new_schema[target]["attributes"][name] = attr
    summary = {
        "name": name,
        "target": target,
        "shape": ext["shape"],
        "reason": ext.get("reason", ""),
        "triggered_by": ext.get("triggered_by", ext.get("mode", "")),
    }
    for k in ("values", "type", "ref", "visual_intent"):
        if k in attr and k != "shape":
            summary[k] = attr[k]
    new_schema["extensions"].append(summary)

    # Mint the token over the canonical (formatting-independent) new schema.
    now = time.time()
    token = {
        "target": L.SCHEMA_FILE,
        "sha256": L.canonical_hash(new_schema),
        "nonce": secrets.token_hex(16),
        "created": now,
        "expires": now + TTL_SECONDS,
    }
    L.save_json(L.path(cdir, L.STAGED_FILE), new_schema)
    L.save_json(L.path(cdir, L.PENDING_FILE), token)
    L.save_json(L.path(cdir, L.ACCEPT_CONTEXT_FILE), {
        "summary": summary,
        "declaration": {"target": target, "name": name, **{
            k: attr[k] for k in ("shape", "values", "type", "ref", "visual_intent")
            if k in attr}},
        "reason": ext.get("reason", ""),
        "triggered_by": summary["triggered_by"],
    })

    print("Acceptance token minted (valid {}s).".format(TTL_SECONDS))
    print(f"Staged new schema: {L.path(cdir, L.STAGED_FILE)}")
    print(f"\nNext step for the agent: write {L.path(cdir, L.SCHEMA_FILE)} with the "
          f"EXACT contents of {L.STAGED_FILE} (the guard verifies the token, then "
          "consumes it). Afterwards run record_evolution.py.")


if __name__ == "__main__":
    main()
