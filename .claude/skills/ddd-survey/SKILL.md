---
name: ddd-survey
description: Survey a local repository and produce a strategic DDD description — bounded contexts, context map, anti-corruption layers, ubiquitous language. Use whenever the user asks to map a repo's domains, extract bounded contexts, build a context map, document ubiquitous language, or understand how a codebase decomposes — even phrased loosely as "survey this repo" or "map the contexts". Small repos are mapped fully; large repos trigger a scoping question first.
---

# ddd-survey

Shim: measure, gate, dispatch **Marco** (`agents/marco.md`). Never survey inline — the exploration would flood this session's context.

## 1. Measure

```bash
bash <skill-dir>/scripts/measure-repo.sh <repo-root> [subpath]
```

Deterministic JSON: `src_files`, `loc`, `top_level_modules`, `modules` (per-dir counts).

## 2. Gate

FULL if `src_files ≤ 400` and `loc ≤ 80000` and `top_level_modules ≤ 8`; otherwise SCOPED. The bound is what one run can map with evidence-backed claims, not a context-window limit. If the user already named a scope, skip the gate.

## 3. If SCOPED

Show the measurement and the `modules` list sorted by size as candidate scopes. Ask only: (a) which paths to map this run, (b) which to ignore. "All of it, in passes" → plan sequential runs, one scope each; later runs receive the prior context map and extend it.

## 4. Dispatch

Spawn **Marco** (Task tool) with: target paths, ignore paths, repo name, the measurement JSON verbatim, output file path (default `<repo-root>/ddd-survey.md`; ask if writing inside the repo is unwanted), and any prior context map to extend.

## 5. After

Relay the agent's summary, including its stated unknowns — do not paper over them.
