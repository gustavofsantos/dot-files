---
name: biz-workflows
description: >
  Create or maintain standalone business workflow diagrams, or consult a named or clearly
  relevant workflow when a request materially depends on it. Do not activate for ordinary
  feature work merely because it has business scope or outcomes.
---

# Business Workflows

Own the canonical business and system workflow views in
`${ENGINEERING_HOME:-$HOME/engineering}/workflows/`.

Use existing diagrams as context when the request names a workflow or cannot be interpreted
correctly without one. Read only the relevant complete files. Check material claims against
current evidence, and state any mismatch. Do not start diagram maintenance unless the user
asks for it.

## Output contract

- Keep one standalone `.mermaid` source file per view. Do not add a Markdown fence,
  frontmatter, prose, or an evidence ledger.
- Follow the existing filenames, folders, stable IDs, orientation, labels, and styles. Do
  not introduce a new taxonomy.
- Default to a business-level, end-to-end integration panorama. Show the upstream trigger,
  cross-system handoffs, and downstream business outcome.
- Use canonical business terms from the user or authoritative local sources.
- Do not show functions, handlers, jobs, namespaces, flags, or other implementation symbols
  in the panorama.
- Put requested implementation depth in a separate `*-detail.mermaid` file.

## Ground the view

State the one question the diagram must answer. Then inspect enough code, schemas, events,
traces, logs, APIs, tests, history, documents, and existing diagrams to challenge the first
flow found.

Verify every edge. Keep observed behavior, inference, and proposed behavior distinct. Never
invent an actor, object, state, rule, transition, or umbrella term. Ask the smallest question
needed when evidence cannot settle a material name or edge.

## Choose the Mermaid view

Use one abstraction level per file:

| View | Use it for | Default grammar |
|---|---|---|
| Integration | End-to-end systems and handoffs | `flowchart TB` with system or phase subgraphs |
| Choreography | Ordered messages across external boundaries | `sequenceDiagram` with external participants |
| Process | Decisions inside one system | `flowchart` with few decision nodes |
| Implementation | Handlers, modules, retries, and internal branches | separate `*-detail.mermaid` |

For an integration panorama, aim for no more than 20 nodes and five numbered stages. Use
one box per system or business stage. Label a handoff type only when it clarifies the flow.
Split the view when business scope and implementation depth would otherwise mix.

## Maintain the artifact

- **Create or reconstruct:** read one or two nearby workflow files first. Draw the complete
  business story at the chosen level.
- **Update:** read the whole file and make the smallest coherent change. Preserve unaffected
  paths and established vocabulary.
- **Merge:** merge only views that answer the same question at compatible levels. Resolve
  duplicate nodes, IDs, terms, and contradictory edges from evidence.
- **Delete:** resolve the exact target and its references. Ask before deleting the only
  valid view when scope is unclear.

## Validate

Before finishing:

1. Confirm that a business reader can grasp the whole integration without reading code.
2. Trace every edge to evidence and confirm every label uses established vocabulary.
3. Confirm that the panorama contains no implementation symbols or mixed abstraction.
4. Validate Mermaid syntax with the repository renderer or the closest available parser.
5. Confirm that the file contains only Mermaid source and follows the existing organization.
6. Report the workflow files used or changed and any uncertainty that remains.

Do not create auxiliary artifacts unless the user asks for them.
