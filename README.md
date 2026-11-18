# Dotfiles

Personal dotfiles. Everything is symlinked into `$HOME` by explicit scripts — no Stow.

## Install

```bash
make install     # or ./setup.sh
```

That's the only step. It's idempotent — re-run it any time. `make help` lists the
individual steps (`make agents`, `make bin`, `make config`, …); each one runs a script
in `scripts/`. `make test` runs the bats suites (`test_bin/` and the tests beside skill
scripts).

### Local overrides (never committed)

- `~/.gitconfig.local` — git `[user] email` and machine-specific git config:
  ```ini
  [user]
      email = <email>
  ```
- `~/.zshlocal` — sourced at the end of `.zprofile`; machine-specific env vars, aliases, secrets.

Both are created empty by `setup.sh` if missing.

## Agent config

Everything agent-related lives under `.agents/`, hand-authored, with no compile step:

| Source | Installed as |
|---|---|
| `.agents/skills/<name>/` | `~/.agents/skills/<name>` (shared skill directory for multi-agent discovery), and `~/.claude/skills/<name>` → that link |
| `.agents/agents/<name>.md` | `~/.claude/agents/<name>.md` (subagents; Cursor reads it too) |
| `.agents/mods/<name>/` | `~/.claude/mods/<name>` (loaded through `CLAUDE_CODE_PLUGIN_DIRS`) |

`make agents` (`scripts/install-agents.sh`) creates those links, prunes the ones whose
source is gone, merges `.claude/settings.json` into `~/.claude/settings.json` (global wins
on conflicts; `permissions` arrays are unioned), and merges `.codex/hooks.json` into
`$CODEX_HOME/hooks.json`. A real file or directory already at a destination is reported
and left alone.

The links are live: editing a `SKILL.md` applies in the next session. Re-run
`make agents` only to add or remove a skill, agent, or mod. A skill that ships a script
calls it by its installed path, `"$HOME/.agents/skills/<name>/scripts/<script>"`.

## More

See [`CLAUDE.md`](CLAUDE.md) for the full layout: agent checks, session navigation,
token stats, the engineering knowledge base, and Neovim config.
