-- The two node kinds: a menu holds keys, an action runs something.
-- A method called on the wrong kind raises at lookup, before it can do anything.

local M = {}

local Menu = {}
local Action = {}

local AFTER = { close = true, loop = true }
local UNMAPPED = { exit = true, ignore = true, run = true }

-- Keys the engine owns. <C-c> is an escape too, so it cannot be bound either.
local RESERVED = { ["<Esc>"] = true, ["<BS>"] = true, ["<C-c>"] = true }

local function norm(key)
  return vim.api.nvim_replace_termcodes(key, true, true, true)
end
M.norm = norm

local reserved_norm
local function is_reserved(key)
  if not reserved_norm then
    reserved_norm = {}
    for k in pairs(RESERVED) do
      reserved_norm[norm(k)] = true
    end
  end
  return reserved_norm[norm(key)] == true
end

local function wrong_kind(own, other, other_name)
  return function(_, k)
    local m = own[k]
    if m ~= nil then
      return m
    end
    if other[k] ~= nil then
      error(("transient: :%s() is %s method"):format(k, other_name), 2)
    end
  end
end

local menu_mt = { __index = wrong_kind(Menu, Action, "an action") }
local action_mt = { __index = wrong_kind(Action, Menu, "a menu") }

local function check_self(self, mt, name, kind)
  if getmetatable(self) ~= mt then
    error(("transient: :%s() must be called on a %s (use ':' not '.')"):format(name, kind), 3)
  end
end

function M.new_menu(title)
  return setmetatable({
    kind = "menu",
    title = title,
    entries = {}, -- registration order
    index = {}, -- normalized key -> node
    policy = { after = nil, unmapped = nil },
    enter_cbs = {},
    exit_cbs = {},
    builders = {},
  }, menu_mt)
end

function M.is_menu(x)
  return getmetatable(x) == menu_mt
end

function M.is_action(x)
  return getmetatable(x) == action_mt
end

--- m:on(key, desc) -> child menu; m:on(key, desc, action) -> action node.
function Menu:on(key, desc, action)
  check_self(self, menu_mt, "on", "menu")
  if type(key) ~= "string" or key == "" then
    error("transient: on(key, desc[, action]): key must be a non-empty string", 2)
  end
  if is_reserved(key) then
    error(("transient: %s is reserved (<Esc> quits, <BS> goes back)"):format(key), 2)
  end
  if type(desc) ~= "string" then
    error("transient: on(key, desc[, action]): desc must be a string", 2)
  end
  if action ~= nil and type(action) ~= "string" and type(action) ~= "function" then
    error("transient: on(): action must be a string or a function", 2)
  end

  local node
  if action == nil then
    node = M.new_menu(desc)
  else
    node = setmetatable({ kind = "action", desc = desc, action = action, override = nil }, action_mt)
  end
  node.key = key
  node.dynamic = self._building or nil

  -- Redefining a key replaces it in place, like vim.keymap.set over an existing map.
  local nk = norm(key)
  local old = self.index[nk]
  if old then
    for i, e in ipairs(self.entries) do
      if e == old then
        self.entries[i] = node
        break
      end
    end
  else
    table.insert(self.entries, node)
  end
  self.index[nk] = node
  return node
end

function Menu:off(key)
  check_self(self, menu_mt, "off", "menu")
  local nk = norm(key)
  local old = self.index[nk]
  if not old then
    error(("transient: off(%q): no such key in menu %q"):format(key, self.title), 2)
  end
  self.index[nk] = nil
  for i, e in ipairs(self.entries) do
    if e == old then
      table.remove(self.entries, i)
      break
    end
  end
  return self
end

function Menu:after(value)
  check_self(self, menu_mt, "after", "menu")
  if not AFTER[value] then
    error(("transient: after(%q): expected \"close\" or \"loop\""):format(tostring(value)), 2)
  end
  self.policy.after = value
  return self
end

function Menu:unmapped(value)
  check_self(self, menu_mt, "unmapped", "menu")
  if not UNMAPPED[value] then
    error(("transient: unmapped(%q): expected \"exit\", \"ignore\" or \"run\""):format(tostring(value)), 2)
  end
  self.policy.unmapped = value
  return self
end

local function add_cb(self, list, fn, name)
  check_self(self, menu_mt, name, "menu")
  if type(fn) ~= "function" then
    error(("transient: %s(fn): fn must be a function"):format(name), 3)
  end
  table.insert(list, fn)
  return self
end

function Menu:on_enter(fn)
  return add_cb(self, self.enter_cbs, fn, "on_enter")
end

function Menu:on_exit(fn)
  return add_cb(self, self.exit_cbs, fn, "on_exit")
end

function Menu:build(fn)
  return add_cb(self, self.builders, fn, "build")
end

--- Drop what earlier builds added, then run every builder against a clean menu.
--- Entries defined outside a build are kept.
function Menu:_rebuild()
  if #self.builders == 0 then
    return
  end
  for i = #self.entries, 1, -1 do
    local e = self.entries[i]
    if e.dynamic then
      table.remove(self.entries, i)
      self.index[norm(e.key)] = nil
    end
  end
  self._building = true
  local ok, err = pcall(function()
    for _, fn in ipairs(self.builders) do
      fn(self)
    end
  end)
  self._building = nil
  if not ok then
    error(err, 0)
  end
end

function Action:loop()
  check_self(self, action_mt, "loop", "action")
  self.override = "loop"
  return self
end

function Action:close()
  check_self(self, action_mt, "close", "action")
  self.override = "close"
  return self
end

return M
