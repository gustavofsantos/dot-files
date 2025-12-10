local blend_colors = function(base, target, ratio)
    local r1, g1, b1 = base:match("#(%x%x)(%x%x)(%x%x)")
    local r2, g2, b2 = target:match("#(%x%x)(%x%x)(%x%x)")

    r1, g1, b1 = tonumber(r1, 16), tonumber(g1, 16), tonumber(b1, 16)
    r2, g2, b2 = tonumber(r2, 16), tonumber(g2, 16), tonumber(b2, 16)

    local r = math.floor(r1 * (1 - ratio) + r2 * ratio)
    local g = math.floor(g1 * (1 - ratio) + g2 * ratio)
    local b = math.floor(b1 * (1 - ratio) + b2 * ratio)

    return string.format("#%02X%02X%02X", r, g, b)
end

local color = function(dark, light)
    local bg = vim.o.background
    if bg == 'light' and light then
        return light
    else
        return dark
    end
end

local palette = {
    black           = "#000000",
    white           = "#FFFFFF",

    base05          = "#001d24",
    base04          = "#002029",
    base03          = "#002b36",
    base02          = "#073642",
    base01          = "#586e75",
    base00          = "#657b83",
    base0           = "#839496",
    base1           = "#93a1a1",
    base2           = "#eee8d5",
    base3           = "#fdf6e3",
    base4           = "#fefbf1",
    base5           = "#fffdf8",
    yellow_darker   = "#886700",
    yellow          = "#b58900",
    yellow_lighter  = "#c8a740",
    orange_darker   = "#983811",
    orange          = "#cb4b16",
    orange_lighter  = "#d87850",
    red_darker      = "#a52623",
    red             = "#dc322f",
    red_lighter     = "#e56563",
    magenta_darker  = "#8d3269",
    magenta         = "#d33682",
    magenta_lighter = "#e176a2",
    violet_darker   = "#485a95",
    violet          = "#6c71c4",
    violet_lighter  = "#9c9dce",
    blue_darker     = "#196b9e",
    blue            = "#268bd2",
    blue_lighter    = "#6eafd8",
    cyan_darker     = "#1c6b65",
    cyan            = "#2aa198",
    cyan_lighter    = "#71c0ba",
    green_darker    = "#596600",
    green           = "#859900",
    green_lighter   = "#aebb55",
}


local highlights = {
    Bold                               = { bold = true },
    Italic                             = { italic = true },
    Underline                          = { underline = true },

    Normal                             = { fg = color(palette.base0, palette.base00), bg = color(palette.base03, palette.base3) },
    NormalNC                           = { fg = color(palette.base0, palette.base00), bg = color(palette.base03, palette.base3) },
    NormalSB                           = { fg = color(palette.base0, palette.base00), bg = color(palette.base03, palette.base3) },
    NormalFloat                        = { fg = color(palette.base0, palette.base00), bg = color(palette.base02, palette.base2) },
    Title                              = { fg = palette.orange },
    FloatTitle                         = { link = "Title" },
    FloatBorder                        = { link = "NormalFloat" },
    FloatFooter                        = { link = "NormalFloat" },
    ColorColumn                        = { bg = color(palette.base02, palette.base2) },
    LineNr                             = { fg = color(palette.base01, palette.base1) },
    MatchParen                         = { bg = palette.magenta },
    Pmenu                              = { fg = color(palette.base0, palette.base00), bg = color(palette.base04, palette.base2) },
    PmenuSel                           = { fg = color(palette.yellow_lighter, palette.base1), bg = color(palette.yellow_darker, palette.base02) },
    PmenuSbar                          = { fg = color(palette.base2, palette.base02), bg = color(palette.base0, palette.base00) },
    PmenuThumb                         = { fg = color(palette.base0, palette.base00), bg = color(palette.base05, palette.base3) },

    VertSplit                          = { fg = color(palette.base01, palette.base1), bg = color(palette.base04, palette.base4) },
    WinSeparator                       = { link = "VertSplit" },

    Cursor                             = { fg = color(palette.base03, palette.base3), bg = color(palette.base0, palette.base00) },
    CursorColumn                       = { bg = color(palette.base02, palette.base2) },
    CursorLine                         = { bg = color(palette.base02, palette.base2) },
    CursorLineNr                       = { fg = color(palette.yellow, palette.yellow_lighter), bg = palette.black },
    CursorLineSign                     = { bg = palette.black },
    TermCursorNC                       = { link = "Cursor" },
    iCursor                            = { link = "Cursor" },
    lCursor                            = { link = "Cursor" },
    SignColumn                         = { link = "Normal" },
    SignColumnSB                       = { link = "Normal" },
    StatusLine                         = { fg = color(palette.base1, palette.base01), bg = color(palette.base02, palette.base2) },
    StatusLineNC                       = { fg = color(palette.base00, palette.base0), bg = color(palette.base02, palette.base2) },
    StatusLineTerm                     = { link = "StatusLine" },
    StatusLineTermNC                   = { link = "StatusLineNC" },
    TabLine                            = { fg = color(palette.base0, palette.base00), bg = color(palette.base02, palette.base2) },
    TabLineFill                        = { fg = color(palette.base0, palette.base00), bg = color(palette.base02, palette.base2) },
    TabLineSel                         = { fg = color(palette.base01, palette.base1), bg = color(palette.base2, palette.base02) },
    Visual                             = { bg = color(palette.base04, palette.base4) },
    VisualNOS                          = { link = "Visual" },

    NonText                            = { link = "Normal" },
    SpecialKey                         = { undercurl = true, sp = palette.red },
    SpellBad                           = { undercurl = true, sp = palette.red },
    SpellCap                           = { undercurl = true, sp = palette.yellow },
    SpellLocal                         = { undercurl = true, sp = palette.cyan },
    SpellRare                          = { undercurl = true, sp = palette.cyan },

    IncSearch                          = { fg = color(palette.base03, palette.base3), bg = palette.orange, underline = true },
    Search                             = { fg = color(palette.base03, palette.base3), bg = palette.yellow },

    DiagnosticWarn                     = { fg = color(palette.yellow_darker, palette.yellow_lighter) },
    DiagnosticError                    = { fg = color(palette.red_darker, palette.red_lighter) },
    DiagnosticInfo                     = {
        fg = color(blend_colors(palette.base03, palette.blue, 0.35),
            blend_colors(palette.base3, palette.blue, 0.35))
    },
    DiagnosticHint                     = {
        fg = color(blend_colors(palette.base03, palette.cyan, 0.35),
            blend_colors(palette.base3, palette.cyan, 0.35))
    },
    DiagnosticUnderlineWarn            = { fg = palette.yellow, undercurl = true },
    DiagnosticUnderlineError           = { fg = palette.red, undercurl = true },
    DiagnosticUnderlineInfo            = { fg = palette.cyan, undercurl = true },
    DiagnosticUnderlineHint            = { fg = palette.blue, undercurl = true },
    DiagnosticSignError                = { fg = palette.red, bg = "NONE" },
    DiagnosticSignWarn                 = { fg = palette.yellow, bg = "NONE" },
    DiagnosticSignHint                 = { fg = palette.blue, bg = "NONE" },
    DiagnosticSignInfo                 = { fg = palette.cyan, bg = "NONE" },

    DiffAdd                            = { fg = palette.green },
    DiffChange                         = { fg = palette.yellow },
    DiffDelete                         = { fg = palette.red },
    DiffText                           = { fg = palette.blue },
    diffAdded                          = { link = "DiffAdd" },
    diffChanged                        = { link = "DiffChange" },
    diffRemoved                        = { link = "DiffDelete" },

    healthError                        = { link = "DiagnosticError" },
    healthSuccess                      = { fg = palette.green },
    healthWarning                      = { link = "DiagnosticWarn" },

    QuickFixLine                       = { link = "Search" },
    QuickFixLineNr                     = { link = "LineNr" },
    QuickFixFilename                   = { link = "File" },

    TelescopeBorder                    = { link = "FloatBorder" },
    TelescopePromptBorder              = { link = "FloatBorder" },
    TelescopePromptNormal              = { link = "NormalFloat" },
    TelescopePromptTitle               = { link = "NormalFloat" },
    TelescopeResultsBorder             = { link = "FloatBorder" },
    TelescopeResultsNormal             = { link = "NormalFloat" },
    TelescopeResultsTitle              = { link = "FloatTitle" },
    TelescopePreviewBorder             = { link = "FloatBorder" },
    TelescopePreviewNormal             = { link = "NormalFloat" },
    TelescopePreviewTitle              = { link = "FloatTitle" },
    TelescopeMatching                  = { link = "IncSearch" },
    TelescopeSelection                 = { link = "Search" },
    TelescopeSelectionCaret            = { fg = palette.orange },
    TelescopeMultiSelection            = { fg = palette.yellow },

    -- Semantic Tokens
    Comment                            = { fg = color(palette.base01, palette.base1), italic = true },

    Constant                           = { fg = palette.cyan },
    Boolean                            = { link = "Constant" },
    Character                          = { link = "Constant" },
    Float                              = { link = "Constant" },
    Number                             = { link = "Constant" },
    String                             = { link = "Constant" },

    Identifier                         = { fg = palette.blue },
    Function                           = { link = "Identifier" }, -- function name (also: methods for classes)
    Field                              = { link = "Identifier" },

    Variable                           = { fg = color(palette.base1, palette.base01) },

    Statement                          = { fg = palette.green },
    Conditional                        = { link = "Statement" }, -- if, then, else, endif, switch, etc.
    Repeat                             = { link = "Statement" }, -- for, do, while, etc.
    Label                              = { link = "Statement" }, -- case, default, etc.
    Operator                           = { link = "Statement" }, -- "sizeof", "+", "*", etc.
    Keyword                            = { link = "Statement" }, -- any other keyword
    Exception                          = { link = "Statement" }, -- try, catch, throw

    PreProc                            = { fg = palette.orange },
    Include                            = { link = "PreProc" }, -- preprocessor #include
    Namespace                          = { link = "PreProc" },
    Define                             = { link = "PreProc" }, -- preprocessor #define
    Macro                              = { link = "PreProc" }, -- same as Define
    PreCondit                          = { link = "PreProc" }, -- preprocessor #if, #else, #endif, etc.
    Decorator                          = { link = "PreProc" },

    Type                               = { fg = palette.yellow },
    StorageClass                       = { link = "Type" }, -- static, register, volatile, etc.
    Structure                          = { link = "Type" }, -- struct, union, enum, etc.
    Typedef                            = { link = "Type" }, -- A typedef

    Special                            = { fg = palette.red },
    SpecialChar                        = { link = "Special" }, -- special character in a constant
    Tag                                = { link = "Special" }, -- you can use CTRL-] on this
    Delimiter                          = { link = "Special" }, -- character that needs attention
    SpecialComment                     = { link = "Special" }, -- special things inside a comment
    Debug                              = { link = "Special" }, -- debugging statements

    Error                              = { undercurl = true, sp = palette.red },
    Ignore                             = { fg = color(palette.base00, palette.base0) },
    Todo                               = { fg = palette.magenta, undercurl = true },

    ["@comment"]                       = { link = "Comment" },
    ["@constant"]                      = { link = "Constant" },
    ["@string"]                        = { link = "String" },
    ["@string.regexp"]                 = { link = "String" },
    ["@string.special.symbol"]         = { link = "Special" },
    ["@string.special.symbol.clojure"] = { fg = palette.base2 },
    ["@keyword"]                       = { link = "Keyword" },
    ["@variable"]                      = { link = "Variable" },
    ["@variable.builtin"]              = { link = "Variable" },
    ["@property"]                      = { link = "Variable" },
    ["@operator"]                      = { link = "Operator" },
    ["@boolean"]                       = { link = "Boolean" },
    ["@function"]                      = { link = "Function" },
    ["@function.builtin"]              = { link = "Function" },
    ["@function.macro"]                = { link = "Function" },
    ["@function.call"]                 = { fg = palette.blue, italic = true },
    ["@type"]                          = { link = "Type" },
    ["@type.builtin"]                  = { link = "Type" },
    ["@constructor"]                   = { link = "Function" },
    ["@constructor.lua"]               = { link = "Ignore" },
    ["@decorator"]                     = { link = "Decorator" },
    ["@punctuation.bracket"]           = { link = "Ignore" },
    ["@punctuation.delimiter"]         = { link = "Ignore" },

    ["@lsp.type.parameter"]            = { link = "Variable" },
    ["@lsp.type.macro"]                = { link = "Macro" },
    ["@lsp.type.macro.clojure"]        = { fg = color(palette.base1), italic = false, bold = true },
    ["@lsp.type.keyword"]              = { link = "@string.special.symbol" },
    ["@lsp.type.keyword.clojure"]      = { link = "@string.special.symbol.clojure" },
    ["@lsp.type.type"]                 = { link = "Type" },
    ["@lsp.type.class"]                = { link = "Typedef" },
    ["@lsp.type.namespace"]            = { link = "Namespace" },
    ["@lsp.typemod.variable.global"]   = { fg = color(palette.base1, palette.base01), bold = true }
}


vim.g.terminal_color_0 = color(palette.base03, palette.base3)
vim.g.terminal_color_1 = palette.red
vim.g.terminal_color_2 = palette.green
vim.g.terminal_color_3 = palette.yellow
vim.g.terminal_color_4 = palette.blue
vim.g.terminal_color_5 = palette.magenta
vim.g.terminal_color_6 = palette.cyan
vim.g.terminal_color_7 = color(palette.base0, palette.base00)
vim.g.terminal_color_8 = color(palette.base02, palette.base2)
vim.g.terminal_color_9 = palette.red
vim.g.terminal_color_10 = palette.green
vim.g.terminal_color_11 = palette.yellow
vim.g.terminal_color_12 = palette.blue
vim.g.terminal_color_13 = palette.magenta
vim.g.terminal_color_14 = palette.cyan
vim.g.terminal_color_15 = color(palette.base1, palette.base01)

for group, opts in pairs(highlights) do
    vim.api.nvim_set_hl(0, group, opts)
end

vim.g.colors_name = "solarized"
