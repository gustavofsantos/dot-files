local M = {}
M.__mappings = {}

M.categories = {
  action = "action",
  testing = "testing",
  navigation = "navigation",
  vcs = "vcs",
  lsp = "lsp",
  problem = "problem",
}

local category_icon = {
  action = { icon = "", color = "TelescopeResultsVariable" },
  testing = { icon = "", color = "TelescopeResultsVariable" },
  navigation = { icon = "", color = "TelescopeResultsLineNr" },
  vcs = { icon = "", color = "TelescopeResultsLineNr" },
  lsp = { icon = "󰀫", color = "TelescopeResultsLineNr" },
  problem = { icon = "", color = "TelescopeResultsLineNr" },
}


---@param cmd string
local execute_cmd = function(cmd)
  vim.cmd(cmd)
end


local function get_icon_display(option)
  local icon = option.icon or category_icon[option.category].icon or ""
  local color = category_icon[option.category].color or "TelescopeResultsLineNr"

  return { icon, color }
end

local get_toggle_display = function(option)
  if not option.predicate then return { "  " } end

  if option.predicate() then
    return { " ", "DiagnosticHint" }
  else
    return { " ", "TelescopeResultsComment" }
  end
end


M.add = function(opts)
  local name = opts.name                     -- string
  local cmd = opts.cmd                       -- string or function
  local category = opts.category or "action" -- string or nil
  local icon = opts.icon or nil              -- string or nil
  local predicate = opts.predicate or nil    -- function or nil
  local keymap = opts.keymap or nil          -- string or nil
  local mode = opts.mode or "n"              -- string or list of strings
  local buffer = opts.buffer or nil

  if keymap ~= nil then
    vim.keymap.set(mode, keymap, cmd, { desc = name, buffer = buffer, noremap = true, silent = true })
  end

  table.insert(M.__mappings,
    { name, cmd = cmd, category = category, icon = icon, keymap = keymap, predicate = predicate })
end

M.open = function()
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local themes = require("telescope.themes")
  local conf = require("telescope.config").values
  local entry_display = require("telescope.pickers.entry_display")
  local dropdown_theme = themes.get_dropdown({})
  local opts = {}

  local displayer = entry_display.create({
    separator = " ",
    items = {
      { width = 1 },
      { width = 2 },
      { width = 58 },
      { remaining = true },
    },
  })

  local function make_display(entry)
    return displayer({
      get_icon_display(entry.value),
      get_toggle_display(entry.value),
      entry.value[1],
      { entry.value.keymap or "", "TelescopeResultsComment" },
    })
  end

  pickers
      .new(dropdown_theme, {
        prompt_title = "Mission Control",
        prompt_prefix = " ",
        sorter = conf.generic_sorter(opts),
        finder = finders.new_table({
          results = M.__mappings,
          entry_maker = function(option)
            return {
              value = option,
              display = make_display,
              ordinal = option[1],
              cmd = option.cmd,
            }
          end,
        }),
        attach_mappings = function(prompt_bufnr, map)
          actions.select_default:replace(function()
            actions.close(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            if type(selection.cmd) == "function" then
              selection.cmd(opts)
            else
              execute_cmd(selection.cmd)
            end
          end)

          return true
        end,
      })
      :find()
end

return M
