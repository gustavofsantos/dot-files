local notes_home = os.getenv("NOTES_HOME")
local worklog = notes_home .. 'worklog.md'

local M = {}

M.navigation = {}
M.navigation.find_files = function() require("telescope.builtin").find_files({}) end

M.navigation.toggle_file_explorer = function()
  require("oil").open()
end

M.navigation.recent_files = function()
  vim.cmd("Telescope frecency workspace=CWD theme=ivy")
end

M.navigation.find_buffer = function()
  require("telescope.builtin").buffers()
end

M.navigation.live_grep = function()
  require("telescope.builtin").live_grep()
end

-- Grep only in test files
M.navigation.live_grep_tests = function()
  local builtin = require("telescope.builtin")
  local test_globs = {
    "**/*.test.*",
    "**/*.spec.*",
    "**/*_test.*",
    "**/*Test.*",
    "test/**",
    "tests/**",
    "**/__tests__/**",
  }

  builtin.live_grep({
    additional_args = function(_)
      local args = {}
      for _, glob in ipairs(test_globs) do
        table.insert(args, "-g")
        table.insert(args, glob)
      end
      return args
    end,
  })
end

-- Grep in non-test files only
M.navigation.live_grep_non_tests = function()
  local builtin = require("telescope.builtin")
  local exclude_test_globs = {
    "!**/*.test.*",
    "!**/*.spec.*",
    "!**/*_test.*",
    "!**/*Test.*",
    "!test/**",
    "!tests/**",
    "!**/__tests__/**",
  }

  builtin.live_grep({
    additional_args = function(_)
      local args = {}
      for _, glob in ipairs(exclude_test_globs) do
        table.insert(args, "-g")
        table.insert(args, glob)
      end
      return args
    end,
  })
end

M.navigation.buf_fuzzy_find = function()
  require("telescope.builtin").current_buffer_fuzzy_find()
end

M.navigation.buf_symbols = function()
  require("telescope.builtin").lsp_document_symbols()
end

M.navigation.workspace_symbols = function()
  require("telescope.builtin").lsp_dynamic_workspace_symbols()
end

M.navigation.jump_to = function()
  require("flash").jump()
end

M.navigation.mark_file = function()
  return require('harpoon'):list():add()
end

M.navigation.toggle_marks = function()
  local harpoon = require('harpoon')
  return harpoon.ui:toggle_quick_menu(harpoon:list())
end

M.navigation.jump_to_mark = function(index)
  return function()
    require('harpoon'):list():select(index)
  end
end

M.navigation.open_daily_note = function ()
  local today = os.date("%Y-%m-%d")
  local today_note = notes_home .. today
  vim.cmd(string.format("tabnew %s.md", today_note))
end

M.navigation.open_worklog = function()
  vim.cmd(string.format("tabnew %s", worklog))
end

M.navigation.split_down = function()
  vim.cmd("split")
end

M.navigation.split_right = function()
  vim.cmd("vsplit")
end

M.navigation.left = function()
  vim.cmd("NavigatorLeft")
end
M.navigation.right = function()
  vim.cmd("NavigatorRight")
end
M.navigation.up = function()
  vim.cmd("NavigatorUp")
end
M.navigation.down = function()
  vim.cmd("NavigatorDown")
end

M.lsp = require("config.lsp")

M.editor = {}

M.editor.toggle_background = function()
  if vim.o.background == "dark" then
    vim.o.background = "light"
  else
    vim.o.background = "dark"
  end
end

M.editor.format_buffer = function()
  vim.cmd("Format")
end

M.editor.toggle_formatting = function()
  vim.cmd("FormatToggle")
end

M.editor.view_diagnostics = function()
  require("telescope.builtin").diagnostics()
end

M.editor.workspace_diagnostics = function()
  require("telescope.builtin").diagnostics({ bufno = 0 })
end

M.editor.toggle_task_runner = function()
  require("overseer").toggle()
end

M.editor.run_task = function()
  vim.cmd("OverseerRun")
end

M.editor.run_last_task = function()
  vim.cmd("OverseerRestartLast")
end

M.editor.toggle_undo_tree = function()
  vim.cmd("UndotreeToggle")
end

M.editor.toggle_line_numbers = function()
  vim.cmd("set number!")
end

M.editor.toggle_relative_line_numbers = function()
  vim.cmd("set relativenumber!")
end

M.editor.run_selection_as_cmd = function()
  local function get_visual_selection()
    local saved_reg = vim.fn.getreg('"')
    local saved_regtype = vim.fn.getregtype('"')
    vim.cmd('normal! ""y')
    local selection = vim.fn.getreg('"')
    vim.fn.setreg('"', saved_reg, saved_regtype)

    return selection
  end

  local selection = get_visual_selection()
  vim.cmd("OverseerRunCmd " .. selection)
end

M.vcs = {}
M.vcs.jump_next_hunk = function()
  require("gitsigns").nav_hunk('next')
end
M.vcs.jump_prev_hunk = function()
  require("gitsigns").nav_hunk('prev')
end

M.testing = {}
M.testing.run_nearest = function()
  local cfg = require("custom_project_configs.configs")
  return require("neotest").overseer.run(cfg.get_testing_runner_params())
end

M.testing.run_file = function()
  local cfg = require("custom_project_configs.configs")
  return require("neotest").overseer.run({ vim.fn.expand("%"), env = cfg.get_testing_env() })
end

return M
