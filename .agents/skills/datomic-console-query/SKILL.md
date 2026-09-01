---
name: datomic-console-query
description: Produce or repair Datomic Pro Console Datalog queries that can be pasted into the browser Console Query pane. Use for ad-hoc current, as-of, since, or history inspection and for converting application or REPL queries to Console form. Do not use for Peer/Client API query code or transactions.
---

# Datomic Console Query

Produce a Console-native query, not a Clojure API call.

## Ground the query

- Inspect the repository's schema and existing queries before drafting. Search exact attribute idents and schema declarations such as `:db/ident`, `:db/valueType`, `:db/cardinality`, `:db/unique`, `:find`, and calls to `d/q` or `datomic.api/q`.
- Verify every referenced attribute's ident, value type, cardinality, uniqueness, and relationship direction. Reuse the repository's naming and query idioms when they are Console-compatible.
- Do not invent schema. If the needed idents or types cannot be established, ask for them or leave clearly marked placeholders outside the pasteable query.
- Determine whether the user needs the current, as-of, since, or history database. Console chooses temporal database views in its UI; never embed `d/as-of`, `d/since`, or `d/history` in the query.

## Output contract

- Put the pasteable artifact first: one fenced `clojure` block containing exactly one unquoted vector beginning with `[:find`.
- Do not put `(d/q ...)`, `(d/query ...)`, a quote, `def`, `require`, `db`, `conn`, an API argument map, prose, or comments inside that block.
- For a one-off Console query, prefer literal EDN values in clauses and omit `:in` when the selected current database is the only input.
- If scalar, collection, tuple, relation, rule, or additional database inputs are genuinely needed, include `:in` in the vector and follow the block with a compact **Console input rows** table containing every binding and value the user must add. Bind `$` to `$` when the current selected database is explicit.
- If a temporal view is required, follow the block with the exact Console control to set: **As of**, **Since**, or **History**.
- Keep any explanation after the artifact short and separate from it.

## Enforce the Console boundary

- Use vector query form. The Query pane is not a REPL and does not accept surrounding Clojure evaluation forms.
- Do not add `:limit`, `:offset`, `:timeout`, `:query-stats`, `:io-context`, or `:order-by` to the query vector. They are API controls or are not Datomic query grammar. Console can sort an already realized result in the UI, but that is not query ordering or limiting.
- Do not fake a row limit with `(max n ?x)` or `(min n ?x)`; those are collection-returning aggregates, not a general result limit. Narrow a Console query with selective facts or state that the requested operation requires the Peer/Client API.
- On a large or production database, anchor the first clause with an exact unique/indexed value or another genuinely selective fact. Console cannot cap work before realizing an otherwise broad result.
- Do not reference application aliases or helpers such as `d/...`, `str/...`, or project namespaces. Console runs on its own classpath. Prefer data patterns and documented Datomic query functions; otherwise use a fully qualified function known to exist in Console's runtime.
- When **History** is selected, do not use `pull`. Return datom components such as `?e`, `?value`, `?tx`, and `?added`; history includes both assertions and retractions.
- If the query needs `not`, `not-join`, `or`, `or-join`, rules, a nested query, or a literal string beginning with `0x`/`0X`, read [references/console-compatibility.md](references/console-compatibility.md) before writing it.
- If the request cannot be expressed faithfully in Console, say so. Provide the nearest safe Console query or a separately labeled API alternative only when useful; never mix the two syntaxes in one pasteable block.

## Static review before answering

Check the final vector as Console input, not merely as application Datalog:

- Every `:find` and `:with` variable is bound by `:where` or `:in`.
- Every predicate consumes variables bound by an earlier selective clause unless it intentionally binds an output.
- Literals match the schema value types; reference direction and cardinality are correct.
- The most selective data patterns precede broad scans and transformations.
- No wrapper, quote, API option, project-local symbol, hidden input, or Console parser hazard remains.
- The query is complete and immediately pasteable; placeholders exist only if missing schema made a real query impossible.

Do not claim the query was executed unless it was actually run against the target Console/database. When repairing a failure, change the smallest necessary part and identify whether the cause was Console form, Console rewriting, Datalog binding, schema/type mismatch, temporal view, or query breadth.
