return {
  -- {
  --   dir = "~/Code/nvim-plugins/vulture.nvim",
  --   dev = true,
  --   config = function()
  --     vim.cmd("colorscheme vulture")
  --   end
  -- },
  {
    "rebelot/kanagawa.nvim",
    lazy = false,
    enabled = true,
    priority = 1000,
    config = function()
      require("kanagawa").setup({
        dimInactive = false,
        globalStatus = true,
        commentStyle = { italic = true },
        functionStyle = { italic = false },
        keywordStyle = { italic = false },
        statementStyle = { italic = false },
        typeStyle = { italic = true },
        variablebuiltinStyle = { italic = false },
        transparent = false,
        background = {
          dark = "wave",
          light = "lotus",
        },
        colors = {
          theme = {
            all = {
              ui = {
                bg_gutter = "none",
              },
            },
          },
        },
        overrides = function(colors)
          -- only override the colors if the background is not light
          if vim.o.background == "light" then
            return {}
          end

          vim.api.nvim_set_hl(0, "NeotestPassed", { fg = colors.theme.diff.add })
          vim.api.nvim_set_hl(0, "NeotestRunning", { fg = colors.theme.diff.text })
          vim.api.nvim_set_hl(0, "NeotestFailed", { fg = colors.theme.diff.delete })


          return {
            Constant = { fg = colors.palette.fujiWhite },

            StatusLine = { bg = colors.palette.sumiInk4 },
            StatusLineNC = { bg = colors.palette.sumiInk2 },
            ColorColumn = { bg = colors.palette.sumiInk2 },

            -- CursorLine = { bg = "NONE" },
            -- CursorLineSign = { bg = "#000000" },
            -- CursorLineNr = { bg = "#000000"},

            -- DiagnosticWarn = { link = "LineNr" },
            -- DiagnosticInfo = { link = "LineNr" },
            -- DiagnosticHint = { link = "LineNr" },
            -- DiagnosticSignWarn = { link = "LineNr" },
            -- DiagnosticSignInfo = { link = "LineNr" },
            -- DiagnosticSignHint = { link = "LineNr" },

            TelescopeTitle = { fg = colors.theme.ui.special, bold = true },
            TelescopePromptNormal = { bg = colors.theme.ui.bg_p1 },
            TelescopePromptBorder = { fg = colors.theme.ui.bg_p1, bg = colors.theme.ui.bg_p1 },
            TelescopeResultsNormal = { fg = colors.theme.ui.fg_dim, bg = colors.theme.ui.bg_m1 },
            TelescopeResultsBorder = { fg = colors.theme.ui.bg_m1, bg = colors.theme.ui.bg_m1 },
            TelescopePreviewNormal = { bg = colors.theme.ui.bg_dim },
            TelescopePreviewBorder = { bg = colors.theme.ui.bg_dim, fg = colors.theme.ui.bg_dim },

            Pmenu = { fg = colors.theme.ui.shade0, bg = colors.theme.ui.bg_p1 }, -- add `blend = vim.o.pumblend` to enable transparency
            PmenuSel = { fg = "NONE", bg = colors.theme.ui.bg_p2 },
            PmenuSbar = { bg = colors.theme.ui.bg_m1 },
            PmenuThumb = { bg = colors.theme.ui.bg_p2 },

            ["@type"] = { italic = false, bold = true },
            ["@tag"] = { italic = false },
            ["@tag.delimiter"] = { fg = colors.palette.sumiInk6 },
            ["@tag.attribute"] = { italic = true },
            ["@punctuation.bracket"] = { fg = colors.palette.sumiInk6 },
            ["@conditional.ternary"] = { fg = colors.palette.oniViolet, italic = false },
            ["@string.documentation.python"] = { link = "Comment" },
          }
        end,
      })

      vim.cmd.colorscheme('kanagawa')
    end,
  },
  {
    "gbprod/nord.nvim",
    lazy = false,
    priority = 1000,
    enabled = false,
    config = function()
      require("nord").setup({
        transparent = true
      })
      vim.cmd.colorscheme("nord")
    end,
  },
  {
    'maxmx03/solarized.nvim',
    lazy = false,
    enabled = false,
    priority = 1000,
    ---@type solarized.config
    opts = {},
    config = function(_, opts)
      vim.o.termguicolors = true

      require('solarized').setup(opts)
      vim.cmd.colorscheme('solarized')
    end,
  },
  {
    'datsfilipe/vesper.nvim',
    lazy = false,
    enabled = false,
    priority = 1000,
    config = function()
      require('vesper').setup({})
      vim.cmd([[colorscheme vesper]])
    end
  },
}
