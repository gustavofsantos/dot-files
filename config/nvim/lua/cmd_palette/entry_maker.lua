local M = {}

M.handle_entry_index = function(opts, t, k)
  local override = ((opts or {}).entry_index or {})[k]
  if not override then
    return
  end

  local val, save = override(t, opts)
  if save then
    rawset(t, k, val)
  end
  return val
end

M.set_default_entry_mt = function(tbl, opts)
  return setmetatable({}, {
    __index = function(t, k)
      local override = M.handle_entry_index(opts, t, k)
      if override then
        return override
      end

      local val = tbl[k]
      if val then
        rawset(t, k, val)
      end

      return val
    end,
  })
end

M.gen_from_diagnostics = function(opts)
  local entry_display = require("telescope.pickers.entry_display")
  local type_diagnostic = vim.diagnostic.severity
  local signs = {
    [type_diagnostic.ERROR] = "●",
    [type_diagnostic.WARN] = "●",
    [type_diagnostic.INFO] = '■',
    [type_diagnostic.HINT] = '■',
  }

  opts = opts or {}

  local get_icon_display = function(entry)
    local highlight = "Diagnostic" .. entry.type
    local icon = signs[type_diagnostic[entry.type]] or "●"

    return { icon, highlight }
  end

  local displayer = entry_display.create {
    separator = " ",
    items = {
      { width = 1 },
      { remaining = true }
    },
  }

  local make_display = function(entry)
    print(vim.inspect(entry))
    return displayer {
      get_icon_display(entry),
      entry.text,
    }
  end


  return function(entry)
    return M.set_default_entry_mt({
      value = entry,
      ordinal = entry.text,
      display = make_display,
      filename = entry.filename,
      type = entry.type,
      lnum = entry.lnum,
      col = entry.col,
      text = entry.text,
      qf_type = signs[type_diagnostic[entry.type]],
    }, opts)
  end
end

return M
