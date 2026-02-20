return {
  "hrsh7th/nvim-cmp",
  event = "InsertEnter",
  dependencies = {
    "neovim/nvim-lspconfig",
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "hrsh7th/cmp-cmdline",
    "hrsh7th/cmp-emoji",
    "onsails/lspkind.nvim",
    "L3MON4D3/LuaSnip",
    "saadparwaiz1/cmp_luasnip"
  },
  config = function()
    local cmp = require("cmp")
    local lspkind = require('lspkind')
    local cmp_mappings = {
      ["<C-u>"] = cmp.mapping.scroll_docs(-4),
      ["<C-d>"] = cmp.mapping.scroll_docs(4),
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
        fields = { "icon", "abbr", "menu", "kind" },
        format = function(entry, vim_item)
          local kind = lspkind.cmp_format({ mode = "symbol_text", maxwidth = 50 })(entry, vim_item)
          kind.icon = " " .. (kind.icon or "") .. "  "
          kind.kind = "   (" .. (kind.kind or "") .. ")"

          return kind
        end,
      },
      window = {
        completion = cmp.config.window.bordered({
          -- border = '',
          winhighlight = 'Normal:Pmenu,FloatBorder:Pmenu,CursorLine:PmenuSel,Search:None',
        }),
        documentation = cmp.config.window.bordered({
          -- border = '',
          winhighlight = 'Normal:Pmenu',
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
        { name = "luasnip",  keyword_length = 2, max_item_count = 2 },
        { name = "buffer",   keyword_length = 3, max_item_count = 5 },
        { name = "nvim_lsp" },
        { name = 'emoji' },
        { name = "nvim_lua", keyword_length = 3, max_item_count = 5 },
        { name = "path",     keyword_length = 5, max_item_count = 5 },
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
