return {
  "hrsh7th/nvim-cmp",
  event = "InsertEnter",
  dependencies = {
    "neovim/nvim-lspconfig",
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "hrsh7th/cmp-cmdline",
    "onsails/lspkind.nvim",
    "L3MON4D3/LuaSnip",
    "saadparwaiz1/cmp_luasnip"
  },
  config = function()
    local cmp = require("cmp")
    local lspkind = require('lspkind')
    local cmp_mappings = {
      ["<C-d>"] = cmp.mapping.scroll_docs(-4),
      ["<C-u>"] = cmp.mapping.scroll_docs(4),
      ["<C-c>"] = cmp.mapping.close(),
      ["<C-space>"] = cmp.mapping.complete(),
      ["<C-y>"] = cmp.mapping.confirm({ select = true }),
      ["<C-p>"] = cmp.mapping.select_prev_item(),
      ["<C-n>"] = cmp.mapping.select_next_item(),
    }

    lspkind.init({
      symbol_map = {
        Copilot = "",
      },
    })

    cmp.setup({
      completion = {
        completeopt = "menu,menuone,fuzzy,noinsert,preview",
      },
      snippet = {
        expand = function(args)
          require("luasnip").lsp_expand(args.body)
        end,
      },
      formatting = {
        format = lspkind.cmp_format({
          mode = "symbol",
        }),
      },
      window = {
        documentation = cmp.config.window.bordered({
          scrolloff = 2,
          side_padding = 2,
          max_height = 10,
          max_width = 80,
        }),
      },
      mapping = cmp_mappings,
      performance = {
        max_view_entries = 25,
      },
      sources = {
        { name = "nvim_lsp" },
        { name = "luasnip",  keyword_length = 2, max_item_count = 5 },
        { name = "nvim_lua", keyword_length = 2, max_item_count = 4 },
        { name = "path",     keyword_length = 3, max_item_count = 5 },
        { name = "buffer",   keyword_length = 5, max_item_count = 3 },
      },
    })

    cmp.setup.cmdline({ '/', '?' }, {
      mapping = cmp.mapping.preset.cmdline(),
      sources = {
        { name = 'buffer' }
      }
    })

    cmp.setup.cmdline(':', {
      mapping = cmp.mapping.preset.cmdline(),
      sources = cmp.config.sources({
        { name = 'path' }
      }, {
        { name = 'cmdline' }
      })
    })
  end
}
