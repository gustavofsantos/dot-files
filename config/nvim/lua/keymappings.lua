local config = require("config.init")
local utils = require("utils")
local cmd = require("cmd_palette")

-- Utils

vim.keymap.set({"n", "v", "t", "i"}, "<C-S-p>", cmd.open, { desc = "Command palette" })

cmd.add {
  name = "Buffer symbols",
  cmd = config.navigation.buf_symbols,
  category = cmd.categories.navigation }

cmd.add {
  name = "Workspace symbols",
  cmd = config.navigation.workspace_symbols,
  category = cmd.categories.navigation }


cmd.add {
  name = "Open daily journal",
  cmd = config.navigation.open_daily_note,
  category = cmd.categories.navigation }

cmd.add {
  name = "Open worklog",
  cmd = config.navigation.open_worklog,
  category = cmd.categories.navigation }

cmd.add {
  name = "Split right",
  cmd = config.navigation.split_right,
  category = cmd.categories.navigation,
  icon = "",
  keymap = "<leader>ws" }

cmd.add {
  name = "Split down",
  cmd = config.navigation.split_down,
  category = cmd.categories.navigation,
  icon = "",
  keymap = "<leader>wS" }

-- Editor
cmd.add {
  name = "Toggle background",
  cmd = config.editor.toggle_background,
  category = cmd.categories.action,
  predicate = function ()
    if vim.o.background == "dark" then
      return true
    end
    return false
  end
}


cmd.add {
  name = "Format buffer",
  cmd = config.editor.format_buffer,
  category = cmd.categories.action }

cmd.add {
  name = "Toggle auto format",
  cmd = config.editor.toggle_formatting,
  category = cmd.categories.action,
  predicate = function()
    if vim.g.disable_autoformat then return false end
    return true
  end }

cmd.add {
  name = "Run selection as cmd",
  cmd = config.editor.run_selection_as_cmd,
  mode = {"v"},
  keymap = "<c-r>",
  category = cmd.categories.action }

cmd.add {
  name = "Toggle undo tree",
  cmd = config.editor.toggle_undo_tree,
  category = cmd.categories.action,
  keymap = "<leader>u" }

cmd.add {
  name = "Toggle line numbers",
  cmd = config.editor.toggle_line_numbers,
  predicate = function() return vim.wo.number end,
  category = cmd.categories.action }

cmd.add {
  name = "Toggle relative line numbers",
  cmd = config.editor.toggle_relative_line_numbers,
  predicate = function() return vim.wo.relativenumber end,
  category = cmd.categories.action }

cmd.add {
  name = "Buffer diagnostics",
  cmd = config.editor.view_diagnostics,
  category = cmd.categories.problem }

cmd.add {
  name = "Workspace diagnostics",
  cmd = config.editor.workspace_diagnostics,
  category = cmd.categories.problem }

cmd.add {
  name = "Run task",
  cmd = config.editor.run_task,
  category = cmd.categories.action,
  keymap = "<leader>r" }

cmd.add {
  name = "Run last task",
  cmd = config.editor.run_last_task,
  category = cmd.categories.action }


-- Version control

cmd.add {
  name = "Toggle line highlight",
  cmd = utils.create_runner("Gitsigns toggle_linehl"),
  category = cmd.categories.version_control }

cmd.add {
  name = "Toggle blame",
  cmd = utils.create_runner("Gitsigns toggle_current_line_blame"),
  category = cmd.categories.version_control }

cmd.add {
  name = "Preview hunk",
  cmd = utils.create_runner("Gitsigns preview_hunk"),
  category = cmd.categories.version_control }

cmd.add {
  name = "Stage hunk",
  cmd = utils.create_runner("Gitsigns stage_hunk"),
  category = cmd.categories.version_control }

cmd.add {
  name = "Reset hunk",
  cmd = utils.create_runner("Gitsigns reset_hunk"),
  category = cmd.categories.version_control }

