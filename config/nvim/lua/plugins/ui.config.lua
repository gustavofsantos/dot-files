return {
  { -- stevearc/dressing.nvim
    "stevearc/dressing.nvim",
    dependencies = { "nvim-telescope/telescope.nvim" },
    opts = {
      select = {
        telescope = require("telescope.themes").get_cursor(),
      },
    },
  },
  { -- kevinhwang91/nvim-bqf
    "kevinhwang91/nvim-bqf",
    filetypes = { "qf" },
  },
  -- {
  --   "nvim-lualine/lualine.nvim",
  --   dependencies = {
  --     "nvim-tree/nvim-web-devicons",
  --   },
  --   enable = false,
  --   config = function()
  --     require("lualine").setup({
  --       options = {
  --         -- globalstatus = false,
  --         section_separators = "",
  --         component_separators = { left = '', right = '' },
  --       },
  --       sections = {
  --         lualine_a = {},
  --         lualine_b = {},
  --         lualine_c = {
  --           "mode",
  --           { "filetype", colored = true, icon_only = true },
  --           { "filename", path = 1 },
  --           "searchcount",
  --           {
  --             "diagnostics",
  --             colored = true,
  --             sources = { "nvim_diagnostic", "nvim_workspace_diagnostic" },
  --             sections = { 'error', 'warn' },
  --             symbols = { error = "■ ", warn = "■ ", hint = "■ ", info = "■ " },
  --           },
  --         },
  --         lualine_x = {
  --           "overseer",
  --         },
  --         lualine_y = {},
  --         lualine_z = {},
  --       },
  --       inactive_sections = {
  --         lualine_a = {},
  --         lualine_b = {},
  --         lualine_c = {
  --           {
  --             "filetype",
  --             colored = true,
  --             icon_only = true
  --           },
  --           {
  --             "filename",
  --             path = 1
  --           },
  --         },
  --         lualine_x = {},
  --         lualine_y = {},
  --         lualine_z = {},
  --       },
  --       extensions = {
  --         "quickfix",
  --         "oil",
  --         "lazy",
  --         "overseer",
  --         "neo-tree",
  --         "fugitive",
  --         "toggleterm",
  --       },
  --     })
  --   end,
  -- },
  {
    'echasnovski/mini.clue',
    version = false,
    enabled = false,
    config = function()
      local miniclue = require('mini.clue')
      miniclue.setup({
        window = { delay = 500 },
        triggers = {
          -- Leader triggers
          { mode = 'n', keys = '<Leader>' },
          { mode = 'x', keys = '<Leader>' },

          -- `g` key
          { mode = 'n', keys = 'g' },
          { mode = 'x', keys = 'g' },

          -- Marks
          { mode = 'n', keys = "'" },
          { mode = 'n', keys = '`' },
          { mode = 'x', keys = "'" },
          { mode = 'x', keys = '`' },

          -- Registers
          { mode = 'n', keys = '"' },
          { mode = 'x', keys = '"' },
          { mode = 'i', keys = '<C-r>' },
          { mode = 'c', keys = '<C-r>' },

          -- Window commands
          { mode = 'n', keys = '<C-w>' },

          -- `z` key
          { mode = 'n', keys = 'z' },
          { mode = 'x', keys = 'z' },
        },

        clues = {
          miniclue.gen_clues.g(),
          miniclue.gen_clues.marks(),
          miniclue.gen_clues.registers(),
          miniclue.gen_clues.windows({ submode_resize = true }),
          miniclue.gen_clues.z(),
        },
      })
    end
  },
}
