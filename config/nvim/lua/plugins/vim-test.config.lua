return {
  "vim-test/vim-test",
  config = function()
    vim.cmd([[let test#strategy = "vtr"]])

    local function find_monorepo_root()
      -- Look for common monorepo root markers
      local root_markers = { ".git" }
      local root = vim.fs.root(0, root_markers)

      return root or vim.fn.getcwd()
    end

    -- 2. Define the Command Transformation
    _G.custom_testf = function(cmd)
      local repo_root = vim.fn.getcwd()
      local relative_file = vim.fn.expand("%")

      return "source ~/.zhelpers && testf " .. repo_root .. " " .. relative_file
    end

    -- vim.cmd([[let test#javascript#playwright#options = "--headed --retries 0 --workers 1"]])
    -- vim.cmd([[let test#clojure#runner = "leintest"]])
    -- vim.cmd([[let test#clojure#leintest#executable = "lein with-profile test midje"]])
    -- vim.cmd([[let test#clojure#leintest#options = ""]])

    vim.g["test#custom_transformations"] = { custom_testf = _G.custom_testf }
    vim.g["test#transformation"] = "custom_testf"

    vim.keymap.set("n", "<leader>tf", "<cmd>TestFile<CR>", { desc = "Test file", noremap = true, silent = true })
    vim.keymap.set("n", "<leader>tv", "<cmd>TestVisit<CR>", { desc = "Visit last test", noremap = true, silent = true })
    vim.keymap.set("n", "<leader>tl", "<cmd>TestLast<CR>", { desc = "Test last file", noremap = true, silent = true })
  end
}
