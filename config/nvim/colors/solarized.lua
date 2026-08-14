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


-- Semantic UI colours the plugin groups below are built from. `color()` reads
-- vim.o.background, so these resolve once, when the colorscheme is sourced.
local ui_bg      = color(palette.base03, palette.base3)  -- editor background
local ui_bg_alt  = color(palette.base02, palette.base2)  -- floats, panels, subtle fills
local ui_fg      = color(palette.base0, palette.base00)  -- body text
local ui_fg_hi   = color(palette.base1, palette.base01)  -- emphasized text
local ui_fg_mute = color(palette.base00, palette.base0)  -- de-emphasized text
local ui_fg_dim  = color(palette.base01, palette.base1)  -- comments, disabled text

-- Tint the editor background towards `target`, for washes behind diffs and
-- virtual text that must stay readable in both backgrounds.
local wash = function(target, ratio)
    return blend_colors(ui_bg, target, ratio)
end

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
    ["@lsp.typemod.variable.global"]   = { fg = color(palette.base1, palette.base01), bold = true },

    -- Editor groups that plugins link into
    Directory                          = { fg = palette.blue },
    Conceal                            = { fg = ui_fg_dim },
    Folded                             = { fg = ui_fg_dim, bg = ui_bg_alt },
    FoldColumn                         = { fg = ui_fg_dim, bg = "NONE" },
    Whitespace                         = { fg = ui_bg_alt },
    EndOfBuffer                        = { link = "NonText" },
    MsgArea                            = { fg = ui_fg },
    MsgSeparator                       = { link = "WinSeparator" },
    ModeMsg                            = { fg = ui_fg_hi, bold = true },
    MoreMsg                            = { fg = palette.blue },
    Question                           = { fg = palette.cyan },
    WarningMsg                         = { fg = palette.yellow },
    ErrorMsg                           = { fg = palette.red },
    CurSearch                          = { link = "IncSearch" },
    Substitute                         = { fg = ui_bg, bg = palette.orange },
    WinBar                             = { fg = ui_fg_hi, bg = ui_bg_alt, bold = true },
    WinBarNC                           = { fg = ui_fg_mute, bg = ui_bg_alt },
    TermCursor                         = { link = "Cursor" },
    SnippetTabstop                     = { bg = ui_bg_alt },
    Added                              = { link = "DiffAdd" },
    Changed                            = { link = "DiffChange" },
    Removed                            = { link = "DiffDelete" },

    -- Diagnostics: virtual text, floats and the Ok severity (nvim-lint, nvim-lspconfig)
    DiagnosticOk                       = { fg = palette.green },
    DiagnosticSignOk                   = { fg = palette.green, bg = "NONE" },
    DiagnosticUnderlineOk              = { fg = palette.green, undercurl = true },
    DiagnosticVirtualTextError         = { fg = palette.red, bg = wash(palette.red, 0.12) },
    DiagnosticVirtualTextWarn          = { fg = palette.yellow, bg = wash(palette.yellow, 0.12) },
    DiagnosticVirtualTextInfo          = { fg = palette.cyan, bg = wash(palette.cyan, 0.12) },
    DiagnosticVirtualTextHint          = { fg = palette.blue, bg = wash(palette.blue, 0.12) },
    DiagnosticVirtualTextOk            = { fg = palette.green, bg = wash(palette.green, 0.12) },
    DiagnosticFloatingError            = { link = "DiagnosticError" },
    DiagnosticFloatingWarn             = { link = "DiagnosticWarn" },
    DiagnosticFloatingInfo             = { link = "DiagnosticInfo" },
    DiagnosticFloatingHint             = { link = "DiagnosticHint" },
    DiagnosticFloatingOk               = { link = "DiagnosticOk" },
    DiagnosticDeprecated               = { fg = ui_fg_dim, strikethrough = true, sp = palette.red },
    DiagnosticUnnecessary              = { fg = ui_fg_dim, italic = true },

    -- LSP (nvim-lspconfig, lazydev, schemastore)
    LspInlayHint                       = { fg = ui_fg_dim, bg = ui_bg_alt, italic = true },
    LspReferenceText                   = { bg = ui_bg_alt },
    LspReferenceRead                   = { bg = ui_bg_alt },
    LspReferenceWrite                  = { bg = ui_bg_alt, underline = true },
    LspReferenceTarget                 = { link = "LspReferenceText" },
    LspSignatureActiveParameter        = { fg = palette.orange, bold = true },
    LspCodeLens                        = { fg = ui_fg_dim, italic = true },
    LspCodeLensSeparator               = { fg = ui_fg_dim },
    LspInfoBorder                      = { link = "FloatBorder" },

    -- nvim-cmp + lspkind (per-kind colours are generated below)
    CmpItemAbbr                        = { fg = ui_fg },
    CmpItemAbbrDeprecated              = { fg = ui_fg_dim, strikethrough = true },
    CmpItemAbbrMatch                   = { fg = palette.blue, bold = true },
    CmpItemAbbrMatchFuzzy              = { fg = palette.blue_lighter },
    CmpItemMenu                        = { fg = ui_fg_dim, italic = true },
    CmpItemKind                        = { fg = palette.violet },
    CmpItemKindIcon                    = { link = "CmpItemKind" },
    CmpGhostText                       = { fg = ui_fg_dim, italic = true },

    -- LuaSnip: snippet node states
    LuasnipInsertNodeActive            = { bg = wash(palette.yellow, 0.20) },
    LuasnipInsertNodePassive           = { bg = ui_bg_alt },
    LuasnipInsertNodeVisited           = { bg = wash(palette.green, 0.12) },
    LuasnipInsertNodeUnvisited         = { bg = "NONE" },
    LuasnipChoiceNodeActive            = { bg = wash(palette.magenta, 0.20) },
    LuasnipChoiceNodePassive           = { bg = ui_bg_alt },
    LuasnipExitNodeActive              = { bg = wash(palette.orange, 0.20) },
    LuasnipSnippetPassive              = { bg = "NONE" },

    -- gitsigns.nvim (Nr/Ln/Cul and Staged variants fall back to these)
    GitSignsAdd                        = { fg = palette.green },
    GitSignsChange                     = { fg = palette.yellow },
    GitSignsDelete                     = { fg = palette.red },
    GitSignsTopdelete                  = { fg = palette.red_darker },
    GitSignsChangedelete               = { fg = palette.orange },
    GitSignsUntracked                  = { fg = palette.green_darker },
    GitSignsAddLn                      = { bg = wash(palette.green, 0.12) },
    GitSignsChangeLn                   = { bg = wash(palette.yellow, 0.12) },
    GitSignsAddPreview                 = { bg = wash(palette.green, 0.15) },
    GitSignsDeletePreview              = { bg = wash(palette.red, 0.15) },
    GitSignsAddInline                  = { bg = wash(palette.green, 0.30) },
    GitSignsChangeInline               = { bg = wash(palette.yellow, 0.30) },
    GitSignsDeleteInline               = { bg = wash(palette.red, 0.30) },
    GitSignsDeleteVirtLn               = { fg = palette.red_darker, bg = wash(palette.red, 0.10) },
    GitSignsDeleteVirtLnInLine         = { bg = wash(palette.red, 0.30) },
    GitSignsVirtLnum                   = { fg = ui_fg_dim },
    GitSignsCurrentLineBlame           = { fg = ui_fg_dim, italic = true },
    GitSignsNoEOLPreview               = { fg = ui_fg_dim },

    -- diffview.nvim
    DiffviewNormal                     = { link = "Normal" },
    DiffviewNonText                    = { link = "NonText" },
    DiffviewCursorLine                 = { link = "CursorLine" },
    DiffviewEndOfBuffer                = { link = "EndOfBuffer" },
    DiffviewSignColumn                 = { link = "SignColumn" },
    DiffviewStatusLine                 = { link = "StatusLine" },
    DiffviewStatusLineNC               = { link = "StatusLineNC" },
    DiffviewWinSeparator               = { link = "WinSeparator" },
    DiffviewFilePanelTitle             = { fg = palette.blue, bold = true },
    DiffviewFilePanelCounter           = { fg = palette.violet, bold = true },
    DiffviewFilePanelRootPath          = { link = "DiffviewFilePanelTitle" },
    DiffviewFilePanelFileName          = { fg = ui_fg },
    DiffviewFilePanelPath              = { fg = ui_fg_dim },
    DiffviewFilePanelSelected          = { fg = palette.yellow, bold = true },
    DiffviewFilePanelInsertions        = { fg = palette.green },
    DiffviewFilePanelDeletions         = { fg = palette.red },
    DiffviewFilePanelConflicts         = { fg = palette.orange },
    DiffviewFolderName                 = { fg = palette.blue },
    DiffviewFolderSign                 = { fg = palette.blue_darker },
    DiffviewHash                       = { fg = palette.violet },
    DiffviewReference                  = { fg = palette.cyan },
    DiffviewReflogSelector             = { fg = palette.magenta },
    DiffviewDim1                       = { fg = ui_fg_dim },
    DiffviewPrimary                    = { fg = palette.blue },
    DiffviewSecondary                  = { fg = palette.orange },
    DiffviewStatusAdded                = { fg = palette.green },
    DiffviewStatusUntracked            = { fg = palette.green_darker },
    DiffviewStatusModified             = { fg = palette.yellow },
    DiffviewStatusRenamed              = { fg = palette.yellow },
    DiffviewStatusCopied               = { fg = palette.yellow },
    DiffviewStatusTypeChange           = { fg = palette.yellow },
    DiffviewStatusUnmerged             = { fg = palette.orange },
    DiffviewStatusUnknown              = { fg = palette.red },
    DiffviewStatusDeleted              = { fg = palette.red },
    DiffviewStatusBroken               = { fg = palette.red_darker },
    DiffviewStatusIgnored              = { fg = ui_fg_dim },
    DiffviewDiffAdd                    = { bg = wash(palette.green, 0.14) },
    DiffviewDiffChange                 = { bg = wash(palette.yellow, 0.10) },
    DiffviewDiffText                   = { bg = wash(palette.yellow, 0.28) },
    DiffviewDiffDelete                 = { fg = wash(palette.red, 0.45), bg = wash(palette.red, 0.08) },
    DiffviewDiffDeleteDim              = { fg = wash(palette.red, 0.30), bg = "NONE" },
    DiffviewDiffAddAsDelete            = { bg = wash(palette.red, 0.14) },

    -- vim-fugitive, git and gitcommit buffers
    fugitiveHeader                     = { fg = palette.yellow, bold = true },
    fugitiveHeading                    = { fg = palette.orange, bold = true },
    fugitiveHelpHeader                 = { link = "fugitiveHeader" },
    fugitiveHelpTag                    = { fg = palette.violet },
    fugitiveHash                       = { fg = palette.violet },
    fugitiveSymbolicRef                = { fg = palette.cyan },
    fugitiveCount                      = { fg = palette.magenta },
    fugitiveInstruction                = { fg = palette.blue },
    fugitiveStop                       = { fg = palette.red },
    fugitiveModifier                   = { fg = palette.yellow },
    fugitiveStagedHeading              = { fg = palette.green, bold = true },
    fugitiveStagedModifier             = { fg = palette.green },
    fugitiveUnstagedHeading            = { fg = palette.yellow, bold = true },
    fugitiveUnstagedModifier           = { fg = palette.yellow },
    fugitiveUntrackedHeading           = { fg = palette.red, bold = true },
    fugitiveUntrackedModifier          = { fg = palette.red },
    gitcommitSummary                   = { fg = ui_fg_hi },
    gitcommitOverflow                  = { fg = palette.red },
    gitcommitComment                   = { link = "Comment" },
    gitcommitBranch                    = { fg = palette.magenta },
    gitcommitHeader                    = { fg = palette.orange, bold = true },
    gitcommitSelectedFile              = { fg = palette.green },
    gitcommitDiscardedFile             = { fg = palette.red },
    gitcommitUntrackedFile             = { fg = palette.yellow },
    gitHash                            = { fg = palette.violet },
    gitIdentity                        = { fg = palette.cyan },
    gitDate                            = { fg = ui_fg_dim },
    diffFile                           = { fg = palette.blue },
    diffNewFile                        = { fg = palette.green },
    diffOldFile                        = { fg = palette.red },
    diffIndexLine                      = { fg = palette.violet },
    diffLine                           = { fg = ui_fg_dim },
    diffSubname                        = { fg = ui_fg_dim },

    -- telescope.nvim (+ fzf-native, symbols, all-recent)
    TelescopeNormal                    = { link = "NormalFloat" },
    TelescopeTitle                     = { link = "FloatTitle" },
    TelescopePromptPrefix              = { fg = palette.orange },
    TelescopePromptCounter             = { fg = ui_fg_dim },
    TelescopeMultiIcon                 = { fg = palette.yellow },
    TelescopeResultsComment            = { link = "Comment" },
    TelescopeResultsClass              = { link = "Type" },
    TelescopeResultsStruct             = { link = "Type" },
    TelescopeResultsField              = { link = "Identifier" },
    TelescopeResultsFunction           = { link = "Function" },
    TelescopeResultsMethod             = { link = "Function" },
    TelescopeResultsIdentifier         = { link = "Identifier" },
    TelescopeResultsVariable           = { link = "Variable" },
    TelescopeResultsConstant           = { link = "Constant" },
    TelescopeResultsNumber             = { link = "Number" },
    TelescopeResultsOperator           = { link = "Operator" },
    TelescopeResultsSpecialComment     = { link = "SpecialComment" },
    TelescopeResultsLineNr             = { link = "LineNr" },
    TelescopeResultsDiffAdd            = { fg = palette.green },
    TelescopeResultsDiffChange         = { fg = palette.yellow },
    TelescopeResultsDiffDelete         = { fg = palette.red },
    TelescopeResultsDiffUntracked      = { fg = ui_fg_dim },
    TelescopePreviewLine               = { bg = ui_bg_alt },
    TelescopePreviewMatch              = { link = "IncSearch" },
    TelescopePreviewDirectory          = { fg = palette.blue },
    TelescopePreviewLink               = { fg = palette.cyan },
    TelescopePreviewExecute            = { fg = palette.green },
    TelescopePreviewRead               = { fg = palette.yellow },
    TelescopePreviewWrite              = { fg = palette.orange },
    TelescopePreviewSize               = { fg = palette.violet },
    TelescopePreviewDate               = { fg = ui_fg_dim },
    TelescopePreviewUser               = { fg = palette.magenta },
    TelescopePreviewGroup              = { fg = palette.magenta_darker },
    TelescopePreviewMessage            = { link = "NormalFloat" },
    TelescopePreviewMessageFillchar    = { link = "NormalFloat" },

    -- oil.nvim
    OilDir                             = { fg = palette.blue, bold = true },
    OilDirIcon                         = { fg = palette.blue },
    OilFile                            = { fg = ui_fg },
    OilLink                            = { fg = palette.cyan },
    OilLinkTarget                      = { fg = palette.cyan_darker },
    OilOrphanLink                      = { fg = palette.red },
    OilOrphanLinkTarget                = { fg = palette.red_darker },
    OilSocket                          = { fg = palette.magenta },
    OilEmpty                           = { fg = ui_fg_dim },
    OilHidden                          = { fg = ui_fg_dim },
    OilDirHidden                       = { fg = ui_fg_dim, bold = true },
    OilFileHidden                      = { fg = ui_fg_dim },
    OilLinkHidden                      = { fg = ui_fg_dim },
    OilLinkTargetHidden                = { fg = ui_fg_dim },
    OilOrphanLinkHidden                = { fg = ui_fg_dim },
    OilOrphanLinkTargetHidden          = { fg = ui_fg_dim },
    OilSocketHidden                    = { fg = ui_fg_dim },
    OilCreate                          = { fg = palette.green },
    OilDelete                          = { fg = palette.red },
    OilMove                            = { fg = palette.yellow },
    OilCopy                            = { fg = palette.cyan },
    OilChange                          = { fg = palette.orange },
    OilRestore                         = { fg = palette.green },
    OilPurge                           = { fg = palette.red_darker },
    OilTrash                           = { fg = palette.magenta },
    OilTrashSourcePath                 = { fg = ui_fg_dim, italic = true },

    -- flash.nvim and mini.jump2d: jump labels
    FlashBackdrop                      = { fg = ui_fg_dim },
    FlashMatch                         = { fg = ui_bg, bg = palette.blue },
    FlashCurrent                       = { fg = ui_bg, bg = palette.orange },
    FlashLabel                         = { fg = ui_bg, bg = palette.magenta, bold = true },
    FlashPrompt                        = { link = "MsgArea" },
    FlashPromptIcon                    = { link = "Special" },
    FlashCursor                        = { link = "Cursor" },
    MiniJump2dSpot                     = { fg = palette.magenta, bold = true, nocombine = true },
    MiniJump2dSpotUnique               = { fg = palette.orange, bold = true, nocombine = true },
    MiniJump2dSpotAhead                = { fg = palette.cyan, bg = ui_bg_alt, nocombine = true },
    MiniJump2dDim                      = { fg = ui_fg_dim, nocombine = true },

    -- mini.hipatterns (hex_color highlighters colour themselves)
    MiniHipatternsFixme                = { fg = ui_bg, bg = palette.red, bold = true },
    MiniHipatternsHack                 = { fg = ui_bg, bg = palette.yellow, bold = true },
    MiniHipatternsTodo                 = { fg = ui_bg, bg = palette.blue, bold = true },
    MiniHipatternsNote                 = { fg = ui_bg, bg = palette.cyan, bold = true },

    -- which-key.nvim
    WhichKey                           = { fg = palette.magenta, bold = true },
    WhichKeyGroup                      = { fg = palette.blue },
    WhichKeyDesc                       = { fg = ui_fg },
    WhichKeySeparator                  = { fg = ui_fg_dim },
    WhichKeyValue                      = { fg = ui_fg_dim },
    WhichKeyIcon                       = { fg = palette.cyan },
    WhichKeyNormal                     = { link = "NormalFloat" },
    WhichKeyBorder                     = { link = "FloatBorder" },
    WhichKeyTitle                      = { link = "FloatTitle" },
    WhichKeyColorAzure                 = { fg = palette.blue },
    WhichKeyColorBlue                  = { fg = palette.blue_darker },
    WhichKeyColorCyan                  = { fg = palette.cyan },
    WhichKeyColorGreen                 = { fg = palette.green },
    WhichKeyColorGrey                  = { fg = ui_fg_dim },
    WhichKeyColorOrange                = { fg = palette.orange },
    WhichKeyColorPurple                = { fg = palette.violet },
    WhichKeyColorRed                   = { fg = palette.red },
    WhichKeyColorYellow                = { fg = palette.yellow },

    -- quicker.nvim (quickfix)
    QuickFixHeaderHard                 = { fg = palette.blue, bold = true },
    QuickFixHeaderSoft                 = { fg = ui_fg_dim },
    QuickFixFilename                   = { fg = palette.blue },
    QuickFixFilenameInvalid            = { fg = ui_fg_dim, strikethrough = true },
    QuickFixText                       = { fg = ui_fg },
    QuickFixTextInvalid                = { fg = ui_fg_dim },

    -- overseer.nvim
    OverseerPENDING                    = { fg = ui_fg_dim },
    OverseerRUNNING                    = { fg = palette.blue },
    OverseerSUCCESS                    = { fg = palette.green },
    OverseerCANCELED                   = { fg = palette.yellow },
    OverseerFAILURE                    = { fg = palette.red },
    OverseerDISPOSED                   = { fg = ui_fg_dim, italic = true },
    OverseerTask                       = { fg = palette.yellow, bold = true },
    OverseerTaskBorder                 = { fg = ui_fg_dim },
    OverseerOutput                     = { fg = ui_fg },
    OverseerComponent                  = { fg = palette.cyan },
    OverseerField                      = { fg = palette.violet },

    -- mason.nvim
    MasonNormal                        = { link = "NormalFloat" },
    MasonBackdrop                      = { bg = ui_bg },
    MasonHeader                        = { fg = ui_bg, bg = palette.orange, bold = true },
    MasonHeaderSecondary               = { fg = ui_bg, bg = palette.yellow, bold = true },
    MasonHeading                       = { fg = ui_fg_hi, bold = true },
    MasonHighlight                     = { fg = palette.cyan },
    MasonHighlightSecondary            = { fg = palette.yellow },
    MasonHighlightBlock                = { fg = ui_bg, bg = palette.cyan },
    MasonHighlightBlockBold            = { fg = ui_bg, bg = palette.cyan, bold = true },
    MasonHighlightBlockSecondary       = { fg = ui_bg, bg = palette.yellow },
    MasonHighlightBlockBoldSecondary   = { fg = ui_bg, bg = palette.yellow, bold = true },
    MasonMuted                         = { fg = ui_fg_dim },
    MasonMutedBlock                    = { fg = ui_fg, bg = ui_bg_alt },
    MasonMutedBlockBold                = { fg = ui_fg, bg = ui_bg_alt, bold = true },
    MasonError                         = { fg = palette.red },
    MasonWarning                       = { fg = palette.yellow },
    MasonLink                          = { fg = palette.blue, underline = true },

    -- lazy.nvim
    LazyNormal                         = { link = "NormalFloat" },
    LazyH1                             = { fg = ui_bg, bg = palette.orange, bold = true },
    LazyH2                             = { fg = ui_fg_hi, bold = true },
    LazyButton                         = { bg = ui_bg_alt },
    LazyButtonActive                   = { fg = ui_bg, bg = palette.yellow, bold = true },
    LazyComment                        = { link = "Comment" },
    LazyCommit                         = { fg = palette.violet },
    LazyCommitIssue                    = { fg = palette.magenta },
    LazyCommitType                     = { fg = palette.orange },
    LazyCommitScope                    = { fg = ui_fg_dim, italic = true },
    LazyDimmed                         = { fg = ui_fg_dim },
    LazyProp                           = { fg = ui_fg_dim },
    LazyValue                          = { fg = palette.cyan },
    LazyDir                            = { fg = palette.blue },
    LazyUrl                            = { fg = palette.blue, underline = true },
    LazyLocal                          = { fg = palette.cyan },
    LazyNoCond                         = { fg = palette.yellow },
    LazyProgressDone                   = { fg = palette.green },
    LazyProgressTodo                   = { fg = ui_fg_dim },
    LazySpecial                        = { fg = palette.magenta },
    LazyTaskOutput                     = { fg = ui_fg },
    LazyTaskError                      = { fg = palette.red },

    -- undotree
    UndotreeNode                       = { fg = palette.blue },
    UndotreeNodeCurrent                = { fg = palette.magenta, bold = true },
    UndotreeBranch                     = { fg = ui_fg_dim },
    UndotreeSeq                        = { fg = ui_fg_dim },
    UndotreeCurrent                    = { fg = palette.magenta, bold = true },
    UndotreeNext                       = { fg = palette.yellow },
    UndotreeHead                       = { fg = palette.cyan },
    UndotreeTimeStamp                  = { fg = ui_fg_dim, italic = true },
    UndotreeFirstNode                  = { fg = palette.violet },
    UndotreeSavedSmall                 = { fg = palette.green },
    UndotreeSavedBig                   = { fg = palette.green, bold = true },
    UndotreeHelp                       = { link = "Comment" },
    UndotreeHelpKey                    = { fg = palette.blue },
    UndotreeHelpTitle                  = { fg = palette.orange, bold = true },

    -- csvview.nvim (rainbow columns and the info panel)
    CsvViewDelimiter                   = { fg = ui_fg_dim },
    CsvViewComment                     = { link = "Comment" },
    CsvViewHeaderLine                  = { fg = ui_fg_hi, bg = ui_bg_alt, bold = true },
    CsvViewStickyHeaderSeparator       = { fg = ui_fg_dim },
    CsvViewCol0                        = { fg = palette.blue },
    CsvViewCol1                        = { fg = palette.green },
    CsvViewCol2                        = { fg = palette.yellow },
    CsvViewCol3                        = { fg = palette.magenta },
    CsvViewCol4                        = { fg = palette.cyan },
    CsvViewCol5                        = { fg = palette.orange },
    CsvViewCol6                        = { fg = palette.violet },
    CsvViewCol7                        = { fg = palette.red },
    CsvViewCol8                        = { fg = ui_fg },
    CsvViewInfoTitle                   = { link = "Title" },
    CsvViewInfoSection                 = { fg = palette.green },
    CsvViewInfoLabel                   = { fg = palette.blue },
    CsvViewInfoText                    = { fg = ui_fg },
    CsvViewInfoNumber                  = { fg = palette.cyan },
    CsvViewInfoHint                    = { fg = ui_fg_dim },
    CsvViewInfoTableHeader             = { link = "TabLineSel" },
    CsvViewInfoTableBorder             = { fg = ui_fg_dim },
    CsvViewInfoPositive                = { fg = palette.green },
    CsvViewInfoNegative                = { fg = palette.red },
    CsvViewInfoNeutral                 = { fg = ui_fg_dim },
    CsvViewInfoScoreBar                = { fg = palette.violet },
    csvCol0                            = { link = "CsvViewCol0" },
    csvCol1                            = { link = "CsvViewCol1" },
    csvCol2                            = { link = "CsvViewCol2" },
    csvCol3                            = { link = "CsvViewCol3" },
    csvCol4                            = { link = "CsvViewCol4" },
    csvCol5                            = { link = "CsvViewCol5" },
    csvCol6                            = { link = "CsvViewCol6" },
    csvCol7                            = { link = "CsvViewCol7" },
    csvCol8                            = { link = "CsvViewCol8" },

    -- nvim-treesitter: markup, tags and diff captures (markdown, html, git)
    ["@markup"]                        = { fg = ui_fg },
    ["@markup.heading"]                = { fg = palette.orange, bold = true },
    ["@markup.heading.1"]              = { fg = palette.orange, bold = true },
    ["@markup.heading.2"]              = { fg = palette.yellow, bold = true },
    ["@markup.heading.3"]              = { fg = palette.green, bold = true },
    ["@markup.heading.4"]              = { fg = palette.cyan, bold = true },
    ["@markup.heading.5"]              = { fg = palette.blue, bold = true },
    ["@markup.heading.6"]              = { fg = palette.violet, bold = true },
    ["@markup.strong"]                 = { fg = ui_fg_hi, bold = true },
    ["@markup.italic"]                 = { italic = true },
    ["@markup.underline"]              = { underline = true },
    ["@markup.strikethrough"]          = { strikethrough = true },
    ["@markup.quote"]                  = { fg = ui_fg_dim, italic = true },
    ["@markup.math"]                   = { fg = palette.cyan },
    ["@markup.link"]                   = { fg = palette.blue },
    ["@markup.link.url"]               = { fg = palette.blue, underline = true },
    ["@markup.link.label"]             = { fg = palette.cyan },
    ["@markup.raw"]                    = { fg = palette.cyan },
    ["@markup.raw.block"]              = { fg = ui_fg },
    ["@markup.list"]                   = { fg = palette.orange },
    ["@markup.list.checked"]           = { fg = palette.green },
    ["@markup.list.unchecked"]         = { fg = ui_fg_dim },
    ["@tag"]                           = { fg = palette.blue },
    ["@tag.builtin"]                   = { fg = palette.blue },
    ["@tag.attribute"]                 = { fg = palette.yellow },
    ["@tag.delimiter"]                 = { link = "Ignore" },
    ["@attribute"]                     = { link = "PreProc" },
    ["@module"]                        = { link = "Namespace" },
    ["@label"]                         = { link = "Label" },
    ["@number"]                        = { link = "Number" },
    ["@character"]                     = { link = "Character" },
    ["@character.special"]             = { link = "SpecialChar" },
    ["@string.escape"]                 = { fg = palette.orange },
    ["@string.special.url"]            = { fg = palette.blue, underline = true },
    ["@constant.builtin"]              = { fg = palette.cyan, italic = true },
    ["@variable.parameter"]            = { link = "Variable" },
    ["@variable.member"]               = { link = "Variable" },
    ["@punctuation.special"]           = { fg = palette.orange },
    ["@keyword.import"]                = { link = "Include" },
    ["@keyword.exception"]             = { link = "Exception" },
    ["@keyword.return"]                = { link = "Keyword" },
    ["@comment.todo"]                  = { link = "Todo" },
    ["@comment.note"]                  = { link = "MiniHipatternsNote" },
    ["@comment.warning"]               = { link = "MiniHipatternsHack" },
    ["@comment.error"]                 = { link = "MiniHipatternsFixme" },
    ["@diff.plus"]                     = { fg = palette.green },
    ["@diff.minus"]                    = { fg = palette.red },
    ["@diff.delta"]                    = { fg = palette.yellow },
}


-- nvim-cmp colours each completion item by its LSP kind, using both
-- `CmpItemKind<Kind>` and `CmpItemKind<Kind>Icon`. Group the kinds so a kind
-- carries the same colour as the syntax group it stands for.
local cmp_kinds = {
    Text          = ui_fg,
    Method        = palette.blue,
    Function      = palette.blue,
    Constructor   = palette.blue,
    Field         = color(palette.base1, palette.base01),
    Variable      = color(palette.base1, palette.base01),
    Property      = color(palette.base1, palette.base01),
    Class         = palette.yellow,
    Interface     = palette.yellow,
    Struct        = palette.yellow,
    Enum          = palette.yellow,
    Event         = palette.yellow,
    TypeParameter = palette.yellow,
    Module        = palette.orange,
    Unit          = palette.cyan,
    Value         = palette.cyan,
    Constant      = palette.cyan,
    EnumMember    = palette.cyan,
    Keyword       = palette.green,
    Operator      = palette.green,
    Snippet       = palette.green,
    Color         = palette.magenta,
    File          = palette.violet,
    Folder        = palette.violet,
    Reference     = palette.violet,
}

for kind, fg in pairs(cmp_kinds) do
    highlights["CmpItemKind" .. kind] = { fg = fg }
    highlights["CmpItemKind" .. kind .. "Icon"] = { fg = fg }
end


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
