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
  -- Base
  bg = palette.bg_main,
  fg = palette.fg_main,
  bg_alt = palette.bg_alt,
  fg_dim = palette.fg_dim,
  
  -- UI Elements
  border = palette.bg_dim,
  cursor_fg = palette.bg_main,
  cursor_bg = palette.nord0,
  line_nr_fg = palette.nord3,
  line_nr_active_fg = palette.blue_dark,
  gutter_bg = palette.bg_dim,
  gutter_bg_active = palette.bg_active,
  selection_bg = palette.nord4,
  float_bg = palette.bg_alt,
  float_border = palette.bg_alt,
  
  -- Status
  error = palette.red,
  warning = palette.yellow,
  success = palette.green,
  info = palette.blue,
  
  -- Status Text
  error_fg = palette.red_dark,
  warning_fg = palette.yellow_dark,
  success_fg = palette.green_dark,
  info_fg = palette.blue_dark,

  -- Syntax
  comment = palette.nord3,
  string = palette.green_dark,
  keyword = palette.blue_dark,
  function_ = palette.blue_dark,
  type = palette.cyan_dark,
  variable = palette.fg_main,
  constant = palette.magenta_dark,
  operator = palette.nord9,
  number = palette.magenta_dark,
  boolean = palette.orange_dark,
  property = palette.blue_dark,
  parameter = palette.fg_main,
  decorator = palette.orange_dark,
  
  -- Search
  search_bg = palette.nord4,
  inc_search_bg = palette.blue_dark,
  inc_search_fg = palette.bg_main,
  
  -- Diff
  diff_add = palette.green_dark,
  diff_change = palette.orange_dark,
  diff_delete = palette.red_dark,
  diff_text = palette.blue_dark,
}

local highlights = {
  -- Attributes
  Bold = { bold = true },
  Italic = { italic = true },
  Underline = { underline = true },

  -- Editor
  ColorColumn = { bg = components.border },
  Cursor = { fg = components.cursor_fg, bg = components.cursor_bg },
  Error = { fg = components.cursor_fg, bg = components.error },
  iCursor = { fg = components.cursor_fg, bg = components.cursor_bg },
  LineNr = { fg = components.line_nr_fg },
  MatchParen = { fg = components.keyword, bg = components.search_bg },
  NonText = { fg = components.search_bg },
  Normal = { fg = components.fg, bg = components.bg },
  NormalNC = { fg = components.fg, bg = components.bg },
  NormalSB = { fg = components.fg, bg = components.bg },
  NormalFloat = { fg = components.fg, bg = components.float_bg },
  FloatBorder = { link = "NormalFloat" },
  FloatTitle = { fg = components.keyword },
  FloatFooter = { link = "NormalFloat" },
  Pmenu = { fg = components.fg, bg = components.bg_alt },
  PmenuSbar = { fg = components.border, bg = components.border },
  PmenuSel = { fg = components.bg, bg = components.operator },
  PmenuThumb = { fg = components.line_nr_fg, bg = components.line_nr_fg },
  SpecialKey = { fg = components.line_nr_fg },
  SpellBad = { fg = components.error, bg = "NONE", undercurl = true, sp = components.error },
  SpellCap = { fg = components.warning, bg = "NONE", undercurl = true, sp = components.warning },
  SpellLocal = { fg = components.keyword, bg = "NONE", undercurl = true, sp = components.keyword },
  SpellRare = { fg = components.type, bg = "NONE", undercurl = true, sp = components.type },
  Visual = { bg = components.selection_bg },
  VisualNOS = { bg = components.selection_bg },

  -- Neovim specific highlights
  healthError = { fg = components.error_fg, bg = components.bg_alt },
  healthSuccess = { fg = components.success_fg, bg = components.bg_alt },
  healthWarning = { fg = components.warning_fg, bg = components.bg_alt },
  TermCursorNC = { bg = components.bg_alt },

  -- Neovim Diagnostics API (for LSP)
  DiagnosticWarn = { fg = components.warning_fg },
  DiagnosticError = { fg = components.error_fg },
  DiagnosticInfo = { fg = components.info_fg },
  DiagnosticHint = { fg = components.keyword },
  DiagnosticUnderlineWarn = { fg = components.warning, undercurl = true },
  DiagnosticUnderlineError = { fg = components.error, undercurl = true },
  DiagnosticUnderlineInfo = { fg = components.info, undercurl = true },
  DiagnosticUnderlineHint = { fg = components.info, undercurl = true },

  -- Neovim DocumentHighlight
  LspReferenceText = { bg = components.selection_bg },
  LspReferenceRead = { bg = components.selection_bg },
  LspReferenceWrite = { bg = components.selection_bg },

  -- Neovim LspSignatureHelp
  LspSignatureActiveParameter = { fg = components.info_fg, underline = true },

  -- Gutter
  CursorColumn = { bg = components.gutter_bg },
  CursorLine = { bg = components.gutter_bg },
  CursorLineNr = { fg = components.line_nr_active_fg, bg = components.gutter_bg_active, bold = true },
  CursorLineSign = { bg = components.gutter_bg_active },
  Folded = { fg = components.line_nr_fg, bg = components.gutter_bg, bold = true },
  FoldColumn = { fg = components.line_nr_fg, bg = components.bg },
  SignColumn = { fg = components.line_nr_fg, bg = components.bg },
  SignColumnSB = { fg = components.line_nr_fg, bg = components.bg },

  -- Navigation
  Directory = { fg = components.keyword },
  File = { fg = components.fg },

  -- Prompt/Status
  EndOfBuffer = { fg = components.border },
  ErrorMsg = { fg = components.bg, bg = components.error },
  ModeMsg = { fg = components.fg },
  MoreMsg = { fg = components.info_fg },
  Question = { fg = components.fg },

  StatusLine = { fg = components.fg, bg = components.border },
  StatusLineNC = { fg = components.line_nr_fg, bg = components.bg_alt },
  StatusLineTerm = { fg = components.fg, bg = components.border },
  StatusLineTermNC = { fg = components.line_nr_fg, bg = components.bg_alt },

  WarningMsg = { fg = components.bg, bg = components.warning },
  WildMenu = { fg = components.keyword, bg = components.bg_alt },

  -- Search
  IncSearch = { fg = components.bg, bg = components.info_fg, underline = true },
  Search = { fg = components.fg, bg = components.search_bg },

  -- Tabs
  TabLine = { fg = components.line_nr_fg, bg = components.bg_alt },
  TabLineFill = { fg = components.line_nr_fg, bg = components.border },
  TabLineSel = { fg = components.fg, bg = components.bg },

  -- Window
  Title = { fg = components.keyword },
  VertSplit = { fg = components.border, bg = components.bg },
  WinSeparator = { link = "VertSplit" },

  -- QuickFix
  QuickFixLine = { link = "Search" },
  QuickFixLineNr = { link = "LineNr" },
  QuickFixFilename = { link = "File" },

  -------------------------------------------------------------------
  -- Semantic Tokens ------------------------------------------------
  -------------------------------------------------------------------

  ["@comment"] = { fg = components.comment, italic = true },
  ["@constant"] = { fg = components.constant },
  ["@string"] = { fg = components.string },
  ["@string.regexp"] = { fg = components.warning_fg },
  ["@number"] = { fg = components.number },
  ["@keyword"] = { fg = components.keyword },
  ["@variable"] = { fg = components.variable },
  ["@variable.builtin"] = { fg = components.operator },
  ["@property"] = { fg = components.property },
  ["@operator"] = { fg = components.operator },
  ["@boolean"] = { fg = components.boolean, bold = true },
  ["@function"] = { fg = components.function_ },
  ["@function.builtin"] = { fg = components.function_ },
  ["@function.macro"] = { fg = components.function_ },
  ["@function.call"] = { fg = components.function_, italic = true },
  ["@type"] = { fg = components.type },
  ["@type.builtin"] = { fg = components.type, bold = true },
  ["@constructor"] = { fg = components.type },
  ["@decorator"] = { fg = components.decorator },
  ["@markup.strong"] = { fg = components.fg, bold = true },
  ["@punctuation"] = { fg = components.comment },
  ["@punctuation.bracket"] = { fg = components.comment },
  ["@punctuation.delimiter"] = { fg = components.comment },

  -- LSP
  ["@lsp.type.macro"] = { fg = components.decorator },
  ["@lsp.type.keyword"] = { fg = components.keyword },
  ["@lsp.type.parameter"] = { fg = components.parameter, italic = true },
  ["@lsp.type.property"] = { link = "@property" },
  ["@lsp.type.function"] = { link = "@function" },
  ["@lsp.type.type"] = { link = "@type" },

  -- JSON
  ["@property.json"] = { fg = components.type },

  -- Markdown
  ["@markup.list.markdown"] = { fg = components.comment },
  ["@markup.heading.1.markdown"] = { fg = components.keyword },
  ["@markup.heading.2.markdown"] = { fg = components.keyword },
  ["@markup.heading.3.markdown"] = { fg = components.keyword },
  ["@markup.heading.4.markdown"] = { fg = components.keyword },
  ["@markup.heading.5.markdown"] = { fg = components.keyword },
  ["@markup.heading.6.markdown"] = { fg = components.keyword },

  -------------------------------------------------------------------
  -- Language Base Groups -------------------------------------------
  -------------------------------------------------------------------
  -- Tier 1 (Noise / Structure)
  Comment = { link = "@comment" },
  Conceal = { bg = "NONE" },
  Delimiter = { fg = components.comment },
  Operator = { link = "@operator" },
  SpecialChar = { fg = components.warning_fg },
  SpecialComment = { fg = components.info_fg, italic = true },

  -- Tier 2 (Body / Variables)
  Field = { link = "@property" },
  Identifier = { link = "@variable" },
  Tag = { link = "@type" },
  Variable = { link = "@variable" },

  -- Tier 3 (Data / Literals)
  Boolean = { link = "@boolean" },
  Character = { fg = components.string },
  Constant = { fg = components.constant },
  Float = { link = "Constant" },
  Number = { link = "Constant" },
  String = { fg = components.string },

  -- Tier 4 (Logic / Emphasis)
  -- T4 Group 1: Control Flow
  Conditional = { fg = components.keyword, bold = true },
  Exception = { fg = components.error_fg, bold = true },
  Repeat = { fg = components.keyword, bold = true },
  Statement = { link = "Conditional" },

  -- T4 Group 2: Keywords & Directives
  Decorator = { fg = components.decorator },
  Define = { fg = components.decorator },
  Include = { fg = components.decorator },
  Keyword = { fg = components.keyword },
  PreProc = { fg = components.decorator },
  StorageClass = { fg = components.decorator },
  Label = { fg = components.decorator },

  -- T4 Group 3: Definitions
  Function = { link = "@function" },
  Builtin = { link = "@function.builtin" },

  -- T4 Group 4: Types
  Structure = { fg = components.keyword },
  Type = { fg = components.type },
  Typedef = { fg = components.type },
  Namespace = { fg = components.type },

  -- Fallbacks
  Special = { fg = components.type },
  Todo = { fg = components.warning_fg, bg = "NONE" },
  Annotation = { link = "Decorator" },
  Macro = { link = "Define" },
  PreCondit = { link = "PreProc" },

  -- Diff highlighting
  DiffAdd = { fg = components.diff_add },
  DiffChange = { fg = components.diff_change },
  DiffDelete = { fg = components.diff_delete },
  DiffText = { fg = components.diff_text },

  -- GitSigns
  GitSignsAdd = { fg = components.diff_add },
  GitSignsChange = { fg = components.diff_change },
  GitSignsDelete = { fg = components.diff_delete },

  -- Telescope
  TelescopeBorder = { fg = components.border, bg = components.bg_alt },
  TelescopePromptBorder = { fg = components.border, bg = components.bg_alt },
  TelescopePromptNormal = { fg = components.fg, bg = components.bg_alt },
  TelescopePromptTitle = { fg = components.fg, bg = components.search_bg },
  TelescopeResultsBorder = { fg = components.border, bg = components.bg },
  TelescopeResultsNormal = { fg = components.fg, bg = components.bg },
  TelescopeResultsTitle = { fg = components.fg, bg = components.search_bg },
  TelescopePreviewBorder = { fg = components.border, bg = components.bg },
  TelescopePreviewNormal = { fg = components.fg, bg = components.bg },
  TelescopePreviewTitle = { fg = components.fg, bg = components.search_bg },
  TelescopeMatching = { fg = components.cursor_bg, bg = components.warning },
  TelescopeSelection = { fg = components.fg, bg = components.search_bg, italic = false },
  TelescopeSelectionCaret = { fg = components.keyword, bg = components.search_bg },

  -- Flash
  FlashMatch = { bg = components.selection_bg },
  FlashCurrent = { fg = components.bg, bg = palette.orange_dim },
  FlashLabel = { fg = components.bg, bg = components.warning },
  FlashPrompt = { link = "MsgArea" },
  FlashPromptIcon = { link = "Special" },
  FlashCursor = { link = "Cursor" },

  -- Oil
  OilFile = { fg = components.fg },
  OilDir = { fg = components.keyword, bold = true },
  OilLink = { fg = components.type, italic = true },
  OilSocket = { fg = components.warning },

  -- Conjure
  ConjureLogHeader = { fg = components.comment, bold = true },
  ConjureLogHue0 = { fg = components.error_fg },
  ConjureLogHue1 = { fg = components.warning_fg },
  ConjureLogHue2 = { fg = components.success_fg },
  ConjureLogHue3 = { fg = components.info_fg },

  -- ToggleTerm
  ToggleTerm1 = { bg = components.bg_alt },
  ToggleTerm2 = { bg = components.bg_alt },
  ToggleTermFloatBorder = { link = "FloatBorder" },

  -- Dadbod UI
  dbui_tables = { fg = components.fg },
  dbui_header = { fg = components.keyword },
  dbui_connection_source = { fg = components.comment, italic = true },
}

for group, opts in pairs(highlights) do
  vim.api.nvim_set_hl(0, group, opts)
end

-- Terminal
vim.g.terminal_color_0 = components.fg
vim.g.terminal_color_1 = components.error_fg
vim.g.terminal_color_2 = components.success_fg
vim.g.terminal_color_3 = components.warning_fg
vim.g.terminal_color_4 = components.info_fg
vim.g.terminal_color_5 = components.constant
vim.g.terminal_color_6 = components.type
vim.g.terminal_color_7 = components.border
vim.g.terminal_color_8 = components.fg_dim
vim.g.terminal_color_9 = components.error_fg
vim.g.terminal_color_10 = components.success_fg
vim.g.terminal_color_11 = components.warning_fg
vim.g.terminal_color_12 = components.info_fg
vim.g.terminal_color_13 = components.constant
vim.g.terminal_color_14 = components.type
vim.g.terminal_color_15 = components.fg

vim.g.colors_name = "nord_light"
