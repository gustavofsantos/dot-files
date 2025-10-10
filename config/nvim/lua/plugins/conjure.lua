return {
  "Olical/conjure",
  ft = { "clojure" },
  cond = string.find(vim.fn.getcwd(), "Workplace/seubarriga") ~= nil,
  lazy = true,
  init = function()
    vim.g['conjure#extract#tree_sitter#enabled'] = true
    vim.g["conjure#mapping#doc_word"] = "gk"

    vim.api.nvim_create_autocmd("VimEnter", {
      pattern = "*",
      callback = function()
        local cwd = vim.fn.getcwd()
        if string.find(cwd, "Workplace/seubarriga") ~= nil then
          -- Start Leiningen REPL (headless)
          vim.fn.jobstart("lein with-profile +test repl :headless", {
            cwd = cwd,
            -- Optionally, write the nREPL port to .nrepl-port for Conjure
            on_stdout = function(_, data)
              for _, line in ipairs(data) do
                local port = line:match("nREPL server started on port (%d+)")
                if port then
                  vim.cmd("ConjureConnect")
                end
              end
            end,
          })
        end
      end
    })
  end,
  dependencies = {
    "guns/vim-sexp",
    "tpope/vim-sexp-mappings-for-regular-people",
    {
      "PaterJason/cmp-conjure",
      lazy = true,
      config = function()
        local cmp = require("cmp")
        local config = cmp.get_config()
        table.insert(config.sources, { name = "conjure" })
        return cmp.setup(config)
      end,
    },
    {
      "julienvincent/nvim-paredit",
      config = function()
        require("nvim-paredit").setup()
      end
    }
  },
}
