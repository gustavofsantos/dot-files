local function clear_highlights()
  if vim.fn.exists("syntax_on") then
    vim.cmd("syntax reset")
  end
end

local function setup()
  clear_highlights()

  vim.g.colors_name = "nord"
  vim.o.background = "dark"

  local nord = {
    nord0_gui = "#2E3440",
    nord1_gui = "#3B4252",
    nord2_gui = "#434C5E",
    nord3_gui = "#4C566A",
    nord3_gui_bright = "#616E88",
    nord4_gui = "#D8DEE9",
    nord5_gui = "#E5E9F0",
    nord6_gui = "#ECEFF4",
    nord7_gui = "#8FBCBB",
    nord8_gui = "#88C0D0",
    nord9_gui = "#81A1C1",
    nord10_gui = "#5E81AC",
    nord11_gui = "#BF616A",
    nord12_gui = "#D08770",
    nord13_gui = "#EBCB8B",
    nord14_gui = "#A3BE8C",
    nord15_gui = "#B48EAD",
  }

  local nord_term = {
    nord1_term = "0",
    nord3_term = "8",
    nord5_term = "7",
    nord6_term = "15",
    nord7_term = "14",
    nord8_term = "6",
    nord9_term = "4",
    nord10_term = "12",
    nord11_term = "1",
    nord12_term = "11",
    nord13_term = "3",
    nord14_term = "2",
    nord15_term = "5"
  }

  -- Generated brightened colors
  nord.nord3_gui_brightened = {
    nord.nord3_gui,
    "#4e586d",
    "#505b70",
    "#525d73",
    "#556076",
    "#576279",
    "#59647c",
    "#5b677f",
    "#5d6982",
    "#5f6c85",
    "#616e88",
    "#63718b",
    "#66738e",
    "#687591",
    "#6a7894",
    "#6d7a96",
    "#6f7d98",
    "#72809a",
    "#75829c",
    "#78859e",
    "#7b88a1"
  }

  -- Get user configuration options
  local nord_bold = (vim.g.nord_bold == 0) and "" or "bold,"
  local nord_underline = (vim.g.nord_underline == 0) and "NONE," or "underline,"

  local term_italic_enabled = (vim.fn.has("gui_running") == 1 or vim.env.TERM_ITALICS == "true")
  local nord_italic = (vim.g.nord_italic == 0 or not term_italic_enabled) and "" or "italic,"

  local nord_italic_comments = (vim.g.nord_italic_comments == 0) and "" or nord_italic

  -- Helper function to set highlight groups
  local function highlight(group, opts)
    local fg = opts.fg or "NONE"
    local bg = opts.bg or "NONE"
    local sp = opts.sp or ""

    local style = opts.style or ""

    -- Handle cterm style conversion (underline special case)
    local cterm_style = style
    if cterm_style:find("undercurl") then
      cterm_style = cterm_style:gsub("undercurl", nord_underline)
    end

    vim.api.nvim_set_hl(0, group, {
      fg = fg,
      bg = bg,
      sp = sp ~= "" and sp or nil,
      bold = style:find("bold") ~= nil,
      italic = style:find("italic") ~= nil,
      underline = style:find("underline") ~= nil,
      undercurl = style:find("undercurl") ~= nil,
    })
  end

  -- UI Components
  -- Attributes
  highlight("Bold", { style = nord_bold })
  highlight("Italic", { style = nord_italic })
  highlight("Underline", { style = nord_underline })

  -- Editor
  highlight("ColorColumn", { bg = nord.nord1_gui })
  highlight("Cursor", { fg = nord.nord0_gui, bg = nord.nord4_gui })
  highlight("CursorLine", { bg = nord.nord1_gui, style = "NONE" })
  highlight("Error", { fg = nord.nord4_gui, bg = nord.nord11_gui })
  highlight("iCursor", { fg = nord.nord0_gui, bg = nord.nord4_gui })
  highlight("LineNr", { fg = nord.nord3_gui })
  highlight("MatchParen", { fg = nord.nord8_gui, bg = nord.nord3_gui })
  highlight("NonText", { fg = nord.nord2_gui })
  highlight("Normal", { fg = nord.nord4_gui, bg = nord.nord0_gui })
  highlight("Pmenu", { fg = nord.nord4_gui, bg = nord.nord2_gui, style = "NONE" })
  highlight("PmenuSbar", { fg = nord.nord4_gui, bg = nord.nord2_gui })
  highlight("PmenuSel", { fg = nord.nord8_gui, bg = nord.nord3_gui })
  highlight("PmenuThumb", { fg = nord.nord8_gui, bg = nord.nord3_gui })
  highlight("SpecialKey", { fg = nord.nord3_gui })
  highlight("SpellBad", { fg = nord.nord11_gui, bg = nord.nord0_gui, style = "undercurl", sp = nord.nord11_gui })
  highlight("SpellCap", { fg = nord.nord13_gui, bg = nord.nord0_gui, style = "undercurl", sp = nord.nord13_gui })
  highlight("SpellLocal", { fg = nord.nord5_gui, bg = nord.nord0_gui, style = "undercurl", sp = nord.nord5_gui })
  highlight("SpellRare", { fg = nord.nord6_gui, bg = nord.nord0_gui, style = "undercurl", sp = nord.nord6_gui })
  highlight("Visual", { bg = nord.nord2_gui })
  highlight("VisualNOS", { bg = nord.nord2_gui })

    vim.g.terminal_color_0 = nord.nord1_gui
    vim.g.terminal_color_1 = nord.nord11_gui
    vim.g.terminal_color_2 = nord.nord14_gui
    vim.g.terminal_color_3 = nord.nord13_gui
    vim.g.terminal_color_4 = nord.nord9_gui
    vim.g.terminal_color_5 = nord.nord15_gui
    vim.g.terminal_color_6 = nord.nord8_gui
    vim.g.terminal_color_7 = nord.nord5_gui
    vim.g.terminal_color_8 = nord.nord3_gui
    vim.g.terminal_color_9 = nord.nord11_gui
    vim.g.terminal_color_10 = nord.nord14_gui
    vim.g.terminal_color_11 = nord.nord13_gui
    vim.g.terminal_color_12 = nord.nord9_gui
    vim.g.terminal_color_13 = nord.nord15_gui
    vim.g.terminal_color_14 = nord.nord7_gui
    vim.g.terminal_color_15 = nord.nord6_gui

    -- Neovim specific highlights
    highlight("healthError", { fg = nord.nord11_gui, bg = nord.nord1_gui })
    highlight("healthSuccess", { fg = nord.nord14_gui, bg = nord.nord1_gui })
    highlight("healthWarning", { fg = nord.nord13_gui, bg = nord.nord1_gui })
    highlight("TermCursorNC", { bg = nord.nord1_gui })

    -- Neovim Diagnostics API (for LSP)
    highlight("DiagnosticWarn", { fg = nord.nord13_gui })
    highlight("DiagnosticError", { fg = nord.nord11_gui })
    highlight("DiagnosticInfo", { fg = nord.nord8_gui })
    highlight("DiagnosticHint", { fg = nord.nord10_gui })
    highlight("DiagnosticUnderlineWarn", { fg = nord.nord13_gui, style = "undercurl" })
    highlight("DiagnosticUnderlineError", { fg = nord.nord11_gui, style = "undercurl" })
    highlight("DiagnosticUnderlineInfo", { fg = nord.nord8_gui, style = "undercurl" })
    highlight("DiagnosticUnderlineHint", { fg = nord.nord10_gui, style = "undercurl" })

    -- Neovim DocumentHighlight
    highlight("LspReferenceText", { bg = nord.nord3_gui })
    highlight("LspReferenceRead", { bg = nord.nord3_gui })
    highlight("LspReferenceWrite", { bg = nord.nord3_gui })

    -- Neovim LspSignatureHelp
    highlight("LspSignatureActiveParameter", { fg = nord.nord8_gui, style = nord_underline })

  -- Gutter
  highlight("CursorColumn", { bg = nord.nord1_gui })
  if vim.g.nord_cursor_line_number_background == 0 then
    highlight("CursorLineNr", { fg = nord.nord4_gui, style = "NONE" })
  else
    highlight("CursorLineNr", { fg = nord.nord4_gui, bg = nord.nord1_gui, style = "NONE" })
  end
  highlight("Folded", { fg = nord.nord3_gui, bg = nord.nord1_gui, style = nord_bold })
  highlight("FoldColumn", { fg = nord.nord3_gui, bg = nord.nord0_gui })
  highlight("SignColumn", { fg = nord.nord1_gui, bg = nord.nord0_gui })

  -- Navigation
  highlight("Directory", { fg = nord.nord8_gui })

  -- Prompt/Status
  highlight("EndOfBuffer", { fg = nord.nord1_gui })
  highlight("ErrorMsg", { fg = nord.nord4_gui, bg = nord.nord11_gui })
  highlight("ModeMsg", { fg = nord.nord4_gui })
  highlight("MoreMsg", { fg = nord.nord8_gui })
  highlight("Question", { fg = nord.nord4_gui })

  -- Status line configuration
  if vim.g.nord_uniform_status_lines == 0 then
    highlight("StatusLine", { fg = nord.nord8_gui, bg = nord.nord3_gui, style = "NONE" })
    highlight("StatusLineNC", { fg = nord.nord4_gui, bg = nord.nord1_gui, style = "NONE" })
    highlight("StatusLineTerm", { fg = nord.nord8_gui, bg = nord.nord3_gui, style = "NONE" })
    highlight("StatusLineTermNC", { fg = nord.nord4_gui, bg = nord.nord1_gui, style = "NONE" })
  else
    highlight("StatusLine", { fg = nord.nord8_gui, bg = nord.nord3_gui, style = "NONE" })
    highlight("StatusLineNC", { fg = nord.nord4_gui, bg = nord.nord3_gui, style = "NONE" })
    highlight("StatusLineTerm", { fg = nord.nord8_gui, bg = nord.nord3_gui, style = "NONE" })
    highlight("StatusLineTermNC", { fg = nord.nord4_gui, bg = nord.nord3_gui, style = "NONE" })
  end

  highlight("WarningMsg", { fg = nord.nord0_gui, bg = nord.nord13_gui })
  highlight("WildMenu", { fg = nord.nord8_gui, bg = nord.nord1_gui })

  -- Search
  highlight("IncSearch", { fg = nord.nord6_gui, bg = nord.nord10_gui, style = nord_underline })
  highlight("Search", { fg = nord.nord1_gui, bg = nord.nord8_gui, style = "NONE" })

  -- Tabs
  highlight("TabLine", { fg = nord.nord4_gui, bg = nord.nord1_gui, style = "NONE" })
  highlight("TabLineFill", { fg = nord.nord4_gui, bg = nord.nord1_gui, style = "NONE" })
  highlight("TabLineSel", { fg = nord.nord8_gui, bg = nord.nord3_gui, style = "NONE" })

  -- Window
  highlight("Title", { fg = nord.nord4_gui, style = "NONE" })

  -- Vertical split styling
  if vim.g.nord_bold_vertical_split_line == 0 then
    highlight("VertSplit", { fg = nord.nord2_gui, bg = nord.nord0_gui, style = "NONE" })
  else
    highlight("VertSplit", { fg = nord.nord2_gui, bg = nord.nord1_gui, style = "NONE" })
  end

  -- Language Base Groups
  highlight("Boolean", { fg = nord.nord9_gui })
  highlight("Character", { fg = nord.nord14_gui })
  highlight("Comment", { fg = nord.nord3_gui_bright, style = nord_italic_comments })
  highlight("Conceal", { bg = "NONE" })
  highlight("Conditional", { fg = nord.nord9_gui })
  highlight("Constant", { fg = nord.nord4_gui })
  highlight("Decorator", { fg = nord.nord12_gui })
  highlight("Define", { fg = nord.nord9_gui })
  highlight("Delimiter", { fg = nord.nord6_gui })
  highlight("Exception", { fg = nord.nord9_gui })
  highlight("Float", { fg = nord.nord15_gui })
  highlight("Function", { fg = nord.nord8_gui })
  highlight("Identifier", { fg = nord.nord4_gui, style = "NONE" })
  highlight("Include", { fg = nord.nord9_gui })
  highlight("Keyword", { fg = nord.nord9_gui })
  highlight("Label", { fg = nord.nord9_gui })
  highlight("Number", { fg = nord.nord15_gui })
  highlight("Operator", { fg = nord.nord9_gui, style = "NONE" })
  highlight("PreProc", { fg = nord.nord9_gui, style = "NONE" })
  highlight("Repeat", { fg = nord.nord9_gui })
  highlight("Special", { fg = nord.nord4_gui })
  highlight("SpecialChar", { fg = nord.nord13_gui })
  highlight("SpecialComment", { fg = nord.nord8_gui, style = nord_italic_comments })
  highlight("Statement", { fg = nord.nord9_gui })
  highlight("StorageClass", { fg = nord.nord9_gui })
  highlight("String", { fg = nord.nord14_gui })
  highlight("Structure", { fg = nord.nord9_gui })
  highlight("Tag", { fg = nord.nord4_gui })
  highlight("Todo", { fg = nord.nord13_gui, bg = "NONE" })
  highlight("Type", { fg = nord.nord9_gui, style = "NONE" })
  highlight("Typedef", { fg = nord.nord9_gui })

  -- Link common groups
  local links = {
    ["Annotation"] = "Decorator",
    ["Macro"] = "Define",
    ["PreCondit"] = "PreProc",
    ["Variable"] = "Identifier",
  }

  for newgroup, oldgroup in pairs(links) do
    vim.api.nvim_set_hl(0, newgroup, { link = oldgroup })
  end

  -- Language specific highlights
  -- Only adding a subset of the language-specific highlights for brevity
  -- More can be added based on your needs

  -- Diff highlighting
  if vim.g.nord_uniform_diff_background == 0 then
    highlight("DiffAdd", { fg = nord.nord14_gui, bg = nord.nord0_gui, style = "inverse" })
    highlight("DiffChange", { fg = nord.nord13_gui, bg = nord.nord0_gui, style = "inverse" })
    highlight("DiffDelete", { fg = nord.nord11_gui, bg = nord.nord0_gui, style = "inverse" })
    highlight("DiffText", { fg = nord.nord9_gui, bg = nord.nord0_gui, style = "inverse" })
  else
    highlight("DiffAdd", { fg = nord.nord14_gui, bg = nord.nord1_gui })
    highlight("DiffChange", { fg = nord.nord13_gui, bg = nord.nord1_gui })
    highlight("DiffDelete", { fg = nord.nord11_gui, bg = nord.nord1_gui })
    highlight("DiffText", { fg = nord.nord9_gui, bg = nord.nord1_gui })
  end

  -- Legacy diff groups
  vim.api.nvim_set_hl(0, "diffAdded", { link = "DiffAdd" })
  vim.api.nvim_set_hl(0, "diffChanged", { link = "DiffChange" })
  vim.api.nvim_set_hl(0, "diffRemoved", { link = "DiffDelete" })

  -- Git related highlights
  highlight("gitcommitDiscardedFile", { fg = nord.nord11_gui })
  highlight("gitcommitUntrackedFile", { fg = nord.nord11_gui })
  highlight("gitcommitSelectedFile", { fg = nord.nord14_gui })

  -- Plugin support - Only adding a subset for brevity
  -- DiagnosticSign highlights for LSP
  highlight("DiagnosticSignError", { fg = nord.nord11_gui, bg = "NONE" })
  highlight("DiagnosticSignWarn", { fg = nord.nord13_gui, bg = "NONE" })
  highlight("DiagnosticSignHint", { fg = nord.nord8_gui, bg = "NONE" })
  highlight("DiagnosticSignInfo", { fg = nord.nord9_gui, bg = "NONE" })

  -- GitSigns plugin support
  highlight("GitSignsAdd", { fg = nord.nord14_gui })
  highlight("GitSignsChange", { fg = nord.nord13_gui })
  highlight("GitSignsDelete", { fg = nord.nord11_gui })

  -- Nvim-Treesitter
  vim.api.nvim_set_hl(0, "TSAnnotation", { link = "Annotation" })
  vim.api.nvim_set_hl(0, "TSConstBuiltin", { link = "Constant" })
  vim.api.nvim_set_hl(0, "TSConstructor", { link = "Function" })
  vim.api.nvim_set_hl(0, "TSEmphasis", { link = "Italic" })
  vim.api.nvim_set_hl(0, "TSFuncBuiltin", { link = "Function" })
  vim.api.nvim_set_hl(0, "TSFuncMacro", { link = "Function" })
  vim.api.nvim_set_hl(0, "TSStringRegex", { link = "SpecialChar" })
  vim.api.nvim_set_hl(0, "TSStrong", { link = "Bold" })
  vim.api.nvim_set_hl(0, "TSStructure", { link = "Structure" })
  vim.api.nvim_set_hl(0, "TSTagDelimiter", { link = "TSTag" })
  vim.api.nvim_set_hl(0, "TSUnderline", { link = "Underline" })
  vim.api.nvim_set_hl(0, "TSVariable", { link = "Variable" })
  vim.api.nvim_set_hl(0, "TSVariableBuiltin", { link = "Keyword" })

  -- Public API: Return the Nord color palette
  _G.NordPalette = function()
    return {
      nord0 = nord.nord0_gui,
      nord1 = nord.nord1_gui,
      nord2 = nord.nord2_gui,
      nord3 = nord.nord3_gui,
      nord4 = nord.nord4_gui,
      nord5 = nord.nord5_gui,
      nord6 = nord.nord6_gui,
      nord7 = nord.nord7_gui,
      nord8 = nord.nord8_gui,
      nord9 = nord.nord9_gui,
      nord10 = nord.nord10_gui,
      nord11 = nord.nord11_gui,
      nord12 = nord.nord12_gui,
      nord13 = nord.nord13_gui,
      nord14 = nord.nord14_gui,
      nord15 = nord.nord15_gui,
      nord3_bright = nord.nord3_gui_bright
    }
  end
end

return setup()
