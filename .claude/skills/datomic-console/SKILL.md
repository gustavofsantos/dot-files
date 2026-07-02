---
name: datomic-console
description: Use this skill when the user wants to explore, query, or inspect data in a **Datomic database via the Datomic Console** — a web-based graphical UI shipped with Datomic On-Prem.
---

**Key facts:**
- Ships with Datomic On-Prem only (`bin/console`)
- Requires a running **Transactor** to connect
- Connects to one or more transactors via named *storage aliases*
- Supports time-travel queries (`as-of`, `since`, `history`)
- Read-only UI — you cannot transact new data through the Console

***

## Starting the Console

```bash
# Basic usage
bin/console -p <port> <alias> <transactor-uri-without-db>

# Example: dev transactor on default port
bin/console -p 8080 dev datomic:dev://localhost:4334/

# Multiple transactors
bin/console -p 8080 dev datomic:dev://localhost:4334/ prod datomic:sql://...
```

Then open: `http://localhost:8080/browse/`

**Common gotchas:**
- The URI must NOT include a database name — the Console picks the DB from the UI
- The alias is just a friendly label you choose (e.g., `dev`, `staging`, `prod`)
- The Transactor must be running before starting the Console

***

## Console Capabilities

### 1. Database Selection & Time Travel
At the top bar, pick a **storage alias** → **DB name**, then optionally:
- **as-of** `t` value / tx entity id / calendar date → point-in-time snapshot
- **since** `t` value → only datoms added after that point
- **history** checkbox → full history database (all assertions + retractions)

Use case: "Show me what this entity looked like on 2024-01-15" → pick `as-of` with the date.

### 2. Schema Explorer (upper-left tree)
Displays all attributes organized by **namespace**. Expanding an attribute shows:
- `:db/valueType`
- `:db/cardinality` (`:db.cardinality/one` or `/many`)
- `:db/doc`, `:db/unique`, `:db/isComponent`, `:db/index`, `:db/fulltext`, etc.

Use this to understand the schema before writing queries.

### 3. Query Tab
Build and execute **Datalog queries** interactively.

Two modes (kept in sync):
- **Form mode**: separate `:find`, `:with`, `:where`, `:in` fields + combo boxes
- **Text mode**: edit raw query text directly — copy/paste to/from application code

Key interactions:
- Add/remove `:where` clauses with `+` / `-` buttons
- Specify `:in` bindings and map them to data sources (use `$` for current DB)
- Results shown in the **Data Set** table (lower right) — sortable by column
- Click on an entity id (non `:db.part/db` partition) → jumps to Entities tab
- Temporarily save/reload queries with the combobox above the query text box

**Example Datalog query (text mode):**
```clojure
[:find ?e ?name ?email
 :where
 [?e :user/name ?name]
 [?e :user/email ?email]]
```

### 4. Entities Tab
Inspect a single entity by its **entity id** (long integer) or **`:db/ident`** value.

- Shows all attributes and values as a tree
- Reference attributes are expandable → traverse the entity graph in any direction
- Reverse references (entities that point TO this entity) are also expandable

Use case: "What are all the attributes of entity `17592186045418`?"

### 5. Transactions Tab
Visualize the **transaction history** as a bar chart across time scales:
- **Day / Hour / Minute** scale → bars = number of transactions
- **Second** scale → bars = number of datoms processed

Click a bar to zoom in; click the up arrow to zoom out. At Second scale, clicking a bar shows the raw datoms in the Data Set table.

Use case: "Was there unusual write activity on the night of 2024-03-10?"

### 6. Indexes Tab
Directly scan Datomic's four indexes for ranges of data:
- **EAVT** — entity-first (all datoms for an entity)
- **AEVT** — attribute-first (all values for an attribute)
- **AVET** — attribute + value lookup (requires `:db/index true` or unique attribute)
- **VAET** — reverse reference index (who references entity X)

Use case: "List all entities where `:order/status` = `:order.status/pending`" → AVET index.

### 7. Data Sources
Named values (databases or data sets) that can be injected as query inputs.

- Create with `+` button in the lower-left panel
- Reference via `:in` bindings as `$`, `$1`, `$2`, ...
- Allows **cross-database queries**: bind two databases and join across them
- Data set sources can be used as in-memory relations in queries

***

## Limitations (Important for Agent Awareness)

| Limitation | Details |
|---|---|
| **On-Prem only** | Not available for Datomic Cloud / Ions — use Datomic REPL or ion tooling there |
| **Read-only** | Cannot transact, retract, or modify data |
| **No REPL / code execution** | Only Datalog query syntax — no `d/q`, `d/pull`, `d/pull-many` API calls |
| **No Pull API** | Cannot use `(pull ?e [*])` patterns in the Console query tab |
| **No aggregates in form mode** | Aggregates (`count`, `sum`, `max`) must be written in text mode |
| **No rules** | Datalog `:rules` not supported in the Console query builder |
| **Saved queries are ephemeral** | Saved queries are in-memory per session — lost on page reload |
| **Single transactor group** | One Console process connects to one transactor URI family |
| **No schema editing** | Schema inspection only — no attribute installation or alteration |
| **No fulltext search UI** | Fulltext predicates (`(fulltext $ :attr "term")`) must be typed manually in text mode |
| **No excision** | Cannot invoke `datomic.api/excise` from Console |

***

## Workflow Recipes

### Find all entities of a "type" (by namespace convention)
```clojure
;; Find all entities that have a :user/* attribute
[:find ?e
 :where [?e :user/name _]]
```

### Inspect a specific entity
1. Run a query to find the entity id
2. Click the entity id in the Data Set table → automatically opens in Entities tab

### Time-travel debugging
1. Set `as-of` to the transaction id or timestamp of interest
2. Run your query or inspect the entity
3. Compare with the current DB by opening a second browser tab with a different `as-of`

### Cross-database join
1. Create two data sources in the lower-left panel (e.g., `db-v1`, `db-v2`)
2. In Query tab → `:in` table → bind `$1` → `db-v1`, `$2` → `db-v2`
3. Write `:where` clauses with explicit `$1` and `$2` prefixes:
```clojure
[:find ?e ?name
 :in $1 $2
 :where
 [$1 ?e :product/sku ?sku]
 [$2 ?e2 :legacy/sku ?sku]
 [$2 ?e2 :legacy/name ?name]]
```

### Investigate write spikes
1. Go to Transactions tab
2. Navigate to the suspicious day → click to zoom to Hour → Minute → Second
3. At Second scale, click a spike bar → inspect raw datoms in Data Set table

***

## Tips for Effective Use

- **Start with the Schema tree** before querying — understand attribute namespaces and value types
- **Entity IDs are clickable** in Data Set results — faster than copying IDs to the Entities tab
- **Use `history` + Transactions tab together** to audit changes to specific entities over time
- **Copy queries from Console to code** — the text mode query is valid Datomic Datalog, paste directly into `(d/q ...)`
- **AVET index** is your fastest lookup for attribute+value combos (only works on indexed/unique attributes)
- **Reverse references in Entities tab** eliminate the need to write reverse-lookup queries manually

***

## What This Skill Does NOT Cover

- Datomic Cloud / Ions console (AWS-based; different tooling)
- `datomic.client.api` (Cloud API) — that's a separate skill domain
- Schema installation or migration via transact
- Peer library (`datomic.api`) usage in application code
- Datomic Pro vs. Starter edition differences
