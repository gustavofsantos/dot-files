---
name: clojure-datomic
description: Use this skill when working with Datomic from Clojure applications, REPLs, jobs, services, migrations, or admin tooling. It covers connection setup, querying, transactions, pull patterns, time travel, schema changes, entity modeling, and practical patterns for writing clear Datomic code in idiomatic Clojure.
path:
  - "**/db/*.edn"
---

## Assumptions
- Code examples are written in Clojure.
- Examples use `datomic.client.api` naming (`d`) where possible.
- Some notes mention Peer-only concepts when behavior differs.
- Prefer pure data and small helper functions around Datomic operations.

## Key functionality

### 1. Connect and manage databases
Core tasks:
- Create a client.
- Connect to a database.
- Obtain immutable database values.
- Re-read the latest database after transactions.

```clojure
(ns app.db
  (:require [datomic.client.api :as d]))

(def cfg
  {:server-type :dev-local
   :system "dev"
   :storage-dir :mem
   :db-name "app"})

(def client (d/client cfg))
(def conn (d/connect client cfg))

(defn db []
  (d/db conn))
```

Important APIs:
- `d/client`
- `d/connect`
- `d/create-database`
- `d/delete-database`
- `d/list-databases`
- `d/db`

Guidance:
- Treat the value from `d/db` as immutable and pass it explicitly.
- Avoid hiding the database value inside global mutable state when writing query helpers.
- Recompute `d/db` after successful transactions when you need the newest basis.

### 2. Define schema clearly
Represent schema as transaction data and apply it through normal transactions.

```clojure
(def user-schema
  [{:db/ident :user/id
    :db/valueType :db.type/uuid
    :db/cardinality :db.cardinality/one
    :db/unique :db.unique/identity
    :db/doc "Stable external user id"}
   {:db/ident :user/email
    :db/valueType :db.type/string
    :db/cardinality :db.cardinality/one
    :db/unique :db.unique/identity}
   {:db/ident :user/name
    :db/valueType :db.type/string
    :db/cardinality :db.cardinality/one}
   {:db/ident :user/roles
    :db/valueType :db.type/keyword
    :db/cardinality :db.cardinality/many}])

(d/transact conn {:tx-data user-schema})
```

Core schema attributes to know:
- `:db/ident`
- `:db/valueType`
- `:db/cardinality`
- `:db/unique`
- `:db/isComponent`
- `:db/tupleAttrs`
- `:db/doc`
- `:db/index`
- `:db/noHistory`

Modeling rules:
- Use `:db.unique/identity` for natural keys and lookup refs.
- Use `:db.unique/value` only when identity semantics are not desired.
- Use refs for relationships, and `:db/isComponent true` for owned lifecycle children.
- Prefer enums as idents like `:order.status/paid`.
- Keep schema declarations versioned in code and transact them through repeatable migrations.

### 3. Write entities with transaction data
Datomic writes are data-first. Favor plain maps and vectors.

```clojure
(defn create-user-tx [{:keys [id email name roles]}]
  [{:user/id id
    :user/email email
    :user/name name
    :user/roles roles}])

(d/transact conn {:tx-data (create-user-tx user)})
```

Common transaction forms:
- Map form: `{:user/id ... :user/name ...}`
- List form: `[:db/add eid attr value]`
- Retract form: `[:db/retract eid attr value]`
- Retract entity: `[:db/retractEntity eid]`

Useful transaction features:
- Tempids.
- Lookup refs like `[:user/email "a@b.com"]`.
- Nested component maps for component entities.
- Transaction metadata via a `tx` entity.

Example with metadata:
```clojure
(d/transact
  conn
  {:tx-data
   [{:user/id user-id
     :user/email email
     :user/name name}
    {:db/id "datomic.tx"
     :audit/source :audit.source/api
     :audit/request-id request-id}]})
```

Returned data to use:
- `:db-before`
- `:db-after`
- `:tx-data`
- `:tempids`

### 4. Query with Datalog
Use `d/q` for relational reads and rule-based filtering.

```clojure
(def find-user-by-email
  '[:find ?e .
    :in $ ?email
    :where [?e :user/email ?email]])

(defn user-eid-by-email [db email]
  (d/q find-user-by-email db email))
```

Tuple, collection, and scalar shapes matter:
- `:find ?e .` returns a scalar.
- `:find [?e ...]` returns a collection.
- `:find ?e ?name` returns tuples.
- `:find (pull ?e pattern) .` returns one pulled map.

Key query features:
- `:in` inputs for dbs, scalars, tuples, collections, relations.
- `or`, `or-join`, `not`, `not-join`.
- Rules for reusable logic.
- Aggregates like `count`, `min`, `max`.
- Predicates and functions in `:where`.

Example with pull:
```clojure
(def user-view
  '[:user/id :user/email :user/name {:user/organization [:org/id :org/name]}])

(defn load-user [db email]
  (d/q
    '[:find (pull ?e pattern) .
      :in $ ?email pattern
      :where [?e :user/email ?email]]
    db
    email
    user-view))
```

Query guidance:
- Keep queries as quoted data, not string templates.
- Name reusable queries.
- Pass patterns and rules in as inputs when it improves reuse.
- Prefer pull for read models and `d/q` tuples for reporting or joins.

### 5. Read with pull and entity ids
`d/pull` is ideal for loading graph-shaped data.

```clojure
(defn user-by-id [db user-id]
  (d/pull db
          '[:db/id :user/id :user/name :user/email {:user/roles [*]}]
          [:user/id user-id]))
```

Important APIs:
- `d/pull`
- `d/pull-many`
- Lookup refs like `[:user/id some-uuid]`

Pull tips:
- Keep pull patterns explicit for stable application read models.
- Avoid `[*]` for external API payloads unless you truly want everything.
- Use nested maps for refs and component trees.
- Prefer pull over entity navigation for predictable shapes.

### 6. Use lookup refs and identities
Lookup refs remove the need to resolve entity ids in application code.

```clojure
(d/transact
  conn
  {:tx-data
   [[:db/add [:user/email "dev@example.com"] :user/name "Gus"]
    [:db/add [:user/email "dev@example.com"] :user/roles :role/admin]]})
```

Best uses:
- Upserts keyed by a unique identity attribute.
- Associating refs by domain identity instead of internal eids.
- Idempotent writes in integration flows.

### 7. Model references and components
Use refs for relationships, and components only for true ownership.

```clojure
(def order-schema
  [{:db/ident :order/id
    :db/valueType :db.type/uuid
    :db/cardinality :db.cardinality/one
    :db/unique :db.unique/identity}
   {:db/ident :order/lines
    :db/valueType :db.type/ref
    :db/cardinality :db.cardinality/many
    :db/isComponent true}
   {:db/ident :order-line/sku
    :db/valueType :db.type/string
    :db/cardinality :db.cardinality/one}
   {:db/ident :order-line/qty
    :db/valueType :db.type/long
    :db/cardinality :db.cardinality/one}])
```

Rule of thumb:
- Component means the child should not outlive the parent and can often be nested in tx data.
- Non-component ref means independent lifecycle.

Nested component write:
```clojure
(d/transact
  conn
  {:tx-data
   [{:order/id order-id
     :order/lines [{:order-line/sku "ABC"
                    :order-line/qty 2}
                   {:order-line/sku "XYZ"
                    :order-line/qty 1}]}]})
```

### 8. Handle time, history, and auditability
Datomic database values are immutable snapshots. Use alternate database values for historical reads.

Important APIs:
- `d/as-of`
- `d/since`
- `d/history`
- `d/with`

Examples:
```clojure
(defn db-as-of [conn t]
  (d/as-of (d/db conn) t))

(defn history-db [conn]
  (d/history (d/db conn)))
```

Use cases:
- Reconstruct state at a given t or tx.
- Ask what changed since a known basis.
- Inspect assertions and retractions over time.
- Implement audit views without building a second audit store.

History query example:
```clojure
(d/q
 '[:find ?v ?tx ?op
   :in $ ?email
   :where
   [?e :user/email ?email]
   [?e :user/name ?v ?tx ?op]]
 (d/history (d/db conn))
 "dev@example.com")
```

### 9. Use `d/with` for pure simulation
`d/with` lets you apply tx-data to a db value without committing it.

```clojure
(defn preview-user-name-change [db user-id new-name]
  (d/with db {:tx-data [[:db/add [:user/id user-id] :user/name new-name]]}))
```

Why it matters:
- Great for validation and decision logic.
- Useful in tests and rule evaluation.
- Keeps business logic pure before actual persistence.

### 10. Understand transaction reports
Transaction results provide enough context to build downstream workflows.

```clojure
(let [{:keys [db-after tx-data tempids]}
      (d/transact conn {:tx-data [{:user/id id :user/email email}]})]
  {:user (d/pull db-after '[:db/id :user/id :user/email] (get tempids "datomic.client/tempid"))
   :tx-data tx-data})
```

Patterns:
- Read from `:db-after` after transact.
- Use `:tempids` when you need the realized ids of newly created entities.
- Capture tx metadata for tracing and audit.

### 11. Compose small repository functions
Wrap Datomic with thin, composable functions instead of opaque abstraction layers.

```clojure
(ns app.user.repo
  (:require [datomic.client.api :as d]))

(def user-pattern
  '[:user/id :user/email :user/name])

(defn by-email [db email]
  (d/q
    '[:find (pull ?e pattern) .
      :in $ ?email pattern
      :where [?e :user/email ?email]]
    db email user-pattern))

(defn save! [conn user]
  (d/transact conn {:tx-data [{:user/id (:user/id user)
                               :user/email (:user/email user)
                               :user/name (:user/name user)}]}))
```

Preferred style:
- Read functions accept `db`.
- Write functions accept `conn` and explicit tx-data inputs.
- Return domain-shaped maps where practical.
- Keep query data near the functions that use it.

### 12. Test Datomic code effectively
Recommended layers:
- Pure tx-data builders unit tested as plain functions.
- Query tests against a real local/dev database.
- `d/with` tests for business rules without persistence.

Example ideas:
- Assert schema assumptions once in integration tests.
- Seed test data with small tx fixtures.
- Query through public repo functions, not internal query fragments only.

## Core APIs

### Client-oriented APIs
- `d/client`
- `d/create-database`
- `d/delete-database`
- `d/list-databases`
- `d/connect`
- `d/db`
- `d/transact`
- `d/q`
- `d/pull`
- `d/pull-many`
- `d/with`
- `d/as-of`
- `d/since`
- `d/history`
- `d/index-pull` (when index-oriented reads are useful)

### Common transaction concepts
- Tempids.
- Lookup refs.
- Transaction entity: `"datomic.tx"`.
- Tx report fields: `:db-before`, `:db-after`, `:tx-data`, `:tempids`.

### Peer-specific concepts to mention when relevant
- `d/entity` for lazy entity navigation.
- `d/touch` for realizing entity attributes.
- Peer API differences around connection and database lifecycle.

## Practical patterns

### Upsert by identity
```clojure
(defn upsert-user! [conn {:keys [id email name]}]
  (d/transact
    conn
    {:tx-data [{:user/id id
                :user/email email
                :user/name name}]}))
```

### Associate an existing ref by lookup ref
```clojure
(d/transact
  conn
  {:tx-data
   [{:team/id team-id
     :team/members [[:user/email "dev@example.com"]]}]})
```

### Query by enum value
```clojure
(d/q
 '[:find (pull ?e [:order/id :order/status])
   :in $ ?status
   :where [?e :order/status ?status]]
 (d/db conn)
 :order.status/paid)
```

### Simulate then commit
```clojure
(let [db (d/db conn)
      tx {:tx-data [{:inventory/sku "ABC" :inventory/count 10}]}
      preview (d/with db tx)]
  (when (seq (:tx-data preview))
    (d/transact conn tx)))
```

## Modeling guidance
- Prefer domain identities such as `:user/id`, `:order/id`, `:org/id` over leaking internal eids.
- Keep many-valued attributes for unordered sets of facts, not position-sensitive lists.
- Use separate entities when values need metadata, history, or references.
- Use tuples when composite identity or indexing is needed.
- Avoid overusing components; ownership must be real.
- Add `:db/doc` generously to schema for future maintainers.

## Query guidance
- Start from the narrowest identity attribute available.
- Keep reusable queries in vars with meaningful names.
- Use pull patterns for app-facing reads and plain tuples for analytics/reporting.
- Push filtering into Datalog before post-processing in Clojure.
- Resist translating SQL table-thinking directly; model facts and relationships instead.

## Error-handling guidance
- Treat transact failures as domain-relevant outcomes, not just infrastructure errors.
- Validate command input before transaction submission when rules are external to Datomic.
- Use `d/with` or query checks to enforce invariants before commit when appropriate.
- Include tx metadata like request ids and actor ids for traceability.

## Skill output expectations
When helping with Datomic in Clojure:
1. Prefer small, explicit namespace examples.
2. Show both tx-data and read-side code.
3. Use lookup refs and pull patterns where they simplify code.
4. Call out whether an example is client-generic or Peer-specific.
5. Favor immutable db values and pure helper functions.
6. Include schema implications when proposing model changes.

## Example namespace layout
```clojure
src/app/db.clj
src/app/user/schema.clj
src/app/user/repo.clj
src/app/user/service.clj
test/app/user/repo_test.clj
```

## What this skill should avoid
- Hiding Datomic behind a generic CRUD abstraction.
- Returning lazy peer entities from outer application layers.
- Using internal eids as public identifiers.
- Overusing `[*]` pull patterns in API boundaries.
- Mixing schema, business logic, and transport concerns in one namespace.
