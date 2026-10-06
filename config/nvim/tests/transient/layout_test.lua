-- layout() is pure: plain tables in, plain tables out.
local H = dofile(debug.getinfo(1, "S").source:sub(2):match("(.*)/") .. "/helpers.lua")
local layout = require("transient.layout").layout
local test, eq = H.test, H.eq

local QUIT = { { key = "<Esc>", desc = "quit" } }
local BACK_QUIT = { { key = "<BS>", desc = "back" }, { key = "<Esc>", desc = "quit" } }

local function act(key, desc, loop) return { key = key, desc = desc, kind = "action", loop = loop or false } end
local function sub(key, desc) return { key = key, desc = desc, kind = "menu" } end

local function view(entries, crumbs, hints)
  return { breadcrumb = crumbs or { "<leader>" }, entries = entries, hints = hints or QUIT }
end

local function groups_on(out, line, text)
  local row = out.lines[line + 1]
  local s, e = row:find(text, 1, true)
  for _, h in ipairs(out.highlights) do
    if h[1] == line and h[2] == s - 1 and h[3] == e then
      return h[4]
    end
  end
end

test("a wide strip puts everything on one row", function()
  local out = layout(view({ sub("f", "file"), sub("w", "window"), sub("b", "buffers"), act("1", "tab 1") }), 80, 10)
  eq(2, out.height)
  eq(" f file   w window   b buffers   1 tab 1", out.lines[2])
end)

test("the smallest row count that fits wins; columns fill top to bottom", function()
  local v = view({ act("h", "narrower", true), act("l", "wider", true), act("j", "shorter", true),
    act("k", "taller", true), act("=", "equalize") }, { "<leader>", "window" }, BACK_QUIT)
  -- One row needs 56 cells; at 40 two rows fit.
  local out = layout(v, 40, 10)
  eq(3, out.height)
  eq(" h narrower   j shorter   = equalize", out.lines[2])
  eq(" l wider      k taller", out.lines[3])
end)

test("header: breadcrumb left, hints right-aligned", function()
  local out = layout(view({ act("a", "a") }, { "<leader>", "window" }, BACK_QUIT), 50, 10)
  H.truthy(out.lines[1]:find("^ <leader> window +<BS> back   <Esc> quit$"), out.lines[1])
  eq(50 - 1, #out.lines[1], "hints end one margin from the right edge")
  eq("TransientCrumb", groups_on(out, 0, "<leader>"))
  eq("TransientTitle", groups_on(out, 0, "window"))
  eq("TransientKey", groups_on(out, 0, "<BS>"))
  eq("TransientHint", groups_on(out, 0, "back"))
end)

test("hints at depth 1 have no <BS>", function()
  local out = layout(view({ act("a", "a") }), 40, 10)
  eq(nil, out.lines[1]:find("<BS>", 1, true))
  H.truthy(out.lines[1]:find("<Esc> quit", 1, true))
end)

test("each entry kind gets its own highlight group; keys are TransientKey", function()
  local out = layout(view({ sub("f", "file"), act("h", "narrower", true), act("=", "equalize") }), 80, 10)
  eq("TransientMenu", groups_on(out, 1, "file"))
  eq("TransientLoop", groups_on(out, 1, "narrower"))
  eq("TransientAction", groups_on(out, 1, "equalize"))
  eq("TransientKey", groups_on(out, 1, "f"))
  eq("TransientKey", groups_on(out, 1, "="))
end)

test("too many entries for max_height truncate with an overflow mark", function()
  local entries = {}
  for i = 1, 30 do table.insert(entries, act(string.char(96 + (i % 26) + 1), "item number " .. i)) end
  local out = layout(view(entries), 60, 4)
  eq(4, out.height)
  local all = table.concat(out.lines, "\n")
  H.truthy(all:find("…", 1, true), "overflow mark shown")
  for _, l in ipairs(out.lines) do
    H.truthy(vim.fn.strdisplaywidth(l) <= 60, "fits the width: " .. l)
  end
  eq("TransientHint", groups_on(out, 3, "…"))
end)

test("a single cell wider than the strip is clipped, not dropped", function()
  local out = layout(view({ act("x", string.rep("long ", 20)) }), 30, 5)
  eq(2, out.height)
  H.truthy(vim.fn.strdisplaywidth(out.lines[2]) <= 30)
  H.truthy(out.lines[2]:find("…$"))
end)

test("a narrow header drops leading crumbs first", function()
  local out = layout(view({ act("a", "a") }, { "<leader>", "git", "branches" }, BACK_QUIT), 38, 5)
  eq(nil, out.lines[1]:find("<leader>", 1, true))
  H.truthy(out.lines[1]:find("branches", 1, true))
end)

test("an empty menu still renders", function()
  local out = layout(view({}), 40, 5)
  eq(2, out.height)
  H.truthy(out.lines[2]:find("(empty)", 1, true))
end)

test("highlight columns are bytes, so multibyte text lines up", function()
  local out = layout(view({ act("é", "café"), act("b", "bar") }), 80, 5)
  eq("TransientAction", groups_on(out, 1, "bar"))
  eq("TransientAction", groups_on(out, 1, "café"))
end)

H.done()
