# Dotfiles

Personal dotfiles. Everything is symlinked into `$HOME` by explicit scripts — no Stow.

## Install

```bash
./setup.sh
```

That's the only step. It's idempotent — re-run it any time. `setup.sh` delegates to
the scripts in `scripts/`: it links dotfiles into `$HOME`, seeds local-override files,
links `bin/` and XDG config, and installs the agent config — skills, subagents,
commands, and hooks — for Claude Code and Cursor (below).

### Local overrides (never committed)

- `~/.gitconfig.local` — git `[user] email` and machine-specific git config:
  ```ini
  [user]
      email = <email>
  ```
- `~/.zshlocal` — sourced at the end of `.zprofile`; machine-specific env vars, aliases, secrets.

Both are created empty by `setup.sh` if missing.

## Agent config

Skills, subagents, commands, and hooks live once each under `agents/` —
`agents/plugins/`, `agents/agents/`, `agents/commands/`, `agents/hooks/` —
in a harness-generic form. This is the source of truth; nothing under `.claude/` or
`.cursor/` is hand-edited except `.claude/settings.json`'s `permissions`/`env`. There is
no separate "rules" mechanism — a rule is just a skill with an eager trigger description,
like any other.

### Install

`./setup.sh` runs `scripts/install-agents.sh`, which:

1. Compiles `agents/{agents,commands,hooks}` into `.claude/` (and, where a
   harness-specific block exists, `.cursor/`) via its own embedded `agents-sync`,
   `hooks-sync` subcommands.
2. Symlinks each `agents/plugins/<name>/` into `~/.claude/skills/` (a Claude Code
   skills-directory plugin) and `~/.cursor/plugins/local/` (a Cursor local plugin, read by
   both the desktop app and the CLI) — the only way skills reach either harness.
3. Symlinks subagents, commands, themes, and workflows into `~/.claude/`, and hooks into
   `~/.cursor/`.
4. Merges `.claude/settings.json` into `~/.claude/settings.json` (global wins on
   conflicts; `permissions`/`hooks` arrays are unioned).

### Add a skill, subagent, command, or hook

A skill goes under a plugin's `agents/plugins/<name>/skills/<skill>/`; everything else
drops under its matching `agents/` subdirectory. Commit and re-run `./setup.sh`.
See [`CLAUDE.md`](CLAUDE.md) for each type's exact frontmatter shape and the
per-harness compile step.

## More

See [`CLAUDE.md`](CLAUDE.md) for the full layout: agent checks, session navigation,
token stats, the engineering knowledge base, and Neovim config.
