vim.cmd([[setlocal linebreak]])
vim.cmd([[setlocal nonumber]])
vim.cmd([[setlocal textwidth=80]])
vim.cmd([[setlocal nolist]])

vim.api.nvim_buf_set_keymap(0, "n", "h", "gh", { silent = true, noremap = true })
vim.api.nvim_buf_set_keymap(0, "n", "j", "gj", { silent = true, noremap = true })
vim.api.nvim_buf_set_keymap(0, "n", "k", "gk", { silent = true, noremap = true })
vim.api.nvim_buf_set_keymap(0, "n", "l", "gl", { silent = true, noremap = true })
