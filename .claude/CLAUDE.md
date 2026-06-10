# Engineering knowledge base

`~/engineering/` holds durable artifacts from every project. Consult it before
reading source code — the signal is already distilled.

| File/Dir | Purpose |
|----------|---------|
| `DOMAIN_MAP.md` | Domain-clustered mind map; start here |
| `*.md` (root) | Atomic knowledge notes — facts, terms, concepts |
| `issues/NNN-*.md` | Tracked work: `## Objective`, `## Scenarios`, `## Facts` |
| `spikes/NNN-*.md` | Research: `## Answer`, `## Claims` |
| `thinking/*/` | `progress.md`, `flush.md` from thinking sessions |

## Retrieval protocol

On any non-trivial task, before reading source files:

1. **Orient** — `cat ~/engineering/DOMAIN_MAP.md`
2. **Search** — `rg -il 'term1|term2' ~/engineering/ --include='*.md' -l 2>/dev/null`
3. **Peek** — extract the key section from a hit:
   ```bash
   # Root note — skip frontmatter
   awk '/^---$/{fm++;next} fm==1{next} NF{print}' file.md | head -6
   # Issue — Objective section
   awk '/^## Objective/{p=1;next} /^## /{p=0} p&&NF' file.md | head -4
   # Spike — Answer section
   awk '/^## Answer/{p=1;next} /^## /{p=0} p&&NF' file.md | head -4
   ```
4. **Code** — open source files using KB context to guide what matters

Regenerate `DOMAIN_MAP.md` manually with `fd`/`rg` when missing or stale.

## Citing KB context

Reference notes by `[[Note Title]]` and issues by `NNN`. Finn
loads note context as axioms before traversing code.
