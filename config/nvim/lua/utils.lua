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

return M
