vim.g.mapleader = " "
vim.g.maplocalleader = ","

vim.opt.background = "dark"
vim.cmd.colorscheme("default")

vim.opt.inccommand = "split"
-- vim.opt.winwidth = 100
vim.o.cursorline = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.number = true
vim.opt.relativenumber = false
-- vim.opt.hidden = true
vim.opt.encoding = "utf-8"
vim.opt.hlsearch = true
-- vim.opt.infercase = true
-- vim.opt.showcmd = true
vim.opt.laststatus = 2
-- vim.opt.expandtab = true
-- vim.opt.smarttab = true
-- vim.opt.cindent = true
-- vim.opt.backup = true
vim.opt.backupdir = { vim.fn.expand('$HOME/.local/share/nvim/backups') }
vim.opt.backupskip = { "/tmp/*", "/private/tmp/*" }
-- vim.opt.writebackup = true
-- vim.opt.breakindent = true
-- vim.opt.backspace = "start,eol,indent"
-- vim.opt.wrap = false
-- vim.opt.shiftwidth = 2
-- vim.opt.tabstop = 2
vim.opt.scrolloff = 3
-- vim.opt.sidescrolloff = 5
-- vim.opt.siso = 3
vim.opt.foldcolumn = "0"
vim.opt.foldlevel = 999
vim.opt.foldlevelstart = 99
vim.opt.foldenable = true
vim.opt.foldmethod = "indent"
vim.opt.wildmenu = true
-- vim.opt.wildmode = "longest,list"
vim.opt.wildoptions:append { 'fuzzy' }
vim.opt.completeopt = "menu,menuone,fuzzy,noinsert,preview"
vim.opt.pumheight = 12
vim.opt.pumwidth = 50
-- vim.opt.updatetime = 100
vim.opt.grepprg = "rg --vimgrep --no-messages --smart-case"
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.signcolumn = "yes"
-- vim.opt.shada = { "'10", "<0", "s10", "h" }
-- vim.opt.cursorline = true
vim.opt.clipboard = "unnamedplus"
vim.opt.swapfile = false
vim.opt.showtabline = 1
-- vim.opt.winbar = ""
vim.opt.title = true
vim.opt.titlestring = '%t%( %M%)%( (%{expand("%:~:h")})%)%a (nvim)'
-- vim.opt.colorcolumn = ""
vim.opt.statusline = " %<%{fnamemodify(expand('%'), ':~:.')} (%{&ft}) %-3(%m%)%=%-19(%3l,%02c%03V%) %P"

vim.opt.path:append({ "**" })
-- vim.opt.wildignore:append({ "*/node_modules/*" })
-- vim.opt.formatoptions:append({ "r" })
-- vim.opt.shortmess:append({
--   I = false, -- No splash screen
--   W = false, -- Don't print "written" when editing
--   a = true,  -- Use abbreviations in messages ([RO] intead of [readonly])
--   c = true,  -- Do not show ins-completion-menu messages (match 1 of 2)
--   F = true,  -- Do not print file name when opening a file
--   s = true,  -- Do not show "Search hit BOTTOM" message
-- })

vim.opt.list = true
vim.opt.listchars = {
  nbsp = "⦸",
  -- eol = "↵",
  tab = "  ",
  extends = "»",
  precedes = "«",
  trail = "·",
}
vim.opt.showbreak = "↳ "
vim.opt.fillchars = {
  eob = " ",
  fold = " ",
  diff = "╱",
  foldopen = "",
  foldclose = "",
}

vim.opt.undofile = true
vim.opt.undodir = vim.fn.stdpath("data") .. "/undo"

vim.diagnostic.config({
  underline = false,
  virtual_text = false,
  update_in_insert = false,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = '■',
      [vim.diagnostic.severity.WARN] = '■',
      [vim.diagnostic.severity.HINT] = '■',
      [vim.diagnostic.severity.INFO] = '■',
    }
  },
  float = {
    source = "if_many",
  },
})

-- Diagnostic symbols in the sign column (gutter)
local signs = { Error = "■", Warn = "■", Hint = '■', Info = '■' }
for type, _ in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = "", texthl = hl, numhl = "" })
end
