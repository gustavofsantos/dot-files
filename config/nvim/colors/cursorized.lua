-- cursorized — warm paper, near-black ink, eight vivid accents.
--
-- Rules the palette is solved against (see the Cursorized canvas for the numbers):
--   * Ink first. Code is mostly fg; color marks meaning, not every identifier.
--   * One lightness per variant. The eight accents share OKLab lightness, so they carry
--     equal weight: WCAG >= 4.6 on bg_hl in light, APCA Lc >= 55 on bg_hl in dark.
--   * Hues spaced for distance. Hues stay inside their names' ranges and are spread to
--     maximize the smallest OKLab distance between any two accents.
--   * A five-step ink ramp: border < fg_faint (3:1) < fg_comment (4.8:1 light, 5.4:1 dark,
--     on bg_hl) < fg < fg_emph. All grays share one warm hue (OKLCH h 95).
--   * The cursor is Cursor orange, #f54e00, the one color outside these rules.
--   * Every terminal slot is readable text on its background. Brights are the accents
--     pushed 0.07 OKLab L toward more contrast.
--
-- `:colorscheme cursorized` picks the variant from 'background'. Neovim re-sources the
-- active colorscheme when 'background' changes, so there is no autocmd here.
-- Options live in `vim.g.cursorized` and are re-read on every load:
--
--   vim.g.cursorized = {
--     transparent     = false,  -- bg = NONE on Normal, SignColumn, NormalFloat, ...
--     italic_comments = true,
--     blend           = "oklab", -- or "srgb" (cheap fallback for debugging)
--     alpha = { light = { diff_add = 0.10 }, dark = {} }, -- partial overrides
--     on_highlights = function(hl, c) end,                -- edit `hl` in place
--   }
--
-- Requires 'termguicolors'; there is no cterm fallback.

-- 1. palette -----------------------------------------------------------------------

local palette = {
  light = {
    bg = "#f7f7f4", bg_hl = "#eeede7", border = "#dbd9d2",
    fg_faint = "#8a8882", fg_comment = "#696761", fg = "#31302d", fg_emph = "#161614",
    red = "#ba3e4b", orange = "#aa5100", yellow = "#846600", green = "#007b2f",
    cyan = "#007677", blue = "#006cbc", violet = "#7856c0", magenta = "#a9438d",
    ansi = {
      "#161614", "#ba3e4b", "#007b2f", "#846600", "#006cbc", "#a9438d", "#007677", "#31302d",
      "#696761", "#a22638", "#006425", "#6c5300", "#00589b", "#922d78", "#006061", "#8a8882",
    },
  },
  dark = {
    bg = "#1a1918", bg_hl = "#272623", border = "#393833",
    fg_faint = "#716f68", fg_comment = "#9d9b92", fg = "#d2cfc5", fg_emph = "#faf8f4",
    red = "#ff8b90", orange = "#f69557", yellow = "#d3a82d", green = "#64c175",
    cyan = "#00c0c0", blue = "#64b2ff", violet = "#b89fff", magenta = "#ed8ecf",
    ansi = {
      "#716f68", "#ff8b90", "#64c175", "#d3a82d", "#64b2ff", "#ed8ecf", "#00c0c0", "#d2cfc5",
      "#9d9b92", "#ffb1b2", "#7bd88a", "#eabe4a", "#93c8ff", "#ffa9e3", "#3ad7d7", "#faf8f4",
    },
  },
}

-- The cursor is always Cursor orange, the one color not held to the accent lightness.
local signature = "#f54e00"

-- 2. color -------------------------------------------------------------------------

local M = { space = "oklab" }

local function hex_to_rgb(hex)
  return tonumber(hex:sub(2, 3), 16) / 255, tonumber(hex:sub(4, 5), 16) / 255, tonumber(hex:sub(6, 7), 16) / 255
end

local function rgb_to_hex(r, g, b)
  local function byte(c) return math.floor(math.min(1, math.max(0, c)) * 255 + 0.5) end
  return string.format("#%02x%02x%02x", byte(r), byte(g), byte(b))
end

local function to_linear(c) return c <= 0.04045 and c / 12.92 or ((c + 0.055) / 1.055) ^ 2.4 end
local function to_srgb(c)
  c = math.min(1, math.max(0, c))
  return c <= 0.0031308 and 12.92 * c or 1.055 * c ^ (1 / 2.4) - 0.055
end
local function cbrt(x) return x >= 0 and x ^ (1 / 3) or -((-x) ^ (1 / 3)) end

function M.to_oklab(hex)
  local r, g, b = hex_to_rgb(hex)
  r, g, b = to_linear(r), to_linear(g), to_linear(b)
  local l = cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b)
  local m = cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b)
  local s = cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b)
  return 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
         1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
         0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s
end

function M.from_oklab(L, a, b)
  local l = (L + 0.3963377774 * a + 0.2158037573 * b) ^ 3
  local m = (L - 0.1055613458 * a - 0.0638541728 * b) ^ 3
  local s = (L - 0.0894841775 * a - 1.2914855480 * b) ^ 3
  local r = 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s
  local g = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s
  local bl = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s
  return rgb_to_hex(to_srgb(r), to_srgb(g), to_srgb(bl))
end

--- Mix `fg` over `bg`; alpha 0 = bg, 1 = fg. Mixes in OKLab unless M.space is "srgb".
function M.blend(fg, bg, alpha)
  local t = alpha
  if M.space == "srgb" then
    local r1, g1, b1 = hex_to_rgb(fg)
    local r2, g2, b2 = hex_to_rgb(bg)
    return rgb_to_hex(r1 * t + r2 * (1 - t), g1 * t + g2 * (1 - t), b1 * t + b2 * (1 - t))
  end
  local L1, a1, b1 = M.to_oklab(fg)
  local L2, a2, b2 = M.to_oklab(bg)
  return M.from_oklab(L1 * t + L2 * (1 - t), a1 * t + a2 * (1 - t), b1 * t + b2 * (1 - t))
end

--- Shift perceived lightness only (OKLab L), hue and chroma kept. delta in [-1, 1].
function M.shade(hex, delta)
  local L, a, b = M.to_oklab(hex)
  return M.from_oklab(math.min(1, math.max(0, L + delta)), a, b)
end

local function luminance(hex)
  local r, g, b = hex_to_rgb(hex)
  return 0.2126 * to_linear(r) + 0.7152 * to_linear(g) + 0.0722 * to_linear(b)
end

--- WCAG contrast ratio, 1..21.
function M.contrast(x, y)
  local a, b = luminance(x), luminance(y)
  if a < b then a, b = b, a end
  return (a + 0.05) / (b + 0.05)
end

--- Walk `fg` toward `target` (usually fg_emph) until it reaches `min` contrast on `bg`.
--- If even `target` falls short, keep walking `target`'s lightness away from `bg`, so the
--- guard holds whatever alpha the user tunes.
function M.ensure_contrast(fg, bg, target, min)
  min = min or 4.5
  for i = 0, 10 do
    local c = M.blend(target, fg, i / 10)
    if M.contrast(c, bg) >= min then return c end
  end
  local away = luminance(bg) > 0.18 and -0.02 or 0.02
  local c = target
  for _ = 1, 50 do
    if M.contrast(c, bg) >= min then break end
    c = M.shade(c, away)
  end
  return c
end

-- 3. options -----------------------------------------------------------------------

local defaults = {
  transparent = false,
  italic_comments = true,
  blend = "oklab",
  -- Light backgrounds show tint sooner, so they get lower alphas than dark ones.
  alpha = {
    light = {
      diff_add = 0.14, diff_delete = 0.14, diff_change = 0.14, diff_text = 0.30,
      visual = 0.16, virtual_text = 0.10,
    },
    dark = {
      diff_add = 0.20, diff_delete = 0.20, diff_change = 0.20, diff_text = 0.40,
      visual = 0.25, virtual_text = 0.14,
    },
  },
  on_highlights = nil,
}

local user = vim.g.cursorized
local opts = vim.tbl_deep_extend("force", defaults, type(user) == "table" and user or {})
M.space = opts.blend == "srgb" and "srgb" or "oklab"

-- 4. roles -------------------------------------------------------------------------

local variant = vim.o.background == "light" and "light" or "dark"
local p = palette[variant]

-- `c` is everything the groups see: the variant's grays and accents, derived tokens.
local c = vim.tbl_extend("force", {}, p)
c.ansi = nil
c.signature = signature
local alpha = opts.alpha[variant]

-- Derived tokens. Only palette values are blended, never one result into another.
local function over_bg(color, a) return M.blend(color, c.bg, a) end

c.diff_add_bg = over_bg(p.green, alpha.diff_add)
c.diff_delete_bg = over_bg(p.red, alpha.diff_delete)
c.diff_change_bg = over_bg(p.blue, alpha.diff_change)
c.diff_text_bg = over_bg(p.blue, alpha.diff_text)
c.visual_bg = over_bg(p.blue, alpha.visual)
c.vt_error_bg = over_bg(p.red, alpha.virtual_text)
c.vt_warn_bg = over_bg(p.yellow, alpha.virtual_text)
c.vt_info_bg = over_bg(p.blue, alpha.virtual_text)
c.vt_hint_bg = over_bg(p.cyan, alpha.virtual_text)
c.vt_ok_bg = over_bg(p.green, alpha.virtual_text)

-- Contrast guard: tints lower fg contrast, so text on them walks toward fg_emph.
local function readable(fg, tint) return M.ensure_contrast(fg, tint, c.fg_emph, 4.5) end

c.diff_add_fg = readable(c.fg, c.diff_add_bg)
c.diff_delete_fg = readable(c.fg, c.diff_delete_bg)
c.diff_change_fg = readable(c.fg, c.diff_change_bg)
c.diff_text_fg = readable(c.fg, c.diff_text_bg)
c.visual_fg = readable(c.fg, c.visual_bg)
c.vt_error_fg = readable(p.red, c.vt_error_bg)
c.vt_warn_fg = readable(p.yellow, c.vt_warn_bg)
c.vt_info_fg = readable(p.blue, c.vt_info_bg)
c.vt_hint_fg = readable(p.cyan, c.vt_hint_bg)
c.vt_ok_fg = readable(p.green, c.vt_ok_bg)

-- 5. groups ------------------------------------------------------------------------

local bg = opts.transparent and "NONE" or c.bg
local float_bg = opts.transparent and "NONE" or c.bg_hl

local hl = {
  -- Editor
  Normal = { fg = c.fg, bg = bg },
  NormalNC = { fg = c.fg, bg = bg },
  NormalFloat = { fg = c.fg, bg = float_bg },
  FloatBorder = { fg = c.border, bg = float_bg },
  FloatTitle = { link = "Title" },
  FloatFooter = { link = "FloatBorder" },
  WinSeparator = { fg = c.border, bg = bg },
  VertSplit = { link = "WinSeparator" },
  Pmenu = { fg = c.fg, bg = c.bg_hl },
  PmenuSel = { fg = c.bg, bg = c.blue },
  PmenuSbar = { bg = c.bg_hl },
  PmenuThumb = { bg = c.fg_faint },
  PmenuKind = { link = "Pmenu" },
  PmenuKindSel = { link = "PmenuSel" },
  PmenuExtra = { fg = c.fg_comment, bg = c.bg_hl },
  PmenuExtraSel = { link = "PmenuSel" },
  PmenuMatch = { fg = c.fg_emph, bg = c.bg_hl, bold = true },
  PmenuMatchSel = { fg = c.bg, bg = c.blue, bold = true },
  WildMenu = { fg = c.bg, bg = c.blue },
  CursorLine = { bg = c.bg_hl },
  CursorColumn = { bg = c.bg_hl },
  ColorColumn = { bg = c.bg_hl },
  Cursor = { fg = c.bg, bg = c.signature },
  lCursor = { link = "Cursor" },
  CursorIM = { link = "Cursor" },
  TermCursor = { link = "Cursor" },
  Visual = { fg = c.visual_fg, bg = c.visual_bg },
  VisualNOS = { link = "Visual" },
  LineNr = { fg = c.fg_faint, bg = bg },
  LineNrAbove = { link = "LineNr" },
  LineNrBelow = { link = "LineNr" },
  SignColumn = { fg = c.fg_faint, bg = bg },
  FoldColumn = { fg = c.fg_faint, bg = bg },
  CursorLineNr = { fg = c.fg_emph, bg = c.bg_hl, bold = true },
  CursorLineSign = { bg = c.bg_hl },
  CursorLineFold = { fg = c.fg_faint, bg = c.bg_hl },
  Folded = { fg = c.fg_comment, bg = c.bg_hl },
  StatusLine = { fg = c.fg_emph, bg = c.bg_hl },
  StatusLineNC = { fg = c.fg_comment, bg = c.bg_hl },
  StatusLineTerm = { link = "StatusLine" },
  StatusLineTermNC = { link = "StatusLineNC" },
  WinBar = { link = "StatusLine" },
  WinBarNC = { link = "StatusLineNC" },
  TabLine = { fg = c.fg_comment, bg = c.bg_hl },
  TabLineSel = { fg = c.fg_emph, bg = c.bg },
  TabLineFill = { bg = c.bg_hl },
  NonText = { fg = c.fg_faint },
  Whitespace = { fg = c.border },
  EndOfBuffer = { fg = c.border },
  Conceal = { fg = c.fg_faint },
  SpecialKey = { fg = c.fg_faint },
  Directory = { fg = c.blue },
  Title = { fg = c.orange, bold = true },
  Search = { fg = c.bg, bg = c.yellow },
  IncSearch = { fg = c.bg, bg = c.orange },
  CurSearch = { fg = c.bg, bg = c.orange },
  Substitute = { link = "IncSearch" },
  QuickFixLine = { link = "Visual" },
  MatchParen = { fg = c.fg_emph, bg = c.border, bold = true },
  ModeMsg = { fg = c.fg_emph, bold = true },
  MsgArea = { fg = c.fg },
  MoreMsg = { fg = c.yellow },
  Question = { fg = c.blue },
  ErrorMsg = { fg = c.red, bold = true },
  WarningMsg = { fg = c.yellow },
  SnippetTabstop = { link = "Visual" },

  -- Syntax: ink first. Identifiers and operators stay fg; each accent owns one idea.
  --   violet  keywords        blue    functions       green   strings
  --   orange  literals        yellow  types           cyan    escapes, regex, specials
  --   magenta macros, attributes, builtins            red     errors only
  Comment = { fg = c.fg_comment, italic = opts.italic_comments },
  Constant = { fg = c.orange },
  String = { fg = c.green },
  Character = { fg = c.green },
  Number = { fg = c.orange },
  Boolean = { fg = c.orange },
  Float = { fg = c.orange },
  Identifier = { fg = c.fg },
  Function = { fg = c.blue },
  Statement = { fg = c.violet },
  Keyword = { fg = c.violet },
  Conditional = { fg = c.violet },
  Repeat = { fg = c.violet },
  Operator = { fg = c.fg },
  Exception = { fg = c.violet },
  PreProc = { fg = c.magenta },
  Include = { fg = c.violet },
  Define = { fg = c.magenta },
  Macro = { fg = c.magenta },
  PreCondit = { link = "PreProc" },
  Type = { fg = c.yellow },
  StorageClass = { fg = c.violet },
  Structure = { fg = c.yellow },
  Typedef = { fg = c.yellow },
  Special = { fg = c.cyan },
  SpecialChar = { fg = c.cyan },
  Delimiter = { fg = c.fg_comment },
  Tag = { fg = c.blue },
  SpecialComment = { fg = c.fg_comment, bold = true },
  Debug = { link = "Special" },
  Label = { fg = c.violet },
  Underlined = { fg = c.blue, underline = true },
  Todo = { fg = c.bg, bg = c.yellow, bold = true },
  Error = { fg = c.red, bold = true },
  Ignore = { fg = c.fg_faint },
  Bold = { bold = true },
  Italic = { italic = true },

  -- Diagnostics
  DiagnosticError = { fg = c.red },
  DiagnosticWarn = { fg = c.yellow },
  DiagnosticInfo = { fg = c.blue },
  DiagnosticHint = { fg = c.cyan },
  DiagnosticOk = { fg = c.green },
  DiagnosticUnderlineError = { undercurl = true, sp = c.red },
  DiagnosticUnderlineWarn = { undercurl = true, sp = c.yellow },
  DiagnosticUnderlineInfo = { undercurl = true, sp = c.blue },
  DiagnosticUnderlineHint = { undercurl = true, sp = c.cyan },
  DiagnosticUnderlineOk = { undercurl = true, sp = c.green },
  DiagnosticVirtualTextError = { fg = c.vt_error_fg, bg = c.vt_error_bg },
  DiagnosticVirtualTextWarn = { fg = c.vt_warn_fg, bg = c.vt_warn_bg },
  DiagnosticVirtualTextInfo = { fg = c.vt_info_fg, bg = c.vt_info_bg },
  DiagnosticVirtualTextHint = { fg = c.vt_hint_fg, bg = c.vt_hint_bg },
  DiagnosticVirtualTextOk = { fg = c.vt_ok_fg, bg = c.vt_ok_bg },
  DiagnosticVirtualLinesError = { link = "DiagnosticVirtualTextError" },
  DiagnosticVirtualLinesWarn = { link = "DiagnosticVirtualTextWarn" },
  DiagnosticVirtualLinesInfo = { link = "DiagnosticVirtualTextInfo" },
  DiagnosticVirtualLinesHint = { link = "DiagnosticVirtualTextHint" },
  DiagnosticVirtualLinesOk = { link = "DiagnosticVirtualTextOk" },
  DiagnosticSignError = { link = "DiagnosticError" },
  DiagnosticSignWarn = { link = "DiagnosticWarn" },
  DiagnosticSignInfo = { link = "DiagnosticInfo" },
  DiagnosticSignHint = { link = "DiagnosticHint" },
  DiagnosticSignOk = { link = "DiagnosticOk" },
  DiagnosticFloatingError = { link = "DiagnosticError" },
  DiagnosticFloatingWarn = { link = "DiagnosticWarn" },
  DiagnosticFloatingInfo = { link = "DiagnosticInfo" },
  DiagnosticFloatingHint = { link = "DiagnosticHint" },
  DiagnosticFloatingOk = { link = "DiagnosticOk" },
  DiagnosticUnnecessary = { fg = c.fg_comment },
  DiagnosticDeprecated = { strikethrough = true, sp = c.fg_comment },

  -- LSP
  LspReferenceText = { bg = c.visual_bg },
  LspReferenceRead = { bg = c.visual_bg },
  LspReferenceWrite = { bg = c.visual_bg },
  LspReferenceTarget = { link = "LspReferenceText" },
  LspInlayHint = { fg = c.fg_comment },
  LspCodeLens = { fg = c.fg_comment },
  LspSignatureActiveParameter = { link = "Visual" },

  -- Diff and git
  DiffAdd = { fg = c.diff_add_fg, bg = c.diff_add_bg },
  DiffDelete = { fg = c.diff_delete_fg, bg = c.diff_delete_bg },
  DiffChange = { fg = c.diff_change_fg, bg = c.diff_change_bg },
  DiffText = { fg = c.diff_text_fg, bg = c.diff_text_bg, bold = true },
  Added = { fg = c.green },
  Removed = { fg = c.red },
  Changed = { fg = c.yellow },
  diffAdded = { link = "Added" },
  diffRemoved = { link = "Removed" },
  diffChanged = { link = "Changed" },
  GitSignsAdd = { link = "Added" },
  GitSignsDelete = { link = "Removed" },
  GitSignsChange = { link = "Changed" },
  GitSignsTopdelete = { link = "Removed" },
  GitSignsChangedelete = { link = "Changed" },
  GitSignsUntracked = { link = "Added" },
  GitSignsAddLn = { link = "DiffAdd" },
  GitSignsDeleteLn = { link = "DiffDelete" },
  GitSignsChangeLn = { link = "DiffChange" },
  GitSignsAddInline = { link = "DiffText" },
  GitSignsDeleteInline = { fg = c.diff_delete_fg, bg = c.diff_delete_bg, bold = true },
  GitSignsChangeInline = { link = "DiffText" },
  GitSignsAddPreview = { link = "DiffAdd" },
  GitSignsDeletePreview = { link = "DiffDelete" },
  GitSignsCurrentLineBlame = { fg = c.fg_comment },

  -- Spelling
  SpellBad = { undercurl = true, sp = c.red },
  SpellCap = { undercurl = true, sp = c.violet },
  SpellRare = { undercurl = true, sp = c.cyan },
  SpellLocal = { undercurl = true, sp = c.yellow },

  -- transient (lua/transient): the strip has no border, so its bg is the only edge and
  -- stays bg_hl even when transparent. Entry kinds: menu blue, loop green, action ink.
  TransientNormal = { fg = c.fg, bg = c.bg_hl },
  TransientTitle = { fg = c.fg_emph, bold = true },
  TransientCrumb = { fg = c.fg_comment },
  TransientKey = { fg = c.orange, bold = true },
  TransientAction = { fg = c.fg },
  TransientLoop = { fg = c.green },
  TransientMenu = { fg = c.blue },
  TransientHint = { fg = c.fg_comment },

  -- Treesitter
  ["@comment"] = { link = "Comment" },
  ["@string"] = { link = "String" },
  ["@string.escape"] = { link = "Special" },
  ["@string.regexp"] = { link = "Special" },
  ["@string.special"] = { link = "Special" },
  ["@character"] = { link = "Character" },
  ["@number"] = { link = "Number" },
  ["@number.float"] = { link = "Number" },
  ["@boolean"] = { link = "Boolean" },
  ["@constant"] = { link = "Constant" },
  ["@constant.builtin"] = { link = "Number" },
  ["@constant.macro"] = { link = "Macro" },
  ["@variable"] = { fg = c.fg },
  ["@variable.builtin"] = { fg = c.magenta },
  ["@variable.parameter"] = { fg = c.fg },
  ["@variable.member"] = { fg = c.fg },
  ["@property"] = { fg = c.fg },
  ["@field"] = { fg = c.fg },
  ["@function"] = { link = "Function" },
  ["@function.call"] = { link = "Function" },
  ["@function.method"] = { link = "Function" },
  ["@function.method.call"] = { link = "Function" },
  ["@method"] = { link = "Function" },
  ["@function.builtin"] = { fg = c.magenta },
  ["@function.macro"] = { link = "Macro" },
  ["@keyword"] = { link = "Keyword" },
  ["@keyword.return"] = { fg = c.violet, bold = true },
  ["@keyword.import"] = { link = "Include" },
  ["@keyword.directive"] = { link = "PreProc" },
  ["@operator"] = { link = "Operator" },
  ["@type"] = { link = "Type" },
  ["@type.builtin"] = { fg = c.yellow, italic = true },
  ["@constructor"] = { fg = c.yellow },
  ["@attribute"] = { link = "PreProc" },
  ["@label"] = { link = "Label" },
  ["@punctuation.delimiter"] = { fg = c.fg_comment },
  ["@punctuation.bracket"] = { fg = c.fg_comment },
  ["@punctuation.special"] = { link = "Special" },
  ["@tag"] = { fg = c.blue },
  ["@tag.builtin"] = { fg = c.blue },
  ["@tag.attribute"] = { fg = c.yellow },
  ["@tag.delimiter"] = { link = "@punctuation.delimiter" },
  ["@module"] = { fg = c.yellow },
  ["@module.builtin"] = { fg = c.magenta },
  ["@namespace"] = { link = "@module" },
  ["@markup.heading"] = { link = "Title" },
  ["@markup.link"] = { link = "Underlined" },
  ["@markup.link.url"] = { link = "Underlined" },
  ["@markup.raw"] = { fg = c.cyan },
  ["@markup.strong"] = { bold = true },
  ["@markup.italic"] = { italic = true },
  ["@markup.strikethrough"] = { strikethrough = true },
  ["@markup.quote"] = { link = "Comment" },
  ["@markup.list"] = { fg = c.fg_comment },
  ["@diff.plus"] = { link = "Added" },
  ["@diff.minus"] = { link = "Removed" },
  ["@diff.delta"] = { link = "Changed" },

  -- LSP semantic tokens: defer to Treesitter
  ["@lsp.type.variable"] = {},
  ["@lsp.type.parameter"] = { link = "@variable.parameter" },
  ["@lsp.type.property"] = { link = "@property" },
  ["@lsp.type.namespace"] = { link = "@module" },
  ["@lsp.type.function"] = { link = "@function" },
  ["@lsp.type.method"] = { link = "@function.method" },
  ["@lsp.type.macro"] = { link = "@function.macro" },
  ["@lsp.type.keyword"] = { link = "@keyword" },
  ["@lsp.type.comment"] = { link = "@comment" },
  ["@lsp.type.string"] = { link = "@string" },
  ["@lsp.type.number"] = { link = "@number" },
  ["@lsp.type.boolean"] = { link = "@boolean" },
  ["@lsp.type.operator"] = { link = "@operator" },
  ["@lsp.type.type"] = { link = "@type" },
  ["@lsp.type.class"] = { link = "@type" },
  ["@lsp.type.struct"] = { link = "@type" },
  ["@lsp.type.enum"] = { link = "@type" },
  ["@lsp.type.interface"] = { link = "@type" },
  ["@lsp.type.typeParameter"] = { link = "@type" },
  ["@lsp.type.enumMember"] = { link = "@constant" },
  ["@lsp.type.decorator"] = { link = "@attribute" },
  ["@lsp.type.event"] = { link = "@type" },
  ["@lsp.type.regexp"] = { link = "@string.regexp" },
  ["@lsp.type.modifier"] = { link = "@keyword" },
}

-- 6. terminal ----------------------------------------------------------------------

-- The same 16 colors as the Ghostty themes. Slot 0 is the darkest ink and 15 the
-- lightest, 7 is fg and 8 is fg_comment, so every slot stays readable.
local term = p.ansi

-- 7. apply -------------------------------------------------------------------------

vim.cmd.highlight("clear")
vim.g.colors_name = "cursorized"

if vim.is_callable(opts.on_highlights) then opts.on_highlights(hl, c) end

for name, spec in pairs(hl) do
  vim.api.nvim_set_hl(0, name, spec)
end

for i, color in ipairs(term) do
  vim.g["terminal_color_" .. (i - 1)] = color
end
