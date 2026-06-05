# Engineering knowledge base

`~/engineering/` holds durable artifacts from every project. Consult it before
reading source code — the signal is already distilled.

| File/Dir | ID format | Purpose |
|----------|-----------|---------|
| `DOMAIN_MAP.md` | — | Domain-clustered mind map; start here for orientation |
| `INDEX.md` | — | Flat one-line-per-artifact list |
| `issues/` | `NNN` | `## Objective`, `## Executive Summary`, `## Scenarios`, `## Facts` |
| `facts/` | `FACT-NNN` | `## Statement`, `## Evidence` |
| `spikes/` | `NNN` | `## Answer`, `## Claims`, `## High-signal files` |
| `thinking/` | (topic dirs) | `progress.md`, `flush.md` |
| `terms/GLOSSARY.md` | — | Ubiquitous language; defines canonical domain names |

## Retrieval protocol

On any non-trivial task, before running `rg` or reading source files:

```bash
# Domain map — compact, domain-clustered view; read this first
cat ~/engineering/DOMAIN_MAP.md

# Full flat list — one line per artifact
cat ~/engineering/INDEX.md

# Find artifacts matching the task domain (terms are OR'd)
kb-search auth token

# Read just the key signal from one file without opening the whole thing
kb-peek ~/engineering/issues/042-auth-refresh.md
```

**Step 1 — orient:** `cat DOMAIN_MAP.md` to understand which domain is relevant. It fits in one screen and shows which facts/issues belong together.  
**Step 2 — list:** `cat INDEX.md` for a flat artifact list if you need breadth.  
**Step 3 — filter:** `kb-search` with 2–3 domain terms for keyword-targeted hits.  
**Step 4 — confirm:** `kb-peek` any promising file before committing to a full read.  
**Step 5 — code:** only then open source files, using facts and issue context to guide what matters.

If `DOMAIN_MAP.md` is missing or stale, run `kb-map` to regenerate it.  
If `INDEX.md` is missing or stale, run `kb-index` to regenerate it.

## Citing KB context

Reference facts as `FACT-NNN` and issues by their numeric ID. The `dead-reckoning`
agent loads facts as axioms before traversing code — don't re-derive what's already
in `~/engineering/facts/`.
