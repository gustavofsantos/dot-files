#!/usr/bin/env python3
"""Failure-analysis traversals over the typed map.

Each mode runs on whatever the active schema supports and DEGRADES GRACEFULLY.
When a mode needs an attribute the schema lacks, it does not guess: it writes a
minimally-scoped extension proposal to `.cartographer/.proposed-extension.json`
and prints a PROPOSAL block. The reasoning skill surfaces that to the user, who
earns the attribute via /accept-schema-change.

Edge semantics: `from -> to` == "from depends on to". A node's failure
propagates BACKWARD along edges to its dependents.

  analyze.py blast-radius <node>
  analyze.py degradation  <node>     (needs edge enum failure_mode: hard|soft)
  analyze.py cascade      [node]
  analyze.py hidden-coupling          (needs node tag: resources)
  analyze.py spof
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _lib as L

# Concrete extensions each mode proposes when its prerequisite is absent.
FAILURE_MODE_EXT = {
    "target": "edge", "name": "failure_mode", "shape": "enum",
    "values": ["hard", "soft"], "triggered_by": "degradation",
    "reason": ("Degradation-survival analysis must distinguish a HARD dependency "
               "(callee failure takes the caller down) from a SOFT/fallback one "
               "(caller degrades but survives). The kernel's sync|async does not "
               "capture this."),
}
RESOURCES_EXT = {
    "target": "node", "name": "resources", "shape": "tag",
    "triggered_by": "hidden-coupling",
    "reason": ("Hidden-coupling analysis needs to know which shared resources "
               "(databases, queues, caches) each component touches, so it can "
               "find components coupled through a resource with no explicit edge."),
}


def load():
    cdir = L.require_dir()
    schema = L.load_json(L.path(cdir, L.SCHEMA_FILE))
    mp = L.load_json(L.path(cdir, L.MAP_FILE))
    return cdir, schema, mp


def propose(cdir, ext):
    L.save_json(L.path(cdir, L.PROPOSED_FILE), ext)
    print("\n=== SCHEMA INSUFFICIENT — PROPOSAL ===")
    print(f"To answer this, the schema needs: {ext['target']}.{ext['name']} "
          f"({ext['shape']}" + (f": {'|'.join(ext['values'])}" if ext.get("values") else "")
          + ")")
    print(f"Why: {ext['reason']}")
    print("This proposal is staged. Present it to the user; if they agree, run "
          "/accept-schema-change to record and apply it. Nothing changed yet.")


def dependents_adjacency(edges):
    """to -> [(from, edge)]: who directly depends on each node."""
    adj = {}
    for e in edges:
        adj.setdefault(e["to"], []).append((e["from"], e))
    return adj


def reverse_reachable(start, adj):
    """All transitive dependents of `start` (failure propagates backward)."""
    seen, stack = set(), [start]
    while stack:
        cur = stack.pop()
        for dep, _e in adj.get(cur, []):
            if dep not in seen:
                seen.add(dep)
                stack.append(dep)
    return seen


def blast_radius(cdir, schema, mp, target):
    ids = {n["id"] for n in mp["nodes"]}
    if target not in ids:
        raise SystemExit(f"Unknown node {target!r}. Known: {sorted(ids)}")
    adj = dependents_adjacency(mp["edges"])
    affected = reverse_reachable(target, adj)
    print(f"BLAST RADIUS of {target!r}: {len(affected)} component(s) depend on it "
          "(directly or transitively).")
    for nid in sorted(affected):
        print(f"  - {nid}")
    if not affected:
        print("  (nothing depends on it — failing it is locally contained)")
    has_strength = "failure_mode" in schema["edge"]["attributes"]
    if affected and not has_strength:
        print("\nNote: this is the crude upper bound — every dependent is counted "
              "as if hard. /map-analyze degradation sharpens it once dependency "
              "strength (hard|soft) is earned.")


def degradation(cdir, schema, mp, target):
    ids = {n["id"] for n in mp["nodes"]}
    if target not in ids:
        raise SystemExit(f"Unknown node {target!r}. Known: {sorted(ids)}")
    if "failure_mode" not in schema["edge"]["attributes"]:
        print(f"DEGRADATION SURVIVAL of {target!r}: cannot answer yet.")
        propose(cdir, FAILURE_MODE_EXT)
        return
    # Propagate HARD failure backward only across hard edges.
    failed = {target}
    changed = True
    while changed:
        changed = False
        for e in mp["edges"]:
            if e["to"] in failed and e.get("failure_mode") == "hard" \
                    and e["from"] not in failed:
                failed.add(e["from"])
                changed = True
    failed.discard(target)
    adj = dependents_adjacency(mp["edges"])
    all_dependents = reverse_reachable(target, adj)
    survivors = all_dependents - failed
    print(f"DEGRADATION SURVIVAL of {target!r}:")
    print(f"  Hard-fail (taken down): {sorted(failed) or '—'}")
    print(f"  Survive degraded (reach {target} only via soft/fallback edges): "
          f"{sorted(survivors) or '—'}")
    missing = sum(1 for e in mp["edges"] if "failure_mode" not in e)
    if missing:
        print(f"  Caveat: {missing} edge(s) lack failure_mode and were treated as "
              "soft. Backfill them (/map-status shows the gap) to sharpen this.")


def cascade(cdir, schema, mp, target):
    sync_edges = [e for e in mp["edges"] if e.get("interaction") == "sync"]
    adj = {}
    for e in sync_edges:
        adj.setdefault(e["from"], []).append(e["to"])

    def longest_from(u, path, seen):
        best = path
        for v in adj.get(u, []):
            if v in seen:
                continue
            cand = longest_from(v, path + [v], seen | {v})
            if len(cand) > len(best):
                best = cand
        return best

    starts = [target] if target else [n["id"] for n in mp["nodes"]]
    chains = []
    for s in starts:
        chain = longest_from(s, [s], {s})
        if len(chain) >= 2:
            chains.append(chain)
    chains.sort(key=len, reverse=True)
    print("CASCADE AMPLIFICATION (synchronous failure chains):")
    if not chains:
        print("  No sync chains of length >= 2. Synchronous cascade risk is low.")
    for c in chains[:10]:
        print(f"  {' -> '.join(c)}  (depth {len(c)})")
    print("\nNote: a future retry/timeout attribute would sharpen this into "
          "amplification factors; not required for the chain structure above.")


def hidden_coupling(cdir, schema, mp, _target):
    if "resources" not in schema["node"]["attributes"]:
        print("HIDDEN COUPLING: cannot answer yet.")
        propose(cdir, RESOURCES_EXT)
        return
    edge_pairs = {frozenset((e["from"], e["to"])) for e in mp["edges"]}
    nodes = mp["nodes"]
    print("HIDDEN COUPLING (share a resource, no explicit edge):")
    found = False
    for i in range(len(nodes)):
        for j in range(i + 1, len(nodes)):
            a, b = nodes[i], nodes[j]
            shared = set(a.get("resources", [])) & set(b.get("resources", []))
            if shared and frozenset((a["id"], b["id"])) not in edge_pairs:
                found = True
                print(f"  {a['id']} <~> {b['id']} via {sorted(shared)}")
    if not found:
        print("  None found.")


def spof(cdir, schema, mp, _target):
    adj = dependents_adjacency(mp["edges"])
    ranked = []
    in_degree = {n["id"]: 0 for n in mp["nodes"]}
    for e in mp["edges"]:
        if e["to"] in in_degree:
            in_degree[e["to"]] += 1
    for n in mp["nodes"]:
        nid = n["id"]
        ranked.append((len(reverse_reachable(nid, adj)), in_degree[nid], nid))
    ranked.sort(reverse=True)
    print("SINGLE POINTS OF FAILURE (by transitive dependents, then direct):")
    shown = False
    for reach, direct, nid in ranked:
        if reach == 0 and direct == 0:
            continue
        shown = True
        print(f"  {nid}: {reach} transitive dependents, {direct} direct")
    if not shown:
        print("  No node has dependents yet.")


MODES = {
    "blast-radius": blast_radius,
    "degradation": degradation,
    "cascade": cascade,
    "hidden-coupling": hidden_coupling,
    "spof": spof,
}


def main():
    if len(sys.argv) < 2 or sys.argv[1] not in MODES:
        raise SystemExit(f"usage: analyze.py <{'|'.join(MODES)}> [node]")
    mode = sys.argv[1]
    target = sys.argv[2] if len(sys.argv) > 2 else None
    if mode in ("blast-radius", "degradation") and not target:
        raise SystemExit(f"{mode} needs a node id: /map-analyze {mode} <node>")
    cdir, schema, mp = load()
    MODES[mode](cdir, schema, mp, target)


if __name__ == "__main__":
    main()
