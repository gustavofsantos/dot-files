local utils = require("utils")
local background = vim.o.background or "dark"

local base_palette = {
  light = {
    color00 = "#F2F1EE",
    color0  = "#F7F7F4",
    color1  = "#cc241d",
    color2  = "#98971a",
    color3  = "#d79921",
    color4  = "#458588",
    color5  = "#b16286",
    color6  = "#689d6a",
    color7  = "#494947",
    color8  = "#61615F",
    color9  = "#9d0006",
    color10 = "#79740e",
    color11 = "#b57614",
    color12 = "#076678",
    color13 = "#8f3f71",
    color14 = "#427b58",
    color15 = "#26251e",
    color16 = "#d65d0e",
    color17 = "#af3a03",
  },
  dark = {
    color00 = "#1d2021",
    color0  = "#282828",
    color1  = "#cc241d",
    color2  = "#98971a",
    color3  = "#d79921",
    color4  = "#458588",
    color5  = "#b16286",
    color6  = "#689d6a",
    color7  = "#a89984",
    color8  = "#928374",
    color9  = "#fb4934",
    color10 = "#b8bb26",
    color11 = "#fabd2f",
    color12 = "#83a598",
    color13 = "#d3869d",
    color14 = "#8ec07c",
    color15 = "#ebdbb2",
    color16 = "#d65d0e",
    color17 = "#f38019",
  }
}

local palette = vim.tbl_extend("force", base_palette[background], {
  bg    = base_palette[background].color0,
  fg    = base_palette[background].color15,
  gray0 = utils.blend_colors(base_palette[background].color0, base_palette[background].color15, 0.1),
  gray1 = utils.blend_colors(base_palette[background].color0, base_palette[background].color15, 0.2),
  gray2 = utils.blend_colors(base_palette[background].color0, base_palette[background].color15, 0.3),
  gray3 = utils.blend_colors(base_palette[background].color0, base_palette[background].color15, 0.4),
  gray4 = utils.blend_colors(base_palette[background].color0, base_palette[background].color15, 0.5),
  gray5 = utils.blend_colors(base_palette[background].color0, base_palette[background].color15, 0.6),
  gray6 = utils.blend_colors(base_palette[background].color0, base_palette[background].color15, 0.75),
  gray7 = utils.blend_colors(base_palette[background].color0, base_palette[background].color15, 0.80),
})

local highlights = {
  Bold = { bold = true },
  Italic = { italic = true },
  Underline = { underline = true },
  -- Editor
  Normal = { bg = palette.bg, fg = palette.fg },
  NormalNC = { bg = palette.bg, fg = palette.fg },
  NormalSB = { bg = palette.bg, fg = palette.fg },
  NormalFloat = { bg = palette.color00, fg = palette.fg },
  ColorColumn = { bg = palette.gray0 },
  Cursor = { bg = palette.color16 },
  Error = { bg = palette.color1 },
  iCursor = { bg = palette.color16 },
  MatchParen = { bg = palette.gray1, fg = palette.fg },
  NonText = { bg = palette.gray3 },
  Pmenu = { bg = palette.gray1 },
  PmenuSbar = { fg = palette.gray1 },
  PmenuSel = { bg = palette.color12, fg = palette.bg },
  PmenuThumb = { fg = palette.gray2 },
  SpecialKey = { undercurl = true },
  SpellBad = { undercurl = true, sp = palette.color1 },
  SpellCap = { undercurl = true },
  SpellLocal = { undercurl = true },
  SpellRare = { undercurl = true },
  Visual = { bg = palette.gray1 },
  VisualNOS = { link = "Visual" },
  -- Gutter
  LineNr = { fg = palette.gray2 },
  CursorColumn = { bg = palette.gray00 },
  CursorLine = { bg = palette.gray1 },
  CursorLineNr = { fg = palette.color11, bg = palette.color00 },
  CursorLineSign = { fg = palette.gray3, bg = palette.color00 },
  TermCursorNC = { bg = palette.gray3 },
  Folded = { fg = palette.gray5, bg = palette.gray1, bold = true },
  FoldColumn = { fg = palette.gray4, bg = palette.bg },
  SignColumn = { fg = palette.gray4, bg = palette.bg },
  SignColumnSB = { fg = palette.gray4, bg = palette.bg },
  DiagnosticSignError = { fg = palette.color1, bg = "NONE" },
  DiagnosticSignWarn = { fg = palette.color3, bg = "NONE" },
  DiagnosticSignHint = { fg = palette.color4, bg = "NONE" },
  DiagnosticSignInfo = { fg = palette.color12, bg = "NONE" },
  DiagnosticWarn = { fg = palette.color3 },
  DiagnosticError = { fg = palette.color1 },
  DiagnosticInfo = { fg = palette.color4 },
  DiagnosticHint = { fg = palette.color12 },
  DiagnosticUnderlineWarn = { fg = palette.yellow, undercurl = true },
  DiagnosticUnderlineError = { fg = palette.red, undercurl = true },
  DiagnosticUnderlineInfo = { fg = palette.sky, undercurl = true },
  DiagnosticUnderlineHint = { fg = palette.blue, undercurl = true },
  DiffAdd = { bg = utils.blend_colors(palette.color2, palette.bg, 0.75) },
  DiffChange = { bg = utils.blend_colors(palette.color3, palette.bg, 0.75) },
  DiffDelete = { fg = palette.color7, bg = utils.blend_colors(palette.color1, palette.bg, 0.75) },
  DiffText = { fg = palette.color12, bg = palette.bg },
  EndOfBuffer = { fg = palette.color00 },
  ErrorMsg = { fg = palette.color9, bg = palette.color00 },
  ModeMsg = { fg = palette.color4 },
  MoreMsg = { fg = palette.color6 },
  Question = { fg = palette.color14 },
  -- QuickFix
  QuickFixLineNr = { link = "LineNr" },
  QuickFixFilename = { link = "File" },
  -- Statusline
  StatusLine = { fg = palette.fg, bg = palette.gray2 },
  StatusLineNC = { fg = palette.gray3, bg = palette.gray0 },
  StatusLineTerm = { fg = palette.fg, bg = palette.gray2 },
  StatusLineTermNC = { fg = palette.gray3, bg = palette.gray0 },
  -- Tabs
  TabLine = { fg = palette.gray2, bg = palette.gray0 },
  TabLineFill = { fg = palette.gray2, bg = palette.gray0 },
  TabLineSel = { fg = palette.gray3, bg = palette.bg },
  -- Window
  Title = { fg = palette.gray5 },
  VertSplit = { fg = palette.gray2, bg = palette.bg },
  WinSeparator = { link = "VertSplit" },
  -- Language Base Groups
  Boolean = { fg = palette.color4 },
  Builtin = { fg = palette.color4 },
  Character = { fg = palette.color2 },
  Comment = { fg = palette.color7, italic = true },
  Conceal = { bg = "NONE" },
  Conditional = { fg = palette.color1 },
  Constant = { fg = palette.color13 },
  Decorator = { fg = palette.color16 },
  Define = { fg = palette.color4 },
  Delimiter = { fg = palette.color8 },
  Exception = { fg = palette.color4 },
  Float = { fg = palette.color5 },
  Field = { fg = palette.color6 },
  Function = { fg = palette.color10 },
  Identifier = { fg = palette.color15 },
  Include = { fg = palette.color4 },
  Keyword = { fg = palette.color16 },
  Label = { fg = palette.color4 },
  Number = { link = "Constant" },
  Namespace = { fg = palette.color3 },
  Operator = { fg = palette.color8 },
  PreProc = { fg = palette.color4 },
  Repeat = { fg = palette.color4 },
  Special = { fg = palette.color6 },
  SpecialChar = { fg = palette.color3 },
  SpecialComment = { fg = palette.color6, italic = true },
  Statement = { fg = palette.color15 },
  StorageClass = { fg = palette.color4 },
  String = { fg = palette.color2 },
  Structure = { fg = palette.color4 },
  Tag = { fg = palette.color7 },
  Todo = { fg = palette.color3, bg = "NONE" },
  Type = { fg = palette.color11 },
  Typedef = { fg = palette.color4 },
  Annotation = { link = "Decorator" },
  Macro = { link = "Define" },
  PreCondit = { link = "PreProc" },
  Variable = { link = "Identifier" },

  diffAdded = { link = "DiffAdd" },
  diffChanged = { link = "DiffChange" },
  diffRemoved = { link = "DiffDelete" },

  -- Gitsigns
  GitSignsAdd = { fg = palette.color10 },
  GitSignsChange = { fg = palette.color3 },
  GitSignsDelete = { fg = palette.color1 },

  -- Flash
  FlashMatch = { link = "Visual" },
  FlashCurrent = { fg = palette.color00, bg = palette.color13 },
  FlashLabel = { fg = palette.color00, bg = palette.color14 },
  FlashPrompt = { link = "MsgArea" },
  FlashPromptIcon = { link = "Special" },
  FlashCursor = { link = "Cursor" },

  -- Telescope
  TelescopeBorder = { fg = palette.gray1, bg = palette.color00 },
  TelescopePromptBorder = { fg = palette.gray0, bg = palette.color00 },
  TelescopePromptNormal = { fg = palette.gray3, bg = palette.color00 },
  TelescopePromptTitle = { fg = palette.gray3, bg = palette.color00 },
  TelescopeResultsBorder = { fg = palette.gray0, bg = palette.color00 },
  TelescopeResultsNormal = { fg = palette.gray3, bg = palette.color00 },
  TelescopeResultsTitle = { fg = palette.gray3, bg = palette.color00 },
  TelescopePreviewBorder = { fg = palette.color00, bg = palette.color00 },
  TelescopePreviewNormal = { fg = palette.gray3, bg = palette.color0 },
  TelescopePreviewTitle = { fg = palette.gray3, bg = palette.color00 },
  TelescopeMatching = { fg = palette.color00, bg = palette.color17 },
  TelescopeSelection = { fg = palette.gray3, bg = palette.gray1, italic = false },
  TelescopeSelectionCaret = { fg = palette.color6, bg = palette.gray1 },
  TelescopeMultiSelection = { fg = palette.color6, bg = palette.gray1 },

  -- Treesitter
  ["@variable"] = { link = "Variable" },
  ["@constructor"] = { link = "Function" },
  ["@markup.strong"] = { bold = true },
  ["@keyword_symbol.single"] = { link = "SpecialChar" },
  ["@keyword_symbol.namespace"] = { link = "Type" },
  ["@keyword_symbol.name"] = { link = "Keyword" },
  ["@keyword_symbol"] = { link = "Type" },
  ["@quilified_symbol.namespace"] = { link = "Type" },
  ["@quilified_symbol.name"] = { link = "Function" },
  ["@quilified_symbol"] = { link = "Type" },
  ["@property.json"] = { link = "Identifier" },
  ["@punctuation.bracket.lua"] = { link = "Delimiter" },
  ["@constructor.lua"] = { link = "Delimiter" },
  ["@punctuation.bracket.clojure"] = { link = "Delimiter" },
  ["@constructor.clojure"] = { link = "Function" },
  -- ["@markup.list.markdown"] = { fg = palette.nord04 },
  -- ["@markup.heading.1.markdown"] = { fg = palette.cyan_bright },
  -- ["@markup.heading.2.markdown"] = { fg = palette.cyan },
  -- ["@markup.heading.3.markdown"] = { fg = palette.cyan },
  -- ["@markup.heading.4.markdown"] = { fg = palette.cyan_dim },
  -- ["@markup.heading.5.markdown"] = { fg = palette.cyan_dim },
  -- ["@markup.heading.6.markdown"] = { fg = palette.cyan_dim },
}


for group, opts in pairs(highlights) do
  vim.api.nvim_set_hl(0, group, opts)
end

-- Terminal
vim.g.terminal_color_0 = palette.color0
vim.g.terminal_color_1 = palette.color1
vim.g.terminal_color_2 = palette.color2
vim.g.terminal_color_3 = palette.color3
vim.g.terminal_color_4 = palette.color4
vim.g.terminal_color_5 = palette.color5
vim.g.terminal_color_6 = palette.color6
vim.g.terminal_color_7 = palette.color7
vim.g.terminal_color_8 = palette.color8
vim.g.terminal_color_9 = palette.color9
vim.g.terminal_color_10 = palette.color10
vim.g.terminal_color_11 = palette.color11
vim.g.terminal_color_12 = palette.color12
vim.g.terminal_color_13 = palette.color13
vim.g.terminal_color_14 = palette.color14
vim.g.terminal_color_15 = palette.color15

vim.g.colors_name = "cream"
