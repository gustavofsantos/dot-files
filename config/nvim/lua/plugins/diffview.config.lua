require("diffview").setup({
  view = {
    merge_tool = {
      layout = "diff3_mixed"
    }
  }
})

vim.keymap.set("n", "<leader>dvc", "<cmd>DiffviewClose<cr>", { desc = "Close diff view" })
