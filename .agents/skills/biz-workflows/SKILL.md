---
name: biz-workflows
description: >
  Create or maintain standalone business workflow diagrams, or consult a named or clearly
  relevant workflow when a request materially depends on it. Not for ordinary feature work.
---

# Business Workflows

Own the canonical workflow views in `${ENGINEERING_HOME:-$HOME/engineering}/workflows/`. When
a request depends on one, read the relevant files as context and state any mismatch with
current evidence. Maintain diagrams only when asked.

## Output contract

- One standalone `.mermaid` file per view: Mermaid source only, with no fence, frontmatter,
  or prose.
- Follow existing filenames, IDs, orientation, labels, and styles. Don't add a new taxonomy.
- The default view is a business-level, end-to-end panorama: upstream trigger, cross-system
  handoffs, downstream outcome. Use `flowchart TB` with system or phase subgraphs, at most
  about 20 nodes and five numbered stages.
- Keep implementation symbols (functions, handlers, jobs, flags) out of the panorama. Put
  requested depth in a separate `*-detail.mermaid`. Use `sequenceDiagram` for
  cross-boundary choreography. Keep one abstraction level per file.
- Use canonical business terms from the user or authoritative sources.

## Ground and validate

State the one question the diagram answers. Verify every edge against code, schemas, events,
logs, or documents. Never invent an actor, state, rule, or umbrella term. Ask when the
evidence can't settle a name or edge. On update, make the smallest coherent change. Before
deleting the only view of something, ask. Validate the Mermaid syntax with the closest
available parser. Report the files you used or changed and any remaining uncertainty.
