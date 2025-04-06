vim.filetype.add({
  extension = {
    png = "image",
    jpg = "image",
    jpeg = "image",
    gif = "image",
  },
  filename = {
    [".eslintrc"] = "json",
    [".prettierrc"] = "json",
    [".babelrc"] = "json",
    [".stylelintrc"] = "json",
  },
  pattern = {
    [".env.*"] = "sh",
  },
})

-- undercurl
vim.cmd([[let &t_Cs = "\e[4:3m"]])
vim.cmd([[let &t_Ce = "\e[4:0m"]])
vim.cmd([[let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"]])
vim.cmd([[let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"]])

vim.cmd([[augroup highlight_yank
    autocmd!
    au TextYankPost * silent! lua vim.highlight.on_yank({higroup="IncSearch", timeout=500})
augroup END]])

-- vim.opt.statusline = "%<%f"
-- vim.opt.statusline:append("%{exists('g:loaded_fugitive')?' ':''}")
-- vim.opt.statusline:append("%{exists('g:loaded_fugitive')?fugitive#statusline():''}")
-- vim.opt.statusline:append("%h%m%r%=%-14.(%l,%c%V%) %P")

-- vim.cmd([[
--   autocmd TermOpen * setlocal nonumber norelativenumber
-- ]])

