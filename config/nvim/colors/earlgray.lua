-- Earl Gray Colorscheme for Neovim
-- Based on https://earl-grey.halt.wtf/

if vim.fn.exists("syntax_on") then
  vim.cmd("syntax reset")
end

vim.o.termguicolors = true
vim.g.colors_name = "earlgray"

-- Color Palette
local colors = {
  -- Primary palette
  foreground = "#605A52",
  foreground_alt = "#5A544C",
  background = "#FCFBF9",
  background_alt = "#F7F3EE",
  purple = "#83577D",
  blue = "#556995",
  teal = "#477A7B",
  orange = "#886A44",
  green = "#747B4D",
  red = "#8F5652",
  comment = "#9E9A95",
  berry = "#AA5087",

  -- Blend colors
  grey1 = "#ECEBE8",
  grey2 = "#DDDBD8",
  grey3 = "#CDCBC7",
  grey4 = "#BEBBB6",
  grey5 = "#AEABA6",
  grey6 = "#9E9A95",
  grey7 = "#8F8A84",
  grey8 = "#7F7A73",
  grey9 = "#706A63",

  purple1 = "#F0EBED",
  purple2 = "#E4DAE0",
  purple3 = "#D8CAD4",
  purple4 = "#CCB9C7",
  purple5 = "#C0A9BB",
  purple6 = "#B399AF",
  purple7 = "#A788A2",
  purple8 = "#9B7896",
  purple9 = "#8F6789",

  blue1 = "#EBECEF",
  blue2 = "#DBDEE5",
  blue3 = "#CACFDB",
  blue4 = "#B9C1D1",
  blue5 = "#A9B2C7",
  blue6 = "#98A3BD",
  blue7 = "#8795B3",
  blue8 = "#7686A9",
  blue9 = "#66789F",

  teal1 = "#EAEEEC",
  teal2 = "#D8E1E0",
  teal3 = "#C6D4D3",
  teal4 = "#B4C7C7",
  teal5 = "#A2BBBA",
  teal6 = "#8FAEAD",
  teal7 = "#7DA1A1",
  teal8 = "#6B9494",
  teal9 = "#598788",

  orange1 = "#F0EDE7",
  orange2 = "#E5DED5",
  orange3 = "#D9D0C3",
  orange4 = "#CEC1B1",
  orange5 = "#C2B39F",
  orange6 = "#B6A48C",
  orange7 = "#AB967A",
  orange8 = "#9F8768",
  orange9 = "#947956",

  green1 = "#EEEEE8",
  green2 = "#E1E1D7",
  green3 = "#D3D5C5",
  green4 = "#C6C8B4",
  green5 = "#B8BBA3",
  green6 = "#AAAE92",
  green7 = "#9DA181",
  green8 = "#8F956F",
  green9 = "#82885E",

  red1 = "#F1EBE8",
  red2 = "#E6DAD8",
  red3 = "#DBCAC7",
  red4 = "#D0B9B6",
  red5 = "#C6A9A6",
  red6 = "#BB9895",
  red7 = "#B08884",
  red8 = "#A57773",
  red9 = "#9A6763",

  berry1 = "#F4EAEE",
  berry2 = "#ECD9E2",
  berry3 = "#E3C8D7",
  berry4 = "#DBB7CB",
  berry5 = "#D3A6C0",
  berry6 = "#CB94B5",
  berry7 = "#C383A9",
  berry8 = "#BA729E",
  berry9 = "#B26192",
}

-- Helper function for highlighting
local function hl(group, fg, bg, attr)
  local hl_table = {}
  if fg then
    hl_table.fg = fg
  end
  if bg then
    hl_table.bg = bg
  end
  if attr then
    -- Handle multiple attributes separated by commas
    for attribute in attr:gmatch("[^,]+") do
      attribute = attribute:match("^%s*(.-)%s*$") -- trim whitespace
      hl_table[attribute] = true
    end
  end
  vim.api.nvim_set_hl(0, group, hl_table)
end

-- UI highlights
hl("Normal", colors.foreground, colors.background)
hl("NormalNC", colors.foreground, colors.background)
hl("NormalFloat", colors.foreground, colors.background_alt)
hl("FloatBorder", colors.grey4, colors.background_alt)

-- Cursor
hl("Cursor", colors.background, colors.foreground)
hl("CursorLine", nil, colors.grey1)
hl("CursorColumn", nil, colors.grey1)

-- Line numbers
hl("LineNr", colors.grey5)
hl("CursorLineNr", colors.foreground, colors.grey1)
hl("SignColumn", nil, colors.background)

-- Status line
hl("StatusLine", colors.foreground, colors.grey1)
hl("StatusLineNC", colors.grey6, colors.grey1)

-- Splits
hl("VertSplit", colors.grey4, colors.background)

-- Folding
hl("Folded", colors.grey7, colors.grey1)
hl("FoldColumn", colors.grey5)

-- Search
hl("Search", colors.background, colors.berry)
hl("IncSearch", colors.background, colors.berry)
hl("Substitute", colors.background, colors.berry)

-- Visual
hl("Visual", nil, colors.blue1)
hl("VisualNOS", nil, colors.blue1)

-- Messages
hl("ModeMsg", colors.foreground)
hl("MoreMsg", colors.green)
hl("WarningMsg", colors.orange)
hl("ErrorMsg", colors.red, colors.background)

-- Spelling
hl("SpellBad", colors.red, colors.background, "undercurl")
hl("SpellCap", colors.orange, colors.background, "undercurl")
hl("SpellRare", colors.teal, colors.background, "undercurl")
hl("SpellLocal", colors.blue, colors.background, "undercurl")

-- Diff
hl("DiffAdd", colors.green, colors.green1)
hl("DiffDelete", colors.red, colors.red1)
hl("DiffChange", colors.blue, colors.blue1)
hl("DiffText", colors.blue, colors.blue3)

-- Tabs
hl("TabLine", colors.grey6, colors.grey1)
hl("TabLineSel", colors.foreground, colors.background)
hl("TabLineFill", nil, colors.grey1)

-- Popups
hl("Pmenu", colors.foreground, colors.grey1)
hl("PmenuSel", colors.background, colors.blue)
hl("PmenuSbar", nil, colors.grey2)
hl("PmenuThumb", nil, colors.grey5)

-- Syntax highlighting (TextMate scopes)
-- General
hl("Comment", colors.comment, nil, "italic")
hl("Constant", colors.teal)
hl("String", colors.green)
hl("Character", colors.teal)
hl("Number", colors.teal)
hl("Boolean", colors.teal)
hl("Float", colors.teal)

hl("Identifier", colors.blue)
hl("Function", colors.foreground, nil, "italic")
hl("Statement", colors.purple)
hl("Conditional", colors.purple)
hl("Repeat", colors.purple)
hl("Label", colors.orange, nil, "italic")
hl("Operator", colors.foreground)
hl("Keyword", colors.purple)
hl("Exception", colors.purple)

hl("PreProc", colors.orange)
hl("Include", colors.orange)
hl("Define", colors.orange)
hl("Macro", colors.orange)
hl("PreCondit", colors.orange)

hl("Type", colors.purple)
hl("StorageClass", colors.purple)
hl("Structure", colors.purple)
hl("Typedef", colors.purple)

hl("Special", colors.orange)
hl("SpecialChar", colors.teal)
hl("Tag", colors.purple)
hl("SpecialComment", colors.comment, nil, "italic")
hl("Delimiter", colors.foreground)

-- Error
hl("Error", colors.red, colors.background)
hl("ErrorMsg", colors.red, colors.background)
hl("Warning", colors.orange)
hl("Todo", colors.orange)

-- Language-specific highlights
-- Underline (for incorrect spellings, trailing whitespace, etc.)
hl("Underlined", colors.blue, nil, "underline")

-- LSP highlights
hl("LspReferenceText", nil, colors.blue1)
hl("LspReferenceRead", nil, colors.blue1)
hl("LspReferenceWrite", nil, colors.blue1)

hl("LspCodeLens", colors.grey6)
hl("LspCodeLensSign", colors.grey6)

hl("DiagnosticError", colors.red)
hl("DiagnosticWarn", colors.orange)
hl("DiagnosticInfo", colors.blue)
hl("DiagnosticHint", colors.teal)

hl("DiagnosticUnderlineError", colors.red, nil, "undercurl")
hl("DiagnosticUnderlineWarn", colors.orange, nil, "undercurl")
hl("DiagnosticUnderlineInfo", colors.blue, nil, "undercurl")
hl("DiagnosticUnderlineHint", colors.teal, nil, "undercurl")

hl("DiagnosticVirtualTextError", colors.red8)
hl("DiagnosticVirtualTextWarn", colors.orange8)
hl("DiagnosticVirtualTextInfo", colors.blue8)
hl("DiagnosticVirtualTextHint", colors.teal8)

-- Treesitter highlights (using standard group names)
hl("@comment", colors.comment, nil, "italic")
hl("@string", colors.green)
hl("@string.regexp", colors.orange)
hl("@string.escape", colors.teal)
hl("@character", colors.teal)
hl("@number", colors.teal)
hl("@boolean", colors.teal)
hl("@constant", colors.teal)
hl("@constant.builtin", colors.teal)

hl("@variable", colors.blue)
hl("@variable.builtin", colors.purple)
hl("@variable.parameter", colors.blue)

hl("@keyword", colors.purple)
hl("@keyword.return", colors.purple)
hl("@keyword.operator", colors.foreground)

hl("@function", colors.foreground, nil, "italic")
hl("@function.builtin", colors.foreground, nil, "italic")
hl("@function.call", colors.foreground, nil, "italic")
hl("@function.method", colors.foreground, nil, "italic")
hl("@function.method.call", colors.foreground, nil, "italic")

hl("@constructor", colors.foreground, nil, "italic")
hl("@constructor.lua", colors.foreground)
hl("@type", colors.foreground, nil, "italic")
hl("@type.builtin", colors.foreground, nil, "italic")

hl("@operator", colors.foreground)
hl("@punctuation.bracket", colors.foreground)
hl("@punctuation.delimiter", colors.foreground)
hl("@punctuation.special", colors.teal)

hl("@tag", colors.purple)
hl("@tag.builtin", colors.purple)
hl("@tag.attribute", colors.blue)

hl("@text", colors.foreground)
hl("@text.emphasis", colors.foreground, nil, "italic")
hl("@text.strong", colors.foreground, nil, "bold")
hl("@text.underline", colors.foreground, nil, "underline")
hl("@text.title", colors.purple, nil, "bold")

hl("@markup.heading", colors.purple, nil, "bold")
hl("@markup.link.text", colors.teal)
hl("@markup.link.url", colors.blue)
hl("@markup.raw", colors.orange)
hl("@markup.quote", colors.orange)
hl("@markup.list", colors.foreground)

-- Additional highlights for popular plugins
-- vim-gitgutter
hl("GitGutterAdd", colors.green)
hl("GitGutterChange", colors.blue)
hl("GitGutterDelete", colors.red)

-- vim-signify
hl("SignifySignAdd", colors.green)
hl("SignifySignChange", colors.blue)
hl("SignifySignDelete", colors.red)

-- vim-sneak
hl("Sneak", colors.background, colors.orange)
hl("SneakScope", nil, colors.grey1)

-- fzf.vim
vim.g.fzf_colors = {
  fg = { "fg", "Normal" },
  bg = { "bg", "Normal" },
  hl = { "fg", "Comment" },
  ["fg+"] = { "fg", "String" },
  ["bg+"] = { "bg", "Pmenu" },
  ["hl+"] = { "fg", "String" },
  info = { "fg", "PreProc" },
  border = { "fg", "Ignore" },
  prompt = { "fg", "Conditional" },
  pointer = { "fg", "Exception" },
  marker = { "fg", "Keyword" },
  spinner = { "fg", "Label" },
  header = { "fg", "Comment" },
}

-- Telescope
hl("TelescopeNormal", colors.foreground, colors.background_alt)
hl("TelescopeBorder", colors.grey4, colors.background_alt)
hl("TelescopePromptNormal", colors.foreground, colors.background_alt)
hl("TelescopePromptBorder", colors.grey4, colors.background_alt)
hl("TelescopePromptPrefix", colors.blue)
hl("TelescopePromptTitle", colors.purple, colors.background_alt, "bold")
hl("TelescopeResultsNormal", colors.foreground, colors.background_alt)
hl("TelescopeResultsBorder", colors.grey4, colors.background_alt)
hl("TelescopeResultsTitle", colors.purple, colors.background_alt, "bold")
hl("TelescopePreviewNormal", colors.foreground, colors.background)
hl("TelescopePreviewBorder", colors.grey4, colors.background)
hl("TelescopePreviewTitle", colors.purple, colors.background, "bold")
hl("TelescopeSelection", colors.background, colors.blue)
hl("TelescopeSelectionCaret", colors.orange, colors.blue)
hl("TelescopeMatching", colors.orange)
hl("TelescopeMultiSelection", colors.berry)

-- nvim-cmp
hl("CmpItemAbbrDeprecated", colors.grey6, nil, "strikethrough")
hl("CmpItemAbbrMatch", colors.orange)
hl("CmpItemAbbrMatchFuzzy", colors.orange)
hl("CmpItemKindVariable", colors.blue)
hl("CmpItemKindInterface", colors.teal)
hl("CmpItemKindText", colors.foreground)
hl("CmpItemKindFunction", colors.purple)
hl("CmpItemKindMethod", colors.purple)
hl("CmpItemKindKeyword", colors.purple)
hl("CmpItemKindProperty", colors.blue)
hl("CmpItemKindUnit", colors.teal)
hl("CmpItemKindValue", colors.teal)
hl("CmpItemKindEnum", colors.teal)
hl("CmpItemKindConstant", colors.teal)
hl("CmpItemKindStruct", colors.foreground)
hl("CmpItemKindClass", colors.foreground)
hl("CmpItemKindModule", colors.foreground)
hl("CmpItemKindOperator", colors.foreground)
hl("CmpItemKindField", colors.blue)
hl("CmpItemKindFolder", colors.blue)
hl("CmpItemKindSnippet", colors.green)
hl("CmpItemKindEnumMember", colors.teal)
hl("CmpItemKindColor", colors.green)
hl("CmpItemKindFile", colors.blue)

-- nvim-cmp floating documentation window
hl("CmpDocumentation", colors.foreground, colors.grey3)
hl("CmpDocumentationBorder", colors.grey4, colors.grey3)
