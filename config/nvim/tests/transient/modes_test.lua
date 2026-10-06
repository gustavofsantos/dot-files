-- Modes through real triggers and real typeahead: keys are typed with feedkeys, so the
-- engine reads them with getcharstr() inside the actual mapping callback.
local H = dofile(debug.getinfo(1, "S").source:sub(2):match("(.*)/") .. "/helpers.lua")
local t = require("transient")
local test, eq = H.test, H.eq

local rec = H.recorder()
t.setup({ renderer = rec })

local function sel()
  return { vim.fn.getpos("v")[2], vim.fn.getpos("v")[3], vim.fn.getpos(".")[2], vim.fn.getpos(".")[3] }
end

test("the trigger is mapped in exactly the root's modes", function()
  t.menu("<F6>")
  t.menu("<F7>", "x")
  t.menu("<F8>", { "n", "x", "o" })
  local function mapped(lhs, mode) return vim.fn.maparg(lhs, mode) ~= "" or vim.fn.mapcheck(lhs, mode) ~= "" end
  eq({ true, false, false }, { mapped("<F6>", "n"), mapped("<F6>", "x"), mapped("<F6>", "o") })
  eq({ false, true, false }, { mapped("<F7>", "n"), mapped("<F7>", "x"), mapped("<F7>", "o") })
  eq({ true, true, true, false }, { mapped("<F8>", "n"), mapped("<F8>", "x"), mapped("<F8>", "o"), mapped("<F8>", "i") })
end)

test("ctx.mode is the mode the root was triggered in", function()
  H.buffer({ "abc" })
  local seen = {}
  local m = t.menu("<F9>", { "n", "x" })
  m:on("m", "mode", function(ctx) table.insert(seen, ctx.mode) end)
  H.type("<F9>m")
  H.type("v<F9>m<Esc>")
  eq({ "n", "x" }, seen)
end)

test("visual: a function action sees the live selection and visual mode stays", function()
  H.buffer({ "hello world", "second line" })
  local inside
  local m = t.menu("<F11>", "x")
  m:on("s", "sub"):on("r", "record", function(ctx)
    inside = { ctx.mode, vim.api.nvim_get_mode().mode, sel() }
  end)
  H.type("0wvjl<F11>sr")
  eq({ "x", "v", { 1, 7, 2, 8 } }, inside)
  eq("v", vim.api.nvim_get_mode().mode)
  eq({ 1, 7, 2, 8 }, sel())
  H.type("<Esc>")
end)

test("visual: <Esc> quits the menu, not visual mode", function()
  H.buffer({ "hello world" })
  local m = t.menu("<F12>", "x")
  m:on("a", "a", "a")
  H.type("0vl<F12><Esc>")
  eq("v", vim.api.nvim_get_mode().mode)
  eq({ 1, 1, 1, 2 }, sel())
  H.type("<Esc>")
end)

test("visual: a close string action like :cmd<cr> gets the '<,'> range", function()
  H.buffer({ "one", "two", "three", "four" })
  _G.transient_range = nil
  local m = t.menu("<S-F1>", "x")
  m:on("r", "range", ":lua _G.transient_range = { vim.fn.line(\"'<\"), vim.fn.line(\"'>\") }<cr>")
  H.type("jVj<S-F1>r")
  eq({ 2, 3 }, _G.transient_range)
end)

test("visual: a loop string action acts on the selection and stays in the menu", function()
  H.buffer({ "hello world" })
  local m = t.menu("<S-F2>", "x"):after("loop")
  m:on("l", "extend", "l")
  local probe
  m:on("p", "probe", function() probe = sel() end)
  H.type("0v<S-F2>llp<Esc>")
  eq({ 1, 1, 1, 3 }, probe)
  eq("v", vim.api.nvim_get_mode().mode, "<Esc> left only the menu")
  H.type("<Esc>")
end)

test("operator-pending: a string action completes the pending operator", function()
  H.buffer({ "hello world foo" })
  local m = t.menu("<S-F3>", "o")
  m:on("w", "inner word", "iw")
  H.type("wd<S-F3>w")
  eq("hello  foo", vim.api.nvim_get_current_line())
  eq("world", vim.fn.getreg('"'))
  eq("n", vim.api.nvim_get_mode().mode)
end)

test("operator-pending: register, count and change operator survive", function()
  H.buffer({ "one two three four" })
  local m = t.menu("<S-F4>", "o")
  m:on("w", "word", "w")
  H.type('"a2d<S-F4>w')
  eq("three four", vim.api.nvim_get_current_line())
  eq("one two ", vim.fn.getreg("a"))

  H.buffer({ "one two three" })
  H.type("c<S-F4>wX<Esc>")
  eq("X two three", vim.api.nvim_get_current_line(), "cw acts like ce")
  eq("n", vim.api.nvim_get_mode().mode)
end)

test("operator-pending: a function action's motion is the operator's motion", function()
  H.buffer({ "hello world foo" })
  local seen
  local m = t.menu("<S-F5>", "o")
  m:on("e", "to col 11", function(ctx)
    seen = ctx.mode
    vim.api.nvim_win_set_cursor(0, { 1, 11 })
  end)
  H.type("wd<S-F5>e")
  eq("hello  foo", vim.api.nvim_get_current_line())
  eq("o", seen)
end)

test("operator-pending: loop is treated as close", function()
  H.buffer({ "hello world foo" })
  local exits = {}
  local m = t.menu("<S-F6>", "o"):after("loop")
  m:on_exit(function(reason) table.insert(exits, reason) end)
  m:on("w", "inner word", "iw"):loop()
  rec.views = {}
  H.type("wd<S-F6>w")
  eq({ "action" }, exits)
  eq(false, rec.views[1].entries[1].loop, "view shows the effective close")
  eq("hello  foo", vim.api.nvim_get_current_line())
end)

test("operator-pending: unmapped run completes the operator with the stray key", function()
  H.buffer({ "hello world foo" })
  local m = t.menu("<S-F7>", "o"):unmapped("run")
  m:on("x", "x", "iw")
  H.type("d<S-F7>w")
  eq("world foo", vim.api.nvim_get_current_line())
end)

test("operator-pending: <Esc> cancels the operator", function()
  H.buffer({ "hello world" })
  local m = t.menu("<S-F8>", "o")
  m:on("w", "w", "iw")
  H.type("d<S-F8><Esc>")
  eq("hello world", vim.api.nvim_get_current_line())
  eq("n", vim.api.nvim_get_mode().mode)
end)

test("operator-pending: <Esc> never applies an operatorfunc to an empty motion", function()
  H.buffer({ "hello world" })
  _G.transient_opfunc_calls = 0
  vim.o.operatorfunc = "v:lua.transient_opfunc"
  _G.transient_opfunc = function() _G.transient_opfunc_calls = _G.transient_opfunc_calls + 1 end
  local m = t.menu("<S-F9>", "o")
  m:on("w", "w", "iw")
  H.type("g@<S-F9><Esc>")
  eq(0, _G.transient_opfunc_calls)
  H.type("g@<S-F9>w")
  eq(1, _G.transient_opfunc_calls)
end)

test("operator-pending: . repeats the operator with the action", function()
  H.buffer({ "aa bb cc dd" })
  local m = t.menu("<S-F10>", "o")
  m:on("w", "word", "w")
  H.type("d<S-F10>w")
  H.type(".")
  eq("cc dd", vim.api.nvim_get_current_line())
end)

H.done()
