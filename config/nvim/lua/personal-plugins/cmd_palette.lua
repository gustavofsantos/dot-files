--- Command Palette Plugin for Neovim
--- A VS Code-like command palette implementation using Telescope
---
--- @class CommandPalette
--- @field private _mappings table[] Internal storage for command mappings
--- @field private _categories table<string, string> Available categories
--- @field private _category_icons table<string, {icon: string, color: string}> Category icons and colors
local M = {}

-- Private state
local _mappings = {}
local _categories = {
  action = "action",
  testing = "testing",
  navigation = "navigation",
  vcs = "vcs",
  lsp = "lsp",
  problem = "problem",
}

local _category_icons = {
  action = { icon = "", color = "TelescopeResultsVariable" },
  testing = { icon = "", color = "TelescopeResultsVariable" },
  navigation = { icon = "", color = "TelescopeResultsLineNr" },
  vcs = { icon = "", color = "TelescopeResultsLineNr" },
  lsp = { icon = "󰀫", color = "TelescopeResultsLineNr" },
  problem = { icon = "", color = "TelescopeResultsLineNr" },
}

--- Validates input parameters for adding a command
--- @param opts table The options table to validate
--- @return boolean, string|nil is_valid, error_message
local function validate_options(opts)
  if not opts then
    return false, "Options table is required"
  end

  if not opts.name or type(opts.name) ~= "string" or opts.name == "" then
    return false, "Valid 'name' string is required"
  end

  if not opts.cmd or (type(opts.cmd) ~= "string" and type(opts.cmd) ~= "function") then
    return false, "'cmd' must be a string or function"
  end

  if opts.category and not _categories[opts.category] then
    return false, string.format("Invalid category '%s'. Valid categories: %s",
      opts.category, vim.inspect(vim.tbl_keys(_categories)))
  end

  if opts.keymap and type(opts.keymap) ~= "string" then
    return false, "'keymap' must be a string"
  end

  if opts.mode and type(opts.mode) ~= "string" and type(opts.mode) ~= "table" then
    return false, "'mode' must be a string or table of strings"
  end

  if opts.predicate and type(opts.predicate) ~= "function" then
    return false, "'predicate' must be a function"
  end

  return true
end

--- Safely executes a command with error handling
--- @param cmd string|function The command to execute
--- @param opts? table Optional arguments for function commands
local function safe_execute_cmd(cmd, opts)
  if type(cmd) == "function" then
    local success, err = pcall(cmd, opts)
    if not success then
      vim.notify("Command execution failed: " .. err, vim.log.levels.ERROR)
    end
  elseif type(cmd) == "string" then
    local success, err = pcall(vim.cmd, cmd)
    if not success then
      vim.notify("Command execution failed: " .. err, vim.log.levels.ERROR)
    end
  end
end

--- Safely calls a predicate function with error handling
--- @param predicate function The predicate function to call
--- @return boolean Result of the predicate or false on error
local function safe_call_predicate(predicate)
  if not predicate then return false end

  local success, result = pcall(predicate)
  if not success then
    vim.notify("Predicate evaluation failed: " .. result, vim.log.levels.WARN)
    return false
  end
  return result
end

--- Gets the display information for an option's icon
--- @param option table The command option
--- @return table {icon, color}
local function get_icon_display(option)
  local category_info = _category_icons[option.category]
  local icon = option.icon or (category_info and category_info.icon) or ""
  local color = (category_info and category_info.color) or "TelescopeResultsLineNr"

  return { icon, color }
end

--- Gets the display information for an option's toggle state
--- @param option table The command option
--- @return table {text, highlight}
local function get_toggle_display(option)
  if not option.predicate then
    return { "  ", "Normal" }
  end

  local is_active = safe_call_predicate(option.predicate)
  if is_active then
    return { " ", "DiagnosticHint" }
  else
    return { " ", "TelescopeResultsComment" }
  end
end

--- Creates responsive display widths based on current window size
--- @return table Display configuration
local function get_display_config()
  local width = vim.api.nvim_win_get_width(0)
  -- Reserve space for icon (1), toggle (2), keymap (~10), separators (~6)
  local name_width = math.max(20, width - 30)

  return {
    separator = " ",
    items = {
      { width = 1 },  -- icon
      { width = 2 },  -- toggle
      { width = name_width }, -- name
      { remaining = true }, -- keymap
    },
  }
end

--- Checks if Telescope is available
--- @return boolean is_available
local function is_telescope_available()
  local ok, _ = pcall(require, "telescope")
  return ok
end

--- Public API: Add a command to the palette
--- @param opts table Options for the command
--- @field name string Required: Display name of the command
--- @field cmd string|function Required: Command to execute (string or function)
--- @field category? string Optional: Category for grouping (default: "action")
--- @field icon? string Optional: Custom icon override
--- @field keymap? string Optional: Keymap to bind the command to
--- @field mode? string|string[] Optional: Vim mode(s) for keymap (default: "n")
--- @field buffer? number Optional: Buffer-local keymap
--- @field predicate? function Optional: Function that returns boolean for toggle state
function M.add(opts)
  local is_valid, err = validate_options(opts)
  if not is_valid then
    vim.notify("CommandPalette: " .. err, vim.log.levels.ERROR)
    return false
  end

  local name = opts.name
  local cmd = opts.cmd
  local category = opts.category or "action"
  local icon = opts.icon
  local predicate = opts.predicate
  local keymap = opts.keymap
  local mode = opts.mode or "n"
  local buffer = opts.buffer

  -- Handle keymap binding with proper mode handling
  if keymap then
    local modes = type(mode) == "table" and mode or { mode }
    for _, m in ipairs(modes) do
      local success, err = pcall(vim.keymap.set, m, keymap, cmd, {
        desc = name,
        buffer = buffer,
        noremap = true,
        silent = true
      })
      if not success then
        vim.notify(string.format("Failed to set keymap '%s' in mode '%s': %s", keymap, m, err), vim.log.levels.WARN)
      end
    end
  end

  -- Add to internal mappings
  table.insert(_mappings, {
    name = name,
    cmd = cmd,
    category = category,
    icon = icon,
    keymap = keymap,
    predicate = predicate,
    mode = mode,
    buffer = buffer,
  })

  return true
end

--- Public API: Remove a command by name
--- @param name string The name of the command to remove
--- @return boolean success
function M.remove(name)
  if not name or type(name) ~= "string" then
    vim.notify("CommandPalette: Invalid name for removal", vim.log.levels.ERROR)
    return false
  end

  for i, mapping in ipairs(_mappings) do
    if mapping.name == name then
      table.remove(_mappings, i)
      return true
    end
  end

  vim.notify(string.format("CommandPalette: Command '%s' not found", name), vim.log.levels.WARN)
  return false
end

--- Public API: Clear all commands
function M.clear()
  _mappings = {}
end

--- Public API: Get all commands (read-only)
--- @return table[] commands
function M.get_commands()
  -- Return a copy to prevent external modification
  local commands = {}
  for _, mapping in ipairs(_mappings) do
    table.insert(commands, vim.deepcopy(mapping))
  end
  return commands
end

--- Public API: Get available categories
--- @return table<string, string> categories
function M.get_categories()
  return vim.deepcopy(_categories)
end

--- Public API: Open the command palette
function M.open()
  if not is_telescope_available() then
    vim.notify("CommandPalette: Telescope is required but not available", vim.log.levels.ERROR)
    return
  end

  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local themes = require("telescope.themes")
  local conf = require("telescope.config").values
  local entry_display = require("telescope.pickers.entry_display")
  local dropdown_theme = themes.get_dropdown({})

  local displayer = entry_display.create(get_display_config())

  local function make_display(entry)
    local option = entry.value
    return displayer({
      get_icon_display(option),
      get_toggle_display(option),
      option.name,
      { option.keymap or "", "TelescopeResultsComment" },
    })
  end

  pickers
    .new(dropdown_theme, {
      prompt_title = "Mission Control",
      prompt_prefix = " ",
      sorter = conf.generic_sorter({}),
      finder = finders.new_table({
        results = _mappings,
        entry_maker = function(option)
          return {
            value = option,
            display = make_display,
            ordinal = option.name,
            cmd = option.cmd,
          }
        end,
      }),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection then
            safe_execute_cmd(selection.cmd)
          end
        end)
        return true
      end,
    })
    :find()
end

-- Backwards compatibility
M.__mappings = _mappings  -- Keep for backwards compatibility but mark as deprecated
M.categories = _categories  -- Keep for backwards compatibility

return M
