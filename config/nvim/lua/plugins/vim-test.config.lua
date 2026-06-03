return {
  "vim-test/vim-test",
  config = function ()
    vim.cmd([[let test#strategy = "vtr"]])
    -- vim.cmd([[let test#javascript#playwright#options = "--headed --retries 0 --workers 1"]])
    -- vim.cmd([[let test#clojure#runner = "leintest"]])
    -- vim.cmd([[let test#clojure#leintest#executable = "lein with-profile test midje"]])
    -- vim.cmd([[let test#clojure#leintest#options = ""]])

    vim.keymap.set("n", "<leader>tf", "<cmd>TestFile<CR>", { desc = "Test file", noremap = true, silent = true })
    vim.keymap.set("n", "<leader>tf", "<cmd>TestNearest<CR>", { desc = "Test nearest", noremap = true, silent = true })
    vim.keymap.set("n", "<leader>tv", "<cmd>TestVisit<CR>", { desc = "Visit last test", noremap = true, silent = true })
    vim.keymap.set("n", "<leader>tl", "<cmd>TestLast<CR>", { desc = "Test last file", noremap = true, silent = true })
  end
}
