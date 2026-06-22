# system-cartographer

A Claude Code plugin that builds and reasons over a **local, machine-readable
map of a system's architecture** — its components, the typed connections
between them, and the business role each plays. The map lives in your repo under
`.cartographer/` and grows progressively as you and Claude discover dependencies
and effects (often mid-debugging). It exists to reason about **failure
propagation**: blast radius, survivable degradation, cascade amplification,
hidden coupling, and single points of failure.

## The core idea: a plugin that grows its own schema

There are two layers:

- **The kernel (fixed, ships in the plugin, identical for everyone).** The
  smallest schema that still describes a graph, *plus a meta-schema* — the
  constitution governing how the schema may grow.
- **The instance (grows locally, per repo).** The actual nodes and edges, *plus
  any schema extensions your scenario has earned.*

The same plugin on two machines diverges completely at the instance level. A
weekend project may never extend past the kernel. A production estate accretes a
rich schema over time. **Richness is earned by need, never specified up front.**

### Two principles

1. **Accretion over redefinition.** The schema is immutable-by-extension. You
   never rewrite it; you add to it and preserve *why* each addition was made.
   `schema-evolution.md` is a decision record, not a changelog.
2. **Gate on irreversibility, not volume.** Adding a node or edge is cheap and
   reversible — it flows freely. Changing the *schema shape* is high-leverage
   and semi-permanent — it requires an explicit, typed human `yes`. This
   asymmetry is enforced structurally by a hook, not by convention.

## The data model

### Kernel (the floor)

A directed typed graph. Two entities:

- **Node** — `id` (stable), `role` (free text: what it does / is source of truth for).
- **Edge** — `from`, `to`, `interaction` (`sync` | `async`). `from -> to` means
  "from depends on to". `sync`/`async` is the single most load-bearing edge
  attribute and the primary determinant of how failure propagates.

Everything else (hard/soft, retry, criticality, provenance) is **deliberately
not in the kernel.** Those are extensions to be *earned later*.

### Meta-schema (the constitution)

Growth is **open in content, closed in form.** A legal extension adds one
**optional** attribute to `node` or `edge`, in exactly one of four shapes:

| shape    | meaning                        | params              |
|----------|--------------------------------|---------------------|
| `enum`   | closed set of string values    | `values`            |
| `scalar` | one typed value                | `type` (string/number/boolean) |
| `ref`    | reference to a node id         | `ref`               |
| `tag`    | free-form set of labels        | —                   |

A `visual_intent` hint (`line-style`/`color`/`badge`) is carried but unused in
v1 — reserved for a future reflective visualizer.

Because every extension is one of four known shapes, a validator (and a future
visualizer) can be written against *any* evolved schema.

## The loop: propose → accept → record

When you ask for an analysis the current schema can't support, Claude **proposes**
a minimally-scoped extension. You **accept** it (a typed command). The acceptance
is **recorded** as a schema-evolution decision. The schema grows only when
reasoning demands it.

```
/map-analyze degradation orders-db
    └─ schema lacks hard/soft → proposes  edge.failure_mode: hard|soft
/accept-schema-change
    └─ you confirm → token minted → schema.json grows → evolution log updated
/map-status
    └─ "2 edges lack failure_mode"  (visible backfill gap, map still valid)
```

### The acceptance-token handshake (the load-bearing joint)

The schema files are protected by a `PreToolUse` hook that **denies any write by
default**. `/accept-schema-change`, *only after you confirm*, mints a single-use
acceptance token: a `sha256` of the **canonical** (sorted-keys, whitespace-free)
new schema object, plus a nonce and a short expiry. The agent then writes
`schema.json`; the hook canonicalizes the incoming content and allows the write
only if it matches the token, then consumes the token. This means:

- Casual/accidental schema edits are rejected (deny-by-default).
- Only a human-confirmed change produces a token, and a token authorizes exactly
  one write of exactly the accepted content, once.
- The hash is over the JSON *object*, so the agent may format freely — only the
  meaning must match what you accepted.

## Install

```
/plugin marketplace add gsantos/systematic
/plugin install system-cartographer@systematic
```

Hooks load at session start, so restart Claude Code (or `/reload-plugins`) after
installing before the protection is active.

## Commands

| command | purpose |
|---------|---------|
| `/cartographer-init` | scaffold `.cartographer/` (kernel schema, empty map, evolution log) |
| `/map-add-node <id> <role>` | add a component |
| `/map-add-edge <from> <to> [sync\|async]` | add a directed dependency |
| `/map-analyze <mode> [node]` | run a failure-analysis mode |
| `/map-status` | size, validity, earned extensions, backfill gaps |
| `/accept-schema-change` | the human gate — the only path that may change the schema |

Analysis modes: `blast-radius`, `degradation`, `cascade`, `hidden-coupling`,
`spof`. Each declares its prerequisite attributes and proposes the extension it
needs when the map can't yet support a sharper answer.

## What lives in `.cartographer/`

| file | role | writable |
|------|------|----------|
| `meta-schema.json` | the constitution (kernel copy) | protected |
| `schema.json` | the active evolved schema (starts == kernel) | protected (grows via `/accept-schema-change`) |
| `map.json` | the instance: nodes + edges | freely (via `/map-add-*`) |
| `schema-evolution.md` | append-only decision log of every accepted change | append-only |

## Scope (v1)

Ships the kernel, the meta-schema, the enforcement hook + token handshake,
referential-integrity validation, the five reasoning modes, and the commands and
skills for the loop. It ships **no** concrete edge attribute beyond `sync`/`async`
— `hard|soft`, retry, criticality, provenance, shared-resource modeling, and the
visualizer are all *earned later through the loop itself*, which is the point.
