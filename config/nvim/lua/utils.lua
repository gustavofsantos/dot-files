local M = {}

function M.toggle_background()
  if vim.o.background == "dark" then
    vim.o.background = "light"
  else
    vim.o.background = "dark"
  end
end

function M.create_runner (cmd)
  return function ()
    vim.cmd(cmd)
  end
end

return M
