vim.opt_local.wrap = true
vim.opt_local.number = false
vim.opt_local.relativenumber = false

vim.api.nvim_buf_set_keymap(0, "n", "j", "gj", { silent = true, noremap = true })
vim.api.nvim_buf_set_keymap(0, "n", "k", "gk", { silent = true, noremap = true })
