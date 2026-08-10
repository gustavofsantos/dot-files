# Dotfiles

Personal dotfiles. Everything is symlinked into `$HOME` by explicit scripts — no Stow.

## Install

```bash
./setup.sh
```

That's the only step. It's idempotent — re-run it any time. `setup.sh` delegates to
the scripts in `scripts/`: it links dotfiles into `$HOME`, seeds local-override files,
links `bin/` and XDG config, and installs the agent config — skills, subagents,
commands, rules, and hooks — for Claude Code and Cursor (below).

### Local overrides (never committed)

- `~/.gitconfig.local` — git `[user] email` and machine-specific git config:
  ```ini
  [user]
      email = <email>
  ```
- `~/.zshlocal` — sourced at the end of `.zprofile`; machine-specific env vars, aliases, secrets.

Both are created empty by `setup.sh` if missing.

## Agent config

Skills, subagents, commands, rules, and hooks live once each under `agents/` —
`agents/skills/`, `agents/agents/`, `agents/commands/`, `agents/rules/`, `agents/hooks/` —
in a harness-generic form. This is the source of truth; nothing under `.claude/` or
`.cursor/` is hand-edited except `.claude/settings.json`'s `permissions`/`env`.

### Install

`./setup.sh` runs `scripts/install-agents.sh`, which:

1. Compiles `agents/{rules,agents,commands,hooks}` into `.claude/` (and, where a
   harness-specific block exists, `.cursor/`) via `rules-sync`, `agents-sync`,
   `hooks-sync`.
2. Symlinks skills, subagents, commands, themes, rules, and workflows into `~/.claude/`,
   and rules and hooks into `~/.cursor/`.
3. Merges `.claude/settings.json` into `~/.claude/settings.json` (global wins on
   conflicts; `permissions`/`hooks` arrays are unioned).

Skills additionally get a per-harness frontmatter transform via `skills-sync` (a
Claude-native `SKILL.md` rewritten for Cursor's narrower frontmatter), generating
`~/.cursor/skills/`.

### Add a skill, subagent, command, rule, or hook

Drop it under the matching `agents/` subdirectory, commit, and re-run `./setup.sh`.
See [`CLAUDE.md`](CLAUDE.md) for each type's exact frontmatter shape and the
per-harness compile step.

## More

See [`CLAUDE.md`](CLAUDE.md) for the full layout: agent checks, session navigation,
token stats, the engineering knowledge base, and Neovim config.
