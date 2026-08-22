# clear-writing

A portable skill for shaping technical documents in English or Brazilian Portuguese.

The skill is STE-inspired, but it is not an ASD-STE100 implementation.

Its main goal is to improve readability without changing truth, intent, or technical meaning.

## Suggested installation

Copy the `clear-writing` directory into the skill/plugin location used by your agent environment.

The exact location depends on Codex, Claude Code, Cursor, or the plugin system you use.

## Example prompts

### Shape an investigation

```text
Use clear-writing in shape mode on docs/investigation.md.

Audience: engineers and engineering managers.
Preserve technical detail.
Verify implementation claims against the repository.
Do not introduce unsupported facts.
```

### Review only

```text
Use clear-writing to review docs/design.md.
Do not edit the file.
Focus on factual risks, semantic ambiguity, structure, and terminology.
```

### Finalize

```text
Use clear-writing to finalize docs/postmortem.md.
Check claims against the repository where possible.
Keep uncertain claims uncertain.
```

### Portuguese

```text
Use clear-writing to shape docs/analise.md.

Idioma: português brasileiro.
Mantenha os termos técnicos usados no projeto.
Não transforme hipóteses em conclusões.
```

## Project configuration

Copy `.clear-writing.example.yml` to `.clear-writing.yml` and adapt it to your repository.

## Evaluation

The `evals/` directory contains small adversarial cases.

Use them to check that future edits to the skill do not introduce semantic drift.
