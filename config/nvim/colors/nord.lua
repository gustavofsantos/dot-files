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

local colors = {
  nord0        = "#2e3440",
  nord1        = "#3b4252",
  nord2        = "#434c5e",
  nord3        = "#4c566a",
  nord4        = "#d8dee9",
  nord5        = "#e5e9f0",
  nord6        = "#eceff4",
  nord7        = "#8fbcbb",
  nord8        = "#88c0d0",
  nord9        = "#81a1c1",
  nord10       = "#5e81ac",
  nord11       = "#bf616a",
  nord12       = "#d08770",
  nord13       = "#ebcb8b",
  nord14       = "#a3be8c",
  nord15       = "#b48ead",

  gray__50     = "#f0f1f3",
  gray__100    = "#e4e5e9",
  gray__200    = "#c6c9d2",
  gray__300    = "#acb0bd",
  gray__400    = "#8f96a7",
  gray__500    = "#787f8f",
  gray__550    = "#4c566a",
  gray__600    = "#434c5e",
  gray__700    = "#3b4252",
  gray__800    = "#2e3440",
  gray__900    = "#222630",
  gray__950    = "#1A1C21",

  fg__50       = "#ede8dc",
  fg__100      = "#e2d9c4",
  fg__200      = "#c8c0ad",
  fg__300      = "#aca595",
  fg__400      = "#918b7d",
  fg__500      = "#767266",
  fg__600      = "#605c52",
  fg__700      = "#47443d",
  fg__800      = "#302e28",
  fg__900      = "#1d1b18",
  fg__950      = "#12110e",

  cyan__50     = "#e1f8f8",
  cyan__100    = "#b7f0ef",
  cyan__200    = "#a3d5d4",
  cyan__300    = "#8fbcbb", -- nord7
  cyan__400    = "#79a09f",
  cyan__500    = "#628281",
  cyan__600    = "#4e6867",
  cyan__700    = "#394d4c",
  cyan__800    = "#263535",
  cyan__900    = "#141d1d",
  cyan__950    = "#0b1212",

  sky__50      = "#ebf5f9",
  sky__100     = "#d0eaf2",
  sky__200     = "#a0d7e8",
  sky__300     = "#88c0d0", -- nord8
  sky__400     = "#73a3b0",
  sky__500     = "#5d8590",
  sky__600     = "#4a6b74",
  sky__700     = "#364f56",
  sky__800     = "#23353b",
  sky__900     = "#131f23",
  sky__950     = "#091215",

  blue__50     = "#edf1f8",
  blue__100    = "#dee6f3",
  blue__200    = "#b8cbe7",
  blue__300    = "#95b3dc",
  blue__400    = "#7099cb",
  blue__500    = "#5e81ac", -- nord10
  blue__600    = "#496588",
  blue__700    = "#374d68",
  blue__800    = "#243447",
  blue__900    = "#131e2c",
  blue__950    = "#0a111b",

  red__50      = "#f7efef",
  red__100     = "#f0e2e3",
  red__200     = "#e1c2c4",
  red__300     = "#d5a4a8",
  red__400     = "#ca8288",
  red__500     = "#bf616a", -- nord11
  red__600     = "#984c53",
  red__700     = "#75393f",
  red__800     = "#512529",
  red__900     = "#321517",
  red__950     = "#1f0b0d",

  orange__50   = "#f7efed",
  orange__100  = "#f2e2df",
  orange__200  = "#e6c5bd",
  orange__300  = "#dba495",
  orange__400  = "#d08770", -- nord12
  orange__500  = "#ad6f5c",
  orange__600  = "#885747",
  orange__700  = "#694235",
  orange__800  = "#482b23",
  orange__900  = "#2c1913",
  orange__950  = "#1b0d09",

  yellow__100  = "#f5e6ce",
  yellow__200  = "#ebcb8b", -- nord13
  yellow__300  = "#ccb078",
  yellow__400  = "#ab9364",
  yellow__500  = "#8e7a52",
  yellow__600  = "#726140",
  yellow__700  = "#54472e",
  yellow__800  = "#3b311f",
  yellow__900  = "#211b0f",
  yellow__950  = "#151008",

  green__50    = "#e9f8de",
  green__100   = "#cef0b2",
  green__200   = "#bad8a0",
  green__300   = "#a3be8c", -- nord14
  green__400   = "#89a075",
  green__500   = "#718561",
  green__600   = "#58684b",
  green__700   = "#434f38",
  green__800   = "#2c3525",
  green__900   = "#191f14",
  green__950   = "#0e120a",

  magenta__100 = "#ece3ea",
  magenta__200 = "#d9c7d5",
  magenta__300 = "#c7abc1",
  magenta__400 = "#b48ead", -- nord15
  magenta__500 = "#997392",
  magenta__600 = "#795a73",
  magenta__700 = "#5c4458",
  magenta__800 = "#3f2d3c",
  magenta__900 = "#261a24",
  magenta__950 = "#170e15",
}


local palette = {
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

  -- Used for UI elements that are rendering success states and visualizations and the highlighting of Git diff additions.
  -- In the context of syntax highlighting it is used as main color for strings of any type like double/single quoted or interpolated.
  nord14         = "#a3be8c",

  -- Rarely used for UI elements, but it may indicate a more uncommon functionality.
  -- In the context of syntax highlighting it is used as main color for numbers of any type like integers and floating point numbers.
  nord15         = "#b48ead",

  cream1         = '#D9D3C4',
  cream2         = '#E5DECD',
  cream3         = '#EDE8DC',
  cream4         = '#F6F3ED',
  cream5         = '#F0EFEA',

  nord00         = "#2E3440",
  nord01         = "#3B4252",
  nord02         = "#434C5E",
  nord03         = "#4C566A",
  nord04         = "#616E88",
  nord05         = "#EDE8DC",
  nord06         = "#F6F3ED",
  nord07         = "#F0EFEA",

  gray000        = '#1A1C21',
  gray00         = '#191D24',
  gray01         = '#1E222A',
  gray02         = '#222630',
  gray0          = '#242933',
  gray1          = '#2E3440',
  gray2          = '#3B4252',
  gray3          = '#434C5E',
  gray4          = '#4C566A',
  gray5          = '#60728A',
  gray6          = '#D9D3C4',
  gray7          = '#E5DECD',
  gray8          = '#EDE8DC',
  gray9          = '#F6F3ED',
  gray10         = '#F0EFEA',

  cyan_bright    = '#9FC6C5',
  cyan           = "#8FBCBB",
  cyan_dim       = '#80B3B2',
  sky            = "#88C0D0",
  sky_bright     = "#bee9e8",
  blue_bright    = "#81A1C1",
  blue           = "#5E81AC",
  blue_muted     = "#415570",
  red_bright     = "#C5727A",
  red            = "#BF616A", -- #c1121f - #780000
  red_dim        = "#B74E58",
  red_muted      = "#72454F",
  orange_bright  = '#D79784', -- #ff6b35
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

local components = {
  editor_bg = palette.gray0,
  editor_fg = palette.cream3,
  editor_fg_alt = palette.cream1,

  popup_bg = palette.gray01,
  popup_fg = palette.cream3,

  border = palette.gray00,
  border_alt = palette.gray01,

  text_normal = palette.cream3,
  text_muted = palette.gray5,
  text_subtle = palette.nord03,

  bg_hover = palette.gray02,
  bg_active = palette.nord02,
  bg_visual = palette.nord02,

  cursor = palette.nord05,
  cursor_bg = palette.gray000,

  ui_accent = palette.cyan,
  ui_accent_bright = palette.cyan_bright,
  ui_accent_dim = palette.cyan_dim,

  ui_highlight = palette.sky,
  ui_highlight_bright = palette.sky_bright,

  control_flow_base = palette.blue,
  control_flow_bright = palette.blue_bright,
  control_flow_muted = palette.blue_muted,

  error_base = palette.red,
  error_bright = palette.red_bright,
  error_dim = palette.red_500,
  error_muted = colors.red__600,

  keyword_base = palette.orange,
  keyword_bright = palette.orange_bright,
  keyword_dim = palette.orange_dim,

  warning_base = palette.yellow,
  warning_bright = palette.yellow_bright,
  warning_muted = palette.yellow_muted,
  warning_dim = palette.yellow_dim,

  string_base = palette.green,
  string_bright = palette.green_bright,

  constant_base = palette.magenta,
  constant_bright = palette.magenta_bright,
  constant_dim = palette.magenta_dim,

  error = palette.red,
  error_bg = palette.gray0,
  warning = palette.yellow,
  success = palette.green,
  info = palette.blue,

  diff_add = palette.nord14,
  diff_change = palette.nord12,
  diff_delete = palette.nord11,
  diff_text = palette.nord9,

  menu_bg = palette.nord1,
  menu_fg = palette.nord4,
  menu_sel_bg = palette.nord13,
  menu_sel_fg = palette.nord0,

  line_nr = palette.nord03,
  fold_column = palette.nord03,

  search_bg = palette.sky,
  search_fg = palette.nord01,
  search_match_bg = palette.yellow_bright,
  search_match_fg = palette.gray00,

  tab_bg = palette.gray01,
  tab_fg = palette.nord05,
  tab_sel_bg = palette.gray0,
  tab_sel_fg = palette.gray6,

  mode_normal = palette.nord8,
  mode_insert = palette.nord12,
  mode_visual = palette.nord15,
  mode_replace = palette.nord11,
  mode_command = palette.nord9,
  mode_other = palette.nord10,

  whitespace = palette.nord02,
  indent_guide = palette.gray4,

  comment = palette.nord3,
  string = palette.green,
  number = palette.nord15,
  constant = palette.magenta_bright,
  variable = palette.cream3,
  variable_builtin = palette.cream2,
  keyword = palette.orange,
  operator = palette.nord10,
  function_name = palette.nord8,
  type = palette.yellow_dim,
  boolean = palette.orange_dim,

  git_add = palette.nord14,
  git_change = palette.nord12,
  git_delete = palette.nord11,

  special = palette.cyan_bright,
}

local highlights = {
  -- Attributes
  Bold = { bold = true },
  Italic = { italic = true },
  Underline = { underline = true },

  -- Editor
  ColorColumn = { bg = components.bg_hover },
  Cursor = { fg = components.cursor_bg, bg = components.cursor },
  Error = { fg = components.cursor, bg = components.error },
  iCursor = { fg = components.cursor_bg, bg = components.cursor },
  LineNr = { fg = components.line_nr },
  MatchParen = { fg = palette.nord9 },
  NonText = { fg = palette.nord02 },
  Normal = { fg = components.editor_fg, bg = components.editor_bg },
  NormalNC = { fg = components.editor_fg_alt, bg = components.editor_bg },
  NormalSB = { fg = components.editor_fg, bg = components.editor_bg },
  NormalFloat = { fg = components.popup_fg, bg = components.popup_bg },
  FloatBorder = { link = "NormalFloat" },
  FloatTitle = { fg = palette.nord6 },
  FloatFooter = { link = "NormalFloat" },
  Pmenu = { fg = components.menu_fg, bg = components.menu_bg },
  PmenuSbar = { fg = palette.gray6, bg = components.bg_hover },
  PmenuSel = { fg = components.menu_sel_fg, bg = components.menu_sel_bg },
  PmenuThumb = { fg = components.bg_hover, bg = components.bg_hover },
  SpecialKey = { fg = components.text_subtle },
  SpellBad = { fg = components.error, bg = palette.nord00, undercurl = true, sp = components.error },
  SpellCap = { fg = components.warning, bg = palette.nord00, undercurl = true, sp = components.warning },
  SpellLocal = { fg = palette.nord06, bg = palette.nord00, undercurl = true, sp = palette.nord06 },
  SpellRare = { fg = palette.nord07, bg = palette.nord00, undercurl = true, sp = palette.nord07 },
  Visual = { bg = components.bg_visual },
  VisualNOS = { bg = components.bg_visual },

  -- Neovim specific highlights
  healthError = { fg = components.error, bg = palette.nord01 },
  healthSuccess = { fg = components.success, bg = palette.nord01 },
  healthWarning = { fg = components.warning, bg = palette.nord01 },
  TermCursorNC = { bg = palette.nord01 },

  -- Neovim Diagnostics API (for LSP)
  DiagnosticWarn = { fg = components.warning_muted },
  DiagnosticError = { fg = components.error_muted, bg = blend_colors(components.error_muted, components.editor_bg, 0.95) },
  DiagnosticInfo = { fg = colors.blue__700 },
  DiagnosticHint = { fg = colors.blue__700 },
  DiagnosticUnderlineWarn = { fg = components.warning, undercurl = true },
  DiagnosticUnderlineError = { fg = components.error, undercurl = true },
  DiagnosticUnderlineInfo = { fg = components.ui_highlight, undercurl = true },
  DiagnosticUnderlineHint = { fg = components.control_flow_base, undercurl = true },

  -- Neovim DocumentHighlight
  LspReferenceText = { bg = palette.nord03 },
  LspReferenceRead = { bg = palette.nord03 },
  LspReferenceWrite = { bg = palette.nord03 },

  -- Neovim LspSignatureHelp
  LspSignatureActiveParameter = { fg = components.ui_highlight, underline = true },

  -- Gutter
  CursorColumn = { bg = palette.nord01 },
  CursorLine = { bg = palette.gray1 },
  CursorLineNr = { fg = components.warning_base, bg = palette.gray00 },
  CursorLineSign = { bg = palette.gray00 },
  Folded = { fg = components.fold_column, bg = palette.nord01, bold = true },
  FoldColumn = { fg = components.fold_column, bg = palette.nord00 },
  SignColumn = { fg = palette.nord01, bg = components.editor_bg },
  SignColumnSB = { fg = palette.nord01, bg = components.editor_bg },

  -- Navigation
  Directory = { fg = palette.nord9 },
  File = { fg = palette.nord05 },

  -- Prompt/Status
  EndOfBuffer = { fg = palette.nord01 },
  ErrorMsg = { fg = palette.nord05, bg = components.error },
  ModeMsg = { fg = palette.nord05 },
  MoreMsg = { fg = components.ui_highlight },
  Question = { fg = palette.nord05 },

  StatusLine = { fg = palette.nord05, bg = colors.gray__800 },
  StatusLineNC = { fg = palette.nord04, bg = colors.gray__950 },
  StatusLineTerm = { fg = palette.nord05, bg = palette.nord01 },
  StatusLineTermNC = { fg = palette.nord04, bg = palette.nord00 },

  WarningMsg = { fg = palette.nord00, bg = components.warning },
  WildMenu = { fg = components.ui_highlight, bg = palette.nord01 },

  -- Search
  IncSearch = { fg = components.search_match_fg, bg = components.control_flow_base, underline = true },
  Search = { fg = components.search_fg, bg = components.search_bg },

  -- Tabs
  TabLine = { fg = components.tab_fg, bg = components.tab_bg },
  TabLineFill = { fg = components.tab_fg, bg = palette.gray00 },
  TabLineSel = { fg = components.tab_sel_fg, bg = components.tab_sel_bg },

  -- Window
  Title = { fg = palette.nord05 },
  VertSplit = { fg = components.border, bg = components.editor_bg },
  WinSeparator = { link = "VertSplit" },

  -- QuickFix
  -- QuickFixText = { bg = palette.gray00 },
  QuickFixLine = { link = "Search" },
  QuickFixLineNr = { link = "LineNr" },
  QuickFixFilename = { link = "File" },

  -------------------------------------------------------------------
  -- Semantic Tokens ------------------------------------------------
  -------------------------------------------------------------------

  ["@comment"] = { fg = components.comment, italic = true },
  ["@constant"] = { fg = palette.nord4 },
  ["@string"] = { fg = components.string },
  ["@string.regexp"] = { fg = components.warning_base },
  ["@number"] = { fg = components.number },
  ["@keyword"] = { fg = palette.nord9 },
  ["@variable"] = { fg = components.variable },
  ["@variable.builtin"] = { fg = components.variable_builtin },
  ["@variable.member"] = { fg = components.variable },
  ["@property"] = { fg = palette.nord07 },
  ["@operator"] = { fg = components.operator },
  ["@boolean"] = { fg = components.boolean, bold = true },
  ["@function"] = { fg = components.function_name },
  ["@function.builtin"] = { fg = components.function_name },
  ["@function.macro"] = { fg = components.function_name },
  ["@function.call"] = { fg = components.function_name, italic = true },
  ["@type"] = { fg = components.type },
  ["@type.builtin"] = { fg = components.type, bold = true },
  ["@constructor"] = { fg = palette.nord10 },
  ["@decorator"] = { fg = palette.nord12 },
  ["@markup.strong"] = { fg = palette.nord07, bold = true },
  ["@punctuation"] = { fg = palette.nord4 },
  ["@punctuation.bracket"] = { fg = palette.nord10 },
  ["@punctuation.delimiter"] = { fg = palette.nord10 },

  -- LSP
  ["@lsp.type.macro"] = { fg = palette.nord12 },
  ["@lsp.type.keyword"] = { fg = components.number },
  ["@lsp.type.parameter"] = { fg = palette.nord05, italic = true },
  ["@lsp.type.property"] = { link = "@property" },
  ["@lsp.type.function"] = { link = "@function" },
  ["@lsp.type.type"] = { link = "@type" },

  -- JSON
  ["@property.json"] = { fg = components.ui_accent },

  -- Lua
  -- ["@punctuation.bracket.lua"] = { link = "Delimiter" },
  -- ["@constructor.lua"] = { link = "Delimiter" },

  -- Clojure
  ["@lsp.type.event.clojure"] = { link = "@lsp.type.type" },
  ["@punctuation.bracket.clojure"] = { fg = components.comment },
  ["@constructor.clojure"] = { link = "@function" },
  ["@string.special.symbol.clojure"] = { fg = components.number },
  ["@function.macro.clojure"] = { link = "@decorator" },
  ["@kw.clojure"] = { fg = components.constant_base },
  ["@keyword.function.clojure"] = { link = "@decorator" },
  ["@required.clojure"] = { link = "Comment" },

  -- ["@module.clojure"] = { fg = palette.nord05, italic = true },
  ["@deref"] = { fg = components.error },
  ["@deref.name"] = { fg = components.keyword_dim },

  -- Markdown
  ["@markup.list.markdown"] = { fg = palette.nord04 },
  ["@markup.heading.1.markdown"] = { fg = components.ui_accent_bright },
  ["@markup.heading.2.markdown"] = { fg = components.ui_accent },
  ["@markup.heading.3.markdown"] = { fg = components.ui_accent },
  ["@markup.heading.4.markdown"] = { fg = components.ui_accent_dim },
  ["@markup.heading.5.markdown"] = { fg = components.ui_accent_dim },
  ["@markup.heading.6.markdown"] = { fg = components.ui_accent_dim },

  -------------------------------------------------------------------
  -- Language Base Groups -------------------------------------------
  -------------------------------------------------------------------
  -- Tier 1 (Noise / Structure)
  Comment = { link = "@comment" },
  Conceal = { bg = "NONE" },
  Delimiter = { fg = components.comment },
  Operator = { link = "@operator" },
  SpecialChar = { fg = components.warning_base },
  SpecialComment = { fg = components.ui_highlight, italic = true },

  -- Tier 2 (Body / Variables)
  Field = { link = "@property" },
  Identifier = { link = "@variable" },
  Tag = { link = "@type" },
  Variable = { link = "@variable" },

  -- Tier 3 (Data / Literals)
  Boolean = { link = "@boolean" },
  Character = { fg = components.success },
  Constant = { fg = components.constant },
  Float = { link = "Constant" },
  Number = { link = "Constant" },
  String = { fg = components.string },

  -- Tier 4 (Logic / Emphasis)
  -- T4 Group 1: Control Flow (if, for, try)
  Conditional = { fg = components.control_flow_bright, bold = true },
  Exception = { fg = components.control_flow_bright, bold = true },
  Repeat = { fg = components.control_flow_bright, bold = true },
  Statement = { link = "Conditional" },

  -- T4 Group 2: Keywords & Directives (const, import)
  Decorator = { fg = components.keyword_base },
  Define = { fg = components.keyword_base },
  Include = { fg = components.keyword_base },
  Keyword = { fg = components.keyword_base },
  PreProc = { fg = components.keyword_base },
  StorageClass = { fg = components.keyword_base },
  Label = { fg = components.keyword_base },

  -- T4 Group 3: Definitions (function, class)
  Function = { link = "@function" },
  Builtin = { link = "@function.builtin" },

  -- T4 Group 4: Types (Type, struct)
  Structure = { fg = components.type },
  Type = { fg = components.type },
  Typedef = { fg = components.type },
  Namespace = { fg = components.type },

  -- Fallbacks
  Special = { fg = components.special },
  Todo = { fg = components.warning_base, bg = "NONE" },
  Annotation = { link = "Decorator" },
  Macro = { link = "Define" },
  PreCondit = { link = "PreProc" },

  -- Diff highlighting
  DiffAdd = { fg = components.diff_add },
  DiffChange = { fg = components.diff_change },
  DiffDelete = { fg = components.diff_delete },
  DiffText = { fg = components.diff_text },

  -- Legacy diff groups
  diffAdded = { link = "DiffAdd" },
  diffChanged = { link = "DiffChange" },
  diffRemoved = { link = "DiffDelete" },

  -- Git related highlights
  gitcommitDiscardedFile = { fg = components.error },
  gitcommitUntrackedFile = { fg = components.error },
  gitcommitSelectedFile = { fg = components.success },

  -- Plugin support - Only adding a subset for brevity
  -- DiagnosticSign highlights for LSP
  DiagnosticSignError = { fg = components.error, bg = "NONE" },
  DiagnosticSignWarn = { fg = components.warning, bg = "NONE" },
  DiagnosticSignHint = { fg = components.info, bg = "NONE" },
  DiagnosticSignInfo = { fg = components.info, bg = "NONE" },

  -- GitSigns plugin support
  GitSignsAdd = { fg = components.git_add },
  GitSignsChange = { fg = components.git_change },
  GitSignsDelete = { fg = components.git_delete },

  -- Flash
  FlashMatch = { link = "Visual" },
  FlashCurrent = { fg = palette.gray00, bg = components.keyword_base },
  FlashLabel = { fg = palette.gray00, bg = components.warning_dim },
  FlashPrompt = { link = "MsgArea" },
  FlashPromptIcon = { link = "Special" },
  FlashCursor = { link = "Cursor" },

  -- Oil
  OilFile = { fg = palette.nord9 },

  -- Telescope plugin support
  TelescopeBorder = { fg = components.comment, bg = palette.nord00 },
  TelescopePromptBorder = { fg = palette.nord01, bg = palette.nord00 },
  TelescopePromptNormal = { fg = palette.nord05, bg = palette.nord00 },
  TelescopePromptTitle = { fg = palette.nord05, bg = palette.nord01 },
  TelescopeResultsBorder = { fg = palette.nord01, bg = palette.nord00 },
  TelescopeResultsNormal = { fg = palette.nord05, bg = palette.nord00 },
  TelescopeResultsTitle = { fg = palette.nord05, bg = palette.nord01 },
  TelescopePreviewBorder = { fg = palette.nord00, bg = palette.nord00 },
  TelescopePreviewNormal = { fg = palette.nord05, bg = palette.nord00 },
  TelescopePreviewTitle = { fg = palette.nord05, bg = palette.nord00 },
  TelescopeMatching = { fg = palette.nord00, bg = components.warning_bright },
  TelescopeSelection = { fg = palette.nord05, bg = components.comment, italic = false },
  TelescopeSelectionCaret = { fg = components.ui_highlight, bg = components.comment },
  TelescopeMultiSelection = { fg = components.ui_highlight, bg = components.comment },

  -- Tree view
  TreeNormal = { link = "Normal" },
  TreeNormalNC = { link = "Normal" },
  TreeRootName = { fg = palette.gray6, bold = true },
  TreeFileIcon = { fg = components.ui_highlight },
  TreeFileNameOpened = { fg = palette.gray6 },
  TreeSpecialFile = { fg = components.constant_bright },
  TreeGitConflict = { fg = components.error },
  TreeGitModified = { fg = components.control_flow_bright },
  TreeGitDirty = { fg = palette.gray4 },
  TreeGitAdded = { fg = components.success },
  TreeGitNew = { fg = palette.gray4 },
  TreeGitDeleted = { fg = palette.gray4 },
  TreeGitStaged = { fg = palette.gray4 },
  TreeGitUntracked = { fg = components.keyword_base },
  TreeTitleBar = { link = 'WinBar' },
  TreeFloatBorder = { link = 'FloatBorder' },
  TreeCursorLine = { bg = palette.gray2 },
  TreeCursor = { bg = "NONE", fg = "NONE" },
  TreeFolderIcon = { fg = components.warning_dim },
  TreeIndentMarker = { fg = components.indent_guide },
  TreeSymlink = { fg = components.ui_highlight },
  TreeFolderName = { fg = components.control_flow_bright },
  TreeWinSeparator = { link = 'WinSeparator' },

  MiniStatuslineModeNormal = { fg = components.editor_bg, bg = colors.gray__500 },
  MiniStatuslineModeInsert = { fg = components.editor_bg, bg = components.mode_insert },
  MiniStatuslineModeVisual = { fg = components.editor_bg, bg = components.mode_visual },
  MiniStatuslineModeReplace = { fg = components.editor_bg, bg = components.mode_replace },
  MiniStatuslineModeCommand = { fg = components.editor_bg, bg = components.mode_command },
  MiniStatuslineModeOther = { fg = components.editor_bg, bg = components.mode_other },
  MiniStatuslineDevinfo = { fg = colors.gray__500, bg = colors.gray__800 },
  MiniStatuslineFilename = { bg = colors.gray__600 },
  MiniStatuslineFileinfo = { bg = colors.gray__900 },
  MiniStatuslineInactive = { fg = components.text_subtle, bg = components.border },

  fugitiveHash = { fg = components.warning_base },
}

for group, opts in pairs(highlights) do
  vim.api.nvim_set_hl(0, group, opts)
end

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

vim.g.colors_name = "nord"
