local H = dofile(debug.getinfo(1, "S").source:sub(2):match("(.*)/") .. "/helpers.lua")
local t = require("transient")
local test, eq, raises = H.test, H.eq, H.raises

-- A root that is not bound to any key; tests open it directly.
local function root(title)
  return require("transient.node").new_menu(title or "<leader>")
end

local function open(menu, keys, opts)
  local r = H.recorder()
  opts = vim.tbl_extend("force", { renderer = r, next_key = H.keys(keys) }, opts or {})
  local state = t.open(menu, opts)
  return r, state
end

-- Records enter/exit callbacks and actions into one ordered log.
local function logger()
  local log = {}
  local L = { log = log }
  function L.watch(menu, name)
    menu:on_enter(function() table.insert(log, "enter " .. name) end)
    menu:on_exit(function(reason) table.insert(log, "exit " .. name .. " " .. reason) end)
    return menu
  end
  function L.act(name)
    return function(ctx) table.insert(log, "run " .. name .. " " .. ctx.mode) end
  end
  return L
end

-- on() and chaining ----------------------------------------------------------------

test("on without an action returns a child menu titled by desc", function()
  local m = root():on("f", "file")
  eq("menu", m.kind)
  eq("file", m.title)
end)

test("on with an action returns an action node", function()
  eq("action", root():on("f", "find", ":echo<cr>").kind)
  eq("action", root():on("r", "recent", function() end).kind)
end)

test("menu methods chain and return the menu", function()
  local m = root():on("w", "window")
  eq(m, m:after("loop"):unmapped("ignore"):on_enter(function() end):on_exit(function() end))
end)

test("action-only methods raise on a menu", function()
  local m = root():on("w", "window")
  raises(function() m:loop() end, ":loop%(%) is an action method")
  raises(function() m:close() end, ":close%(%) is an action method")
end)

test("menu-only methods raise on an action", function()
  local a = root():on("h", "narrower", "<C-w><")
  for _, name in ipairs({ "on", "after", "unmapped", "on_enter", "on_exit", "build", "off" }) do
    raises(function() a[name](a) end, ":" .. name .. "%(%) is a menu method")
  end
end)

test("bad policy values and reserved keys raise", function()
  local m = root()
  raises(function() m:after("stay") end, "after")
  raises(function() m:unmapped("drop") end, "unmapped")
  raises(function() m:on("<Esc>", "nope", "x") end, "reserved")
  raises(function() m:on("<BS>", "nope") end, "reserved")
  raises(function() m:on("x", "bad", 42) end, "string or a function")
  raises(function() m.on("x", "dot call") end, "use ':'")
end)

test("off removes a key, and raises for a missing one", function()
  local m = root()
  m:on("a", "a", "a")
  m:on("b", "b", "b")
  eq(m, m:off("a"))
  eq({ "b" }, vim.tbl_map(function(e) return e.key end, m.entries))
  raises(function() m:off("zz") end, "no such key")
end)

test("redefining a key replaces it in place", function()
  local m = root()
  m:on("a", "one", "x")
  m:on("b", "two", "x")
  m:on("a", "three", "x")
  eq({ "three", "two" }, vim.tbl_map(function(e) return e.desc end, m.entries))
end)

-- stack and exit order -------------------------------------------------------------

test("close action pops every menu innermost first, then runs", function()
  local L = logger()
  local r0 = L.watch(root(), "root")
  local a = L.watch(r0:on("a", "A"), "A")
  local b = L.watch(a:on("b", "B"), "B")
  b:on("x", "act", L.act("x"))
  local rec = open(r0, { "a", "b", "x" })
  eq({
    "enter root", "enter A", "enter B",
    "exit B action", "exit A action", "exit root action",
    "run x n",
  }, L.log)
  eq(1, rec.closed)
end)

test("callbacks of one menu run in registration order", function()
  local log = {}
  local m = root()
  m:on_exit(function() table.insert(log, 1) end)
  m:on_exit(function() table.insert(log, 2) end)
  m:on_enter(function() table.insert(log, "e1") end)
  m:on_enter(function() table.insert(log, "e2") end)
  open(m, { "<Esc>" })
  eq({ "e1", "e2", 1, 2 }, log)
end)

test("a failing callback does not skip the others", function()
  local log = {}
  local m = root()
  m:on_exit(function() error("boom") end)
  m:on_exit(function() table.insert(log, "second") end)
  local notify = vim.notify
  local notes = {}
  vim.notify = function(msg) table.insert(notes, msg) end
  open(m, { "<Esc>" })
  vim.notify = notify
  eq({ "second" }, log)
  H.truthy(notes[1] and notes[1]:find("boom"), "error was reported")
end)

test("<Esc> pops everything with reason escape", function()
  local L = logger()
  local r0 = L.watch(root(), "root")
  L.watch(r0:on("a", "A"), "A")
  open(r0, { "a", "<Esc>" })
  eq({ "enter root", "enter A", "exit A escape", "exit root escape" }, L.log)
end)

test("<C-c> exits like <Esc>", function()
  local L = logger()
  local r0 = L.watch(root(), "root")
  open(r0, { "<C-c>" })
  eq({ "enter root", "exit root escape" }, L.log)
end)

test("<BS> pops one level with reason back; at the root it exits", function()
  local L = logger()
  local r0 = L.watch(root(), "root")
  L.watch(r0:on("a", "A"), "A")
  local rec = open(r0, { "a", "<BS>", "<BS>" })
  eq({ "enter root", "enter A", "exit A back", "exit root back" }, L.log)
  eq({ { "<leader>" }, { "<leader>", "A" }, { "<leader>" } },
    vim.tbl_map(function(v) return v.breadcrumb end, rec.views))
end)

test("a key source that runs dry exits like <Esc>", function()
  local L = logger()
  open(L.watch(root(), "root"), {})
  eq({ "enter root", "exit root escape" }, L.log)
end)

-- loop vs close --------------------------------------------------------------------

test("loop action runs and stays on its menu; no exit fires", function()
  local L = logger()
  local r0 = L.watch(root(), "root")
  local w = L.watch(r0:on("w", "window"):after("loop"), "window")
  w:on("h", "narrower", L.act("h"))
  local rec = open(r0, { "w", "h", "h", "<Esc>" })
  eq({ "enter root", "enter window", "run h n", "run h n", "exit window escape", "exit root escape" }, L.log)
  eq(4, #rec.views)
  eq({ "<leader>", "window" }, rec.views[4].breadcrumb)
end)

test("per-key close overrides a looping menu", function()
  local L = logger()
  local w = L.watch(root():after("loop"), "w")
  w:on("=", "equalize", L.act("=")):close()
  open(w, { "=" })
  eq({ "enter w", "exit w action", "run = n" }, L.log)
end)

test("per-key loop overrides a closing menu", function()
  local L = logger()
  local m = L.watch(root(), "m")
  m:on("h", "h", L.act("h")):loop()
  open(m, { "h", "<Esc>" })
  eq({ "enter m", "run h n", "exit m escape" }, L.log)
end)

test("a child menu does not inherit after or unmapped", function()
  local L = logger()
  local parent = L.watch(root():after("loop"):unmapped("ignore"), "parent")
  local child = L.watch(parent:on("c", "child"), "child")
  child:on("x", "x", L.act("x"))
  open(parent, { "c", "x" })
  eq({ "enter parent", "enter child", "exit child action", "exit parent action", "run x n" }, L.log)

  L.log[1] = nil
  for k in pairs(L.log) do L.log[k] = nil end
  open(parent, { "c", "?" })
  eq({ "enter parent", "enter child", "exit child unmapped", "exit parent unmapped" }, L.log)
end)

test("opening a child menu ignores after", function()
  local L = logger()
  local m = L.watch(root():after("close"), "m")
  L.watch(m:on("c", "child"), "child")
  open(m, { "c", "<Esc>" })
  eq({ "enter m", "enter child", "exit child escape", "exit m escape" }, L.log)
end)

test("loop string action runs synchronously and does not leak into the engine", function()
  H.buffer({ "abcdefgh" })
  local m = root():after("loop")
  m:on("l", "right", "l")
  local reads = 0
  local keys = H.keys({ "l", "l", "l", "<Esc>" })
  open(m, {}, { next_key = function()
    reads = reads + 1
    -- Nothing may be waiting in typeahead when the engine asks for a key.
    eq(0, vim.fn.getchar(1), "typeahead empty at read " .. reads)
    return keys()
  end })
  eq(4, reads)
  eq({ 1, 3 }, vim.api.nvim_win_get_cursor(0))
end)

test("close string action is queued and runs after the engine returns", function()
  H.buffer({ "abcdefgh" })
  local m = root()
  m:on("x", "delete", "x")
  open(m, { "x" })
  eq("abcdefgh", vim.api.nvim_get_current_line(), "not run yet")
  H.type("")
  eq("bcdefgh", vim.api.nvim_get_current_line())
end)

test("loop string action through the real trigger and getcharstr", function()
  H.buffer({ "abcdefgh" })
  local m = t.menu("<F5>", "n"):after("loop")
  m:on("l", "right", "l")
  t.setup({ renderer = H.recorder() })
  H.type("<F5>lll<Esc>")
  eq({ 1, 3 }, vim.api.nvim_win_get_cursor(0))
  eq("n", vim.api.nvim_get_mode().mode)
end)

-- unmapped -------------------------------------------------------------------------

test("unmapped exit leaves and drops the key", function()
  H.buffer({ "abc" })
  local L = logger()
  open(L.watch(root(), "m"), { "x" })
  H.type("")
  eq({ "enter m", "exit m unmapped" }, L.log)
  eq("abc", vim.api.nvim_get_current_line())
end)

test("unmapped ignore stays in the menu", function()
  local L = logger()
  local m = L.watch(root():unmapped("ignore"), "m")
  local rec = open(m, { "x", "y", "<Esc>" })
  eq({ "enter m", "exit m escape" }, L.log)
  eq(3, #rec.views)
end)

test("unmapped run exits, then runs the key normally", function()
  H.buffer({ "abc" })
  local L = logger()
  open(L.watch(root():unmapped("run"), "m"), { "x" })
  H.type("")
  eq({ "enter m", "exit m unmapped" }, L.log)
  eq("bc", vim.api.nvim_get_current_line())
end)

-- views ----------------------------------------------------------------------------

test("view lists entries in order with effective loop and kind", function()
  local m = root()
  m:on("f", "file")
  local w = m:on("w", "window"):after("loop")
  w:on("h", "narrower", "<C-w><")
  w:on("=", "equalize", "<C-w>="):close()
  m:on("1", "tab 1", "1gt")
  local rec = open(m, { "w", "<Esc>" })
  eq({
    breadcrumb = { "<leader>" },
    entries = {
      { key = "f", desc = "file", kind = "menu" },
      { key = "w", desc = "window", kind = "menu" },
      { key = "1", desc = "tab 1", kind = "action", loop = false },
    },
    hints = { { key = "<Esc>", desc = "quit" } },
  }, rec.views[1])
  eq({
    breadcrumb = { "<leader>", "window" },
    entries = {
      { key = "h", desc = "narrower", kind = "action", loop = true },
      { key = "=", desc = "equalize", kind = "action", loop = false },
    },
    hints = { { key = "<BS>", desc = "back" }, { key = "<Esc>", desc = "quit" } },
  }, rec.views[2])
end)

-- build ----------------------------------------------------------------------------

test("build repopulates the menu on every entry, keeping eager keys", function()
  local n = 0
  local m = root()
  m:on("e", "eager", "x")
  m:build(function(self)
    n = n + 1
    self:on(tostring(n), "item " .. n, "x")
  end)
  local rec = open(m, { "<Esc>" })
  eq({ "e", "1" }, vim.tbl_map(function(e) return e.key end, rec.views[1].entries))
  rec = open(m, { "<Esc>" })
  eq({ "e", "2" }, vim.tbl_map(function(e) return e.key end, rec.views[1].entries))
end)

-- abnormal exits -------------------------------------------------------------------

test("an erroring action unwinds the stack and closes the renderer", function()
  local L = logger()
  local m = L.watch(root():after("loop"), "m")
  m:on("x", "bad", function() error("kaput") end)
  local notify, notes = vim.notify, {}
  vim.notify = function(msg) table.insert(notes, msg) end
  local rec = open(m, { "x" })
  vim.notify = notify
  eq({ "enter m", "exit m escape" }, L.log)
  eq(1, rec.closed)
  H.truthy(notes[1]:find("kaput"))
end)

test("a keyboard interrupt unwinds silently", function()
  local L = logger()
  local m = L.watch(root(), "m")
  local notify, notes = vim.notify, {}
  vim.notify = function(msg) table.insert(notes, msg) end
  local rec = open(m, {}, { next_key = function() error("Keyboard interrupt") end })
  vim.notify = notify
  eq({ "enter m", "exit m escape" }, L.log)
  eq(1, rec.closed)
  eq({}, notes)
end)

test("a broken renderer does not trap the user", function()
  local L = logger()
  local m = L.watch(root(), "m")
  m:on("a", "A")
  local closes = 0
  local bad = {
    show = function() error("render fail") end,
    close = function() closes = closes + 1; error("close fail") end,
  }
  t.open(m, { renderer = bad, next_key = H.keys({ "a", "<Esc>" }) })
  eq({ "enter m", "exit m escape" }, L.log)
  eq(1, closes)
end)

test("setup rejects a renderer without show and close", function()
  raises(function() t.setup({ renderer = { show = function() end } }) end, "show%(view%) and close%(%)")
end)

H.done()
