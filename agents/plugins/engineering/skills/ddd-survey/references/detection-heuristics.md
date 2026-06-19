# Detection heuristics — code signals → strategic DDD patterns

How to find the patterns without reading every file. Work boundary-first: boundaries are cheaper to detect than internals and matter more to the KB.

## Finding bounded context candidates (in order of reliability)

1. **Deployment/build boundaries**: one build manifest = one candidate context. Multiple manifests in a monorepo usually mean the contexts are already physically separated.
2. **Top-level namespace/package roots**: `com.company.billing` vs `com.company.payments`; Clojure ns prefixes. Disjoint namespace trees with few cross-references are contexts.
3. **Database ownership**: distinct schemas/migration directories per module. Two modules writing the same tables = NOT separate contexts regardless of package structure — record as big ball of mud or shared kernel.
4. **Team/CODEOWNERS boundaries** if present (Conway signal).

A candidate is confirmed as a context when it has its own model of at least one business concept — not just its own folder.

## Pattern signals

| Signal in code | Likely pattern |
|---|---|
| Module A imports B's domain types directly, no translation | Conformist (A conforms to B) |
| Mapper/adapter at A's edge reshaping B's types into A's own | ACL in A against B |
| Shared library of domain types (not utils) used by ≥2 contexts | Shared kernel — record which types exactly |
| Event schemas (Avro/proto/EDN topics) consumed by many | Published language; producer is upstream |
| Versioned public API module with its own DTOs | Open host service |
| Two contexts solving the same problem with zero integration | Separate ways |
| Cross-module direct DB reads/writes | No boundary — big ball of mud, record honestly |

## Ubiquitous language extraction

- Harvest nouns from: aggregate/entity class names, event names, public API DTOs, enum values, DB table names. These are the terms the business actually pays for.
- For each context, build the term set; then **diff term sets across contexts**. Same term in two sets → read both definitions → if meanings differ, that's a collision fact (highest value output).
- Terms appearing in code but absent from events/APIs are internal jargon — record only if they encode a business rule.

## Legacy↔new migration specifics

When the repo (or pair of repos) spans a legacy platform and its replacement:
- The new platform is NOT a 1:1 reimplementation — never assume behavioral equivalence from matching names.
- Map which capability lives where TODAY: legacy-only, new-only, dual-running. Dual-running capabilities are automatic seam facts.
- Legacy event-driven flows: trace topic producers/consumers to find implicit context boundaries that the code layout hides.
- Business logic fragmented across services in the legacy side: record the fragmentation itself as a fact ("invoice-discount-logic-spreads-across-three-legacy-services") — that's exactly the cross-domain knowledge the KB exists to hold.

## Budgeting reads

Deterministic script output tells you where the mass is. Read in this order, stop when marginal facts dry up:
1. Build manifests + top-level structure (orientation, free)
2. Event/schema definitions (published language, cheap, high yield)
3. Edges: adapters, clients, mappers (ACLs, relationships)
4. Aggregate roots / core domain files of each context (invariants, terms)
5. Internals — only when a claim needs verification to be typed `verified`
