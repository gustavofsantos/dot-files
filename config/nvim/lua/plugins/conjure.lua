return {
  "Olical/conjure",
  ft = { "clojure" },
  lazy = true,
  init = function()
    vim.g['conjure#extract#tree_sitter#enabled'] = true
    vim.g["conjure#mapping#doc_word"] = "gk"
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
