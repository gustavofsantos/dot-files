vim.keymap.set("n", "Q", "<Nop>")
vim.keymap.set("n", "<c-s>", "<cmd>w<cr>")
vim.keymap.set("i", "<c-c>", "<Esc>")
vim.keymap.set("n", "<c-q>", "<cmd>q<cr>")
vim.keymap.set("n", "<Esc>", ":noh<cr><Esc>")
vim.keymap.set("t", "<Esc>", "<c-\\><c-n>")
vim.keymap.set("n", "<leader><leader>", "<c-^>", { desc = "Switch buffer" })
vim.keymap.set("n", "]c", "<cmd>cnext<cr>", { desc = "quickfix next" })
vim.keymap.set("n", "[c", "<cmd>cprevious<cr>", { desc = "quickfix previous" })
vim.keymap.set("n", "<leader>ws", "<cmd>vsplit<cr>", { desc = "split window", noremap = true })
vim.keymap.set("n", "<leader>wS", "<cmd>split<cr>", { desc = "split window down", noremap = true })
vim.keymap.set("n", "<leader>Q", "<cmd>qa!<cr>", { desc = "Quit!" })
vim.keymap.set("n", "<leader>W", "<cmd>wa!<cr>", { desc = "Save all" })
vim.keymap.set('n', 'gK', function()
  local new_config = not vim.diagnostic.config().virtual_lines
  vim.diagnostic.config({ virtual_lines = new_config })
end, { desc = 'Toggle diagnostic virtual_lines' })

vim.keymap.set("v", "<leader>b",
  ':<C-U>!git blame <C-R>=expand("%:p") <CR> | sed -n <C-R>=line("\'<") <CR>,<C-R>=line("\'>") <CR>p <CR>')

vim.keymap.set("n", '[d', function() vim.diagnostic.jump { count = -1 } end, { desc = 'Previous diagnostic' })
vim.keymap.set("n", ']d', function() vim.diagnostic.jump { count = 1 } end, {desc =  'Next diagnostic' })
vim.keymap.set("n", '[e', function() vim.diagnostic.jump { count = -1, severity = vim.diagnostic.severity.ERROR } end,
{desc = 'Previous error'})
vim.keymap.set("n", ']e', function() vim.diagnostic.jump { count = 1, severity = vim.diagnostic.severity.ERROR } end,
{ desc = 'Next error' })

vim.keymap.set("n", "<leader>tf", "<cmd>RunTests<CR>", { desc = "Test current file", noremap = true, silent = true })
vim.keymap.set("n", "<leader>tv", "<cmd>TestVisit<CR>", { desc = "Visit last test", noremap = true, silent = true })
vim.keymap.set("n", "<leader>tl", "<cmd>TestLast<CR>", { desc = "Test last file", noremap = true, silent = true })
vim.keymap.set("n", "<leader>u", "<cmd>UndotreeToggle<cr>", { desc = "Undo tree", noremap = true, silent = true })

vim.keymap.set("n", "<leader>;a", "<cmd>BookmarkAdd<CR>",
  { desc = "Bookmark current file", noremap = true, silent = true })
vim.keymap.set("n", "<leader>;o", "<cmd>BookmarkSearch<CR>",
  { desc = "Search project bookmarks", noremap = true, silent = true })
vim.keymap.set("n", "<leader>;O", "<cmd>BookmarkSearchAll<CR>",
  { desc = "Search bookmarks accross all projects", noremap = true, silent = true })
