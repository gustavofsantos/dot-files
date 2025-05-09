vim.g.colors_name = "nord"
vim.o.background = "dark"

-- Helper function to set highlight groups
local function highlight(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

local palette = {
  nord00 = "#2E3440",
  nord01 = "#3B4252",
  nord02 = "#434C5E",
  nord03 = "#4C566A",
  nord04 = "#616E88",
  nord05 = "#D8DEE9",
  nord06 = "#E5E9F0",
  nord07 = "#ECEFF4",


  gray00         = '#191D24',
  gray01         = '#1E222A',
  gray02         = '#222630',
  gray0          = '#242933',
  gray1          = '#2E3440',
  gray2          = '#3B4252',
  gray3          = '#434C5E',
  gray4          = '#4C566A',
  gray5          = '#60728A',
  gray6          = '#BBC3D4',
  gray7          = '#C0C8D8',
  gray8          = '#D8DEE9',
  gray9          = '#E5E9F0',
  gray10         = '#ECEFF4',

  cyan_bright    = '#9FC6C5',
  cyan           = "#8FBCBB",
  cyan_dim       = '#80B3B2',
  sky            = "#88C0D0",
  blue_bright    = "#81A1C1",
  blue           = "#5E81AC",
  red_bright     = "#C5727A",
  red            = "#BF616A",
  red_dim        = "#B74E58",
  orange_bright  = '#D79784',
  orange         = "#D08770",
  orange_dim     = '#CB775D',
  yellow_bright  = '#EFD49F',
  yellow         = "#EBCB8B",
  yellow_dim     = '#E7C173',
  green_bright   = '#B1C89D',
  green          = "#A3BE8C",
  green_dim      = '#97B67C',
  magenta_bright = '#BE9DB8',
  magenta        = "#B48EAD",
  magenta_dim    = '#A97EA1',
}

local components = {
  editor_bg = palette.gray0,
  popup_bg = palette.gray01,
  border = palette.gray00
}

-- Attributes
highlight("Bold", { bold = true })
highlight("Italic", { italic = true })
highlight("Underline", { underline = true })

-- Editor
highlight("ColorColumn", { bg = palette.gray02 })
highlight("Cursor", { fg = palette.nord00, bg = palette.nord05 })
highlight("CursorLine", { bg = palette.gray2 })
highlight("Error", { fg = palette.nord05, bg = palette.red })
highlight("iCursor", { fg = palette.nord00, bg = palette.nord05 })
highlight("LineNr", { fg = palette.nord03 })
highlight("MatchParen", { fg = palette.sky, bg = palette.nord03 })
highlight("NonText", { fg = palette.nord02 })
highlight("Normal", { fg = palette.gray6, bg = palette.gray0 })
highlight("NormalNC", { fg = palette.gray6, bg = palette.gray0 })
highlight("NormalSB", { fg = palette.gray6, bg = palette.gray0 })
highlight("NormalFloat", { fg = palette.gray6, bg = palette.gray01 })
highlight("Pmenu", { fg = palette.gray6, bg = palette.gray00 })
highlight("PmenuSbar", { fg = palette.gray6, bg = palette.gray02 })
highlight("PmenuSel", { fg = palette.cyan, bg = palette.nord03 })
highlight("PmenuThumb", { fg = palette.gray02, bg = palette.gray02 })
highlight("SpecialKey", { fg = palette.nord03 })
highlight("SpellBad", { fg = palette.red, bg = palette.nord00, undercurl = true, sp = palette.red })
highlight("SpellCap", { fg = palette.yellow, bg = palette.nord00, undercurl = true, sp = palette.yellow })
highlight("SpellLocal", { fg = palette.nord06, bg = palette.nord00, undercurl = true, sp = palette.nord06 })
highlight("SpellRare", { fg = palette.nord07, bg = palette.nord00, undercurl = true, sp = palette.nord07 })
highlight("Visual", { bg = palette.nord02 })
highlight("VisualNOS", { bg = palette.nord02 })

-- Neovim specific highlights
highlight("healthError", { fg = palette.red, bg = palette.nord01 })
highlight("healthSuccess", { fg = palette.green, bg = palette.nord01 })
highlight("healthWarning", { fg = palette.yellow, bg = palette.nord01 })
highlight("TermCursorNC", { bg = palette.nord01 })

-- Neovim Diagnostics API (for LSP)
highlight("DiagnosticWarn", { fg = palette.yellow })
highlight("DiagnosticError", { fg = palette.red })
highlight("DiagnosticInfo", { fg = palette.sky })
highlight("DiagnosticHint", { fg = palette.blue })
highlight("DiagnosticUnderlineWarn", { fg = palette.yellow, undercurl = true })
highlight("DiagnosticUnderlineError", { fg = palette.red, undercurl = true })
highlight("DiagnosticUnderlineInfo", { fg = palette.sky, undercurl = true })
highlight("DiagnosticUnderlineHint", { fg = palette.blue, undercurl = true })

-- Neovim DocumentHighlight
highlight("LspReferenceText", { bg = palette.nord03 })
highlight("LspReferenceRead", { bg = palette.nord03 })
highlight("LspReferenceWrite", { bg = palette.nord03 })

-- Neovim LspSignatureHelp
highlight("LspSignatureActiveParameter", { fg = palette.sky, underline = true })

-- Gutter
highlight("CursorColumn", { bg = palette.nord01 })
highlight("CursorLineNr", { fg = palette.yellow, bg = palette.nord01 })
highlight("CursorLineSign", { bg = palette.nord01 })
highlight("Folded", { fg = palette.nord03, bg = palette.nord01, bold = true })
highlight("FoldColumn", { fg = palette.nord03, bg = palette.nord00 })
highlight("SignColumn", { fg = palette.nord01, bg = components.editor_bg })
highlight("SignColumnSB", { fg = palette.nord01, bg = components.editor_bg })

-- Navigation
highlight("Directory", { fg = palette.sky })

-- Prompt/Status
highlight("EndOfBuffer", { fg = palette.nord01 })
highlight("ErrorMsg", { fg = palette.nord05, bg = palette.red })
highlight("ModeMsg", { fg = palette.nord05 })
highlight("MoreMsg", { fg = palette.sky })
highlight("Question", { fg = palette.nord05 })

highlight("StatusLine", { fg = palette.sky, bg = palette.nord03 })
highlight("StatusLineNC", { fg = palette.nord05, bg = palette.nord03 })
highlight("StatusLineTerm", { fg = palette.sky, bg = palette.nord03 })
highlight("StatusLineTermNC", { fg = palette.nord05, bg = palette.nord03 })

highlight("WarningMsg", { fg = palette.nord00, bg = palette.yellow })
highlight("WildMenu", { fg = palette.sky, bg = palette.nord01 })

-- Search
highlight("IncSearch", { fg = palette.nord07, bg = palette.blue, underline = true })
highlight("Search", { fg = palette.nord01, bg = palette.sky })

-- Tabs
highlight("TabLine", { fg = palette.nord05, bg = palette.gray01 })
highlight("TabLineFill", { fg = palette.nord05, bg = palette.gray00 })
highlight("TabLineSel", { fg = palette.gray6, bg = components.editor_bg })

-- Window
highlight("Title", { fg = palette.nord05 })
highlight("VertSplit", { fg = palette.gray00, bg = components.editor_bg })
highlight("WinSeparator", { link = "VertSplit" })

-- Language Base Groups
highlight("Boolean", { fg = palette.blue_bright })
highlight("Builtin", { fg = palette.blue })
highlight("Character", { fg = palette.green })
highlight("Comment", { fg = palette.nord04, italic = true })
highlight("Conceal", { bg = "NONE" })
highlight("Conditional", { fg = palette.blue_bright })
highlight("Constant", { fg = palette.magenta_bright })
highlight("Decorator", { fg = palette.orange })
highlight("Define", { fg = palette.blue_bright })
highlight("Delimiter", { fg = palette.nord07 })
highlight("Exception", { fg = palette.blue_bright })
highlight("Float", { fg = palette.magenta })
highlight("Field", { fg = palette.cyan })
highlight("Function", { fg = palette.sky })
highlight("Identifier", { fg = palette.nord05 })
highlight("Include", { fg = palette.blue_bright })
highlight("Keyword", { fg = palette.orange })
highlight("Label", { fg = palette.blue_bright })
highlight("Number", { link = "Constant" })
highlight("Namespace", { fg = palette.yellow_dim })
highlight("Operator", { fg = palette.blue_bright })
highlight("PreProc", { fg = palette.blue_bright })
highlight("Repeat", { fg = palette.blue_bright })
highlight("Special", { fg = palette.nord05 })
highlight("SpecialChar", { fg = palette.yellow })
highlight("SpecialComment", { fg = palette.sky, italic = true })
highlight("Statement", { fg = palette.blue_bright })
highlight("StorageClass", { fg = palette.blue_bright })
highlight("String", { fg = palette.green })
highlight("Structure", { fg = palette.blue_bright })
highlight("Tag", { fg = palette.nord05 })
highlight("Todo", { fg = palette.yellow, bg = "NONE" })
highlight("Type", { fg = palette.blue_bright })
highlight("Typedef", { fg = palette.blue_bright })

-- Link common groups
local links = {
  ["Annotation"] = "Decorator",
  ["Macro"] = "Define",
  ["PreCondit"] = "PreProc",
  ["Variable"] = "Identifier",
}

for newgroup, oldgroup in pairs(links) do
  vim.api.nvim_set_hl(0, newgroup, { link = oldgroup })
end

-- Language specific highlights
-- Only adding a subset of the language-specific highlights for brevity
-- More can be added based on your needs

-- Diff highlighting
highlight("DiffAdd", { fg = palette.green, bg = palette.nord00 })
highlight("DiffChange", { fg = palette.yellow, bg = palette.nord00 })
highlight("DiffDelete", { fg = palette.red, bg = palette.nord00 })
highlight("DiffText", { fg = palette.blue_bright, bg = palette.nord00 })

-- Legacy diff groups
highlight("diffAdded", { link = "DiffAdd" })
highlight("diffChanged", { link = "DiffChange" })
highlight("diffRemoved", { link = "DiffDelete" })

-- Git related highlights
highlight("gitcommitDiscardedFile", { fg = palette.red })
highlight("gitcommitUntrackedFile", { fg = palette.red })
highlight("gitcommitSelectedFile", { fg = palette.green })

-- Plugin support - Only adding a subset for brevity
-- DiagnosticSign highlights for LSP
highlight("DiagnosticSignError", { fg = palette.red, bg = "NONE" })
highlight("DiagnosticSignWarn", { fg = palette.yellow, bg = "NONE" })
highlight("DiagnosticSignHint", { fg = palette.sky, bg = "NONE" })
highlight("DiagnosticSignInfo", { fg = palette.blue_bright, bg = "NONE" })

-- GitSigns plugin support
highlight("GitSignsAdd", { fg = palette.green })
highlight("GitSignsChange", { fg = palette.yellow })
highlight("GitSignsDelete", { fg = palette.red })

-- Nvim-Treesitter
highlight("TSAnnotation", { link = "Annotation" })
highlight("TSConstBuiltin", { link = "Constant" })
highlight("TSConstructor", { link = "Function" })
highlight("TSEmphasis", { link = "Italic" })
highlight("TSFuncBuiltin", { link = "Function" })
highlight("TSFuncMacro", { link = "Function" })
highlight("TSStringRegex", { link = "SpecialChar" })
highlight("TSStrong", { link = "Bold" })
highlight("TSStructure", { link = "Structure" })
highlight("TSTagDelimiter", { link = "TSTag" })
highlight("TSUnderline", { link = "Underline" })
highlight("TSVariable", { link = "Variable" })
highlight("TSVariableBuiltin", { link = "Keyword" })

-- Telescope plugin support
highlight("TelescopeBorder", { fg = palette.nord03, bg = palette.nord01 })
highlight("TelescopePromptBorder", { fg = palette.nord03, bg = palette.nord01 })
highlight("TelescopePromptNormal", { fg = palette.nord05, bg = palette.nord01 })
highlight("TelescopePromptTitle", { fg = palette.nord01, bg = palette.sky })
highlight("TelescopeResultsBorder", { fg = palette.nord03, bg = palette.nord01 })
highlight("TelescopeResultsNormal", { fg = palette.nord05, bg = palette.nord01 })
highlight("TelescopeResultsTitle", { fg = palette.nord01, bg = palette.sky })
highlight("TelescopePreviewBorder", { fg = palette.nord03, bg = palette.nord01 })
highlight("TelescopePreviewNormal", { fg = palette.nord05, bg = palette.nord01 })
highlight("TelescopePreviewTitle", { fg = palette.nord01, bg = palette.sky })
highlight("TelescopeSelection", { fg = palette.sky, bg = palette.nord03 })
highlight("TelescopeSelectionCaret", { fg = palette.sky, bg = palette.nord03 })
highlight("TelescopeMultiSelection", { fg = palette.sky, bg = palette.nord03 })

-- Tree view
highlight("TreeNormal", { link = "Normal" })
highlight("TreeNormalNC", { link = "Normal" })
highlight("TreeRootName", { fg = palette.gray6, bold = true })
highlight("TreeFileIcon", { fg = palette.sky })
highlight("TreeFileNameOpened", { fg = palette.gray6 })
highlight("TreeSpecialFile", { fg = palette.magenta_bright })
highlight("TreeGitConflict", { fg = palette.red })
highlight("TreeGitModified", { fg = palette.blue_bright })
highlight("TreeGitDirty", { fg = palette.gray4 })
highlight("TreeGitAdded", { fg = palette.green })
highlight("TreeGitNew", { fg = palette.gray4 })
highlight("TreeGitDeleted", { fg = palette.gray4 })
highlight("TreeGitStaged", { fg = palette.gray4 })
highlight("TreeGitUntracked", { fg = palette.orange_base })
highlight("TreeTitleBar", { link = 'WinBar' })
highlight("TreeFloatBorder", { link = 'FloatBorder' })
highlight("TreeCursorLine", { bg = palette.gray2 })
highlight("TreeCursor", { bg = "NONE", fg = "NONE" })
highlight("TreeFolderIcon", { fg = palette.yellow_dim })
highlight("TreeIndentMarker", { fg = palette.gray4 })
highlight("TreeSymlink", { fg = palette.sky })
highlight("TreeFolderName", { fg = palette.blue_bright })
highlight("TreeWinSeparator", { link = 'WinSeparator' })

-- Terminal
vim.g.terminal_color_0 = palette.nord01
vim.g.terminal_color_1 = palette.red
vim.g.terminal_color_2 = palette.green
vim.g.terminal_color_3 = palette.yellow
vim.g.terminal_color_4 = palette.blue_bright
vim.g.terminal_color_5 = palette.magenta
vim.g.terminal_color_6 = palette.sky
vim.g.terminal_color_7 = palette.nord06
vim.g.terminal_color_8 = palette.nord03
vim.g.terminal_color_9 = palette.red
vim.g.terminal_color_10 = palette.green
vim.g.terminal_color_11 = palette.yellow
vim.g.terminal_color_12 = palette.blue_bright
vim.g.terminal_color_13 = palette.magenta
vim.g.terminal_color_14 = palette.cyan
vim.g.terminal_color_15 = palette.nord07
