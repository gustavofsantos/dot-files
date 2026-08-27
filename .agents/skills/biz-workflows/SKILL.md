---
name: biz-workflows
description: "Use when a request depends on business scope, vocabulary, boundaries, handoffs, or outcomes, or when the user asks to maintain a business-workflow diagram. Read relevant durable diagrams to orient the current session. Create, reconstruct, update, merge, or delete standalone `.mermaid` files in `~/engineering/workflows/` by default. Use business-level integration panoramas by default. Keep engineer-facing detail in separate `*-detail.mermaid` files."
---

# Business Workflows

Use Mermaid views of business behavior as durable context for both the user and future agents. They have two equal purposes:

1. Orient the current session around the relevant business scope before interpreting requests or implementation evidence.
2. Give the user a faithful, maintainable view of the business behavior.

Spend skill context on grounding, abstraction, and validation — not on reproducing call stacks in diagram form.

## Workflow vault

The vault is `$ENGINEERING_HOME`, which defaults to `~/engineering`. Store and maintain workflow diagrams under `workflows/`. Every path below is relative to the vault.

- Keep each workflow as a standalone `.mermaid` file in `workflows/`.
- Treat that directory as the canonical durable home even when the evidence lives in an application repository.
- Follow established filenames and organization already present in `workflows/`. Do not introduce a new taxonomy merely because it seems cleaner.
- When the user explicitly targets a different file, respect that target. Do not silently copy or move it into the vault.

## Orient the current session

When this skill applies, use existing diagrams before deciding what the user means by a business process, system, handoff, actor, or outcome:

1. Extract the likely business scope and vocabulary from the user's request and current working context.
2. Search `workflows/` by filename and content for those terms. Read the complete relevant diagrams. Do not load unrelated workflows merely because they share a technical system.
3. Use the diagrams to establish the session's business boundaries, canonical terms, upstream triggers, external handoffs, and downstream outcomes. Carry that orientation into code reading, planning, explanations, and diagram maintenance during the current session.
4. Treat diagrams as maintained context, not unquestionable truth. Check material claims against current authoritative evidence when the task depends on present behavior. If the diagram conflicts with the user's request or current evidence, state the mismatch and resolve it instead of silently choosing one account.
5. If no relevant diagram exists, continue from grounded sources. Create one only when the user asks for it or the request already includes that work.

In the final response, name the workflow files that materially oriented the work or that changed. This makes the business context visible to the user and reusable by the next agent.

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
2. Search broadly enough to challenge the first flow you find. Treat technical implementation names as evidence, not automatically as canonical business terms.
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

For integration workflows, mirror the user's established panoramas when they exist. Use numbered subgraphs per phase and business labels on nodes. Add handoff types on edges when they clarify the integration. Include terminal downstream stages when the story requires them. Read one or two existing workflow files in the same location before creating a new diagram.

## Respect File Organization

Before writing, inspect `workflows/`, discover the nearest applicable instructions, and learn the existing organization for filenames, orientation, IDs, labels, styles, themes, and abstraction level.

- Preserve that organization and style. Do not introduce a new root, taxonomy, or naming system merely because it seems cleaner.
- Choose a self-explanatory filename from grounded domain vocabulary and follow the local filename convention. Use `.mermaid` exactly.
- Engineer-facing supplements: `*-detail.mermaid` alongside the panorama file.
- If no filename convention exists and more than one naming scheme is materially plausible, ask the user before creating files. The location remains `workflows/` unless the user explicitly supplies another target.
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

Merge only views that answer the same semantic question at compatible abstraction levels. Reconcile duplicated nodes, ID collisions, terminology, boundaries, and contradictory paths from evidence. Ask the user if two labels may represent different concepts or if the evidence does not resolve competing flows. Preserve separate diagrams when merging would erase meaningful viewpoints.

### Delete

Resolve the exact file, node, branch, or workflow that the user wants to remove. Check related diagram references and preserve unrelated content. Ask before deletion if it would discard the only view of valid behavior or if the scope is unclear.

## Check the Result

Before finishing:

1. **Skim test** — can a business reader grasp the whole integration in one look without reading code?
2. Confirm every visible label comes from user or source vocabulary.
3. Trace every path for semantic consistency at the chosen abstraction level.
4. Confirm observed, inferred, and proposed behavior are not visually conflated.
5. Check Mermaid syntax with the repository's renderer or the closest available parser.
6. Confirm the filename explains the view, the file contains only diagram source, and the change matches the user's organization.
7. Report created, changed, merged, or deleted files and any explicitly retained uncertainties. Do not create auxiliary artifacts unless requested.
