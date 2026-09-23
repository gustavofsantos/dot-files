require("gitsigns").setup({
  signcolumn = true,
  numhl = false,
  linehl = false,
  attach_to_untracked = false,
  current_line_blame = false,
  current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d>",
  signs = {
    add = { text = "▎" },
    change = { text = "▎" },
    delete = { text = "▎" },
    topdelete = { text = "▎" },
    changedelete = { text = "▎" },
    untracked = { text = "░" },
  },
  signs_staged = {
    add          = { text = '░' },
    change       = { text = '░' },
    delete       = { text = '░' },
    topdelete    = { text = '░' },
    changedelete = { text = '░' },
    untracked    = { text = '░' },
  },
})

vim.keymap.set("n", "]h", "<cmd>Gitsigns next_hunk<cr>", { desc = "Next hunk" })
vim.keymap.set("n", "[h", "<cmd>Gitsigns prev_hunk<cr>", { desc = "Previous hunk" })
vim.keymap.set("n", "<leader>dhp", "<cmd>Gitsigns preview_hunk<cr>", { desc = "Diff hunk" })
vim.keymap.set("n", "<leader>ghr", "<cmd>Gitsigns reset_hunk<cr>", { desc = "Reset hunk" })
vim.keymap.set("n", "<leader>ghtl", "<cmd>Gitsigns toggle_linehl<cr>", { desc = "Toggle line highlight" })
vim.keymap.set("n", "<leader>ghtw", "<cmd>Gitsigns toggle_word_diff<cr>", { desc = "Toggle word diff" })
vim.keymap.set("n", "<leader>ghdt", "<cmd>Gitsigns diffthis<cr>", { desc = "Diff this" })
