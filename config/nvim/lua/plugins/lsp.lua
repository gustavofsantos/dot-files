return {
  "neovim/nvim-lspconfig",
  event = { "BufEnter", "BufReadPre", "BufNewFile" },
  dependencies = {
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    {
      "folke/lazydev.nvim",
      ft = "lua",
      opts = {
        library = {
          { path = "${3rd}/luv/library", words = { "vim%.uv" } }
        }
      }
    },
    "hrsh7th/nvim-cmp",
    "b0o/schemastore.nvim",
    "nvim-telescope/telescope.nvim",
  },
  config = function()
    local mason = require("mason")
    local mason_lspconfig = require("mason-lspconfig")
    local capabilities = require("cmp_nvim_lsp").default_capabilities()

    mason.setup()
    mason_lspconfig.setup({
      automatic_enable = true,
      ensure_installed = {
        "lua_ls",
        "vtsls",
        "pyright",
        "dockerls",
        "sqlls",
        "docker_compose_language_service",
        "vimls",
        "bashls",
      },
    })

    vim.lsp.config("*", { capabilities = capabilities })

    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
      callback = function(ev)
        vim.keymap.set("n", "K", function() vim.lsp.buf.hover({ max_width = 60 }) end,
          { buffer = ev.buf, desc = "Hover" })
        vim.keymap.set("n", "grd", vim.lsp.buf.definition, { buffer = ev.buf, desc = "Go to definition" })
        vim.keymap.set("n", "gf", "<cmd>Format<cr>", { buffer = ev.buf, desc = "Format async" })
      end,
    })
  end,
}
