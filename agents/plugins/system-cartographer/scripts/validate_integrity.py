#!/usr/bin/env python3
"""Referential-integrity validator — the graph checks JSON Schema can't express.

  - every edge's `from`/`to` resolves to a declared node (dangling -> error)
  - any earned `ref`-shaped attribute resolves to a declared node (dangling -> error)
  - reports SPOFs (nodes many dependencies converge on) and cycles (informational)

Errors (dangling endpoints) exit 1; SPOF/cycle reports are warnings (exit 0).
Invoked by the PostToolUse hook after instance writes, and by /map-status.

Edge semantics: `from -> to` means "from depends on to". Failure therefore
propagates BACKWARD along edges (from a failed node to its dependents).
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _lib as L


def find_cycles(node_ids, edges):
    """Return a list of cycles (each a list of node ids) via DFS. Best-effort."""
    adj = {nid: [] for nid in node_ids}
    for e in edges:
        if e.get("from") in adj and e.get("to") in adj:
            adj[e["from"]].append(e["to"])

    cycles, color, stack = [], {}, []

    def dfs(u):
        color[u] = "gray"
        stack.append(u)
        for v in adj[u]:
            if color.get(v) == "gray":
                if v in stack:
                    cycles.append(stack[stack.index(v):] + [v])
            elif color.get(v) != "black":
                dfs(v)
        stack.pop()
        color[u] = "black"

    for nid in node_ids:
        if color.get(nid) != "black":
            dfs(nid)
    return cycles


def analyze(schema, mp):
    errors, warnings = [], []
    nodes = mp.get("nodes", [])
    edges = mp.get("edges", [])
    node_ids = {n.get("id") for n in nodes if n.get("id")}

    # Dangling edge endpoints.
    for i, e in enumerate(edges):
        for end in ("from", "to"):
            ref = e.get(end)
            if ref not in node_ids:
                errors.append(f"edge[{i}].{end} -> {ref!r} is not a declared node")

    # Dangling earned ref attributes.
    ref_attrs = {kind: [name for name, a in schema[kind]["attributes"].items()
                        if a.get("shape") == "ref"]
                 for kind in ("node", "edge")}
    for kind, coll in (("node", nodes), ("edge", edges)):
        for i, entry in enumerate(coll):
            for name in ref_attrs[kind]:
                if name in entry and entry[name] not in node_ids:
                    errors.append(
                        f"{kind}[{i}].{name} -> {entry[name]!r} is not a declared node")

    # SPOF report: in-degree = how many components directly depend on a node.
    in_degree = {nid: 0 for nid in node_ids}
    for e in edges:
        if e.get("to") in in_degree:
            in_degree[e["to"]] += 1
    spofs = sorted((d, nid) for nid, d in in_degree.items() if d >= 2)
    spofs.reverse()
    for d, nid in spofs:
        warnings.append(f"SPOF candidate: {nid!r} has {d} direct dependents")

    # Cycles (informational — circular dependencies are worth surfacing).
    for cyc in find_cycles(node_ids, edges):
        warnings.append("cycle: " + " -> ".join(cyc))

    return errors, warnings


def main():
    cdir = L.require_dir()
    schema = L.load_json(L.path(cdir, L.SCHEMA_FILE))
    mp = L.load_json(L.path(cdir, L.MAP_FILE))
    errors, warnings = analyze(schema, mp)

    for w in warnings:
        print(f"NOTE  {w}")
    for e in errors:
        print(f"ERROR {e}")
    if not errors:
        print("Referential integrity OK.")
    sys.exit(1 if errors else 0)


if __name__ == "__main__":
    main()
