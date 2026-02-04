local black = "#100F0F"
local base_950 = "#1C1B1A"
local base_900 = "#282726"
local base_850 = "#343331"
local base_800 = "#403E3C"
local base_700 = "#575653"
local base_600 = "#6F6E69"
local base_500 = "#878580"
local base_300 = "#B7B5AC"
local base_200 = "#CECDC3"
local base_150 = "#DAD8CE"
local base_100 = "#E6E4D9"
local base_50 = "#F2F0E5"
local light = "#FFFCF0"

local red = "#bf616a"
local orange = "#d08770"
local yellow = "#ebcb8b"
local green = "#a3be8c"
local cyan = "#bee9e8"
local blue = "#81A1C1"
local purple = "#b48ead"
local magenta = "#A97EA1"

local highlights = {
    -- Attributes
    Bold = { bold = true },
    Italic = { italic = true },
    Underline = { underline = true },
    NonText = { fg = base_500 },
    Error = { fg = red },
    Title = { fg = base_200 },

    -- Editor
    Normal = { fg = base_300, bg = black },
    NormalNC = { fg = base_500, bg = black },
    NormalSB = { link = "Normal" },
    NormalFloat = { fg = base_300, bg = base_900 },
    FloatBorder = { fg = base_700, bg = base_900 },
    FloatTitle = { link = "Title" },
    FloatFooter = { link = "NormalFloat" },
    ColorColumn = { bg = base_900 },
    IncSearch = { fg = black, bg = cyan },
    Search = { fg = black, bg = blue },
    Cursor = { fg = black, bg = yellow },
    iCursor = { fg = yellow, bg = black },
    MatchParen = { fg = cyan },
    Pmenu = { fg = base_300, bg = base_950 },
    PmenuSbar = { fg = base_800, bg = base_950 },
    PmenuSel = { fg = black, bg = yellow },
    PmenuThumb = { fg = base_800, bg = base_950 },
    Visual = { bg = base_800 },
    VisualNOS = { link = "Visual" },
    TabLine = { fg = base_800, bg = base_300 },
    TabLineFill = { fg = base_800, bg = base_300 },
    TabLineSel = { link = "Normal" },
    StatusLine = { fg = base_300, bg = base_900 },
    StatusLineNC = { link = "StatusLine" },
    StatusLineTerm = { link = "StatusLine" },
    StatusLineTermNC = { link = "StatusLine" },
    VertSplit = { fg = base_850, bg = black },
    WinSeparator = { link = "VertSplit" },

    -- Gutter
    LineNr = { fg = base_600 },
    CursorColumn = { bg = black },
    CursorLine = { bg = base_900 },
    CursorLineNr = { fg = yellow, bg = base_900 },
    CursorLineSign = { bg = base_900 },
    Folded = { fg = base_500, bg = black, bold = true },
    FoldColumn = { fg = base_500, bg = black },
    SignColumn = { fg = base_500, bg = black },
    SignColumnSB = { fg = base_500, bg = black },

    -- Spell
    SpecialKey = { link = "Normal" },
    SpellBad = { undercurl = true, sp = orange },
    SpellCap = { undercurl = true, sp = orange },
    SpellLocal = { undercurl = true, sp = orange },
    SpellRare = { undercurl = true, sp = orange },

    -- Prompt/Status
    EndOfBuffer = { fg = base_500 },
    ErrorMsg = { fg = red },
    ModeMsg = { fg = base_300 },
    MoreMsg = { fg = base_300 },
    Question = { fg = base_300 },

    -- Neovim Diagnostics API (for LSP)
    DiagnosticWarn = { fg = orange },
    DiagnosticError = { fg = red },
    DiagnosticInfo = { fg = blue },
    DiagnosticHint = { fg = base_500 },
    DiagnosticUnderlineWarn = { fg = orange, undercurl = true },
    DiagnosticUnderlineError = { fg = red, undercurl = true },
    DiagnosticUnderlineInfo = { fg = blue, undercurl = true },
    DiagnosticUnderlineHint = { fg = base_500, undercurl = true },

    Comment = { fg = base_500, italic = true },
    Conceal = { bg = "NONE" },
    Delimiter = { fg = base_500 },
    Operator = { fg = base_500 },
    SpecialChar = { fg = magenta },
    SpecialComment = { fg = magenta, italic = true },

    Identifier = { fg = base_100 },
    Field = { fg = base_300 },
    Tag = { fg = base_200 },
    Variable = { fg = base_300 },

    -- Tier 3 (Data / Literals)
    Constant = { fg = base_50, bold = true },
    Boolean = { link = "Constant" },
    Float = { link = "Constant" },
    Number = { link = "Constant" },
    String = { fg = green },
    Character = { link = "String" },

    Keyword = { fg = purple },
    Decorator = { link = "Keyword" },
    Define = { link = "Keyword" },
    Include = { link = "Keyword" },
    PreProc = { link = "Keyword" },
    StorageClass = { link = "Keyword" },
    Label = { link = "Keyword" },
    Conditional = { link = "Keyword" },
    Exception = { link = "Keyword" },
    Repeat = { link = "Keyword" },
    Statement = { link = "Keyword" },

    Function = { fg = blue },
    Builtin = { fg = cyan },

    Structure = { fg = base_50, bold = true },
    Type = { link = "Structure" },
    Typedef = { link = "Structure" },
    Namespace = { link = "Structure" },

    Special = { fg = orange },
    Todo = { fg = orange },
    Annotation = { fg = orange },
    Macro = { fg = magenta },
    PreCondit = { fg = magenta },


    -- Treesitter
    ["@comment"] = { link = "Comment" },
    ["@constant"] = { link = "Constant" },
    ["@string"] = { link = "String" },
    ["@string.regexp"] = { link = "SpecialChar" },
    ["@number"] = { link = "Number" },
    ["@keyword"] = { link = "Keyword" },
    ["@variable"] = { link = "Variable" },
    ["@variable.builtin"] = { link = "Variable" },
    ["@variable.member"] = { link = "Variable" },
    ["@property"] = { link = "Field" },
    ["@operator"] = { link = "Operator" },
    ["@boolean"] = { link = "Boolean" },
    ["@function"] = { link = "Function" },
    ["@function.builtin"] = { link = "Function" },
    ["@function.macro"] = { link = "Function" },
    ["@function.call"] = { link = "Function" },
    ["@type"] = { link = "Type" },
    ["@type.builtin"] = { link = "Type" },
    ["@punctuation"] = { link = "Delimiter" },
    ["@punctuation.bracket"] = { link = "Delimiter" },
    ["@punctuation.delimiter"] = { link = "Delimiter" },

    TelescopeBorder = { link = "FloatBorder" },
    TelescopePromptBorder = { link = "FloatBorder" },
    TelescopePromptNormal = { link = "NormalFloat" },
    TelescopePromptTitle = { link = "FloatTitle" },
    TelescopeResultsBorder = { link = "FloatBorder" },
    TelescopeResultsNormal = { link = "NormalFloat" },
    TelescopeResultsTitle = { link = "FloatTitle" },
    TelescopePreviewBorder = { link = "FloatBorder" },
    TelescopePreviewNormal = { link = "NormalFloat" },
    TelescopePreviewTitle = { link = "FloatTitle" },
    TelescopeMatching = { link = "MatchParen" },
    TelescopeSelection = { link = "Search" },
    TelescopeSelectionCaret = { link = "Search" },

}

for group, opts in pairs(highlights) do
    vim.api.nvim_set_hl(0, group, opts)
end

vim.g.colors_name = "shrike"
