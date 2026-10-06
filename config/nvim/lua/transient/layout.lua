-- Pure layout: view + size -> lines and highlight ranges. No Neovim calls, so it can be
-- unit-tested with plain tables. Columns are filled top to bottom in registration order,
-- and the smallest row count that fits wins, which keeps the strip short and wide.

local M = {}

local unpack = table.unpack or unpack

M.MARGIN = 1 -- left edge, in cells
M.GAP = 3 -- between columns; with no borders, whitespace is the separator
M.HINT_GAP = 3 -- between hints
M.OVERFLOW = "…"

-- Codepoint count. The window code passes strdisplaywidth for wide characters.
local function utf8_width(s)
  local _, n = s:gsub("[^\128-\191]", "")
  return n
end

local function entry_group(e)
  if e.kind == "menu" then
    return "TransientMenu"
  end
  return e.loop and "TransientLoop" or "TransientAction"
end

-- Cut `s` to at most `max` cells, ending in the overflow mark when cut.
local function clip(s, max, width)
  if width(s) <= max then
    return s
  end
  if max <= 0 then
    return ""
  end
  local out = ""
  for ch in s:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
    if width(out .. ch) + width(M.OVERFLOW) > max then
      break
    end
    out = out .. ch
  end
  return out .. M.OVERFLOW
end

-- A line under construction: text plus highlight ranges in byte offsets.
local function new_line()
  return { text = "", hls = {} }
end

local function put(line, s, group)
  local start = #line.text
  line.text = line.text .. s
  if group and #s > 0 then
    table.insert(line.hls, { start, #line.text, group })
  end
end

local function pad_to(line, cells, width)
  local w = width(line.text)
  if w < cells then
    line.text = line.text .. string.rep(" ", cells - w)
  end
end

local function header(view, width, sw)
  local hint_parts = {}
  for _, h in ipairs(view.hints or {}) do
    table.insert(hint_parts, h)
  end
  local hints_w = 0
  for i, h in ipairs(hint_parts) do
    hints_w = hints_w + sw(h.key) + 1 + sw(h.desc) + (i > 1 and M.HINT_GAP or 0)
  end

  -- Drop leading crumbs until the row fits; the current menu is always kept.
  local crumbs = view.breadcrumb or {}
  local first = 1
  local function crumbs_w(from)
    local w = 0
    for i = from, #crumbs do
      w = w + sw(crumbs[i]) + (i > from and 1 or 0)
    end
    return w
  end
  local room = width - M.MARGIN * 2 - (hints_w > 0 and hints_w + M.GAP or 0)
  while first < #crumbs and crumbs_w(first) > room do
    first = first + 1
  end

  local line = new_line()
  put(line, string.rep(" ", M.MARGIN))
  for i = first, #crumbs do
    if i > first then
      put(line, " ")
    end
    local text = crumbs[i]
    if i == #crumbs then
      text = clip(text, math.max(room, 1), sw)
    end
    put(line, text, i == #crumbs and "TransientTitle" or "TransientCrumb")
  end

  local hint_col = width - M.MARGIN - hints_w
  if hints_w > 0 and hint_col >= sw(line.text) + 1 then
    pad_to(line, hint_col, sw)
    for i, h in ipairs(hint_parts) do
      if i > 1 then
        put(line, string.rep(" ", M.HINT_GAP))
      end
      put(line, h.key, "TransientKey")
      put(line, " ")
      put(line, h.desc, "TransientHint")
    end
  end
  return line
end

-- Column widths when `n` cells are split into columns of `rows` cells each.
local function column_widths(cells, rows, sw)
  local widths = {}
  for i, c in ipairs(cells) do
    local col = math.floor((i - 1) / rows) + 1
    widths[col] = math.max(widths[col] or 0, sw(c.key) + 1 + sw(c.desc))
  end
  return widths
end

local function total_width(widths)
  local w = M.MARGIN
  for i, cw in ipairs(widths) do
    w = w + cw + (i > 1 and M.GAP or 0)
  end
  return w
end

--- layout(view, width, max_height[, opts]) -> { lines, highlights, height }
--- `highlights` holds { line, col_start, col_end, group }: 0-based line, byte columns.
--- `opts.strwidth` measures display cells (default: codepoint count).
function M.layout(view, width, max_height, opts)
  local sw = (opts and opts.strwidth) or utf8_width
  width = math.max(width, 1)
  local max_rows = math.max((max_height or 2) - 1, 1)

  local cells = {}
  for _, e in ipairs(view.entries or {}) do
    table.insert(cells, { key = e.key, desc = e.desc, group = entry_group(e) })
  end
  local n = #cells

  local rows, overflow = 1, false
  if n > 0 then
    rows = nil
    for r = 1, math.min(n, max_rows) do
      if total_width(column_widths(cells, r, sw)) <= width - M.MARGIN then
        rows = r
        break
      end
    end
    if not rows then
      rows = math.min(n, max_rows)
      overflow = true
    end
  end

  -- On overflow keep the columns that fit; the last visible slot becomes "…".
  local avail = width - M.MARGIN
  local widths = column_widths(cells, rows, sw)
  local shown = n
  if overflow then
    local ncols = 1
    while ncols < #widths and total_width({ unpack(widths, 1, ncols + 1) }) <= avail do
      ncols = ncols + 1
    end
    widths = { unpack(widths, 1, ncols) }
    widths[1] = math.min(widths[1], math.max(avail - M.MARGIN, 1))
    if ncols * rows < n then
      shown = ncols * rows - 1
    end
  end

  local lines = { header(view, width, sw) }
  for r = 1, rows do
    lines[r + 1] = new_line()
    put(lines[r + 1], string.rep(" ", M.MARGIN))
  end

  if n == 0 then
    put(lines[2], "(empty)", "TransientHint")
  end

  local slots = math.min(n, #widths * rows)
  for i = 1, slots do
    local col = math.floor((i - 1) / rows) + 1
    local row = (i - 1) % rows + 1
    local line = lines[row + 1]
    if col > 1 then
      pad_to(line, total_width({ unpack(widths, 1, col - 1) }) + M.GAP, sw)
    end
    if i > shown then
      put(line, M.OVERFLOW, "TransientHint")
    else
      local c = cells[i]
      local key = clip(c.key, widths[col], sw)
      put(line, key, "TransientKey")
      local room = widths[col] - sw(key) - 1
      if room > 0 then
        put(line, " ")
        put(line, clip(c.desc, room, sw), c.group)
      end
    end
  end

  local out = { lines = {}, highlights = {}, height = #lines }
  for i, line in ipairs(lines) do
    out.lines[i] = line.text
    for _, h in ipairs(line.hls) do
      table.insert(out.highlights, { i - 1, h[1], h[2], h[3] })
    end
  end
  return out
end

return M
