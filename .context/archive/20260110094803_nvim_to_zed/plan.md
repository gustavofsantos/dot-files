# Migration: Neovim to Zed

**Objective:** Port Neovim configuration to Zed, specifically focusing on keymaps, test execution, and external terminal usage.

## Context
- **Neovim Configs:**
    - Keymaps: `config/nvim/lua/config/keymaps.lua`
    - Tests: `config/nvim/lua/plugins/vim-test.lua`
    - Terminal/Tasks: `config/nvim/lua/plugins/toggleterm.lua`, `config/nvim/lua/plugins/task_runner.config.lua`
- **Zed Configs:**
    - Keymaps: `config/zed/keymap.json`
    - Tasks: `config/zed/tasks.json`
    - Settings: `config/zed/settings.json`

## Plan
- [x] Analyze Neovim Keymaps
    - [x] Read `config/nvim/lua/config/keymaps.lua`
    - [x] Identify critical custom keymaps to port.
- [x] Analyze Neovim Test & Task Configuration
    - [x] Read `config/nvim/lua/plugins/vim-test.lua`
    - [x] Read `config/nvim/lua/plugins/toggleterm.lua`
    - [x] Read `config/nvim/lua/plugins/task_runner.config.lua`
    - [x] Understand how tests are executed (commands, strategies).
- [x] Analyze Existing Zed Configuration
    - [x] Read `config/zed/keymap.json`
    - [x] Read `config/zed/tasks.json`
    - [x] Read `config/zed/settings.json`
- [x] Port Keymaps to Zed
    - [x] Map Neovim keybindings to Zed's `keymap.json`.
    - [x] Handle mode-specific bindings (Normal, Insert, Visual).
    - [x] Mapped Save/Quit (`<c-s>`, `<c-q>`, `<leader>W`, `<leader>Q`).
    - [x] Mapped Splits (`<leader>ws`, `<leader>wS`).
    - [x] Mapped Diagnostics (`[d`, `]d` etc).
- [x] Port Test/Task Execution to Zed
    - [x] Configure `tasks.json` in Zed to replicate Neovim's test running capabilities.
    - [x] Set up keybindings to trigger these tasks (`<leader>tf`, `<leader>tc`).
    - Note: `TestNearest` and `TestLast` require more complex state management/scripting which is currently out of scope.
- [x] Verify and Refine
    - [x] Review the new Zed configuration.

## Notes
- `TestNearest` is not implemented as `testfile` script does not support line numbers.
- `TestLast` is not implemented as it requires persistent state of last run test.
- `ToggleTerm` is replaced by Zed's built-in terminal toggle `ctrl-\`.
