local set = vim.keymap.set
local n = "n"
local i = "i"
local x = "x"
local o = "o"
local v = "v"
local t = "t"

set(n, "Q", "<Nop>")
set(n, "<c-s>", "<cmd>w<cr>")
set(i, "<c-c>", "<Esc>")
set(n, "<c-q>", "<cmd>q<cr>")
set(n, "<Esc>", ":noh<cr><Esc>")
set(t, "<Esc>", "<c-\\><c-n>")
set(n, "<leader><leader>", "<c-^>", { desc = "Switch buffer" })
set(n, "]c", "<cmd>cnext<cr>", { desc = "quickfix next" })
set(n, "[c", "<cmd>cprevious<cr>", { desc = "quickfix previous" })
set(n, "<leader>ws", "<cmd>vsplit<cr>", { desc = "split window", noremap = true, silent = true })
set(n, "<leader>wS", "<cmd>split<cr>", { desc = "split window down", noremap = true, silent = true })

set(v, "<leader>b",
  ':<C-U>!git blame <C-R>=expand("%:p") <CR> | sed -n <C-R>=line("\'<") <CR>,<C-R>=line("\'>") <CR>p <CR>')

set(n, "<leader>t", "<cmd>TermExec cmd=\"testfile %:p\" name=\"testfile\"<CR>",
  { noremap = true, silent = true, desc = "Test file" })

set(n, "<leader>;a", "<cmd>NewBookmark<CR>", { desc = "Add bookmark" })
set(n, "<leader>;f", "<cmd>ProjectBookmarks<CR>", { desc = "Project bookmarks" })
set(n, "<leader>;g", "<cmd>GlobalBookmarks<CR>", { desc = "All bookmarks" })

set(n, "-", "<cmd>Oil<CR>", { noremap = true, silent = true, desc = "File explorer" })

set(n, "<leader>tn", "<cmd>TestNearest<cr>", { noremap = true, silent = true })
set(n, "<leader>tf", "<cmd>TestFile<cr>", { noremap = true, silent = true })
set(n, "<leader>tl", "<cmd>TestLast<cr>", { noremap = true, silent = true })
