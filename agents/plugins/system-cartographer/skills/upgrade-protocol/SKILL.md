---
name: upgrade-protocol
description: How to grow the system-cartographer schema. Use whenever an analysis or a mapping need exceeds what the current schema can express — to propose a minimally-scoped, legal schema extension and route it through human acceptance. Governs the propose -> accept -> record loop and the four legal extension shapes.
version: 1.0.0
---

# Upgrade protocol — earning schema extensions

The schema grows itself, but only when reasoning demands it and only with a
human `yes`. Richness is **earned by need, never specified up front**. This is
the loop that earns it.

## When to trigger

Propose an extension only when a concrete, requested analysis or a real mapping
fact **cannot be expressed** by the active schema (`.cartographer/schema.json`).
Two triggers:

- `analyze.py` printed a `SCHEMA INSUFFICIENT — PROPOSAL` block (the reasoning
  mode hit a wall and already staged a proposal).
- The user states a fact about a component/dependency that no current attribute
  can hold (e.g. "this call retries 3× with backoff", "these two share a Kafka
  topic"), and capturing it would change an analysis.

Do **not** propose extensions speculatively, to "round out" the schema, or
because an attribute seems generally useful. No need → no growth.

## The four legal shapes (the meta-schema bounds growth)

An extension adds **one optional attribute** to `node` or `edge`. Its shape must
be exactly one of:

- `enum` — a closed set of string values. Params: `values` (non-empty list).
  *e.g.* `edge.failure_mode: hard | soft`
- `scalar` — one typed value. Params: `type` ∈ `string | number | boolean`.
  *e.g.* `edge.timeout_ms: number`
- `ref` — a reference to a node id. Params: `ref` (e.g. `"node"`).
- `tag` — a free-form set of labels. No params.
  *e.g.* `node.resources: tag`

Optionally include `visual_intent` (`line-style` | `color` | `badge`) — carried
for a future visualizer, unused now.

Growth is **open in content, closed in form**: you may name any attribute, but
it must be one of these four shapes, it is always optional, and it never
redefines or shadows a kernel field (`id`, `role`, `from`, `to`, `interaction`).

## Scope the proposal minimally

Propose the **smallest** attribute that unblocks the specific analysis at hand —
not a richer model you imagine wanting later. If degradation analysis needs to
tell hard from soft dependencies, propose `edge.failure_mode: hard|soft` — not a
five-value criticality scale, not retry counts, not provenance. Those are
separate extensions to be earned by their own separate needs.

## Stage, then route through the gate — never write the schema yourself

1. Write the proposal to `.cartographer/.proposed-extension.json` with fields:
   `target`, `name`, `shape`, the shape's params, `reason` (why this analysis
   needs it), `triggered_by` (the reasoning mode), optional `visual_intent`.
   (When `analyze.py` raised the proposal, it already wrote this file.)
2. Tell the user what you propose and why, in one or two sentences.
3. Direct them to run **`/accept-schema-change`**. That command — not you — is
   the only sanctioned path that may write the schema. It re-presents the
   proposal, takes an explicit typed `yes`, mints the single-use acceptance
   token, applies the staged schema, and records the decision in
   `schema-evolution.md`.

**You must never** edit `.cartographer/schema.json` or `meta-schema.json`
directly (the PreToolUse guard will reject it anyway). The asymmetry is the
point: instance data flows freely; schema shape changes require the human gate.

## After acceptance

The new attribute is optional, so existing entries lack it — a visible backfill
gap, not an error. Mention `/map-status` so the user can see and fill the gap
over time, and re-run the analysis that triggered the extension to show the
sharper answer.
