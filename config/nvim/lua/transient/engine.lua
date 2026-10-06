-- The blocking engine: a stack of open menus driven by one key at a time.
--
-- It knows nothing about windows. It builds a view after every state change and hands it
-- to `renderer.show`; it calls `renderer.close` on every exit path. Keys come from
-- `next_key`, a function, so the stack can be driven headlessly.
--
-- Interface (what a non-blocking engine would have to provide instead):
--   engine.run(root, { mode = "n", op = operator_state(), renderer = r, next_key = fn })

local node = require("transient.node")

local M = {}

local ESC = node.norm("<Esc>")
local BS = node.norm("<BS>")
local CTRL_C = node.norm("<C-c>")

M.DEFAULT_AFTER = "close"
M.DEFAULT_UNMAPPED = "exit"

local function default_next_key()
  return vim.fn.getcharstr()
end

--- The pending operator, or nil outside operator-pending mode. Read from Neovim's mode,
--- not from the mode a root was registered in, so a root registered in "" (n+x+o) works.
--- Safe under textlock, so an expr mapping can call it.
function M.operator_state()
  local m = vim.api.nvim_get_mode().mode
  if m:sub(1, 2) ~= "no" then
    return nil
  end
  return {
    operator = vim.v.operator,
    register = vim.v.register,
    count = vim.v.count,
    force = m:sub(3), -- "", "v", "V" or CTRL-V: a forced motion such as `dvj`
  }
end

--- Effective `after` for an action: per-key, then owning menu, then global.
--- In operator-pending mode the first action completes the operator, so loop is close.
function M.resolve_after(action, owner, op_pending)
  if op_pending then
    return "close"
  end
  return action.override or owner.policy.after or M.DEFAULT_AFTER
end

function M.build_view(stack, op_pending)
  local view = { breadcrumb = {}, entries = {}, hints = {} }
  for _, m in ipairs(stack) do
    table.insert(view.breadcrumb, m.title)
  end
  local top = stack[#stack]
  for _, e in ipairs(top.entries) do
    if e.kind == "menu" then
      table.insert(view.entries, { key = e.key, desc = e.title, kind = "menu" })
    else
      local loop = M.resolve_after(e, top, op_pending) == "loop"
      table.insert(view.entries, { key = e.key, desc = e.desc, kind = "action", loop = loop })
    end
  end
  if #stack > 1 then
    table.insert(view.hints, { key = "<BS>", desc = "back" })
  end
  table.insert(view.hints, { key = "<Esc>", desc = "quit" })
  return view
end

-- Callbacks never stop each other: errors are collected and reported once at the end.
local function call_all(state, fns, ...)
  for _, fn in ipairs(fns) do
    local ok, err = pcall(fn, ...)
    if not ok then
      table.insert(state.errors, err)
    end
  end
end

local function push(state, menu)
  menu:_rebuild()
  table.insert(state.stack, menu)
  call_all(state, menu.enter_cbs, state.ctx)
end

local function pop(state, reason)
  local menu = table.remove(state.stack)
  if menu then
    call_all(state, menu.exit_cbs, reason, state.ctx)
  end
end

local function pop_all(state, reason)
  while #state.stack > 0 do
    pop(state, reason)
  end
end

-- Operator-pending mode: the trigger cancelled the operator with <Esc> before the menu
-- opened (see init.lua), so an action types it again in front of itself (`"x2d` + `iw`).
local function operator_prefix(op)
  local prefix = '"' .. op.register
  if op.count > 0 then
    prefix = prefix .. op.count
  end
  return prefix .. op.operator .. op.force
end

local function feed(keys, flags)
  vim.api.nvim_feedkeys(node.norm(keys), flags, false)
end

-- Loop actions run synchronously and never touch typeahead, so the engine's next read
-- is the user's next key, not the action's own keys.
local function run_now(state, action)
  if type(action) == "function" then
    action(state.ctx)
  else
    vim.cmd.normal({ args = { node.norm(action) }, bang = true })
  end
end

-- A function action under a retyped operator runs from a <Cmd> key, so the cursor
-- motion it makes is the operator's motion. `.` repeats the last one.
local op_motion

function M._op_motion()
  if op_motion then
    op_motion()
  end
end

-- Close actions run after the stack is gone. Strings are queued at the front of the
-- typeahead with noremap (like a mapping RHS) and run once the trigger mapping returns,
-- so they see the mode the trigger saw: `:cmd<cr>` from visual mode gets `'<,'>`.
local function run_after_close(state, action)
  local op = state.op
  if type(action) == "function" then
    if not op then
      action(state.ctx)
      return
    end
    local ctx = state.ctx
    op_motion = function()
      action(ctx)
    end
    feed(operator_prefix(op) .. "<Cmd>lua require('transient.engine')._op_motion()<CR>", "in")
    return
  end
  feed((op and operator_prefix(op) or "") .. action, "in")
end

-- A stray key under `unmapped = "run"` is replayed as if typed, so mappings apply.
local function replay_stray(state, key)
  vim.api.nvim_feedkeys(key, "im", false)
  if state.op then
    feed(operator_prefix(state.op), "in") -- inserted in front of the key
  end
end

--- One key. Returns a deferred thunk to run after the loop ends, or nil.
function M.step(state, key)
  if key == ESC or key == CTRL_C then
    pop_all(state, "escape")
    return
  end
  if key == BS then
    pop(state, "back")
    return
  end

  local top = state.stack[#state.stack]
  local entry = top.index[key]

  if entry == nil then
    local policy = top.policy.unmapped or M.DEFAULT_UNMAPPED
    if policy == "ignore" then
      return
    end
    pop_all(state, "unmapped")
    if policy == "run" then
      return function()
        replay_stray(state, key)
      end
    end
    return
  end

  if entry.kind == "menu" then
    push(state, entry)
    return
  end

  if M.resolve_after(entry, top, state.op ~= nil) == "loop" then
    run_now(state, entry.action)
    return
  end

  pop_all(state, "action")
  return function()
    run_after_close(state, entry.action)
  end
end

local function safe(renderer, method, arg)
  if renderer and renderer[method] then
    pcall(renderer[method], arg)
  end
end

local function report(errors)
  if #errors == 0 then
    return
  end
  local msg = "transient: " .. table.concat(vim.tbl_map(tostring, errors), "\ntransient: ")
  vim.notify(msg, vim.log.levels.ERROR)
end

local function is_interrupt(err)
  return type(err) == "string" and err:find("Keyboard interrupt", 1, true) ~= nil
end

--- Open `root` and block until the stack is empty.
function M.run(root, opts)
  opts = opts or {}
  local mode = opts.mode or "n"
  local state = {
    stack = {},
    errors = {},
    ctx = { mode = mode },
    op = opts.op,
    renderer = opts.renderer,
  }
  local next_key = opts.next_key or default_next_key
  local deferred

  local ok, err = xpcall(function()
    push(state, root)
    while #state.stack > 0 do
      safe(state.renderer, "show", M.build_view(state.stack, state.op ~= nil))
      local key = next_key()
      if key == nil then -- the key source ran dry: same as <Esc>
        key = ESC
      end
      deferred = M.step(state, key)
    end
  end, debug.traceback)

  -- Abnormal exit (<C-c>, an erroring action or builder): unwind, innermost first.
  if not ok then
    pop_all(state, "escape")
    deferred = nil
  end
  safe(state.renderer, "close")

  if deferred then
    local dok, derr = pcall(deferred)
    if not dok then
      table.insert(state.errors, derr)
    end
  end

  if not ok and not is_interrupt(err) then
    table.insert(state.errors, err)
  end
  report(state.errors)
  return state
end

return M
