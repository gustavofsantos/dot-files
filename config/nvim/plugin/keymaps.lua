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
set(n, "<leader>u", "<cmd>UndotreeToggle<cr>", { desc = "Undo tree" })
set(v, "<leader>b",
  ':<C-U>!git blame <C-R>=expand("%:p") <CR> | sed -n <C-R>=line("\'<") <CR>,<C-R>=line("\'>") <CR>p <CR>')

set(n, "<leader>o", "<cmd>Telescope find_files<CR>", { noremap = true, silent = true, desc = "Find files" })
set(n, "<leader>b", "<cmd>Telescope buffers<CR>", { noremap = true, silent = true, desc = "Find buffer" })
set(n, "<leader>l", "<cmd>Telescope live_grep<CR>", { noremap = true, silent = true, desc = "Live grep" })
set(n, "<leader>f", "<cmd>Telescope current_buffer_fuzzy_find<CR>", { noremap = true, silent = true, desc = "Buffer fuzzy find" })
set(v, "<F3>", '"zy:Telescope grep_string default_text=<C-r>z<cr>', { noremap = true, silent = true, desc = "Find Selected" })
set(n, "<F3>", "<cmd>Telescope grep_string<cr>", { noremap = true, silent = true, desc = "Find Word" })

set(n , "<leader>?", "<cmd>AvanteToggle<CR>", { noremap = true, silent = true, desc = "Open Avante" })
set(n, "<leader>ss", "<cmd>Switch<CR>", { noremap = true, silent = true, desc = "Switch" })
set(n, "<leader>ws", "<cmd>vsplit<cr>", { desc = "split window", noremap = true, silent = true })
set(n, "<leader>wS", "<cmd>split<cr>", { desc = "split window down", noremap = true, silent = true })

set({n, x, o }, "s", function() require("flash").jump() end, { desc = "Flash", noremap = true, silent=true })

set(n, "<leader>;a", "<cmd>NewBookmark<CR>", { desc = "Add bookmark" })
set(n, "<leader>;f", "<cmd>ProjectBookmarks<CR>", { desc = "Project bookmarks" })
set(n, "<leader>;g", "<cmd>GlobalBookmarks<CR>", { desc = "All bookmarks" })

set(n, "-", "<cmd>Oil<CR>", { noremap = true, silent = true, desc = "File explorer" })


