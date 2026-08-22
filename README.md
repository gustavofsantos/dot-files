# Dotfiles

Personal dotfiles. Everything is symlinked into `$HOME` by explicit scripts — no Stow.

## Install

```bash
./setup.sh
```

That's the only step. It's idempotent — re-run it any time. `setup.sh` delegates to
the scripts in `scripts/`: it links dotfiles into `$HOME`, seeds local-override files,
links `bin/` and XDG config, and installs the agent config — plugins, settings, and the
global Codex hook — for Claude Code, Cursor, and Codex (below).

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
3. Merges `.codex/hooks.json` into the user-level `$CODEX_HOME/hooks.json` (or
   `~/.codex/hooks.json`), preserving unrelated Codex hooks and replacing this
   hook's prior entry idempotently.

### Add a skill, subagent, hook, or theme

Everything drops directly under a plugin's matching subdirectory —
`agents/plugins/<name>/skills/<skill>/`, `agents/plugins/<name>/hooks/`,
`agents/plugins/<name>/themes/`. Commit and re-run `./setup.sh`. See
[`CLAUDE.md`](CLAUDE.md) for each type's exact frontmatter shape and per-harness quirks.

### Causality

The `causality` skill bundles a standard-library Python CLI for verified semantic-graph
retrieval, query planning, and persistent root-cause investigations. The executable, its
tests, references, and demo assets all live under
`agents/plugins/gustavofsantos/skills/causality/`, so the plugin installs as one portable
unit. The skill invokes `python3 <skill-dir>/scripts/causality`; it does not depend on a
separate PATH-visible binary.

In a project that uses Causality, create `causality.toml` and keep trusted declarative
sources under its configured `model_dir`. The command discovers configuration from the
current directory upward:

```toml
model_dir = "model"
proposals_dir = "proposals"
investigations_dir = "investigations"
sqlite_path = ".generated/causality.sqlite"

[safety]
large_table_rows = 100000000
large_table_bytes = 100000000000
```

Then verify and compile the model before using it:

```bash
CAUSALITY=/path/to/installed/causality/scripts/causality
python3 "$CAUSALITY" validate
python3 "$CAUSALITY" test
python3 "$CAUSALITY" compile
python3 "$CAUSALITY" resolve "delivery cancellations"
```

For a five-minute local trial, copy
`agents/plugins/gustavofsantos/skills/causality/assets/demo/` to a temporary directory,
enter it, and run the commands above. The demo includes a cross-domain causal path, a
current and historical binding, large-table partition metadata, an isolated concept, and
declarative regression tests.

Trusted sources remain in `model/`; agent-created relationship proposals go only to
`proposals/`, incident-specific reasoning goes to `investigations/`, and the SQLite index
is an atomically replaced build artifact. The installed skill teaches Claude Code and
Cursor to retrieve bounded neighborhoods, inspect physical scale and grain before querying,
and preserve refuted explanations across sessions.

The bundled end-to-end tests run directly with Python:

```bash
python3 agents/plugins/gustavofsantos/skills/causality/scripts/causality_test.py
```

## More

See [`CLAUDE.md`](CLAUDE.md) for the full layout: agent checks, session navigation,
token stats, the engineering knowledge base, and Neovim config.
