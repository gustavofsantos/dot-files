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
vim.keymap.set("n", "gD", function()
  vim.diagnostic.setloclist()
  vim.cmd('lopen')
end, { desc = 'Toggle diagnostics' })
vim.keymap.set('n', 'gK', function()
  local new_config = not vim.diagnostic.config().virtual_lines
  vim.diagnostic.config({ virtual_lines = new_config })
end, { desc = 'Toggle diagnostic virtual_lines' })

vim.keymap.set("v", "<leader>b",
  ':<C-U>!git blame <C-R>=expand("%:p") <CR> | sed -n <C-R>=line("\'<") <CR>,<C-R>=line("\'>") <CR>p <CR>')

vim.keymap.set({ "n", "v" }, "<leader>yp", ":YankPath<CR>", { desc = "Yank path", noremap = true, silent = true })

vim.keymap.set("n", '[d', function() vim.diagnostic.jump { count = -1 } end, { desc = 'Previous diagnostic' })
vim.keymap.set("n", ']d', function() vim.diagnostic.jump { count = 1 } end, { desc = 'Next diagnostic' })
vim.keymap.set("n", '[e', function() vim.diagnostic.jump { count = -1, severity = vim.diagnostic.severity.ERROR } end,
  { desc = 'Previous error' })
vim.keymap.set("n", ']e', function() vim.diagnostic.jump { count = 1, severity = vim.diagnostic.severity.ERROR } end,
  { desc = 'Next error' })

-- vim.keymap.set("n", "<leader>tf", "<cmd>RunTests<CR>", { desc = "Test current file", noremap = true, silent = true })

vim.keymap.set("n", "<leader>u", "<cmd>UndotreeToggle<cr>", { desc = "Toggle undo tree", noremap = true, silent = true })

vim.keymap.set("v", "<CR>", ":ReviewAdd<CR>",
  { desc = "Queue a review comment for selection", noremap = true, silent = true })
vim.keymap.set("n", "<leader>cx", "<cmd>ReviewClear<CR>",
  { desc = "Drop every pending review comment", noremap = true, silent = true })
vim.keymap.set("n", "<leader>cd", "<cmd>ReviewDelete<CR>",
  { desc = "Drop review comment near cursor", noremap = true, silent = true })
vim.keymap.set("n", "<leader>ce", "<cmd>ReviewEdit<CR>",
  { desc = "Edit review comment near cursor", noremap = true, silent = true })
vim.keymap.set("n", "<leader>co", "<cmd>ReviewList<CR>",
  { desc = "Open review queue location list", noremap = true, silent = true })
vim.keymap.set("n", "<leader>cr", "<cmd>ReviewRefresh<CR>",
  { desc = "Redraw review signs from the queue", noremap = true, silent = true })
