vim.opt_local.wrap = true
vim.opt_local.number = false
vim.opt_local.relativenumber = false

vim.api.nvim_buf_set_keymap(0, "n", "j", "gj", { silent = true, noremap = true })
vim.api.nvim_buf_set_keymap(0, "n", "k", "gk", { silent = true, noremap = true })

local ok, render_markdown = pcall(require, 'render-markdown')
if ok then
  render_markdown.setup({
    completions = { lsp = { enabled = true } },
  })
end
