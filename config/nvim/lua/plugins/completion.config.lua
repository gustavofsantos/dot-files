local utils = require "utils"

return {
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "neovim/nvim-lspconfig",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      {
        "zbirenbaum/copilot-cmp",
        dependencies = { "zbirenbaum/copilot.lua" },
        enabled = utils.is_copilot_enabled
      }
    },
    config = function()
      local cmp = require("cmp")
      local cmp_mappings = {
        ["<C-d>"] = cmp.mapping.scroll_docs(-4),
        ["<C-u>"] = cmp.mapping.scroll_docs(4),
        ["<C-c>"] = cmp.mapping.close(),
        ["<C-space>"] = cmp.mapping.complete(),
        ["<C-y>"] = cmp.mapping.confirm({ select = true }),
        ["<C-p>"] = cmp.mapping.select_prev_item(),
        ["<C-n>"] = cmp.mapping.select_next_item(),
      }

      if utils.is_copilot_enabled() then
        require("copilot_cmp").setup()
      end

      cmp.setup({
        completion = {
          completeopt = "menu,menuone,noinsert",
        },
        snippet = {
          expand = function(args)
            require("luasnip").lsp_expand(args.body)
          end,
        },
        window = {
          documentation = cmp.config.window.bordered({
            scrolloff = 2,
            side_padding = 2,
            max_height = 10,
          }),
        },
        mapping = cmp_mappings,
        performance = {
          max_view_entries = 20,
        },
        sources = {
          { name = "copilot",  max_item_count = 3,  priority = 10 },
          { name = "luasnip",  max_item_count = 2,  priority = 10 },
          { name = "nvim_lsp", max_item_count = 10, priority = 5 },
          { name = "nvim_lua", max_item_count = 4,  keyword_length = 2, priority = 2 },
          { name = "path",     keyword_length = 3,  max_item_count = 5, priority = 2 },
          { name = "buffer",   max_item_count = 4,  keyword_length = 5, priority = 1 },
        },
      })
    end
  },
  {
    "L3MON4D3/LuaSnip",
    version = "v2.*",
  }
}
