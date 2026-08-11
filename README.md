# Dotfiles

Personal dotfiles. Everything is symlinked into `$HOME` by explicit scripts — no Stow.

## Install

```bash
./setup.sh
```

That's the only step. It's idempotent — re-run it any time. `setup.sh` delegates to
the scripts in `scripts/`: it links dotfiles into `$HOME`, seeds local-override files,
links `bin/` and XDG config, and installs the agent config — plugins and settings — for
Claude Code and Cursor (below).

### Local overrides (never committed)

- `~/.gitconfig.local` — git `[user] email` and machine-specific git config:
  ```ini
  [user]
      email = <email>
  ```
- `~/.zshlocal` — sourced at the end of `.zprofile`; machine-specific env vars, aliases, secrets.

Both are created empty by `setup.sh` if missing.

## Agent config

Skills, subagents, hooks, and themes all live inside a single plugin per project at
`agents/plugins/<name>/`, hand-authored directly in each harness's native plugin shape —
there is no separate source format or compile step. This is the source of truth; nothing
under `.claude/skills/` or `.cursor/plugins/local/` is hand-edited. `.claude/settings.json`
holds the one thing that isn't plugin-scoped: `permissions`/`env`/`statusLine`/`theme`,
hand-maintained and merged into the global settings file on install. There is no separate
"rules" mechanism — a rule is just a skill with an eager trigger description, like any
other.

### Install

`./setup.sh` runs `scripts/install-agents.sh`, which:

1. Symlinks each `agents/plugins/<name>/` into `~/.claude/skills/` (a Claude Code
   skills-directory plugin) and `~/.cursor/plugins/local/` (a Cursor local plugin, read by
   both the desktop app and the CLI) — the only way a plugin's skills, agents, hooks, and
   themes reach either harness.
2. Merges `.claude/settings.json` into `~/.claude/settings.json` (global wins on
   conflicts; `permissions` arrays are unioned).

### Add a skill, subagent, hook, or theme

Everything drops directly under a plugin's matching subdirectory —
`agents/plugins/<name>/skills/<skill>/`, `agents/plugins/<name>/hooks/`,
`agents/plugins/<name>/themes/`. Commit and re-run `./setup.sh`. See
[`CLAUDE.md`](CLAUDE.md) for each type's exact frontmatter shape and per-harness quirks.

## More

See [`CLAUDE.md`](CLAUDE.md) for the full layout: agent checks, session navigation,
token stats, the engineering knowledge base, and Neovim config.
