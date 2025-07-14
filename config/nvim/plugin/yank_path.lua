vim.api.nvim_create_user_command(
  'YankPath',
  function()
    vim.fn.setreg('+', vim.fn.expand('%:.:p'))
    print('Current buffer relative path yanked!')
  end,
  {
    desc = 'Yank the relative path of the current buffer',
    force = true, -- Overwrite if command already exists
  }
)
