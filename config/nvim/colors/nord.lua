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

  -- The origin color or the Polar Night palette.
  -- For dark ambiance designs, it is used for background and area coloring while it's not used for syntax highlighting at all because otherwise it would collide with the same background color.
  --
  -- For bright ambiance designs, it is used for base elements like plain text, the text editor caret and reserved syntax characters like curly- and square brackets.
  -- It is rarely used for passive UI elements like borders, but might be possible to achieve a higher contrast and better visual distinction (harder/not flat) between larger components.
  nord0  = "#2e3440",

  -- A brighter shade color based on nord0.
  --
  -- For dark ambiance designs it is used for elevated, more prominent or focused UI elements like
  --
  -- status bars and text editor gutters
  -- panels, modals and floating popups like notifications or auto completion
  -- user interaction/form components like buttons, text/select fields or checkboxes
  -- It also works fine for more inconspicuous and passive elements like borders or as dropshadow between different components.
  -- There's currently no official port project that makes use of it for syntax highlighting.
  --
  -- For bright ambiance designs, it is used for more subtle/inconspicuous UI text elements that do not need so much visual attention.
  -- Other use cases are also state animations like a more brighter text color when a button is hovered, active or focused.
  nord1  = "#3b4252",

  -- An even more brighter shade color of nord0.
  --
  -- For dark ambiance designs, it is used to colorize the currently active text editor line as well as selection- and text highlighting color.
  -- For both bright & dark ambiance designs it can also be used as an brighter variant for the same target elements like nord1.
  nord2  = "#434c5e",

  -- The brightest shade color based on nord0.
  --
  -- For dark ambiance designs, it is used for UI elements like indent- and wrap guide marker.
  -- In the context of code syntax highlighting it is used for comments and invisible/non-printable characters.
  --
  -- For bright ambiance designs, it is, next to nord1 and nord2 as darker variants, also used for the most subtle/inconspicuous UI text elements that do not need so much visual attention.
  nord3  = "#4c566a",

  -- The origin color or the Snow Storm palette.
  --
  -- For dark ambiance designs, it is used for UI elements like the text editor caret.
  -- In the context of syntax highlighting it is used as text color for variables, constants, attributes and fields.
  --
  -- For bright ambiance designs, it is used for elevated, more prominent or focused UI elements like
  --
  -- status bars and text editor gutters
  -- panels, modals and floating popups like notifications or auto completion
  -- user interaction/form components like buttons, text/select fields or checkboxes
  -- It also works fine for more inconspicuous and passive elements like borders or as dropshadow between different components.
  -- In the context of syntax highlighting it's not used at all.
  nord4  = "#d8dee9",

  -- A brighter shade color of nord4.
  --
  -- For dark ambiance designs, it is used for more subtle/inconspicuous UI text elements that do not need so much visual attention.
  -- Other use cases are also state animations like a more brighter text color when a button is hovered, active or focused.
  -- For bright ambiance designs, it is used to colorize the currently active text editor line as well as selection- and text highlighting color.
  nord5  = "#e5e9f0",

  -- The brightest shade color based on nord4.
  --
  -- For dark ambiance designs, it is used for elevated UI text elements that require more visual attention.
  -- In the context of syntax highlighting it is used as text color for plain text as well as reserved and structuring syntax characters like curly- and square brackets.
  --
  -- For bright ambiance designs, it is used as background and area coloring while it's not used for syntax highlighting at all because otherwise it would collide with the same background color.
  nord6  = "#eceff4",

  -- A calm and highly contrasted color reminiscent of frozen polar water.
  -- Used for UI elements that should, next to the primary accent color nord8, stand out and get more visual attention.
  -- In the context of syntax highlighting it is used for classes, types and primitives.
  nord7  = "#8fbcbb",
  -- The bright and shiny primary accent color reminiscent of pure and clear ice.
  -- Used for primary UI elements with main usage purposes that require the most visual attention.
  -- In the context of syntax highlighting it is used for declarations, calls and execution statements of functions, methods and routines.
  nord8  = "#88c0d0",

  -- A more darkened and less saturated color reminiscent of arctic waters.
  -- Used for secondary UI elements that also require more visual attention than other elements.
  -- In the context of syntax highlighting it is used for language specific, syntactic and reserved keywords as well as
  nord9  = "#81a1c1",

  -- A dark and intensive color reminiscent of the deep arctic ocean.
  -- Used for tertiary UI elements that require more visual attention than default elements.
  -- In the context of syntax highlighting it is used for pragmas, comment keywords and pre-processor statements.
  nord10 = "#5e81ac",

  -- Used for UI elements that are rendering error states like linter markers and the highlighting of Git diff deletions.
  -- In the context of syntax highlighting it is used to override the highlighting of syntax elements that are detected as errors.
  nord11 = "#bf616a",

  -- Rarely used for UI elements, but it may indicate a more advanced or dangerous functionality.
  -- In the context of syntax highlighting it is used for special syntax elements like annotations and decorators.
  nord12 = "#d08770",

  -- Used for UI elements that are rendering warning states like linter markers and the highlighting of Git diff modifications.
  -- In the context of syntax highlighting it is used to override the highlighting of syntax elements that are detected as warnings as well as escape characters and within regular expressions.
  nord13 = "#ebcb8b",

  -- Used for UI elements that are rendering success states and visualizations and the highlighting of Git diff additions.
  -- In the context of syntax highlighting it is used as main color for strings of any type like double/single quoted or interpolated.
  nord14 = "#a3be8c",

  -- Rarely used for UI elements, but it may indicate a more uncommon functionality.
  -- In the context of syntax highlighting it is used as main color for numbers of any type like integers and floating point numbers.
  nord15 = "#b48ead",

  cream1 = '#D9D3C4',
  cream2 = '#E5DECD',
  cream3 = '#EDE8DC',
  cream4 = '#F6F3ED',
  cream5 = '#F0EFEA',


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
  MatchParen = { fg = palette.nord9 },
  NonText = { fg = palette.nord02 },
  Normal = { fg = palette.cream3, bg = palette.gray0 },
  NormalNC = { fg = palette.cream3, bg = palette.gray0 },
  NormalSB = { fg = palette.cream3, bg = palette.gray0 },
  NormalFloat = { fg = palette.cream3, bg = palette.gray01 },
  FloatBorder = { link = "NormalFloat" },
  FloatTitle = { fg = palette.nord6 },
  FloatFooter = { link = "NormalFloat" },
  Pmenu = { fg = palette.nord4, bg = palette.nord1 },
  PmenuSbar = { fg = palette.gray6, bg = palette.gray02 },
  PmenuSel = { fg = palette.nord0, bg = palette.nord13 },
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
  Directory = { fg = palette.nord9 },
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
  QuickFixLine = { link = "Search" },
  QuickFixLineNr = { link = "LineNr" },
  QuickFixFilename = { link = "File" },

  -------------------------------------------------------------------
  -- Semantic Tokens ------------------------------------------------
  -------------------------------------------------------------------

  ["@comment"] = { fg = palette.nord3, italic = true },
  ["@constant"] = { fg = palette.nord4 },
  ["@string"] = { fg = palette.nord14 },
  ["@string.regexp"] = { fg = palette.nord13 },
  ["@number"] = { fg = palette.nord15 },
  ["@keyword"] = { fg = palette.nord9 },
  ["@variable"] = { fg = palette.cream3 },
  ["@variable.builtin"] = { fg = palette.cream2 },
  ["@property"] = { fg = palette.nord07 },
  ["@operator"] = { fg = palette.nord10 },
  ["@boolean"] = { fg = palette.orange_dim, bold = true },
  ["@function"] = { fg = palette.nord8 },
  ["@function.builtin"] = { fg = palette.nord8 },
  ["@function.macro"] = { fg = palette.nord8 },
  ["@function.call"] = { fg = palette.nord8, italic = true },
  ["@type"] = { fg = palette.nord7 },
  ["@type.builtin"] = { fg = palette.nord7, bold = true },
  ["@constructor"] = { fg = palette.nord10 },
  ["@decorator"] = { fg = palette.nord12 },
  ["@markup.strong"] = { fg = palette.nord07, bold = true },
  ["@punctuation"] = { fg = palette.nord4 },
  ["@punctuation.bracket"] = { fg = palette.nord10 },
  ["@punctuation.delimiter"] = { fg = palette.nord10 },

  -- LSP
  ["@lsp.type.macro"] = { fg = palette.nord12 },
  ["@lsp.type.keyword"] = { fg = palette.nord15 },
  ["@lsp.type.parameter"] = { fg = palette.nord05, italic = true },
  ["@lsp.type.property"] = { link = "@property" },
  ["@lsp.type.function"] = { link = "@function" },
  ["@lsp.type.type"] = { link = "@type" },

  -- JSON
  ["@property.json"] = { fg = palette.cyan },

  -- Lua
  -- ["@punctuation.bracket.lua"] = { link = "Delimiter" },
  -- ["@constructor.lua"] = { link = "Delimiter" },

  -- Clojure
  ["@lsp.type.event.clojure"] = { link = "@lsp.type.type" },
  ["@punctuation.bracket.clojure"] = { fg = palette.nord3 },
  ["@constructor.clojure"] = { link = "@function" },
  ["@string.special.symbol.clojure"] = { fg = palette.nord15 },
  ["@function.macro.clojure"] = { link = "@decorator" },
  ["@kw.clojure"] = { fg = palette.magenta },
  ["@keyword.function.clojure"] = { link = "@decorator" },
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

  -------------------------------------------------------------------
  -- Language Base Groups -------------------------------------------
  -------------------------------------------------------------------
  -- Tier 1 (Noise / Structure)
  Comment = { link = "@comment" },
  Conceal = { bg = "NONE" },
  Delimiter = { fg = palette.nord03 },
  Operator = { link = "@operator" },
  SpecialChar = { fg = palette.yellow },
  SpecialComment = { fg = palette.sky, italic = true },

  -- Tier 2 (Body / Variables)
  Field = { link = "@property" },
  Identifier = { link = "@variable" },
  Tag = { link = "@type" },
  Variable = { link = "@variable" },

  -- Tier 3 (Data / Literals)
  Boolean = { link = "@boolean" },
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
  Function = { link = "@function" },
  Builtin = { link = "@function.builtin" },

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
  DiffAdd = { fg = palette.nord14 },
  DiffChange = { fg = palette.nord12 },
  DiffDelete = { fg = palette.nord11 },
  DiffText = { fg = palette.nord9 },

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
  DiagnosticSignError = { fg = palette.nord11, bg = "NONE" },
  DiagnosticSignWarn = { fg = palette.nord13, bg = "NONE" },
  DiagnosticSignHint = { fg = palette.nord10, bg = "NONE" },
  DiagnosticSignInfo = { fg = palette.nord10, bg = "NONE" },

  -- GitSigns plugin support
  GitSignsAdd = { fg = palette.nord14 },
  GitSignsChange = { fg = palette.nord12 },
  GitSignsDelete = { fg = palette.nord11 },

  -- Flash
  FlashMatch = { link = "Visual" },
  FlashCurrent = { fg = palette.gray00, bg = palette.orange },
  FlashLabel = { fg = palette.gray00, bg = palette.yellow_dim },
  FlashPrompt = { link = "MsgArea" },
  FlashPromptIcon = { link = "Special" },
  FlashCursor = { link = "Cursor" },

  -- Oil
  OilFile = { fg = palette.nord9 },

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

  fugitiveHash = { fg = palette.nord13 },
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
