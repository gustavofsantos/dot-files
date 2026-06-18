---
name: eng-search
description: Search the knowledge base for previous tailored context.
---
# Search Engineering Knowledge Base

Vault: `~/engineering/` — markdown notes with `[[wikilinks]]`. Layout evolves; discover structure from hits, not from memory.

Search before inventing domain context on QuintoAndar billing/fintech topics. Prefer KB over web.

## Who searches

| mira subagent | main agent |
| --- | --- |
| `/mira`, explicit delegate | exact symbol, attr, path, ticket/spike key |
| broad / multi-hop wikilink chase | one-shot confirmation |
| heavy fan-out while context is full | strong grep anchor from code |

`Task(subagent_type="mira", prompt="question, code anchors, terms tried; return cited paths, synthesis, gaps, next wikilinks")`

## grep vs QMD

Run both when it matters.

**grep** — exact tokens, Datomic attrs, function names, issue/spike ids, recent edits, or when QMD may be stale. `Grep` on `~/engineering` or `rg … ~/engineering --glob '*.md'`.

**QMD** — ranked candidates, conceptual recall. Collection: `engineering`. Snippets are leads only — `qmd get` / `Read` before claiming.

```bash
cd ~/engineering
qmd search "term anchors" -c engineering -n 10 --full-path          # fast lexical
qmd query $'intent: …\nlex: …\nvec: …' -c engineering -n 10 --full-path  # semantic; write fields yourself
```

`qmd query` slow or failing → `qmd search` + grep. Index lags disk → trust grep; `qmd update` only if user asks.

## Loop

1. Anchor from code/ticket (attrs, namespaces, keys).
2. Parallel: grep exact anchors + `qmd search` or structured `qmd query`.
3. Read top hits; prefer concept notes over issues/spikes when both match.
4. Follow `[[wikilinks]]` — grep basename if path unknown.
5. Cite paths (+ lines); separate fact from inference; say not found rather than guessing layout.
