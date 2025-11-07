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
  popup_bg = palette.gray01,
  border = palette.gray00
}

local highlights = {
  -- Attributes
  Bold = { bold = true },
  Italic = { italic = true },
  Underline = { underline = true },

  -- Editor
  ColorColumn = { bg = palette.gray02 },
  Cursor = { fg = palette.gray000, bg = palette.nord05 },
  Error = { fg = palette.nord05, bg = palette.red },
  iCursor = { fg = palette.gray000, bg = palette.nord05 },
  LineNr = { fg = palette.nord03 },
  MatchParen = { fg = palette.sky, bg = palette.nord03 },
  NonText = { fg = palette.nord02 },
  Normal = { fg = palette.gray6, bg = palette.gray0 },
  NormalNC = { fg = palette.gray6, bg = palette.gray0 },
  NormalSB = { fg = palette.gray6, bg = palette.gray0 },
  NormalFloat = { fg = palette.gray6, bg = palette.gray01 },
  Pmenu = { fg = palette.gray6, bg = palette.gray00 },
  PmenuSbar = { fg = palette.gray6, bg = palette.gray02 },
  PmenuSel = { fg = palette.cyan, bg = palette.nord03 },
  PmenuThumb = { fg = palette.gray02, bg = palette.gray02 },
  SpecialKey = { fg = palette.nord03 },
  SpellBad = { fg = palette.red, bg = palette.nord00, undercurl = true, sp = palette.red },
  SpellCap = { fg = palette.yellow, bg = palette.nord00, undercurl = true, sp = palette.yellow },
  SpellLocal = { fg = palette.nord06, bg = palette.nord00, undercurl = true, sp = palette.nord06 },
  SpellRare = { fg = palette.nord07, bg = palette.nord00, undercurl = true, sp = palette.nord07 },
  Visual = { bg = palette.nord02 },
  VisualNOS = { bg = palette.nord02 },

  -- Neovim specific highlights
  healthError = { fg = palette.red, bg = palette.nord01 },
  healthSuccess = { fg = palette.green, bg = palette.nord01 },
  healthWarning = { fg = palette.yellow, bg = palette.nord01 },
  TermCursorNC = { bg = palette.nord01 },

  -- Neovim Diagnostics API (for LSP)
  DiagnosticWarn = { fg = palette.yellow_muted },
  DiagnosticError = { fg = palette.red_muted, bg = blend_colors(palette.red_muted, palette.gray0, 0.95) },
  DiagnosticInfo = { fg = palette.blue_muted },
  DiagnosticHint = { fg = palette.blue },
  DiagnosticUnderlineWarn = { fg = palette.yellow, undercurl = true },
  DiagnosticUnderlineError = { fg = palette.red, undercurl = true },
  DiagnosticUnderlineInfo = { fg = palette.sky, undercurl = true },
  DiagnosticUnderlineHint = { fg = palette.blue, undercurl = true },

  -- Neovim DocumentHighlight
  LspReferenceText = { bg = palette.nord03 },
  LspReferenceRead = { bg = palette.nord03 },
  LspReferenceWrite = { bg = palette.nord03 },

  -- Neovim LspSignatureHelp
  LspSignatureActiveParameter = { fg = palette.sky, underline = true },

  -- Gutter
  CursorColumn = { bg = palette.nord01 },
  CursorLine = { bg = palette.gray1 },
  CursorLineNr = { fg = palette.yellow, bg = palette.gray00 },
  CursorLineSign = { bg = palette.gray00 },
  Folded = { fg = palette.nord03, bg = palette.nord01, bold = true },
  FoldColumn = { fg = palette.nord03, bg = palette.nord00 },
  SignColumn = { fg = palette.nord01, bg = components.editor_bg },
  SignColumnSB = { fg = palette.nord01, bg = components.editor_bg },

  -- Navigation
  Directory = { fg = palette.blue },
  File = { fg = palette.nord05 },

  -- Prompt/Status
  EndOfBuffer = { fg = palette.nord01 },
  ErrorMsg = { fg = palette.nord05, bg = palette.red },
  ModeMsg = { fg = palette.nord05 },
  MoreMsg = { fg = palette.sky },
  Question = { fg = palette.nord05 },

  StatusLine = { fg = palette.nord05, bg = palette.nord01 },
  StatusLineNC = { fg = palette.nord04, bg = palette.nord00 },
  StatusLineTerm = { fg = palette.nord05, bg = palette.nord01 },
  StatusLineTermNC = { fg = palette.nord04, bg = palette.nord00 },

  WarningMsg = { fg = palette.nord00, bg = palette.yellow },
  WildMenu = { fg = palette.sky, bg = palette.nord01 },

  -- Search
  IncSearch = { fg = palette.nord07, bg = palette.blue, underline = true },
  Search = { fg = palette.nord01, bg = palette.sky },

  -- Tabs
  TabLine = { fg = palette.nord05, bg = palette.gray01 },
  TabLineFill = { fg = palette.nord05, bg = palette.gray00 },
  TabLineSel = { fg = palette.gray6, bg = components.editor_bg },

  -- Window
  Title = { fg = palette.nord05 },
  VertSplit = { fg = palette.gray00, bg = components.editor_bg },
  WinSeparator = { link = "VertSplit" },

  -- QuickFix
  -- QuickFixText = { bg = palette.gray00 },
  QuickFixLineNr = { link = "LineNr" },
  QuickFixFilename = { link = "File" },

  -------------------------------------------------------------------
  -- Language Base Groups -------------------------------------------
  -------------------------------------------------------------------
  -- Tier 1 (Noise / Structure)
  Comment = { fg = palette.nord04, italic = true },
  Conceal = { bg = "NONE" },
  Delimiter = { fg = palette.nord04 },
  Operator = { fg = palette.nord04 },
  SpecialChar = { fg = palette.yellow },
  SpecialComment = { fg = palette.sky, italic = true },

  -- Tier 2 (Body / Variables)
  Field = { fg = palette.cyan },
  Identifier = { fg = palette.nord05 },
  Tag = { fg = palette.nord05 },
  Variable = { link = "Identifier" },

  -- Tier 3 (Data / Literals)
  Boolean = { fg = palette.orange_dim },
  Character = { fg = palette.green },
  Constant = { fg = palette.magenta_bright },
  Float = { link = "Constant" },
  Number = { link = "Constant" },
  String = { fg = palette.green },

  -- Tier 4 (Logic / Emphasis)
  -- T4 Group 1: Control Flow (if, for, try)
  Conditional = { fg = palette.blue_bright, bold = true },
  Exception = { fg = palette.blue_bright, bold = true },
  Repeat = { fg = palette.blue_bright, bold = true },
  Statement = { link = "Conditional" },

  -- T4 Group 2: Keywords & Directives (const, import)
  Decorator = { fg = palette.orange },
  Define = { fg = palette.orange },
  Include = { fg = palette.orange },
  Keyword = { fg = palette.orange },
  PreProc = { fg = palette.orange },
  StorageClass = { fg = palette.orange },
  Label = { fg = palette.orange },

  -- T4 Group 3: Definitions (function, class)
  Function = { fg = palette.sky, bold = true },
  Builtin = { fg = palette.blue },

  -- T4 Group 4: Types (Type, struct)
  Structure = { fg = palette.yellow_dim },
  Type = { fg = palette.yellow_dim },
  Typedef = { fg = palette.yellow_dim },
  Namespace = { fg = palette.yellow_dim },

  -- Fallbacks
  Special = { fg = palette.cyan_bright },
  Todo = { fg = palette.yellow, bg = "NONE" },
  Annotation = { link = "Decorator" },
  Macro = { link = "Define" },
  PreCondit = { link = "PreProc" },

  -- Diff highlighting
  DiffAdd = { fg = blend_colors(palette.green, palette.gray10, 0.25), bg = blend_colors(palette.green, palette.gray0, 0.95) },
  DiffChange = { fg = blend_colors(palette.yellow, palette.gray10, 0.25), bg = blend_colors(palette.yellow, palette.gray0, 0.95) },
  DiffDelete = { fg = blend_colors(palette.orange, palette.gray10, 0.25), bg = blend_colors(palette.orange, palette.gray0, 0.95) },
  DiffText = { fg = palette.blue_bright, bg = palette.gray0 },

  -- Legacy diff groups
  diffAdded = { link = "DiffAdd" },
  diffChanged = { link = "DiffChange" },
  diffRemoved = { link = "DiffDelete" },

  -- Git related highlights
  gitcommitDiscardedFile = { fg = palette.red },
  gitcommitUntrackedFile = { fg = palette.red },
  gitcommitSelectedFile = { fg = palette.green },

  -- Plugin support - Only adding a subset for brevity
  -- DiagnosticSign highlights for LSP
  DiagnosticSignError = { fg = palette.red_muted, bg = "NONE" },
  DiagnosticSignWarn = { fg = palette.yellow_muted, bg = "NONE" },
  DiagnosticSignHint = { fg = palette.sky, bg = "NONE" },
  DiagnosticSignInfo = { fg = palette.blue_bright, bg = "NONE" },

  -- GitSigns plugin support
  GitSignsAdd = { fg = palette.green },
  GitSignsChange = { fg = palette.orange },
  GitSignsDelete = { fg = palette.red },

  -- Flash
  FlashMatch = { link = "Visual" },
  FlashCurrent = { fg = palette.gray00, bg = palette.orange },
  FlashLabel = { fg = palette.gray00, bg = palette.yellow_dim },
  FlashPrompt = { link = "MsgArea" },
  FlashPromptIcon = { link = "Special" },
  FlashCursor = { link = "Cursor" },

  -- Oil
  OilFile = { fg = palette.nord06 },

  -- Nvim-Treesitter
  TSAnnotation = { link = "Annotation" },
  TSConstBuiltin = { link = "Constant" },
  TSConstructor = { link = "Function" },
  TSEmphasis = { link = "Italic" },
  TSFuncBuiltin = { link = "Function" },
  TSFuncMacro = { link = "Function" },
  TSStringRegex = { link = "SpecialChar" },
  TSStrong = { link = "Bold" },
  TSStructure = { link = "Structure" },
  TSTagDelimiter = { link = "TSTag" },
  TSUnderline = { link = "Underline" },
  TSVariable = { link = "Variable" },
  TSVariableBuiltin = { link = "Keyword" },

  -- Telescope plugin support
  TelescopeBorder = { fg = palette.nord03, bg = palette.nord00 },
  TelescopePromptBorder = { fg = palette.nord01, bg = palette.nord00 },
  TelescopePromptNormal = { fg = palette.nord05, bg = palette.nord00 },
  TelescopePromptTitle = { fg = palette.nord05, bg = palette.nord01 },
  TelescopeResultsBorder = { fg = palette.nord01, bg = palette.nord00 },
  TelescopeResultsNormal = { fg = palette.nord05, bg = palette.nord00 },
  TelescopeResultsTitle = { fg = palette.nord05, bg = palette.nord01 },
  TelescopePreviewBorder = { fg = palette.nord00, bg = palette.nord00 },
  TelescopePreviewNormal = { fg = palette.nord05, bg = palette.nord00 },
  TelescopePreviewTitle = { fg = palette.nord05, bg = palette.nord00 },
  TelescopeMatching = { fg = palette.nord00, bg = palette.yellow_bright },
  TelescopeSelection = { fg = palette.nord05, bg = palette.nord03, italic = false },
  TelescopeSelectionCaret = { fg = palette.sky, bg = palette.nord03 },
  TelescopeMultiSelection = { fg = palette.sky, bg = palette.nord03 },

  -- Tree view
  TreeNormal = { link = "Normal" },
  TreeNormalNC = { link = "Normal" },
  TreeRootName = { fg = palette.gray6, bold = true },
  TreeFileIcon = { fg = palette.sky },
  TreeFileNameOpened = { fg = palette.gray6 },
  TreeSpecialFile = { fg = palette.magenta_bright },
  TreeGitConflict = { fg = palette.red },
  TreeGitModified = { fg = palette.blue_bright },
  TreeGitDirty = { fg = palette.gray4 },
  TreeGitAdded = { fg = palette.green },
  TreeGitNew = { fg = palette.gray4 },
  TreeGitDeleted = { fg = palette.gray4 },
  TreeGitStaged = { fg = palette.gray4 },
  TreeGitUntracked = { fg = palette.orange_base },
  TreeTitleBar = { link = 'WinBar' },
  TreeFloatBorder = { link = 'FloatBorder' },
  TreeCursorLine = { bg = palette.gray2 },
  TreeCursor = { bg = "NONE", fg = "NONE" },
  TreeFolderIcon = { fg = palette.yellow_dim },
  TreeIndentMarker = { fg = palette.gray4 },
  TreeSymlink = { fg = palette.sky },
  TreeFolderName = { fg = palette.blue_bright },
  TreeWinSeparator = { link = 'WinSeparator' },

  -------------------------------------------------------------------
  -- Custom for languages -------------------------------------------
  -------------------------------------------------------------------

  ["@variable"] = { link = "Variable" },
  ["@constructor"] = { link = "Function" },
  ["@markup.strong"] = { fg = palette.nord07, bold = true },
  ["@keyword_symbol.single"] = { link = "SpecialChar" },
  ["@keyword_symbol.namespace"] = { fg = palette.magenta_dim, italic = true },
  ["@keyword_symbol.name"] = { fg = palette.magenta_bright, italic = true },
  ["@keyword_symbol"] = { link = "Type" },
  ["@qualified_symbol.namespace"] = { fg = palette.blue },
  ["@qualified_symbol.name"] = { link = "Function" },
  ["@qualified_symbol"] = { link = "Function" },

  -- JSON
  ["@property.json"] = { fg = palette.cyan },

  -- Lua
  ["@punctuation.bracket.lua"] = { link = "Delimiter" },
  ["@constructor.lua"] = { link = "Delimiter" },

  -- Clojure
  ["@punctuation.bracket.clojure"] = { fg = palette.nord03 },
  ["@constructor.clojure"] = { link = "Function" },
  ["@function.macro.clojure"] = { link = "Keyword" },
  ["@kw.clojure"] = { fg = palette.magenta },
  ["@keyword.function.clojure"] = { link = "Keyword" },
  ["@required.clojure"] = { link = "Comment" },
  -- ["@module.clojure"] = { fg = palette.nord05, italic = true },
  ["@deref"] = { fg = palette.red },
  ["@deref.name"] = { fg = palette.orange_dim },

  -- Markdown
  ["@markup.list.markdown"] = { fg = palette.nord04 },
  ["@markup.heading.1.markdown"] = { fg = palette.cyan_bright },
  ["@markup.heading.2.markdown"] = { fg = palette.cyan },
  ["@markup.heading.3.markdown"] = { fg = palette.cyan },
  ["@markup.heading.4.markdown"] = { fg = palette.cyan_dim },
  ["@markup.heading.5.markdown"] = { fg = palette.cyan_dim },
  ["@markup.heading.6.markdown"] = { fg = palette.cyan_dim },
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
