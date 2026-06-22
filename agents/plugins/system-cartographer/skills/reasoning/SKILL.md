---
name: reasoning
description: Interpret system-cartographer failure analyses and reason about failure propagation across interdependent systems. Use when answering questions about blast radius, degradation/survivability, cascade amplification, hidden coupling, or single points of failure over a .cartographer/ map, or when interpreting analyze.py output. Each mode declares the schema attribute it needs and proposes an extension (via upgrade-protocol) when the map can't yet support a sharper answer.
version: 1.0.0
---

# Reasoning over the system map

The map is a **directed typed graph**. Edge `from -> to` means **"from depends
on to."** Failure therefore propagates **backward** along edges: when a node
fails, its *dependents* (predecessors) are affected.

Run modes with `analyze.py` (or `/map-analyze`). Each mode runs on whatever the
schema currently supports and **degrades gracefully** — a richer map gives a
sharper answer. When a mode needs an attribute the schema lacks, it does not
guess: it stages a minimal extension proposal and you route it through the
`upgrade-protocol` skill (→ `/accept-schema-change`). Never invent the missing
attribute's values; earn the attribute first.

## The five modes

### blast-radius `<node>`
Everything that transitively **depends on** the node — reverse-reachability
following edges backward. Crude on the kernel (every dependent counted as if
hard). **Sharpened by** `edge.failure_mode: hard|soft` (then use `degradation`
to separate true casualties from survivors).

### degradation `<node>`
Which dependents are taken down vs survive degraded when the node fails.
**Prerequisite:** `edge.failure_mode` (enum `hard|soft`). Missing → propose it.
A dependent survives if every path it has to the failed node passes through at
least one `soft`/fallback edge; it hard-fails if any all-`hard` path reaches it.

### cascade `[node]`
Synchronous failure chains — paths of `sync` edges, where failure propagates
without buffering. Runs on the kernel (`interaction`). A future retry/timeout
scalar would turn chain structure into amplification factors, but is not
required to surface the chains.

### hidden-coupling
Components that share a resource but have **no explicit edge** — coupling the
graph doesn't show. **Prerequisite:** a way to model shared resources, e.g.
`node.resources: tag`. Missing → propose it. With it, report node pairs sharing
a tag value and not directly connected.

### spof
Single points of failure — nodes the most dependencies converge on, ranked by
size of their transitive-dependent set (then direct in-degree). Runs on the
kernel; a large blast radius + central position flags a SPOF.

## Interpreting and answering

- Lead with the **business consequence**, using each node's `role` (what it is
  source-of-truth for), not just ids. "Orders DB failing takes the checkout API
  down (hard, sync) but the recommendations widget degrades and survives."
- Be **honest about unknowns.** If many edges lack an earned attribute (see the
  caveats analyze.py prints and `/map-status` backfill gaps), say the answer is
  provisional and offer to backfill — don't present a partial map as complete.
- If the analysis is blocked by a missing attribute, switch to the
  `upgrade-protocol` skill: present the staged proposal and point the user to
  `/accept-schema-change`. Do not fabricate the answer.
