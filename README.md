# Dotfiles

Personal dotfiles. Everything is symlinked into `$HOME` by explicit scripts — no Stow.

## Install

```bash
./setup.sh
```

That's the only step. It's idempotent — re-run it any time. `setup.sh` delegates to
the scripts in `scripts/`: it links dotfiles into `$HOME`, seeds local-override files,
links `bin/` and XDG config, and installs the Claude Code / Cursor plugins (below).

### Local overrides (never committed)

- `~/.gitconfig.local` — git `[user] email` and machine-specific git config:
  ```ini
  [user]
      email = <email>
  ```
- `~/.zshlocal` — sourced at the end of `.zprofile`; machine-specific env vars, aliases, secrets.

Both are created empty by `setup.sh` if missing.

## Plugins

Claude Code and Cursor config ships as four plugins under `agents/plugins/` —
`bruno`, `clojure`, `engineering`, `productivity` — each bundling its own skills, hooks,
rules, and scripts. They're served from a single local marketplace named `personal`
(`agents/plugins/.claude-plugin/marketplace.json` for Claude,
`agents/plugins/.cursor-plugin/marketplace.json` for Cursor).

### Install

`./setup.sh` installs them for both tools (via `scripts/install-claude.sh` and
`scripts/install-cursor.sh`). What each does differs:

- **Claude Code** — registers the `personal` marketplace, then `plugin install`s each
  plugin. Claude **copies** the plugin into `~/.claude/plugins/cache/personal/<name>/<version>/`
  from the repo's **committed HEAD** — not the working tree.
- **Cursor** — symlinks each plugin into `~/.cursor/plugins/local/<name>`. Edits are live.

### Use

Skills are namespaced by plugin once installed — invoke them as `/<plugin>:<skill>`:

```
/engineering:create-pull-request
/productivity:issue
/clojure:clojure-datomic
```

### Update

Because Claude installs from committed HEAD, **commit first**, then re-run install:

```bash
git commit -am "…"      # uncommitted edits are NOT loaded by Claude
./setup.sh              # or: ./scripts/install-claude.sh
```

`plugin update` is version-based and won't refresh a same-version (`1.0.0`) edit, so
`install-claude.sh` compares each plugin's pinned commit to HEAD and uninstall+reinstalls
only when they differ.

For **Cursor**, edits are live (symlinked) — just reload Cursor to pick them up.

### Add a skill or plugin

- **New skill** → drop it under the right plugin's `skills/` dir, commit, re-run `./setup.sh`.
- **New plugin** → also add it to both `marketplace.json` files and the `PLUGINS` list in
  `scripts/install-claude.sh`.

## More

See [`CLAUDE.md`](CLAUDE.md) for the full layout: agent checks, session navigation,
token stats, the engineering knowledge base, and Neovim config.
