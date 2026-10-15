# mermaid-render

A Claude Code mod that draws the ` ```mermaid ` blocks in Claude's replies as
images, inline in the transcript, through the kitty graphics protocol (kitty,
Ghostty, WezTerm). Terminals without it show the source and an `[mermaid diagram]` alt.

- Each complete block is rendered with `mmdc` once, to
  `${XDG_CACHE_HOME:-~/.cache}/claude-mermaid/<hash>.png`; a resumed session draws from
  the cache.
- Under each diagram: `source` swaps back to the code block, `expand` opens it in a
  pane sized to the pane (Esc closes; `/mermaid` reopens the last one).
- With `autoRender` off, each block keeps its source with a `render diagram` button.

## Install

`setup.sh` links this folder to `~/.claude/mods/mermaid-render`, and
`.claude/settings.json` names it in `CLAUDE_CODE_PLUGIN_DIRS`. `mmdc` comes from
mise (`npm:@mermaid-js/mermaid-cli`).

## Options

Set under `pluginConfigs["mermaid-render"].options` in `~/.claude/settings.json`, or in `/config`:

| Option | Default | |
|---|---|---|
| `autoRender` | `true` | Render as soon as a block is complete |
| `command` | `mmdc` | The mermaid-cli executable |
| `puppeteerConfig` | `""` | JSON file for `mmdc -p` (e.g. a system Chromium's `executablePath`) |
| `theme` | `dark` | `dark`, `default`, `forest`, `neutral` |
| `background` | `transparent` | `mmdc -b` |
| `maxRows` | `30` | Rows a diagram takes inline at most |

## Tests

```bash
claude plugin validate .agents/mods/mermaid-render
claude plugin test .agents/mods/mermaid-render
```
