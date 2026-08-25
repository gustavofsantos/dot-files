---
name: biz-workflows
description: "Create, reconstruct, update, merge, or delete business-workflow representations as standalone `.mermaid` files. Use when You must derive an observed workflow from code, databases, events, traces, logs, schemas, APIs, documentation, or other evidence; design a proposed workflow; maintain existing Mermaid business diagrams; or organize workflow diagrams within the user's established file structure and naming conventions."
---

# Business Workflows

Produce faithful, maintainable Mermaid views of business behavior. Use trained business-analysis and Mermaid knowledge; spend skill context on grounding, decisions, and validation rather than generic instruction.

## Ground the Domain

1. Inspect the user's instructions, local conventions, existing diagrams, domain documentation, code, schemas, events, traces, logs, APIs, tests, history, and any other relevant sources available through tools or companion skills.
2. Search broadly enough to challenge the first apparent flow. Treat technical implementation names as evidence, not automatically as canonical business terms.
3. Prefer vocabulary explicitly established by the user or authoritative local sources. Preserve exact capitalization, distinctions, and bounded-context meanings.
4. Keep observed facts, reasonable inferences, and proposed behavior distinct. Never present an inference as observed behavior.
5. Never invent an actor, business object, process, event, state, transition, rule, exception, or umbrella term. When a needed name or meaning is uncertain, conflicting, or absent, ask the user the smallest concrete question that resolves it. Asking is the success path; a plausible invented name is a failure.

## Choose the Representation

Identify the question the diagram must answer, then choose the Mermaid grammar with the closest semantics: process/control flow, lifecycle/state, interaction/choreography, journey, quantitative flow, timeline, ownership/structure, requirements, or another supported form.

- Use the richest semantic features that make the workflow more precise: boundaries, groups, decisions, concurrency, loops, alternatives, notes, activations, nested states, forks and joins, relationships, links, styling, and accessible labels as appropriate.
- Optimize for semantic fit and readability, not feature count. Split incompatible concerns into separately named `.mermaid` views instead of forcing one overloaded diagram.
- Reuse the repository's supported Mermaid version and existing conventions. When grammar or renderer support is uncertain, inspect the project toolchain and consult current official Mermaid documentation with available tools, then validate against the actual renderer when possible.
- Do not imitate semantics Mermaid cannot faithfully express. Explain the limitation and ask whether to use an explicit Mermaid approximation or a different format.

## Respect File Organization

Before writing, discover the nearest applicable instructions and the user's existing organization for diagrams, filenames, extensions, orientation, IDs, labels, styles, themes, and abstraction level.

- Preserve that organization and style. Do not introduce a new root, taxonomy, or naming system merely because it seems cleaner.
- Choose a self-explanatory filename from grounded domain vocabulary and follow the local filename convention. Use `.mermaid` exactly.
- If no convention exists and more than one location or naming scheme is materially plausible, ask the user before creating files.
- Keep each file standalone and limited to Mermaid diagram source: no Markdown fence, prose preface, frontmatter, evidence ledger, or generated documentation.

## Maintain Workflows

### Create or reconstruct

Establish scope, viewpoint, start and end boundaries, actors or owners, normal path, decisions, alternate paths, failures, retries, compensation, concurrency, and terminal outcomes from evidence. For designed workflows, ground existing terms first and confirm any genuinely new business vocabulary.

### Update

Read the complete existing diagram and its surrounding conventions before editing. Preserve stable IDs, terminology, style, abstraction level, and unaffected paths. Make the smallest coherent change that reflects the new evidence or intent.

### Merge

Merge only views that answer the same semantic question at compatible abstraction levels. Reconcile duplicated nodes, ID collisions, terminology, boundaries, and contradictory paths from evidence. If two similar labels may represent different concepts, or competing flows cannot be resolved, ask the user. Preserve separate diagrams when merging would erase meaningful viewpoints.

### Delete

Resolve the exact file, node, branch, or workflow being removed. Check related diagram references and preserve unrelated content. If deletion would discard the only representation of still-valid behavior or the scope is ambiguous, ask before deleting.

## Validate the Result

Before finishing:

1. Confirm every visible business term is grounded in user or source vocabulary.
2. Trace every path, decision, loop, concurrent branch, error path, and terminal state for semantic consistency.
3. Confirm observed, inferred, and proposed behavior are not visually conflated.
4. Validate Mermaid syntax with the repository's renderer or the closest available parser, including the target Mermaid version.
5. Confirm the filename explains the view, the file contains only diagram source, and the change matches the user's organization.
6. Report the created, changed, merged, or deleted files and any explicitly retained uncertainties; do not create auxiliary artifacts unless requested.
