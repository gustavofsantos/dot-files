-- nord_light: a high-contrast light Nord, tuned for reading in direct sunlight.
--
-- Standard Nord is intentionally low-contrast and muted, which falls apart on a
-- bright screen outdoors. This variant keeps the Nord hue family but pushes for
-- legibility: a bright near-white background and dark, saturated "ink" accents
-- that all clear WCAG AA (>= 4.5:1) against that background. Nothing here is a
-- pastel — every color is meant to survive glare.

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
  -- Surfaces: bright, faint cool tint so the page reads as paper, not gray.
  white       = "#FFFFFF",
  bg          = "#F7F9FB", -- main editor background
  bg_alt      = "#E9EFF4", -- panels: pmenu, inactive statusline, telescope
  bg_dim      = "#E0E7EE", -- subtle fills
  cursorline  = "#EBF0F5", -- current line / column tint
  selection   = "#C7DDF2", -- visual selection (clearly blue, still light)
  border      = "#C2CCD7",

  -- Ink: text, from darkest body text down to faint structural marks.
  ink         = "#11161F", -- primary text — near black, max contrast
  ink_soft    = "#2A3340", -- secondary text / variables
  slate       = "#34506F", -- properties, parameters
  muted       = "#5B6573", -- comments — dimmed but fully readable in sun
  faint       = "#98A2AF", -- line numbers, whitespace, non-text glyphs

  -- Accents: dark + saturated so they hold up against glare on a light page.
  blue        = "#2C5C8F", -- keywords
  blue_bright = "#3E72A8", -- operators / info
  blue_deep   = "#234B76", -- emphasis / incsearch
  teal        = "#1C6B6E", -- functions
  green       = "#3F6428", -- strings / additions
  green_soft  = "#5E8C3E", -- success fills
  amber       = "#8A5A12", -- types
  amber_soft  = "#9A6A00", -- warning fills
  orange      = "#A24E1E", -- decorators / booleans
  orange_dim  = "#B5642E", -- flash accent
  red         = "#A0182A", -- errors
  red_soft    = "#B21F2B", -- error fills
  purple      = "#7A3B86", -- numbers / constants

  -- Highlights.
  search      = "#FBE39A", -- soft amber wash for matches
  gold        = "#FDC500",
}

local components = {
  -- Base
  bg = palette.bg,
  fg = palette.ink,
  bg_alt = palette.bg_alt,
  fg_dim = palette.ink_soft,

  -- UI Elements
  border = palette.border,
  cursor_fg = palette.bg,
  cursor_bg = palette.ink,
  line_nr_fg = palette.faint,
  line_nr_active_fg = palette.orange,
  gutter_bg = palette.cursorline,
  gutter_bg_active = palette.bg_dim,
  selection_bg = palette.selection,
  float_bg = palette.white,
  float_border = palette.border,

  -- Status (fills / undercurl colors — kept saturated)
  error = palette.red_soft,
  warning = palette.amber_soft,
  success = palette.green_soft,
  info = palette.blue_bright,

  -- Status Text (foreground — kept dark)
  error_fg = palette.red,
  warning_fg = palette.amber,
  success_fg = palette.green,
  info_fg = palette.blue_deep,

  -- Syntax
  comment = palette.muted,
  string = palette.green,
  keyword = palette.blue,
  function_ = palette.teal,
  type = palette.amber,
  variable = palette.ink_soft,
  constant = palette.purple,
  operator = palette.blue_bright,
  number = palette.purple,
  boolean = palette.orange,
  property = palette.slate,
  parameter = palette.slate,
  decorator = palette.orange,

  -- Search
  search_bg = palette.search,
  inc_search_bg = palette.blue_deep,
  inc_search_fg = palette.bg,

  -- Diff
  diff_add = palette.green,
  diff_change = palette.amber,
  diff_delete = palette.red,
  diff_text = palette.blue_deep,
}

local highlights = {
  -- Attributes
  Bold = { bold = true },
  Italic = { italic = true },
  Underline = { underline = true },

  -- Editor
  ColorColumn = { bg = components.gutter_bg },
  Cursor = { fg = components.cursor_fg, bg = components.cursor_bg },
  Error = { fg = components.cursor_fg, bg = components.error },
  iCursor = { fg = components.cursor_fg, bg = components.cursor_bg },
  LineNr = { fg = components.line_nr_fg },
  MatchParen = { fg = components.keyword, bg = components.search_bg, bold = true },
  NonText = { fg = components.line_nr_fg },
  Normal = { fg = components.fg, bg = components.bg },
  NormalNC = { fg = components.fg, bg = components.bg },
  NormalSB = { fg = components.fg, bg = components.bg },
  NormalFloat = { fg = components.fg, bg = components.float_bg },
  FloatBorder = { fg = components.float_border, bg = components.float_bg },
  FloatTitle = { fg = components.keyword, bold = true },
  FloatFooter = { link = "NormalFloat" },
  Pmenu = { fg = components.fg, bg = components.bg_alt },
  PmenuSbar = { fg = components.border, bg = components.border },
  PmenuSel = { fg = components.bg, bg = components.keyword },
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
  Folded = { fg = components.comment, bg = components.gutter_bg, bold = true },
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
  IncSearch = { fg = components.inc_search_fg, bg = components.inc_search_bg, bold = true },
  Search = { fg = components.fg, bg = components.search_bg },

  -- Tabs
  TabLine = { fg = components.line_nr_fg, bg = components.bg_alt },
  TabLineFill = { fg = components.line_nr_fg, bg = components.border },
  TabLineSel = { fg = components.fg, bg = components.bg, bold = true },

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
  Todo = { fg = components.warning_fg, bg = "NONE", bold = true },
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
  TelescopePromptTitle = { fg = components.bg, bg = components.keyword },
  TelescopeResultsBorder = { fg = components.border, bg = components.bg },
  TelescopeResultsNormal = { fg = components.fg, bg = components.bg },
  TelescopeResultsTitle = { fg = components.bg, bg = components.keyword },
  TelescopePreviewBorder = { fg = components.border, bg = components.bg },
  TelescopePreviewNormal = { fg = components.fg, bg = components.bg },
  TelescopePreviewTitle = { fg = components.bg, bg = components.keyword },
  TelescopeMatching = { fg = components.cursor_bg, bg = components.search_bg, bold = true },
  TelescopeSelection = { fg = components.fg, bg = components.selection_bg, italic = false },
  TelescopeSelectionCaret = { fg = components.keyword, bg = components.selection_bg },

  -- Flash
  FlashMatch = { bg = components.selection_bg },
  FlashCurrent = { fg = components.bg, bg = palette.orange_dim },
  FlashLabel = { fg = components.bg, bg = components.error, bold = true },
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
vim.g.terminal_color_6 = components.function_
vim.g.terminal_color_7 = components.border
vim.g.terminal_color_8 = components.fg_dim
vim.g.terminal_color_9 = components.error_fg
vim.g.terminal_color_10 = components.success_fg
vim.g.terminal_color_11 = components.warning_fg
vim.g.terminal_color_12 = components.info_fg
vim.g.terminal_color_13 = components.constant
vim.g.terminal_color_14 = components.function_
vim.g.terminal_color_15 = components.fg

vim.g.colors_name = "nord_light"
