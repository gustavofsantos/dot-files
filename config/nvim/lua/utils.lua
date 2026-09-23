local M = {}

function M.toggle_background()
  if vim.o.background == "dark" then
    vim.o.background = "light"
  else
    vim.o.background = "dark"
  end
end

function M.create_runner(cmd)
  return function()
    vim.cmd(cmd)
  end
end

function M.is_copilot_enabled()
  return os.getenv("IS_COPILOT_ENABLED") == "1"
end

function M.is_transparent_background_enabled()
  return vim.loop.os_uname().sysname == "Darwin"
end

function M.get_current_visual_selection()
  local selected_text = ""
  local temp_reg = "z"
  local old_reg_content = vim.fn.getreg(temp_reg)
  local old_reg_type = vim.fn.getregtype(temp_reg)

  vim.cmd('normal! "' .. temp_reg .. 'y')

  selected_text = vim.fn.getreg(temp_reg, true)

  vim.fn.setreg(temp_reg, old_reg_content, old_reg_type)

  return selected_text
end

local packadded = {}

-- Load opt plugins from an ftplugin, once per session. The current FileType
-- event has already fired, so replay it for the autocmd groups the plugins
-- (or setup) just registered, or the first buffer would miss them.
function M.packadd(names, setup)
  local key = table.concat(names, ",")
  if packadded[key] then
    return
  end
  packadded[key] = true

  local known = {}
  for _, au in ipairs(vim.api.nvim_get_autocmds({ event = "FileType" })) do
    if au.group then
      known[au.group] = true
    end
  end

  for _, name in ipairs(names) do
    vim.cmd.packadd(name)
  end
  if setup then
    setup()
  end

  local replay = {}
  for _, au in ipairs(vim.api.nvim_get_autocmds({ event = "FileType" })) do
    if au.group and not known[au.group] then
      replay[au.group] = true
    end
  end
  for group in pairs(replay) do
    vim.api.nvim_exec_autocmds("FileType", { group = group, pattern = vim.bo.filetype, modeline = false })
  end
end

function M.blend_colors(base, target, ratio)
  local r1, g1, b1 = base:match("#(%x%x)(%x%x)(%x%x)")
  local r2, g2, b2 = target:match("#(%x%x)(%x%x)(%x%x)")

  r1, g1, b1 = tonumber(r1, 16), tonumber(g1, 16), tonumber(b1, 16)
  r2, g2, b2 = tonumber(r2, 16), tonumber(g2, 16), tonumber(b2, 16)

  local r = math.floor(r1 * (1 - ratio) + r2 * ratio)
  local g = math.floor(g1 * (1 - ratio) + g2 * ratio)
  local b = math.floor(b1 * (1 - ratio) + b2 * ratio)

  return string.format("#%02X%02X%02X", r, g, b)
end

return M
