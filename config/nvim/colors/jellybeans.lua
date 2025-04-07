-- Jellybeans colorscheme for Neovim
-- Ported from the original Vim colorscheme by NanoTech (https://github.com/nanotech/jellybeans.vim)

local M = {}

-- Helper function to set highlight groups
local function highlight(group, opts)
  opts.default = opts.default or false
  vim.api.nvim_set_hl(0, group, opts)
end

function M.setup()
  vim.cmd("hi clear")
  if vim.fn.exists("syntax_on") then
    vim.cmd("syntax reset")
  end

  vim.g.colors_name = "jellybeans"
  vim.o.background = "dark"

  -- Get configuration options from user (with defaults)
  local config = {
    background_color = vim.g.jellybeans_background_color or "151515",
    use_lowcolor_black = vim.g.jellybeans_use_lowcolor_black or false,
    use_gui_italics = vim.g.jellybeans_use_gui_italics == nil and true or vim.g.jellybeans_use_gui_italics,
    use_term_italics = vim.g.jellybeans_use_term_italics or false,
    display_cursor_line = vim.g.jellybeans_display_cursor_line ~= nil and vim.g.jellybeans_display_cursor_line or true,
    overrides = vim.g.jellybeans_overrides or {},
  }

  -- Backwards compatibility
  if vim.g.jellybeans_background_color or vim.g.jellybeans_background_color_256 or vim.g.jellybeans_use_term_background_color then
    if not config.overrides.background then
      config.overrides.background = {}
    end

    if vim.g.jellybeans_background_color then
      config.overrides.background.guibg = vim.g.jellybeans_background_color
    end

    if vim.g.jellybeans_background_color_256 then
      config.overrides.background["256ctermbg"] = vim.g.jellybeans_background_color_256
    end

    if vim.g.jellybeans_use_term_background_color then
      config.overrides.background.ctermbg = "NONE"
      config.overrides.background["256ctermbg"] = "NONE"
    end
  end

  -- If background is overridden, use that value
  if config.overrides.background and config.overrides.background.guibg then
    config.background_color = config.overrides.background.guibg
  end

  -- Define colors
  local colors = {
    -- Base colors
    background = "#" .. config.background_color,
    foreground = "#e8e8d3",

    -- UI elements
    cursor_line = "#1c1c1c",
    visual = "#404040",
    search = "#302028",

    -- Syntax colors
    comment = "#888888",
    string = "#99ad6a",
    constant = "#cf6a4c",
    identifier = "#c6b6ee",
    statement = "#8197bf",
    preproc = "#8fbfdc",
    type = "#ffb964",
    special = "#799d6a",
    delimiter = "#668799",

    -- Additional colors
    red = "#902020",
    green = "#437019",
    blue = "#2B5B77",
    yellow = "#ffb964",
    magenta = "#540063",
    cyan = "#8fbfdc",

    -- UI colors
    line_nr = "#605958",
    status_line = "#dddddd",
    status_line_nc = "#403c41",
    tab_line = "#b0b8c0",
    tab_line_fill = "#9098a0",
    tab_line_sel = "#f0f0f0",
    pmenu = "#606060",
    pmenu_sel = "#eeeeee",
    fold_column = "#384048",

    -- Diff colors
    diff_add = "#D2EBBE",
    diff_add_bg = "#437019",
    diff_delete = "#40000A",
    diff_delete_bg = "#700009",
    diff_change_bg = "#2B5B77",
    diff_text = "#8fbfdc",
  }

  -- Define highlight groups
  local groups = {
    -- Editor UI
    Normal = { fg = colors.foreground, bg = colors.background },
    NormalFloat = { fg = colors.foreground, bg = colors.background },
    Cursor = { fg = colors.background, bg = "#b0d0f0" },
    CursorLine = { bg = config.display_cursor_line and colors.cursor_line or 'NONE' },
    CursorColumn = { bg = colors.cursor_line },
    ColorColumn = { bg = "#000000" },

    LineNr = { fg = colors.line_nr, bg = colors.background },
    CursorLineNr = { fg = "#ccc5c4" },
    SignColumn = { fg = "#777777", bg = "#333333" },

    VertSplit = { fg = "#777777", bg = colors.background },
    WinSeparator = { link = "VertSplit" },
    StatusLine = { fg = "#000000", bg = colors.status_line, italic = false },
    StatusLineNC = { fg = "#ffffff", bg = colors.status_line_nc, italic = false },

    Folded = { fg = "#a0a8b0", bg = colors.fold_column, italic = config.use_gui_italics },
    FoldColumn = { fg = "#535D66", bg = "#1f1f1f" },

    Pmenu = { fg = "#ffffff", bg = colors.pmenu },
    PmenuSel = { fg = "#101010", bg = colors.pmenu_sel },
    PmenuSbar = { bg = colors.pmenu },
    PmenuThumb = { bg = "#777777" },

    TabLine = { fg = "#000000", bg = colors.tab_line, italic = false },
    TabLineFill = { fg = colors.tab_line_fill },
    TabLineSel = { fg = "#000000", bg = colors.tab_line_sel, italic = false, bold = true },

    Search = { fg = "#f0a0c0", bg = colors.search, underline = true },
    IncSearch = { fg = "#f0a0c0", bg = colors.search, underline = true },
    MatchParen = { fg = "#ffffff", bg = "#556779", bold = true },

    Visual = { bg = colors.visual },
    VisualNOS = { bg = colors.visual },

    WildMenu = { fg = "#f0a0c0", bg = "#302028" },
    Directory = { fg = "#dad085" },
    Title = { fg = "#70b950", bold = true },

    ErrorMsg = { bg = colors.red },
    WarningMsg = { fg = "#ff5f00" },
    MoreMsg = { link = "Special" },
    Question = { fg = "#65C254" },

    NonText = { fg = "#606060", bg = colors.background },
    SpecialKey = { fg = "#444444", bg = colors.cursor_line },

    -- Diff
    DiffAdd = { fg = colors.diff_add, bg = colors.diff_add_bg },
    DiffDelete = { fg = colors.diff_delete, bg = colors.diff_delete_bg },
    DiffChange = { bg = colors.diff_change_bg },
    DiffText = { fg = colors.diff_text, bg = "#000000", reverse = true },

    -- Spell checking
    SpellBad = { undercurl = true, sp = colors.red },
    SpellCap = { undercurl = true, sp = "#0000df" },
    SpellRare = { undercurl = true, sp = colors.magenta },
    SpellLocal = { undercurl = true, sp = "#2D7067" },

    -- Syntax highlighting
    Comment = { fg = colors.comment, italic = config.use_gui_italics },
    Todo = { fg = "#c7c7c7", bold = true },

    Constant = { fg = colors.constant },
    String = { fg = colors.string },
    StringDelimiter = { fg = "#556633" },

    Identifier = { fg = colors.identifier },
    Function = { fg = "#fad07a" },

    Statement = { fg = colors.statement },
    Conditional = { link = "Statement" },
    Repeat = { link = "Statement" },
    Label = { link = "Statement" },
    Operator = { link = "Statement" },
    Keyword = { link = "Statement" },
    Exception = { link = "Statement" },

    PreProc = { fg = colors.preproc },
    Include = { link = "PreProc" },
    Define = { link = "PreProc" },
    Macro = { link = "PreProc" },
    PreCondit = { link = "PreProc" },

    Type = { fg = colors.type },
    StorageClass = { fg = "#c59f6f" },
    Structure = { fg = colors.cyan },
    Typedef = { link = "Type" },

    Special = { fg = colors.special },
    SpecialChar = { link = "Special" },
    Tag = { link = "Special" },
    Delimiter = { fg = colors.delimiter },
    SpecialComment = { link = "Special" },
    Debug = { link = "Special" },

    -- Language specific
    -- HTML
    htmlTag = { link = "Statement" },
    htmlEndTag = { link = "htmlTag" },
    htmlTagName = { link = "htmlTag" },

    -- XML
    xmlTag = { link = "Statement" },
    xmlEndTag = { link = "xmlTag" },
    xmlTagName = { link = "xmlTag" },
    xmlEqual = { link = "xmlTag" },
    xmlEntity = { link = "Special" },
    xmlEntityPunct = { link = "xmlEntity" },
    xmlDocTypeDecl = { link = "PreProc" },
    xmlDocTypeKeyword = { link = "PreProc" },
    xmlProcessingDelim = { link = "xmlAttrib" },

    -- CSS
    cssBraces = { link = "Delimiter" },
    cssSelectorOp = { link = "Delimiter" },

    -- JavaScript
    javaScriptValue = { link = "Constant" },
    javaScriptTemplateVar = { link = "StringDelimiter" },
    javaScriptTemplateDelim = { link = "Identifier" },
    javaScriptTemplateString = { link = "String" },

    -- Ruby
    rubyClass = { fg = "#447799" },
    rubyIdentifier = { fg = "#c6b6fe" },
    rubyInstanceVariable = { fg = "#c6b6fe" },
    rubySymbol = { fg = "#7697d6" },
    rubyControl = { fg = "#7597c6" },
    rubyRegexpDelimiter = { fg = colors.magenta },
    rubyRegexp = { fg = "#dd0093" },
    rubyRegexpSpecial = { fg = "#a40073" },

    -- Python
    pythonOperator = { link = "Statement" },

    -- Git
    gitcommitComment = { link = "Comment" },
    gitcommitUntracked = { link = "gitcommitComment" },
    gitcommitDiscarded = { link = "gitcommitComment" },
    gitcommitSelected = { link = "gitcommitComment" },
    gitcommitHeader = { link = "PreProc" },

    -- Markdown
    markdownHeadingDelimiter = { link = "PreProc" },
    markdownH1 = { bold = true },
    markdownH2 = { bold = true },
    markdownH3 = { bold = true },

    -- Treesitter (additional, not in original)
    ["@comment"] = { link = "Comment" },
    ["@string"] = { link = "String" },
    ["@punctuation.string.delimiter"] = { link = "StringDelimiter" },
    ["@constant"] = { link = "Constant" },
    ["@character"] = { link = "Character" },
    ["@number"] = { link = "Number" },
    ["@boolean"] = { link = "Boolean" },
    ["@float"] = { link = "Float" },
    ["@function"] = { link = "Function" },
    ["@conditional"] = { link = "Conditional" },
    ["@repeat"] = { link = "Repeat" },
    ["@label"] = { link = "Label" },
    ["@operator"] = { link = "Operator" },
    ["@property"] = { fg = "#e8e8d3" },
    ["@keyword"] = { link = "Keyword" },
    ["@exception"] = { link = "Exception" },
    ["@variable"] = { link = "Identifier" },
    ["@type"] = { link = "Type" },
    ["@type.definition"] = { link = "Typedef" },
    ["@storageclass"] = { link = "StorageClass" },
    ["@structure"] = { link = "Structure" },
    ["@namespace"] = { link = "Identifier" },
    ["@include"] = { link = "Include" },
    ["@preproc"] = { link = "PreProc" },
    ["@debug"] = { link = "Debug" },
    ["@tag"] = { link = "Tag" },

    -- Diagnostic
    DiagnosticError = { fg = "#FF0000" },
    DiagnosticWarn = { fg = "#FFFF00" },
    DiagnosticInfo = { fg = "#00FFFF" },
    DiagnosticHint = { fg = "#00FF00" },

    DiagnosticUnderlineError = { undercurl = true, sp = "#FF0000" },
    DiagnosticUnderlineWarn = { undercurl = true, sp = "#FFFF00" },
    DiagnosticUnderlineInfo = { undercurl = true, sp = "#00FFFF" },
    DiagnosticUnderlineHint = { undercurl = true, sp = "#00FF00" },

    -- Telescope
    TelescopeBorder = { fg = "#777777" },
    TelescopePromptBorder = { fg = "#777777" },
    TelescopeResultsBorder = { fg = "#777777" },
    TelescopePreviewBorder = { fg = "#777777" },
    TelescopePromptPrefix = { fg = colors.special },
    TelescopeSelectionCaret = { fg = colors.statement },
    TelescopeSelection = { bg = "#303030" },
    TelescopeMatching = { fg = "#fad07a", bold = true },
    TelescopePromptTitle = { fg = "#000000", bg = colors.special },
    TelescopeResultsTitle = { fg = "#000000", bg = colors.special },
    TelescopePreviewTitle = { fg = "#000000", bg = colors.special },

    -- Overseer
    OverseerTask = { link = "Normal" },
    OverseerTaskBorder = { fg = "#777777" },
    OverseerRunning = { fg = "#8197bf" },
    OverseerSuccess = { fg = "#99ad6a" },
    OverseerFailure = { fg = "#cf6a4c" },
    OverseerCancelled = { fg = "#c59f6f" },
    OverseerOutput = { link = "Normal" },
    OverseerComponent = { fg = "#fad07a" },
    OverseerField = { fg = "#8fbfdc" },
    OverseerTask = { link = "Normal" },
    OverseerTaskIcon = { fg = "#c6b6ee" },
  }

  -- Apply overrides
  if config.overrides then
    for group, style in pairs(config.overrides) do
      if group == "background" then
        -- Special case for background to affect multiple groups
        if style.guibg then
          groups.Normal.bg = "#" .. style.guibg
          groups.LineNr.bg = "#" .. style.guibg
          groups.NonText.bg = "#" .. style.guibg
        end
      elseif groups[group] then
        -- Override existing groups
        if style.guifg and style.guifg ~= "NONE" then
          groups[group].fg = "#" .. style.guifg
        end
        if style.guibg and style.guibg ~= "NONE" then
          groups[group].bg = "#" .. style.guibg
        end
        if style.attr then
          local attrs = vim.split(style.attr, ",")
          for _, attr in ipairs(attrs) do
            groups[group][attr] = true
          end
        end
      end
    end
  end

  -- Set all highlight groups
  for group, style in pairs(groups) do
    highlight(group, style)
  end
end

M.setup()

return M
