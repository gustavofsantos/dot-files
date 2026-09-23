require("oil").setup({
  default_file_explorer = true,
  skip_confirm_for_simple_edits = true,
  columns = {},
  view_options = {
    show_hidden = true
  }
})

vim.keymap.set("n", "-", "<cmd>Oil<CR>", { desc = "File explorer" })
