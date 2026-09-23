vim.opt_local.shiftwidth = 2
vim.opt_local.expandtab = true

require("utils").packadd({ "lazydev.nvim" }, function()
  require("lazydev").setup({
    library = {
      { path = "${3rd}/luv/library", words = { "vim%.uv" } },
    },
  })
end)
