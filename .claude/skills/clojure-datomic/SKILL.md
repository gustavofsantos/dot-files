---
name: clojure-datomic
description: Use this skill when writing or reviewing Datomic code in Clojure — schema, transactions, queries, pull patterns, time travel, migrations, or repository namespaces. It sets the house style and modeling rules; the Datomic API itself is assumed known.
---

# Datomic in Clojure — House Style

Examples use `datomic.client.api` as `d`. Call out when a pattern is Peer-only
(`d/entity`, `d/touch`, connection lifecycle differences).

## Style rules

- **Immutable db values, passed explicitly.** Read functions take `db`; write functions take `conn` plus explicit tx-data inputs. Never hide the db value in global mutable state. Recompute `d/db` after a transact when the newest basis matters — or read from the tx report's `:db-after`.
- **Data first.** Queries stay quoted data in named vars, never string templates. Pass pull patterns and rules in as `:in` inputs when it improves reuse. Tx-data builders are pure functions, unit-testable without a connection.
- **Thin repository namespaces, not CRUD abstractions.** Small composable functions that return domain-shaped maps; keep query data next to the functions that use it.

```clojure
(def user-pattern '[:user/id :user/email :user/name])

(defn by-email [db email]
  (d/q '[:find (pull ?e pattern) .
         :in $ ?email pattern
         :where [?e :user/email ?email]]
       db email user-pattern))
```

## Modeling rules

- `:db.unique/identity` for natural keys → enables lookup refs (`[:user/email "a@b.com"]`) and idempotent upserts. `:db.unique/value` only when identity semantics are not desired.
- Domain identities (`:user/id`, `:order/id`) in public surfaces — never leak internal eids.
- Refs for relationships; `:db/isComponent true` only for true ownership (child cannot outlive parent; nestable in tx data).
- Enums as idents (`:order.status/paid`). Tuples for composite identity/indexing. Many-valued attrs are unordered sets of facts, not lists.
- Schema is tx-data versioned in code, applied through repeatable migrations. Add `:db/doc` generously.

## Query & read rules

- Start `:where` from the narrowest identity attribute available; push filtering into Datalog before post-processing in Clojure.
- Pull patterns for app-facing read models (explicit, stable shapes — avoid `[*]` at API boundaries); plain tuples for reporting/joins.
- Time travel is first-class: `d/as-of` / `d/since` / `d/history` replace bespoke audit tables. `d/with` simulates a transaction purely — use it for validation, invariant checks, and tests before committing.

## Error handling

- Treat transact failures as domain-relevant outcomes, not just infrastructure errors.
- Attach tx metadata (request id, actor) via the `"datomic.tx"` entity for traceability.

## Testing layers

1. Pure tx-data builders → plain unit tests.
2. Business rules → `d/with` against a seeded db value, no persistence.
3. Queries → integration tests through public repo functions against a real dev-local db; assert schema assumptions once.

## When producing code

Show both the tx-data side and the read side; state schema implications of any model change; note client-vs-Peer applicability when it differs.
