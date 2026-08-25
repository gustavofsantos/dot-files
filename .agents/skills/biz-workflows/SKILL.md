---
name: biz-workflows
description: "Create, reconstruct, update, merge, or delete business-workflow representations as standalone `.mermaid` files. Default to business-level integration panoramas (system boundaries, numbered stages, ≤20 nodes). Use code and events only to ground edges, not to label nodes. Split engineer-facing detail into separate *-detail.mermaid files when needed."
---

# Business Workflows

Produce faithful, maintainable Mermaid views of business behavior. Spend skill context on grounding, abstraction, and validation — not on reproducing call stacks in diagram form.

## Audience and abstraction (default)

Unless the user asks for implementation detail, optimize for a **business reader** who should grasp the **whole integration in one look**.

**Default:** system-level integration panorama — who talks to whom, with what kind of handoff, in what order. Target **≤ 20 nodes** and **≤ 5 numbered stages**.

**Grounding rule:** read code, events, schemas, traces, logs, APIs, and docs to **verify** the flow. Do **not** put internal symbols (function names, job names, namespaces, feature flags, branch logic) on the diagram unless the user explicitly wants an engineer-facing view. Cite evidence in chat or a report, not on the diagram.

**Abstraction ladder** — pick one level per file. Do not mix levels without labeling the view:

| Level | Question it answers | Typical grammar |
|-------|---------------------|-----------------|
| Integration | Who integrates with whom end-to-end? | `flowchart TB` with subgraphs per system |
| Choreography | What messages cross boundaries and when? | `sequenceDiagram` with **external** participants only |
| Process | What decisions exist inside one system? | `flowchart` with a few decision nodes |
| Implementation | Which handlers or modules run? | separate `*-detail.mermaid` only when requested |

When the user asks for **integration**, **business workflow**, or **data flows between systems**, default to **Integration**. Include downstream systems that complete the business outcome when evidence supports them.

## Ground the Domain

1. Inspect the user's instructions, local conventions, existing diagrams, domain documentation, code, schemas, events, traces, logs, APIs, tests, history, and any other relevant sources available through tools or companion skills.
2. Search broadly enough to challenge the first apparent flow. Treat technical implementation names as evidence, not automatically as canonical business terms.
3. Prefer vocabulary explicitly established by the user or authoritative local sources. Preserve exact capitalization, distinctions, and bounded-context meanings.
4. Keep observed facts, reasonable inferences, and proposed behavior distinct. Never present an inference as observed behavior.
5. Never invent an actor, business object, process, event, state, transition, rule, exception, or umbrella term. When a needed name or meaning is uncertain, conflicting, or absent, ask the user the smallest concrete question that resolves it. Asking is the success path. A plausible invented name is a failure.

## Choose the Representation

Identify the **one sentence** the diagram must answer, then choose the Mermaid grammar with the closest semantics.

- Prefer the **simplest grammar** that answers that question. Rich features (`alt`, nested branches, activations, many decision nodes) belong in **detail** diagrams, not integration panoramas.
- For cross-system flows, prefer **`flowchart TB`** with subgraphs per phase or system. Match existing diagram files in the user's workflow location when present.
- Use `sequenceDiagram` when **message order across external boundaries** is the main question. Keep **one box per system**, not per internal step.
- Split incompatible concerns into separately named `.mermaid` views instead of forcing one overloaded diagram.
- Reuse the repository's supported Mermaid version and existing conventions. When grammar or renderer support is uncertain, inspect the project toolchain and consult current official Mermaid documentation, then check syntax against the actual renderer when possible.
- Do not imitate semantics Mermaid cannot faithfully express. Explain the limitation and ask whether to use an explicit approximation or a different format.

## Reference style

For integration workflows, mirror the user's established panoramas when they exist: numbered subgraphs per phase, business labels on nodes, handoff type on edges when it clarifies integration, terminal downstream stages when the story requires them. Read one or two existing workflow files in the same location before creating a new diagram.

## Respect File Organization

Before writing, discover the nearest applicable instructions and the user's existing organization for diagrams, filenames, extensions, orientation, IDs, labels, styles, themes, and abstraction level.

- Preserve that organization and style. Do not introduce a new root, taxonomy, or naming system merely because it seems cleaner.
- Choose a self-explanatory filename from grounded domain vocabulary and follow the local filename convention. Use `.mermaid` exactly.
- Engineer-facing supplements: `*-detail.mermaid` alongside the panorama file.
- If no convention exists and more than one location or naming scheme is materially plausible, ask the user before creating files.
- Keep each file standalone and limited to Mermaid diagram source: no Markdown fence, prose preface, frontmatter, evidence ledger, or generated documentation.

## Anti-patterns

- **Code dump:** diagram reads like a call stack (internal layer names chained together).
- **Missing downstream:** integration stops before a downstream system that evidence shows is part of the business outcome.
- **Wrong grammar:** `sequenceDiagram` with many `alt` blocks entirely inside one system.
- **False precision:** nodes or edges not supported by evidence.
- **Overloaded file:** integration panorama and internal branches in the same `.mermaid` file.
- **Distraction boxes:** splitting one system into many nodes when a single outcome phrase would suffice.

## Maintain Workflows

### Create or reconstruct

Before drawing:

1. **Question** — one sentence: "This diagram answers: ___"
2. **Audience** — business (default) vs engineer
3. **Boundaries** — external systems and handoffs only. Collapse internal work into one box per stage.
4. **End-to-end** — upstream trigger and downstream outcomes through the full business story
5. **Evidence** — verify each edge. List sources in chat, not on the diagram.

**Do not** on the first integration diagram:

- Branch on every status, feature flag, or error path
- Name internal jobs, handlers, or modules
- Exceed ~20 nodes without splitting into a detail file

**Do** on the first integration diagram:

- Number stages (`1 · …`, `2 · …`) for scanability
- Use domain vocabulary from the user and authoritative local sources only
- Label edges with handoff type (sync API, async event, queue, batch) when it clarifies integration
- Include terminal downstream systems when the integration story includes them

For engineer-facing views, capture alternate paths, failures, retries, and compensation in a separate `*-detail.mermaid` or when the user explicitly requests implementation depth.

### Update

Read the complete existing diagram and its surrounding conventions before editing. Preserve stable IDs, terminology, style, abstraction level, and unaffected paths. Make the smallest coherent change that reflects the new evidence or intent.

### Merge

Merge only views that answer the same semantic question at compatible abstraction levels. Reconcile duplicated nodes, ID collisions, terminology, boundaries, and contradictory paths from evidence. If two similar labels may represent different concepts, or competing flows cannot be resolved, ask the user. Preserve separate diagrams when merging would erase meaningful viewpoints.

### Delete

Resolve the exact file, node, branch, or workflow being removed. Check related diagram references and preserve unrelated content. If deletion would discard the only representation of still-valid behavior or the scope is ambiguous, ask before deleting.

## Validate the Result

Before finishing:

1. **Skim test** — can a business reader grasp the whole integration in one look without reading code?
2. Confirm every visible label is grounded in user or source vocabulary.
3. Trace every path for semantic consistency at the chosen abstraction level.
4. Confirm observed, inferred, and proposed behavior are not visually conflated.
5. Check Mermaid syntax with the repository's renderer or the closest available parser.
6. Confirm the filename explains the view, the file contains only diagram source, and the change matches the user's organization.
7. Report created, changed, merged, or deleted files and any explicitly retained uncertainties. Do not create auxiliary artifacts unless requested.
