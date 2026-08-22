---
name: ddd-survey
description: Survey a local repository and produce a strategic DDD description — bounded contexts, context map, anti-corruption layers, ubiquitous language. Use whenever the user asks to map a repo's domains, extract bounded contexts, build a context map, document ubiquitous language, or understand how a codebase decomposes — even phrased loosely as "survey this repo" or "map the contexts". Small repos are mapped fully. Large repos trigger a scoping question first.
---

# ddd-survey

Measure the repo, gate by size, then dispatch a repository-survey subagent to run a full zone-discovery + DDD analysis. Never survey inline — the exploration would flood this session's context.

## 1. Measure

```bash
bash <skill-dir>/scripts/measure-repo.sh <repo-root> [subpath]
```

Deterministic JSON: `src_files`, `loc`, `top_level_modules`, `modules` (per-dir counts).

## 2. Gate

FULL if `src_files ≤ 400` and `loc ≤ 80000` and `top_level_modules ≤ 8`. Otherwise SCOPED. The bound is what one run can map with evidence-backed claims, not a context-window limit. If the user already named a scope, skip the gate.

## 3. If SCOPED

Show the measurement and the `modules` list sorted by size as candidate scopes. Ask only: (a) which paths to map this run, (b) which to ignore. "All of it, in passes" → plan sequential runs, one scope each. Later runs receive the prior context map and extend it.

## 4. Dispatch

Spawn a subagent in a read-only research/exploration role. Brief it with `references/survey-procedure.md` verbatim. Add the target paths, the ignore paths, the repo name, the measurement JSON, the output file path, and any prior context map. Use whichever subagent fits the context for read-only exploration — the procedure is self-contained, so no specific named agent is required.

The survey is contextual knowledge, so it belongs in the vault. Default the output path to `${ENGINEERING_HOME:-$HOME/engineering}/artifacts/<YYYY-MM-DD>-<repo>-ddd-survey.md`. Never default to the repository root, and never write inside this skill directory. If the user names another path, use that one.

## 5. After

Relay the subagent's summary including stated unknowns — do not paper over them. Surface the **Fact candidates** for promotion into the knowledge base, and the **Entry points for follow-up investigation** as suggested next steps.

A survey describes system state, which is what a project brief holds. Offer to fold the contexts, the ubiquitous language, and the context map into the brief. Invoke the `project` skill to do that work. Link the survey artifact under **Key artifacts**. Do not write the brief yourself — the `project` skill owns that file.
