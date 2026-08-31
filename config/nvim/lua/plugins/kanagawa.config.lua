return {
  "rebelot/kanagawa.nvim",
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

        local theme = colors.theme
        local makeDiagnosticColor = function(color)
          local c = require("kanagawa.lib.color")
          return { fg = color, bg = c(color):blend(theme.ui.bg, 0.95):to_hex() }
        end

        return {
          Constant                         = { fg = colors.palette.fujiWhite },

          StatusLine                       = { bg = colors.palette.sumiInk4 },
          StatusLineNC                     = { bg = colors.palette.sumiInk2 },
          ColorColumn                      = { bg = colors.palette.sumiInk2 },

          TelescopeTitle                   = { fg = colors.theme.ui.special, bold = true },
          TelescopePromptNormal            = { bg = colors.theme.ui.bg_p1 },
          TelescopePromptBorder            = { fg = colors.theme.ui.bg_p1, bg = colors.theme.ui.bg_p1 },
          TelescopeResultsNormal           = { fg = colors.theme.ui.fg_dim, bg = colors.theme.ui.bg_m1 },
          TelescopeResultsBorder           = { fg = colors.theme.ui.bg_m1, bg = colors.theme.ui.bg_m1 },
          TelescopePreviewNormal           = { bg = colors.theme.ui.bg_dim },
          TelescopePreviewBorder           = { bg = colors.theme.ui.bg_dim, fg = colors.theme.ui.bg_dim },

          DiagnosticVirtualTextHint        = makeDiagnosticColor(theme.diag.hint),
          DiagnosticVirtualTextInfo        = makeDiagnosticColor(theme.diag.info),
          DiagnosticVirtualTextWarn        = makeDiagnosticColor(theme.diag.warning),
          DiagnosticVirtualTextError       = makeDiagnosticColor(theme.diag.error),

          -- Pmenu                            = { fg = colors.theme.ui.shade0, bg = colors.theme.ui.bg_p1 },
          -- PmenuSel                         = { fg = "NONE", bg = colors.theme.ui.bg_p2 },
          -- PmenuSbar                        = { bg = colors.theme.ui.bg_m1 },
          -- PmenuThumb                       = { bg = colors.theme.ui.bg_p2 },

          ["@type"]                        = { italic = false, bold = true },
          ["@tag"]                         = { italic = false },
          ["@tag.delimiter"]               = { fg = colors.palette.sumiInk6 },
          ["@tag.attribute"]               = { italic = true },
          ["@punctuation.bracket"]         = { fg = colors.palette.sumiInk6 },
          ["@conditional.ternary"]         = { fg = colors.palette.oniViolet, italic = false },
          ["@string.documentation.python"] = { link = "Comment" },
        }
      end,
    })

    vim.cmd("colorscheme kanagawa")
  end
}
