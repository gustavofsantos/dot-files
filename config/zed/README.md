# Zed

A port of the Neovim + tmux setup (`config/nvim`, `config/tmux`) to Zed, kept as close
as Zed allows. `link-xdg-config.sh` links this directory to `~/.config/zed`, so every file
here is live: Zed reloads `settings.json`, `keymap.json`, and `tasks.json` on save.

| File | Holds |
|---|---|
| `settings.json` | `options.lua`, the plugin options, formatters, and the theme |
| `keymap.json` | `keymaps.lua`, the plugin keymaps, and the tmux bindings |
| `tasks.json` | The tmux popups and windows, vim-test, and the rvw review queue |
| `themes/cursorized.json` | `colors/cursorized.lua` and the Ghostty cursorized palettes, light and dark |

## Layout model

A tmux pane is a Zed pane, and a tmux window is a tab in that pane. Shells and agents
are terminal tabs in the center (`ctrl-a c`, or `ctrl-a C` for `claude`), not in the
bottom dock. So `ctrl-h/j/k/l` moves between code and agents as vim-tmux-navigator did,
and `ctrl-a z` zooms. The bottom dock is the toggleterm terminal (`ctrl-t`) and where test
and review tasks print.

## tmux (prefix `ctrl-a`)

| tmux | Zed |
|---|---|
| `s` / `S` split | `pane::SplitRight` / `pane::SplitDown` |
| `c` new window | A new terminal tab in the center |
| `x` kill pane, `z` zoom | Close the tab, zoom the pane |
| `n` / `p` / `1`–`9` | Next, previous, or numbered tab (`9` is the last) |
| `C-h/j/k/l` resize | `vim::ResizePane*` |
| `C-S-Left/Right` swap window | `pane::SwapItemLeft/Right` (no prefix) |
| `o` sessionizer, sessions only | Recent projects |
| `O` sessionizer | Task `project: open`: `project-dirs \| fzf`, then `zed <dir>` |
| `a` claude-sessions | Every tab in every pane, terminals included |
| `g` lazygit, `D` lazydocker, `w` wlog | The same programs as center tasks that close on exit |
| `[` copy mode | `terminal::ToggleViMode` |
| `C-a C-a` send prefix | `ctrl-a` to the terminal, increment in the editor |
| `C-\` last pane | The previously active pane |

## Neovim (leader `space`)

| Neovim | Zed |
|---|---|
| Telescope `o` / `b` / `e` / `f` / `l` / `h` / `F3` | File finder, tab switcher, file finder (recent files first), buffer search, project search, command palette, project search for the word |
| `<leader>T` terminal buffers | `space T`: every tab, terminals included |
| oil `-` | Reveal in the project panel; `-` again closes it |
| `gr{a,d,r,i,n,t}`, `K` | The same LSP actions |
| `gf` Format | `editor::Format` (format-on-save stays off) |
| `gD` / `gK` / `]d` / `]e` | Project diagnostics, inline diagnostics, next diagnostic, next error |
| gitsigns `]h` / `[h`, `dhp`, `ghr` | Hunks: next, previous, expand, restore |
| diffview `dv`, visual `b` blame | Project diff, git blame |
| vim-test `tf` / `tl` | Task `test: file` (`testf` from `.zhelpers`), rerun |
| `<leader><leader>`, `ws`/`wS`, `W`, `Q`, `yp` | Alternate file, splits, save all, quit, copy relative path (`path:line` in visual mode) |
| flash `s` / `S` | Jump labels at word starts, grow a syntax-node selection |
| `:W`, `:Wq`, `:Qall`, … | `command_aliases` |
| Markdown `j`/`k` by display line, soft wrap | Same, by extension |

Built-in Zed vim mode already covers vim-surround (`ys`/`cs`/`ds`), Comment.nvim
(`gc`), mini.ai argument and indent text objects, and autopairs.

## Review queue (rvw)

`bin/zed-review` is the Zed side of `after/plugin/review.lua`. It runs as a task and
reads the selection from the task environment (`ZED_FILE`, `ZED_ROW`,
`ZED_SELECTED_TEXT`). The comment is typed in a Zed tab, opened with
`zed --existing --wait`: save and close the tab to queue it, or close it empty to cancel.

| Neovim | Zed |
|---|---|
| visual `<CR>` | Queue a comment on the selection (`space r a` also works in normal mode) |
| `<leader>re` | Edit the comment nearest the cursor |
| `<leader>rd` | Withdraw it (`rvw reject` with a reason, as in the Doom port) |
| `<leader>ro` location list | `path:line` list in the terminal; ctrl-click an entry to jump |
| `:ReviewSubmit` | `space r s`: pick a decision, type the summary |

Tests: `bats test_bin/zed-review.bats`.

## What Zed cannot do

- **No review signs.** Zed extensions cannot draw in the gutter, so comments are seen
  through `space r o`, not as signs. `<leader>rr` (refresh) has nothing to refresh.
- **The prefix has a timeout.** A pending `ctrl-a` fires after about one second, where
  tmux waits for the next key.
- **No sessions that outlive the editor.** A terminal tab dies with its Zed window. Keep a
  long-running agent in tmux, or in Ghostty, if it must survive an editor restart.
- **No pane picker for agents.** `claude-sessions` found agents by process. `ctrl-a a`
  lists tabs by title instead.
- **Not ported:** undotree, switch.vim, vim-test's `tv` (visit the last test), Conjure,
  nvim-lint (Vale has no built-in Zed integration), `:TaskNotes`, and csvview.
- **Terminal ctrl-h/j/k/l always move between panes.** tmux let them through to `fzf`, and
  Zed cannot tell which program runs in a terminal.
