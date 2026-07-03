---
name: datomic-console
description: Use this skill when the user wants to explore, query, or inspect data in a Datomic database via the Datomic Console — the web UI shipped with Datomic On-Prem. Covers starting the console and guiding the user through its tabs, queries, and time-travel features. Not for Datomic Cloud or for writing application code (that's clojure-datomic).
---

# Datomic Console

Web-based, **read-only** graphical UI shipped with Datomic On-Prem (`bin/console`).
Requires a running **Transactor**; connects via named *storage aliases*. Supports
time-travel (`as-of`, `since`, `history`).

## Starting the Console

```bash
# bin/console -p <port> <alias> <transactor-uri-without-db>
bin/console -p 8080 dev datomic:dev://localhost:4334/

# Multiple transactors
bin/console -p 8080 dev datomic:dev://localhost:4334/ prod datomic:sql://...
```

Then open: `http://localhost:8080/browse/`

Gotchas:
- The URI must NOT include a database name — the Console picks the DB from the UI
- The alias is just a friendly label you choose (`dev`, `staging`, `prod`)
- The Transactor must be running before starting the Console

## Guiding the user

Read [references/console-guide.md](references/console-guide.md) for the tab-by-tab
capabilities (Schema explorer, Query, Entities, Transactions, Indexes, Data sources)
and workflow recipes (time-travel debugging, cross-database joins, write-spike
investigation, entity audits). Suggest the Schema tree first, then queries.

## Hard limitations — check before promising anything

| Limitation | Details |
|---|---|
| **On-Prem only** | Not for Datomic Cloud / Ions — use Datomic REPL or ion tooling there |
| **Read-only** | Cannot transact, retract, modify data, edit schema, or excise |
| **Datalog text only** | No `d/q`/`d/pull` API calls, no Pull patterns, no `:rules` |
| **Form mode is limited** | Aggregates (`count`, `sum`) and fulltext predicates must be typed in text mode |
| **Saved queries are ephemeral** | In-memory per session — lost on page reload |
| **One transactor family** | One Console process connects to one transactor URI family |
