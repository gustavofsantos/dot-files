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

return M
