# Datomic Console — UI guide and recipes

## Capabilities by tab

### Database selection & time travel (top bar)
Pick a **storage alias** → **DB name**, then optionally:
- **as-of** `t` value / tx entity id / calendar date → point-in-time snapshot
- **since** `t` value → only datoms added after that point
- **history** checkbox → full history database (all assertions + retractions)

### Schema explorer (upper-left tree)
All attributes organized by **namespace**. Expanding an attribute shows `:db/valueType`, `:db/cardinality`, `:db/doc`, `:db/unique`, `:db/isComponent`, `:db/index`, `:db/fulltext`. Start here before writing queries.

### Query tab
Build and execute Datalog interactively. Two synced modes:
- **Form mode**: separate `:find`, `:with`, `:where`, `:in` fields — no aggregates or rules here
- **Text mode**: raw query text — valid Datomic Datalog, copy/paste to/from application code

Key interactions: add/remove `:where` clauses with `+`/`-`; map `:in` bindings to data sources (`$` = current DB); results land in the sortable **Data Set** table; clicking an entity id jumps to the Entities tab; the combobox above the query text saves queries for the session only.

### Entities tab
Inspect one entity by entity id or `:db/ident`. All attributes shown as an expandable tree; reference attributes traverse forward, and **reverse references** (who points here) are expandable too — no reverse-lookup query needed.

### Transactions tab
Transaction history as a bar chart. Day/Hour/Minute scale → bars are transaction counts; Second scale → bars are datom counts, and clicking a bar shows the raw datoms. Click a bar to zoom in, up arrow to zoom out. Use for "was there unusual write activity that night?"

### Indexes tab
Scan the four indexes directly for ranges of data:
- **EAVT** — all datoms for an entity
- **AEVT** — all values for an attribute
- **AVET** — attribute + value lookup (requires `:db/index true` or unique) — fastest attribute+value lookup
- **VAET** — reverse refs (who references entity X)

### Data sources (lower-left panel)
Named databases or data sets injected as query inputs via `:in` (`$`, `$1`, `$2`…). Enables **cross-database queries** and in-memory relations.

## Recipes

### Find all entities of a "type" (namespace convention)
```clojure
[:find ?e
 :where [?e :user/name _]]
```

### Inspect a specific entity
Query for the id, then click it in the Data Set table → opens in Entities tab.

### Time-travel debugging
Set `as-of` to the tx id or timestamp of interest, run the query; compare with current state in a second browser tab with a different `as-of`.

### Cross-database join
1. Create two data sources (e.g. `db-v1`, `db-v2`)
2. Query tab → `:in` table → bind `$1` → `db-v1`, `$2` → `db-v2`
3. Prefix `:where` clauses explicitly:
```clojure
[:find ?e ?name
 :in $1 $2
 :where
 [$1 ?e :product/sku ?sku]
 [$2 ?e2 :legacy/sku ?sku]
 [$2 ?e2 :legacy/name ?name]]
```

### Investigate write spikes
Transactions tab → zoom Day → Hour → Minute → Second on the suspicious window → click the spike bar → inspect raw datoms.

### Audit changes to specific entities
Enable `history` and combine with the Transactions tab to see assertions/retractions over time.
