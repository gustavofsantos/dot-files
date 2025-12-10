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


local palette = {
  -- Default nord colors
  -------------------------

  nord0  = "#2e3440",
  nord1  = "#3b4252",
  nord2  = "#434c5e",
  nord3  = "#4c566a",
  nord4  = "#d8dee9",
  nord5  = "#e5e9f0",
  nord6  = "#eceff4",
  nord7  = "#8fbcbb",
  nord8  = "#88c0d0",
  nord9  = "#81a1c1",
  nord10 = "#5e81ac",
  nord11 = "#bf616a",
  nord12 = "#d08770",
  nord13 = "#ebcb8b",
  nord14 = "#a3be8c",
  nord15 = "#b48ead",

  cream1 = '#D9D3C4',
  cream2 = '#E5DECD',
  cream3 = '#EDE8DC',
  cream4 = '#F6F3ED',
  cream5 = '#F0EFEA',

  -- Mappings for Light Theme (inversions)
  -- Dark backgrounds become light foregrounds
  
  gray000        = '#1A1C21',
  gray00         = '#191D24',
  gray0          = '#242933',
  gray1          = '#2E3440',
  gray2          = '#3B4252',
  gray3          = '#434C5E',
  gray4          = '#4C566A',
  gray5          = '#60728A',
  
  -- Light backgrounds
  bg_main        = '#F0EFEA', -- cream5
  bg_alt         = '#F6F3ED', -- cream4
  bg_dim         = '#EDE8DC', -- cream3
  bg_active      = '#E5DECD', -- cream2
  bg_inactive    = '#D9D3C4', -- cream1
  
  -- Text colors
  fg_main        = '#2E3440', -- nord0
  fg_alt         = '#3B4252', -- nord1
  fg_dim         = '#4C566A', -- nord3

  cyan_bright    = '#9FC6C5',
  cyan           = "#8FBCBB",
  cyan_dim       = '#80B3B2',
  sky            = "#88C0D0",
  sky_bright     = "#bee9e8",
  blue_bright    = "#81A1C1",
  blue           = "#5E81AC",
  blue_muted     = "#415570",
  red_bright     = "#C5727A",
  red            = "#BF616A", 
  red_dim        = "#B74E58",
  red_muted      = "#72454F",
  orange_bright  = '#D79784', 
  orange         = "#D08770",
  orange_dim     = '#CB775D',
  yellow_bright  = '#EFD49F',
  yellow         = "#EBCB8B",
  yellow_dim     = '#E7C173',
  yellow_muted   = "#BAA375",
  gold           = "#FDC500",
  golder         = "#FFD500",
  green_bright   = '#B1C89D',
  green          = "#A3BE8C",
  green_dim      = '#97B67C',
  magenta_bright = '#BE9DB8',
  magenta        = "#B48EAD",
  magenta_dim    = '#A97EA1',
}

-- Darker Variants for Light Theme Accessibility
local p = palette
p.red_dark     = blend_colors(p.red, "#000000", 0.3)
p.green_dark   = blend_colors(p.green, "#000000", 0.4) -- More darkening needed for green
p.yellow_dark  = blend_colors(p.yellow, "#000000", 0.4)
p.blue_dark    = blend_colors(p.blue, "#000000", 0.2)
p.magenta_dark = blend_colors(p.magenta, "#000000", 0.3)
p.cyan_dark    = blend_colors(p.cyan, "#000000", 0.4)
p.orange_dark  = blend_colors(p.orange, "#000000", 0.2)


local components = {
  editor_bg = palette.bg_main,
  popup_bg = palette.bg_alt,
  border = palette.bg_dim
}

local highlights = {
  -- Attributes
  Bold = { bold = true },
  Italic = { italic = true },
  Underline = { underline = true },

  -- Editor
  ColorColumn = { bg = palette.bg_dim },
  Cursor = { fg = palette.bg_main, bg = palette.nord0 },
  Error = { fg = palette.bg_main, bg = palette.red },
  iCursor = { fg = palette.bg_main, bg = palette.nord0 },
  LineNr = { fg = palette.nord3 },
  MatchParen = { fg = palette.nord10, bg = palette.nord4 },
  NonText = { fg = palette.nord4 },
  Normal = { fg = palette.fg_main, bg = components.editor_bg },
  NormalNC = { fg = palette.fg_main, bg = components.editor_bg },
  NormalSB = { fg = palette.fg_main, bg = components.editor_bg },
  NormalFloat = { fg = palette.fg_main, bg = components.popup_bg },
  FloatBorder = { link = "NormalFloat" },
  FloatTitle = { fg = palette.blue_dark },
  FloatFooter = { link = "NormalFloat" },
  Pmenu = { fg = palette.fg_main, bg = palette.bg_alt },
  PmenuSbar = { fg = palette.bg_dim, bg = palette.bg_dim },
  PmenuSel = { fg = palette.bg_main, bg = palette.nord9 },
  PmenuThumb = { fg = palette.nord3, bg = palette.nord3 },
  SpecialKey = { fg = palette.nord3 },
  SpellBad = { fg = palette.red, bg = "NONE", undercurl = true, sp = palette.red },
  SpellCap = { fg = palette.yellow, bg = "NONE", undercurl = true, sp = palette.yellow },
  SpellLocal = { fg = palette.nord10, bg = "NONE", undercurl = true, sp = palette.nord10 },
  SpellRare = { fg = palette.nord7, bg = "NONE", undercurl = true, sp = palette.nord7 },
  Visual = { bg = palette.nord4 },
  VisualNOS = { bg = palette.nord4 },

  -- Neovim specific highlights
  healthError = { fg = palette.red_dark, bg = palette.bg_alt },
  healthSuccess = { fg = palette.green_dark, bg = palette.bg_alt },
  healthWarning = { fg = palette.yellow_dark, bg = palette.bg_alt },
  TermCursorNC = { bg = palette.bg_alt },

  -- Neovim Diagnostics API (for LSP)
  DiagnosticWarn = { fg = palette.yellow_dark },
  DiagnosticError = { fg = palette.red_dark },
  DiagnosticInfo = { fg = palette.blue_dark },
  DiagnosticHint = { fg = palette.nord10 },
  DiagnosticUnderlineWarn = { fg = palette.yellow, undercurl = true },
  DiagnosticUnderlineError = { fg = palette.red, undercurl = true },
  DiagnosticUnderlineInfo = { fg = palette.sky, undercurl = true },
  DiagnosticUnderlineHint = { fg = palette.blue, undercurl = true },

  -- Neovim DocumentHighlight
  LspReferenceText = { bg = palette.nord4 },
  LspReferenceRead = { bg = palette.nord4 },
  LspReferenceWrite = { bg = palette.nord4 },

  -- Neovim LspSignatureHelp
  LspSignatureActiveParameter = { fg = palette.blue_dark, underline = true },

  -- Gutter
  CursorColumn = { bg = palette.bg_dim },
  CursorLine = { bg = palette.bg_dim },
  CursorLineNr = { fg = palette.blue_dark, bg = palette.bg_active, bold = true },
  CursorLineSign = { bg = palette.bg_active },
  Folded = { fg = palette.nord3, bg = palette.bg_dim, bold = true },
  FoldColumn = { fg = palette.nord3, bg = components.editor_bg },
  SignColumn = { fg = palette.nord3, bg = components.editor_bg },
  SignColumnSB = { fg = palette.nord3, bg = components.editor_bg },

  -- Navigation
  Directory = { fg = palette.blue_dark },
  File = { fg = palette.fg_main },

  -- Prompt/Status
  EndOfBuffer = { fg = palette.bg_dim },
  ErrorMsg = { fg = palette.bg_main, bg = palette.red },
  ModeMsg = { fg = palette.fg_main },
  MoreMsg = { fg = palette.blue_dark },
  Question = { fg = palette.fg_main },

  StatusLine = { fg = palette.fg_main, bg = palette.bg_dim },
  StatusLineNC = { fg = palette.nord3, bg = palette.bg_alt },
  StatusLineTerm = { fg = palette.fg_main, bg = palette.bg_dim },
  StatusLineTermNC = { fg = palette.nord3, bg = palette.bg_alt },

  WarningMsg = { fg = palette.bg_main, bg = palette.yellow },
  WildMenu = { fg = palette.blue_dark, bg = palette.bg_alt },

  -- Search
  IncSearch = { fg = palette.bg_main, bg = palette.blue_dark, underline = true },
  Search = { fg = palette.fg_main, bg = palette.nord4 },

  -- Tabs
  TabLine = { fg = palette.nord3, bg = palette.bg_alt },
  TabLineFill = { fg = palette.nord3, bg = palette.bg_dim },
  TabLineSel = { fg = palette.fg_main, bg = components.editor_bg },

  -- Window
  Title = { fg = palette.blue_dark },
  VertSplit = { fg = palette.bg_dim, bg = components.editor_bg },
  WinSeparator = { link = "VertSplit" },

  -- QuickFix
  QuickFixLine = { link = "Search" },
  QuickFixLineNr = { link = "LineNr" },
  QuickFixFilename = { link = "File" },

  -------------------------------------------------------------------
  -- Semantic Tokens ------------------------------------------------
  -------------------------------------------------------------------

  ["@comment"] = { fg = palette.nord3, italic = true },
  ["@constant"] = { fg = palette.nord3 },
  ["@string"] = { fg = palette.green_dark },
  ["@string.regexp"] = { fg = palette.yellow_dark },
  ["@number"] = { fg = palette.magenta_dark },
  ["@keyword"] = { fg = palette.blue_dark },
  ["@variable"] = { fg = palette.fg_main },
  ["@variable.builtin"] = { fg = palette.nord9 },
  ["@property"] = { fg = palette.blue_dark },
  ["@operator"] = { fg = palette.nord9 },
  ["@boolean"] = { fg = palette.orange_dark, bold = true },
  ["@function"] = { fg = palette.blue_dark },
  ["@function.builtin"] = { fg = palette.blue_dark },
  ["@function.macro"] = { fg = palette.blue_dark },
  ["@function.call"] = { fg = palette.blue_dark, italic = true },
  ["@type"] = { fg = palette.cyan_dark },
  ["@type.builtin"] = { fg = palette.cyan_dark, bold = true },
  ["@constructor"] = { fg = palette.cyan_dark },
  ["@decorator"] = { fg = palette.orange_dark },
  ["@markup.strong"] = { fg = palette.fg_main, bold = true },
  ["@punctuation"] = { fg = palette.nord3 },
  ["@punctuation.bracket"] = { fg = palette.nord3 },
  ["@punctuation.delimiter"] = { fg = palette.nord3 },

  -- LSP
  ["@lsp.type.macro"] = { fg = palette.orange_dark },
  ["@lsp.type.keyword"] = { fg = palette.blue_dark },
  ["@lsp.type.parameter"] = { fg = palette.fg_main, italic = true },
  ["@lsp.type.property"] = { link = "@property" },
  ["@lsp.type.function"] = { link = "@function" },
  ["@lsp.type.type"] = { link = "@type" },

  -- JSON
  ["@property.json"] = { fg = palette.cyan_dark },

  -- Markdown
  ["@markup.list.markdown"] = { fg = palette.nord3 },
  ["@markup.heading.1.markdown"] = { fg = palette.blue_dark },
  ["@markup.heading.2.markdown"] = { fg = palette.blue_dark },
  ["@markup.heading.3.markdown"] = { fg = palette.blue_dark },
  ["@markup.heading.4.markdown"] = { fg = palette.blue_dark },
  ["@markup.heading.5.markdown"] = { fg = palette.blue_dark },
  ["@markup.heading.6.markdown"] = { fg = palette.blue_dark },

  -------------------------------------------------------------------
  -- Language Base Groups -------------------------------------------
  -------------------------------------------------------------------
  -- Tier 1 (Noise / Structure)
  Comment = { link = "@comment" },
  Conceal = { bg = "NONE" },
  Delimiter = { fg = palette.nord3 },
  Operator = { link = "@operator" },
  SpecialChar = { fg = palette.yellow_dark },
  SpecialComment = { fg = palette.blue_dark, italic = true },

  -- Tier 2 (Body / Variables)
  Field = { link = "@property" },
  Identifier = { link = "@variable" },
  Tag = { link = "@type" },
  Variable = { link = "@variable" },

  -- Tier 3 (Data / Literals)
  Boolean = { link = "@boolean" },
  Character = { fg = palette.green_dark },
  Constant = { fg = palette.magenta_dark },
  Float = { link = "Constant" },
  Number = { link = "Constant" },
  String = { fg = palette.green_dark },

  -- Tier 4 (Logic / Emphasis)
  -- T4 Group 1: Control Flow
  Conditional = { fg = palette.blue_dark, bold = true },
  Exception = { fg = palette.red_dark, bold = true },
  Repeat = { fg = palette.blue_dark, bold = true },
  Statement = { link = "Conditional" },

  -- T4 Group 2: Keywords & Directives
  Decorator = { fg = palette.orange_dark },
  Define = { fg = palette.orange_dark },
  Include = { fg = palette.orange_dark },
  Keyword = { fg = palette.blue_dark },
  PreProc = { fg = palette.orange_dark },
  StorageClass = { fg = palette.orange_dark },
  Label = { fg = palette.orange_dark },

  -- T4 Group 3: Definitions
  Function = { link = "@function" },
  Builtin = { link = "@function.builtin" },

  -- T4 Group 4: Types
  Structure = { fg = palette.blue_dark },
  Type = { fg = palette.cyan_dark },
  Typedef = { fg = palette.cyan_dark },
  Namespace = { fg = palette.cyan_dark },

  -- Fallbacks
  Special = { fg = palette.cyan_dark },
  Todo = { fg = palette.yellow_dark, bg = "NONE" },
  Annotation = { link = "Decorator" },
  Macro = { link = "Define" },
  PreCondit = { link = "PreProc" },

  -- Diff highlighting
  DiffAdd = { fg = palette.green_dark },
  DiffChange = { fg = palette.orange_dark },
  DiffDelete = { fg = palette.red_dark },
  DiffText = { fg = palette.blue_dark },

  -- GitSigns
  GitSignsAdd = { fg = palette.green_dark },
  GitSignsChange = { fg = palette.orange_dark },
  GitSignsDelete = { fg = palette.red_dark },

  -- Telescope
  TelescopeBorder = { fg = palette.bg_dim, bg = palette.bg_alt },
  TelescopePromptBorder = { fg = palette.bg_dim, bg = palette.bg_alt },
  TelescopePromptNormal = { fg = palette.fg_main, bg = palette.bg_alt },
  TelescopePromptTitle = { fg = palette.fg_main, bg = palette.nord4 },
  TelescopeResultsBorder = { fg = palette.bg_dim, bg = palette.bg_main },
  TelescopeResultsNormal = { fg = palette.fg_main, bg = palette.bg_main },
  TelescopeResultsTitle = { fg = palette.fg_main, bg = palette.nord4 },
  TelescopePreviewBorder = { fg = palette.bg_dim, bg = palette.bg_main },
  TelescopePreviewNormal = { fg = palette.fg_main, bg = palette.bg_main },
  TelescopePreviewTitle = { fg = palette.fg_main, bg = palette.nord4 },
  TelescopeMatching = { fg = palette.nord0, bg = palette.yellow },
  TelescopeSelection = { fg = palette.fg_main, bg = palette.nord4, italic = false },
  TelescopeSelectionCaret = { fg = palette.blue_dark, bg = palette.nord4 },
}

for group, opts in pairs(highlights) do
  vim.api.nvim_set_hl(0, group, opts)
end

-- Terminal
vim.g.terminal_color_0 = palette.fg_main
vim.g.terminal_color_1 = palette.red_dark
vim.g.terminal_color_2 = palette.green_dark
vim.g.terminal_color_3 = palette.yellow_dark
vim.g.terminal_color_4 = palette.blue_dark
vim.g.terminal_color_5 = palette.magenta_dark
vim.g.terminal_color_6 = palette.cyan_dark
vim.g.terminal_color_7 = palette.bg_dim
vim.g.terminal_color_8 = palette.fg_dim
vim.g.terminal_color_9 = palette.red_dark
vim.g.terminal_color_10 = palette.green_dark
vim.g.terminal_color_11 = palette.yellow_dark
vim.g.terminal_color_12 = palette.blue_dark
vim.g.terminal_color_13 = palette.magenta_dark
vim.g.terminal_color_14 = palette.cyan_dark
vim.g.terminal_color_15 = palette.fg_main -- White is dark in light theme

vim.g.colors_name = "nord_light"
