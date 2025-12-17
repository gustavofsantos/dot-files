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

local nord0        = "#2e3440"
local nord1        = "#3b4252"
local nord2        = "#434c5e"
local nord3        = "#4c566a"
local nord4        = "#d8dee9"
local nord5        = "#e5e9f0"
local nord6        = "#eceff4"
local nord7        = "#8fbcbb"
local nord8        = "#88c0d0"
local nord9        = "#81a1c1"
local nord10       = "#5e81ac"
local nord11       = "#bf616a"
local nord12       = "#d08770"
local nord13       = "#ebcb8b"
local nord14       = "#a3be8c"
local nord15       = "#b48ead"

local gray__50     = "#f0f1f3"
local gray__100    = "#e4e5e9"
local gray__200    = "#c6c9d2"
local gray__300    = "#acb0bd"
local gray__400    = "#8f96a7"
local gray__500    = "#787f8f"
local gray__550    = "#4c566a"
local gray__600    = "#434c5e"
local gray__700    = "#3b4252"
local gray__800    = "#2e3440"
local gray__900    = "#23262c"
local gray__950    = "#1a1c21"
local fg__50       = "#ede8dc"
local fg__100      = "#e2d9c4"
local fg__200      = "#c8c0ad"
local fg__300      = "#aca595"
local fg__400      = "#918b7d"
local fg__500      = "#767266"
local fg__600      = "#605c52"
local fg__700      = "#47443d"
local fg__800      = "#302e28"
local fg__900      = "#1d1b18"
local fg__950      = "#12110e"
local cyan__50     = "#e1f8f8"
local cyan__100    = "#b7f0ef"
local cyan__200    = "#a3d5d4"
local cyan__300    = "#8fbcbb"
local cyan__400    = "#79a09f"
local cyan__500    = "#628281"
local cyan__600    = "#4e6867"
local cyan__700    = "#394d4c"
local cyan__800    = "#263535"
local cyan__900    = "#141d1d"
local cyan__950    = "#0b1212"
local sky__50      = "#ebf5f9"
local sky__100     = "#d0eaf2"
local sky__200     = "#a0d7e8"
local sky__300     = "#88c0d0"
local sky__400     = "#73a3b0"
local sky__500     = "#5d8590"
local sky__600     = "#4a6b74"
local sky__700     = "#364f56"
local sky__800     = "#23353b"
local sky__900     = "#131f23"
local sky__950     = "#091215"
local blue__50     = "#edf1f8"
local blue__100    = "#dee6f3"
local blue__200    = "#b8cbe7"
local blue__300    = "#95b3dc"
local blue__400    = "#7099cb"
local blue__500    = "#5e81ac"
local blue__600    = "#496588"
local blue__700    = "#374d68"
local blue__800    = "#243447"
local blue__900    = "#131e2c"
local blue__950    = "#0a111b"
local red__50      = "#f7efef"
local red__100     = "#f0e2e3"
local red__200     = "#e1c2c4"
local red__300     = "#d5a4a8"
local red__400     = "#ca8288"
local red__500     = "#bf616a"
local red__600     = "#984c53"
local red__700     = "#75393f"
local red__800     = "#512529"
local red__900     = "#321517"
local red__950     = "#1f0b0d"
local orange__50   = "#f7efed"
local orange__100  = "#f2e2df"
local orange__200  = "#e6c5bd"
local orange__300  = "#dba495"
local orange__400  = "#d08770"
local orange__500  = "#ad6f5c"
local orange__600  = "#885747"
local orange__700  = "#694235"
local orange__800  = "#482b23"
local orange__900  = "#2c1913"
local orange__950  = "#1b0d09"
local yellow__100  = "#f5e6ce"
local yellow__200  = "#ebcb8b"
local yellow__300  = "#ccb078"
local yellow__400  = "#ab9364"
local yellow__500  = "#8e7a52"
local yellow__600  = "#726140"
local yellow__700  = "#54472e"
local yellow__800  = "#3b311f"
local yellow__900  = "#211b0f"
local yellow__950  = "#151008"
local green__50    = "#e9f8de"
local green__100   = "#cef0b2"
local green__200   = "#bad8a0"
local green__300   = "#a3be8c"
local green__400   = "#89a075"
local green__500   = "#718561"
local green__600   = "#58684b"
local green__700   = "#434f38"
local green__800   = "#2c3525"
local green__900   = "#191f14"
local green__950   = "#0e120a"
local magenta__100 = "#ece3ea"
local magenta__200 = "#d9c7d5"
local magenta__300 = "#c7abc1"
local magenta__400 = "#b48ead"
local magenta__500 = "#997392"
local magenta__600 = "#795a73"
local magenta__700 = "#5c4458"
local magenta__800 = "#3f2d3c"
local magenta__900 = "#261a24"
local magenta__950 = "#170e15"


local palette  = {
  -- Default nord colors
  -------------------------

  nord0          = "#2e3440",
  nord1          = "#3b4252",
  nord2          = "#434c5e",
  nord3          = "#4c566a",
  nord4          = "#d8dee9",
  nord5          = "#e5e9f0",
  nord6          = "#eceff4",
  nord7          = "#8fbcbb",
  nord8          = "#88c0d0",
  nord9          = "#81a1c1",
  nord10         = "#5e81ac",
  nord11         = "#bf616a",
  nord12         = "#d08770",
  nord13         = "#ebcb8b",
  nord14         = "#a3be8c",
  nord15         = "#b48ead",

  cream1         = '#D9D3C4',
  cream2         = '#E5DECD',
  cream3         = '#EDE8DC',
  cream4         = '#F6F3ED',
  cream5         = '#F0EFEA',

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
local p        = palette
p.red_dark     = blend_colors(p.red, "#000000", 0.4)
p.green_dark   = blend_colors(p.green, "#000000", 0.6) -- More darkening needed for green
p.yellow_dark  = blend_colors(p.yellow, "#000000", 0.65)
p.blue_dark    = blend_colors(p.blue, "#000000", 0.4)
p.magenta_dark = blend_colors(p.magenta, "#000000", 0.5)
p.cyan_dark    = blend_colors(p.cyan, "#000000", 0.6)
p.orange_dark  = blend_colors(p.orange, "#000000", 0.4)


local components = {
  -- Base
  bg = gray__50,
  fg = gray__800,
  bg_alt = gray__100,
  fg_dim = gray__800,

  -- UI Elements
  border = gray__300,
  cursor_fg = palette.bg_main,
  cursor_bg = palette.nord0,
  line_nr_fg = gray__300,
  line_nr_active_fg = yellow__200,
  gutter_bg = gray__100,
  gutter_bg_active = gray__700,
  selection_bg = blue__200,
  float_bg = gray__200,
  float_border = gray__300,

  -- Status
  error = red__600,
  warning = yellow__500,
  success = green__200,
  info = blue__300,

  -- Status Text
  error_fg = red__700,
  warning_fg = yellow__700,
  success_fg = green__600,
  info_fg = blue__500,

  -- Syntax
  comment = gray__300,
  string = green__500,
  keyword = nord10,
  function_ = sky__500,
  type = yellow__500,
  variable = nord2,
  constant = nord2,
  operator = nord9,
  number = nord15,
  boolean = nord12,
  property = gray__600,
  parameter = gray__600,
  decorator = nord12,

  -- Search
  search_bg = palette.nord4,
  inc_search_bg = palette.blue_dark,
  inc_search_fg = palette.bg_main,

  -- Diff
  diff_add = green__400,
  diff_change = orange__400,
  diff_delete = red__400,
  diff_text = blue__800,
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
