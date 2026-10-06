-- transient: one trigger key opens a menu; each key runs an action or opens a child menu.
--
--   local t = require("transient")
--   local leader = t.menu("<leader>")            -- root, normal mode
--   local win = leader:on("w", "window"):after("loop")
--   win:on("l", "wider", "<C-w>>")
--   win:on("=", "equalize", "<C-w>="):close()
--
-- See engine.lua for runtime semantics, layout.lua and strip.lua for the renderer.

local node = require("transient.node")
local engine = require("transient.engine")

local M = {}

local config = { renderer = nil }

local function renderer()
  if not config.renderer then
    config.renderer = require("transient.strip").new()
  end
  return config.renderer
end

-- Fallback links. Colorschemes that define the groups win; `:colorscheme` clears
-- highlights, so the links are set again on every ColorScheme event.
local LINKS = {
  TransientNormal = "NormalFloat",
  TransientTitle = "Title",
  TransientCrumb = "Comment",
  TransientKey = "Special",
  TransientAction = "Normal",
  TransientLoop = "String",
  TransientMenu = "Directory",
  TransientHint = "Comment",
}

function M.set_highlights()
  for group, link in pairs(LINKS) do
    vim.api.nvim_set_hl(0, group, { link = link, default = true })
  end
end

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("transient_highlights", { clear = true }),
  callback = M.set_highlights,
})
M.set_highlights()

--- setup({ renderer = { show = fn(view), close = fn() } }). Default: the bottom strip.
function M.setup(opts)
  opts = opts or {}
  if opts.renderer ~= nil then
    local r = opts.renderer
    if type(r) ~= "table" or type(r.show) ~= "function" or type(r.close) ~= "function" then
      error("transient: setup({ renderer }): renderer needs show(view) and close()", 2)
    end
    config.renderer = r
  end
  M.set_highlights()
end

--- Open a menu now. Normally a root's trigger does this; tests drive it directly.
--- opts: { mode = "n", op = engine.operator_state(), renderer = r, next_key = fn }
function M.open(menu, opts)
  if not node.is_menu(menu) then
    error("transient: open(menu): not a menu", 2)
  end
  opts = opts or {}
  return engine.run(menu, {
    mode = opts.mode or "n",
    op = opts.op,
    renderer = opts.renderer or renderer(),
    next_key = opts.next_key,
  })
end

local pending

function M._resume()
  local p = pending
  pending = nil
  if p then
    M.open(p.root, { mode = p.mode, op = p.op })
  end
end

--- t.menu(trigger[, mode]) -> root menu. `mode` has vim.keymap.set's shape: a string or
--- a list. Child menus run in whatever mode the root was triggered in.
function M.menu(trigger, mode)
  if type(trigger) ~= "string" or trigger == "" then
    error("transient: menu(trigger[, mode]): trigger must be a non-empty string", 2)
  end
  mode = mode or "n"
  local modes = type(mode) == "table" and mode or { mode }

  local root = node.new_menu(trigger)
  root.trigger = trigger
  root.modes = modes
  for _, m in ipairs(modes) do
    vim.keymap.set(m, trigger, function()
      -- An expr mapping, so operator-pending mode can be left cleanly: once a callback
      -- returns, Neovim applies the operator to an empty motion (`c` enters Insert). The
      -- operator is saved here, cancelled with <Esc>, and retyped by the action.
      local op = engine.operator_state()
      pending = { root = root, mode = m, op = op }
      return (op and "<Esc>" or "") .. "<Cmd>lua require('transient')._resume()<CR>"
    end, { expr = true, desc = "transient: " .. trigger })
  end
  return root
end

return M
