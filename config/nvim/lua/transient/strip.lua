-- Default renderer: a borderless strip across the bottom of the editor, above the
-- statusline. Thin window code around the pure layout; one buffer and one window per
-- session, reused and resized on every show.

local layout = require("transient.layout").layout

local M = {}

local ns = vim.api.nvim_create_namespace("transient")

local function statusline_rows()
  local ls = vim.o.laststatus
  if ls == 0 then
    return 0
  end
  if ls == 1 then
    local normal = 0
    for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.api.nvim_win_get_config(w).relative == "" then
        normal = normal + 1
      end
    end
    return normal > 1 and 1 or 0
  end
  return 1
end

--- A fresh strip renderer: { show = fn(view), close = fn() }.
function M.new()
  local buf, win

  local function show(view)
    local width = vim.o.columns
    local bottom = vim.o.lines - vim.o.cmdheight - statusline_rows()
    local max_height = math.max(math.min(math.floor(vim.o.lines / 3), bottom), 2)
    local out = layout(view, width, max_height, { strwidth = vim.fn.strdisplaywidth })
    local height = math.max(math.min(out.height, bottom), 1)

    if not (buf and vim.api.nvim_buf_is_valid(buf)) then
      buf = vim.api.nvim_create_buf(false, true)
      vim.bo[buf].bufhidden = "wipe"
    end
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, out.lines)
    vim.bo[buf].modifiable = false
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    for _, h in ipairs(out.highlights) do
      vim.api.nvim_buf_set_extmark(buf, ns, h[1], h[2], { end_col = h[3], hl_group = h[4] })
    end

    local cfg = {
      relative = "editor",
      row = math.max(bottom - height, 0),
      col = 0,
      width = width,
      height = height,
      focusable = false,
      style = "minimal",
      border = "none",
      zindex = 250,
    }
    if win and vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_set_config(win, cfg)
    else
      cfg.noautocmd = true
      win = vim.api.nvim_open_win(buf, false, cfg)
      vim.wo[win].winhighlight = "Normal:TransientNormal,NormalFloat:TransientNormal"
      vim.wo[win].wrap = false
    end
    -- The engine blocks in getcharstr() right after this; draw now.
    vim.cmd.redraw()
  end

  local function close()
    if win and vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    if buf and vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
    win, buf = nil, nil
    vim.cmd.redraw()
  end

  return { show = show, close = close }
end

return M
