#!/usr/bin/env python3
"""Low-friction instance editing — add a node or an edge to map.json.

Instance data is cheap and reversible, so this writes freely (no token). It
validates the *prospective* map first and refuses a write that would break
format or referential integrity, so growth never corrupts the map. Adding one
edge never requires touching any other entry.

  add-node --id ID --role ROLE
  add-edge --from A --to B --interaction sync|async [--attr name=value ...]
"""
import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _lib as L
import validate_format as VF
import validate_integrity as VI


def parse_attr_value(schema, kind, name, raw):
    """Coerce a --attr value per its declared shape; error if attr unknown."""
    attr_def = schema[kind]["attributes"].get(name)
    if attr_def is None:
        raise SystemExit(
            f"REJECTED: {kind} has no attribute {name!r} in the active schema. "
            "Earn it first via /map-analyze + /accept-schema-change.")
    shape = attr_def.get("shape")
    if shape == "scalar" and attr_def.get("type") == "number":
        try:
            return float(raw) if "." in raw else int(raw)
        except ValueError:
            raise SystemExit(f"REJECTED: {name!r} must be a number, got {raw!r}")
    if shape == "scalar" and attr_def.get("type") == "boolean":
        return raw.lower() in ("1", "true", "yes")
    if shape == "tag":
        return [t.strip() for t in raw.split(",") if t.strip()]
    return raw


def write_validated(cdir, schema, mp):
    fe, fw = VF.validate(schema, mp)
    ie, iw = VI.analyze(schema, mp)
    errors = fe + ie
    if errors:
        for e in errors:
            print(f"ERROR {e}")
        raise SystemExit("REJECTED: write would break the map; no changes made.")
    L.save_json(L.path(cdir, L.MAP_FILE), mp)
    for w in fw + iw:
        print(f"NOTE  {w}")


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)

    n = sub.add_parser("add-node")
    n.add_argument("--id", required=True)
    n.add_argument("--role", required=True)

    e = sub.add_parser("add-edge")
    e.add_argument("--from", dest="frm", required=True)
    e.add_argument("--to", required=True)
    e.add_argument("--interaction", required=True, choices=["sync", "async"])
    e.add_argument("--attr", action="append", default=[],
                   help="earned attribute as name=value (repeatable)")

    args = ap.parse_args()
    cdir = L.require_dir()
    schema = L.load_json(L.path(cdir, L.SCHEMA_FILE))
    mp = L.load_json(L.path(cdir, L.MAP_FILE))

    if args.cmd == "add-node":
        if any(nd.get("id") == args.id for nd in mp["nodes"]):
            raise SystemExit(f"REJECTED: node {args.id!r} already exists.")
        mp["nodes"].append({"id": args.id, "role": args.role})
        write_validated(cdir, schema, mp)
        print(f"Added node {args.id!r}.")

    elif args.cmd == "add-edge":
        edge = {"from": args.frm, "to": args.to, "interaction": args.interaction}
        for pair in args.attr:
            if "=" not in pair:
                raise SystemExit(f"REJECTED: --attr must be name=value, got {pair!r}")
            name, raw = pair.split("=", 1)
            edge[name] = parse_attr_value(schema, "edge", name, raw)
        mp["edges"].append(edge)
        write_validated(cdir, schema, mp)
        print(f"Added edge {args.frm!r} --{args.interaction}--> {args.to!r}.")


if __name__ == "__main__":
    main()
