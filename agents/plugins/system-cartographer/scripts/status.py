#!/usr/bin/env python3
"""Report map size, validity, and backfill gaps.

The backfill report is how the user climbs the completeness gradient: when an
extension is accepted, existing entries lack it. That is not an error — it is a
visible, reportable gap ("8 edges lack failure_mode") the user can fill over
time. A missing earned attribute is always a known-unknown.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _lib as L
import validate_format as VF
import validate_integrity as VI


def main():
    cdir = L.require_dir()
    schema = L.load_json(L.path(cdir, L.SCHEMA_FILE))
    mp = L.load_json(L.path(cdir, L.MAP_FILE))
    nodes, edges = mp.get("nodes", []), mp.get("edges", [])

    print(f"Map: {len(nodes)} nodes, {len(edges)} edges")
    exts = schema.get("extensions", [])
    print(f"Schema: kernel + {len(exts)} earned extension(s)"
          + (": " + ", ".join(f"{e['target']}.{e['name']}" for e in exts) if exts else ""))

    fe, fw = VF.validate(schema, mp)
    ie, iw = VI.analyze(schema, mp)
    print(f"\nValidity: {'OK' if not (fe + ie) else 'ERRORS'}")
    for e in fe + ie:
        print(f"  ERROR {e}")

    # Backfill gaps: per earned (non-kernel) attribute, how many entries lack it.
    print("\nBackfill gaps (earned attributes):")
    any_gap = False
    for kind, coll in (("node", nodes), ("edge", edges)):
        for name, a in schema[kind]["attributes"].items():
            if a.get("origin") != "extension":
                continue
            missing = sum(1 for entry in coll if name not in entry)
            total = len(coll)
            if total:
                any_gap = True
                print(f"  {missing}/{total} {kind}s lack {name!r}")
    if not any_gap:
        print("  (none — no earned attributes yet, or fully backfilled)")

    if iw:
        print("\nStructural notes:")
        for w in iw:
            print(f"  {w}")


if __name__ == "__main__":
    main()
