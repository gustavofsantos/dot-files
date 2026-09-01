# Datomic Pro Console compatibility

Read this reference only for advanced clauses, Console parser surprises, temporal queries, or requests for ordering/limits.

## Stable Console model

“Transactor Console” is a common informal name, but Console is a separate web application using Datomic's peer capabilities. Datomic Pro Datalog queries execute in the peer process, not in the transactor's serialized write path. A bad Console query can still exhaust the Console JVM and create heavy shared-storage I/O, so this distinction does not make broad production queries safe.

The Console Query pane holds the Datalog query vector only. Its **In** table stores each input binding separately from its value. `$` can refer to the currently selected database, while named database or data-set sources must first exist in Console's **Data sources** table.

Consequences:

- Application examples such as `(d/q '[:find ...] db)` must be reduced to `[:find ...]`.
- A parameterized query such as `[:find ?e :in $ ?email :where [?e :user/email ?email]]` is incomplete until the **In** rows bind `$` and `?email` to values.
- For a one-off query, an inline literal is usually less error-prone than requiring the user to reproduce UI input rows.
- As-of, since, and history are database selections in Console, not query wrappers.

The documented query grammar has no vector clauses for general ordering or result limiting. `:timeout`, `:limit`, `:offset`, query stats, and I/O context belong to particular API argument maps/arities. Console's table sorting happens only after results have been realized.

## Version-sensitive parser hazards

Treat these as Console parser hazards, not limitations of Datomic Datalog itself. After pasting an advanced query, compare the text Console displays with the text supplied. If Console rewrites a symbol or literal, do not trust the executed query.

### Datalog `not` clause rewritten as data

On Datomic Pro 1.0.6735, Console was reported to rewrite:

```clojure
(not [(clojure.string/includes? ?name "Foo")])
```

as:

```clojure
["not" [(clojure.string/includes? ?name "Foo")]]
```

Use a simpler Console-safe formulation when semantics permit:

- Missing attribute: `[(missing? $ ?e :domain/attribute)]`
- Value inequality after binding: `[(not= ?value "excluded")]`
- Negated boolean predicate: bind the predicate result and test it:

```clojure
[(clojure.string/includes? ?name "Foo") ?includes]
[(not ?includes)]
```

These are not universal rewrites for relational negation. An anti-join spanning multiple data patterns may genuinely require `not`/`not-join`. If the installed Console does not round-trip that clause exactly, use a Peer/Client query instead of changing its meaning.

Apply the same round-trip check to `not-join`, `or`, `or-join`, rules, and nested queries. Do not assume a workaround preserves semantics merely because it executes.

### Quoted `0x...` string rewritten as a number

On Datomic Pro 1.0.6735, Console was confirmed to rewrite the query literal `"0x1"` to numeric `1`. Avoid presenting the complete hex-looking token as one query literal. Construct it from safe pieces and bind the result:

```clojure
[(str "0" "x1") ?needle]
[?e :domain/value ?needle]
```

Split after the first character for other `0x...`/`0X...` strings. This workaround is for values whose actual schema type is string; do not use it to coerce numeric data.

## Temporal view constraints

For **History**, a data pattern may expose all five datom fields:

```clojure
[?e :domain/value ?value ?tx ?added]
```

`?added` is `true` for assertions and `false` for retractions. Pull is not supported against a history database because pull requires a single point-in-time entity view. Join any identifying attributes explicitly and include `?tx`/`?added` when the user needs event meaning.

As-of is inclusive of its boundary; since is exclusive. Set the requested t, transaction entity id, or instant in Console's database controls rather than manufacturing a database value inside the query.

## Sources

- [Datomic Pro Console documentation](https://docs.datomic.com/resources/console.html)
- [Datomic Pro clients and peers architecture](https://docs.datomic.com/reference/clients-and-peers.html)
- [Datomic query grammar](https://docs.datomic.com/query/query-data-reference.html)
- [Executing queries: API options and clause order](https://docs.datomic.com/query/query-executing.html)
- [Datomic history tutorial](https://docs.datomic.com/client-tutorial/history.html)
- [Console `not` parsing report](https://forum.datomic.com/t/datomic-console-not-parse-not-clause-correctly/2314)
- [Console `0x...` string parsing report and Datomic team confirmation](https://forum.datomic.com/t/datomic-console-parse-query-contains-hex-string-error/2313)

The two parser reports identify Console-specific bugs on Datomic Pro 1.0.6735. Datomic's published Pro changelog lists Console 0.1.233 (2022-01-05) as the last separately named Console update and does not explicitly document later fixes for these parser bugs. Keep the workarounds version-sensitive: prefer an exact round-trip on the user's installed Console when available.
