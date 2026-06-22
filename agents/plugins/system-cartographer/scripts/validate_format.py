#!/usr/bin/env python3
"""Structural validator — map.json against the active schema.json.

Enforces the kernel-required fields and checks that any EARNED attribute that
is present matches its declared shape. A missing earned attribute is never an
error (it is a known-unknown). Unknown attributes (not in the schema) are
reported as warnings, not errors, so the map is never invalidated by a typo.

Exit 0 if no errors (warnings allowed); exit 1 if errors.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _lib as L


def check_attr_value(attr_def, value):
    """Return an error string if `value` violates the attribute's shape, else None."""
    shape = attr_def.get("shape")
    if shape == "enum":
        if value not in attr_def.get("values", []):
            return f"must be one of {attr_def.get('values')}, got {value!r}"
    elif shape == "scalar":
        typ = attr_def.get("type")
        ok = (typ == "string" and isinstance(value, str)) or \
             (typ == "number" and isinstance(value, (int, float)) and not isinstance(value, bool)) or \
             (typ == "boolean" and isinstance(value, bool))
        if not ok:
            return f"must be a {typ}, got {value!r}"
    elif shape == "ref":
        if not isinstance(value, str):
            return f"ref must be a node id string, got {value!r}"
    elif shape == "tag":
        if not (isinstance(value, list) and all(isinstance(v, str) for v in value)):
            return f"tag must be a list of strings, got {value!r}"
    return None


def validate(schema, mp):
    errors, warnings = [], []

    def check_entity(kind, entry, idx):
        spec = schema[kind]
        label = f"{kind}[{idx}]"
        for req in spec["required"]:
            if req not in entry or entry[req] in (None, ""):
                errors.append(f"{label}: missing required field {req!r}")
        for key, value in entry.items():
            attr_def = spec["attributes"].get(key)
            if attr_def is None:
                warnings.append(f"{label}: unknown attribute {key!r} (not in schema)")
                continue
            err = check_attr_value(attr_def, value)
            if err:
                errors.append(f"{label}.{key}: {err}")

    nodes = mp.get("nodes", [])
    edges = mp.get("edges", [])

    seen_ids = set()
    for i, n in enumerate(nodes):
        check_entity("node", n, i)
        nid = n.get("id")
        if nid in seen_ids:
            errors.append(f"node[{i}]: duplicate id {nid!r}")
        seen_ids.add(nid)

    for i, e in enumerate(edges):
        check_entity("edge", e, i)

    return errors, warnings


def main():
    cdir = L.require_dir()
    schema = L.load_json(L.path(cdir, L.SCHEMA_FILE))
    mp = L.load_json(L.path(cdir, L.MAP_FILE))
    errors, warnings = validate(schema, mp)

    for w in warnings:
        print(f"WARN  {w}")
    for e in errors:
        print(f"ERROR {e}")
    if not errors:
        print(f"Format OK: {len(mp.get('nodes', []))} nodes, "
              f"{len(mp.get('edges', []))} edges.")
    sys.exit(1 if errors else 0)


if __name__ == "__main__":
    main()
