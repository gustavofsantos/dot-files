vim.keymap.set("n", "gg", "<cmd>LTExpandCalltree<cr>",
  { buffer = 0, noremap = true, silent = true, desc = "Expand calltree" })
vim.keymap.set("n", "gb", "<cmd>LTCollapseCalltree<cr>",
  { buffer = 0, noremap = true, silent = true, desc = "Collapse calltree" })
