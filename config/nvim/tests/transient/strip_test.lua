-- Smoke test for the window code: opens, updates in place, closes on every exit path,
-- and leaves no stray windows or buffers.
local H = dofile(debug.getinfo(1, "S").source:sub(2):match("(.*)/") .. "/helpers.lua")
local t = require("transient")
local strip = require("transient.strip")
local test, eq = H.test, H.eq

local function floats()
  local out = {}
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_config(w).relative ~= "" then
      table.insert(out, w)
    end
  end
  return out
end

local function counts()
  return { wins = #vim.api.nvim_list_wins(), bufs = #vim.api.nvim_list_bufs() }
end

local V1 = { breadcrumb = { "<leader>" }, entries = { { key = "f", desc = "file", kind = "menu" } },
  hints = { { key = "<Esc>", desc = "quit" } } }
local V2 = { breadcrumb = { "<leader>", "file" }, entries = {
  { key = "f", desc = "find", kind = "action", loop = false },
  { key = "r", desc = "recent", kind = "action", loop = false },
}, hints = { { key = "<BS>", desc = "back" }, { key = "<Esc>", desc = "quit" } } }

test("show opens one float above the statusline; show again updates it in place", function()
  vim.o.laststatus = 2
  vim.o.cmdheight = 1
  local before = counts()
  local r = strip.new()
  r.show(V1)
  local f = floats()
  eq(1, #f)
  local win = f[1]
  local cfg = vim.api.nvim_win_get_config(win)
  eq({ "editor", vim.o.columns, 2, false }, { cfg.relative, cfg.width, cfg.height, cfg.focusable })
  eq(vim.o.lines - 1 - 1 - 2, vim.api.nvim_win_get_position(win)[1])
  local buf = vim.api.nvim_win_get_buf(win)
  H.truthy(vim.api.nvim_buf_get_lines(buf, 1, 2, false)[1]:find("f file", 1, true))
  H.truthy(vim.wo[win].winhighlight:find("Normal:TransientNormal", 1, true))
  eq(vim.api.nvim_get_current_win() ~= win, true, "focus stays in the editor")

  r.show(V2)
  eq({ win }, floats(), "same window reused")
  eq(buf, vim.api.nvim_win_get_buf(win), "same buffer reused")
  H.truthy(vim.api.nvim_buf_get_lines(buf, 1, 2, false)[1]:find("f find", 1, true))

  r.close()
  eq({}, floats())
  eq(before, counts())
  r.close() -- safe when not shown
end)

test("geometry follows laststatus and cmdheight", function()
  local r = strip.new()
  vim.o.laststatus = 0
  vim.o.cmdheight = 2
  r.show(V1)
  eq(vim.o.lines - 2 - 0 - 2, vim.api.nvim_win_get_position(floats()[1])[1])
  r.close()
  vim.o.laststatus = 2
  vim.o.cmdheight = 1
end)

local function run_with_strip(menu, keys, mode)
  local r = strip.new()
  local seen = {}
  local wrapped = {
    show = function(v) r.show(v); table.insert(seen, #floats()) end,
    close = r.close,
  }
  local notify = vim.notify
  vim.notify = function() end
  t.open(menu, { renderer = wrapped, next_key = H.keys(keys), mode = mode })
  vim.notify = notify
  return seen
end

test("closes on escape, back, unmapped, action and error", function()
  local before = counts()
  local function menu()
    local m = require("transient.node").new_menu("<leader>")
    m:on("a", "action", function() end)
    m:on("e", "error", function() error("x") end):loop()
    m:on("s", "sub"):on("x", "x", function() end)
    return m
  end
  for _, keys in ipairs({ { "<Esc>" }, { "<BS>" }, { "?" }, { "a" }, { "e" }, { "s", "x" }, { "s", "<BS>", "<Esc>" } }) do
    local seen = run_with_strip(menu(), keys)
    for _, n in ipairs(seen) do eq(1, n, "exactly one strip while open") end
    eq({}, floats(), "no float left after " .. table.concat(keys, " "))
    eq(before, counts(), "no stray buffer after " .. table.concat(keys, " "))
  end
end)

test("visual: the real strip leaves the selection and visual mode alone", function()
  H.buffer({ "hello world", "second line" })
  t.setup({ renderer = strip.new() })
  local inside
  local m = t.menu("<F2>", "x")
  m:on("s", "sub"):on("r", "record", function()
    inside = { vim.api.nvim_get_mode().mode, vim.fn.getpos("v"), vim.fn.getpos("."), #floats() }
  end)
  H.type("0wvjl<F2>s<BS>sr")
  eq("v", inside[1])
  eq({ 1, 7 }, { inside[2][2], inside[2][3] })
  eq({ 2, 8 }, { inside[3][2], inside[3][3] })
  eq(0, inside[4], "strip is closed before a close action runs")
  eq("v", vim.api.nvim_get_mode().mode)
  eq({}, floats())
  H.type("<Esc>")
  eq({ 1, 2 }, { vim.fn.line("'<"), vim.fn.line("'>") }, "'< '> marks match the selection")
end)

test("highlight fallbacks are links and come back after :colorscheme", function()
  vim.cmd.colorscheme("default")
  for _, g in ipairs({ "TransientNormal", "TransientTitle", "TransientCrumb", "TransientKey",
    "TransientAction", "TransientLoop", "TransientMenu", "TransientHint" }) do
    H.truthy(vim.api.nvim_get_hl(0, { name = g }).link, g .. " is linked")
  end
  eq("Directory", vim.api.nvim_get_hl(0, { name = "TransientMenu" }).link)
end)

H.done()
