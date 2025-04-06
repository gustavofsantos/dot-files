vim.opt.termguicolors = true
vim.g.colorscheme = "jellybeans"
vim.opt.background = "dark"
vim.opt.hidden = true
vim.opt.encoding = "utf-8"
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.hidden = true
vim.opt.ai = true
vim.opt.si = true
vim.opt.hlsearch = true
vim.opt.infercase = true
vim.opt.showcmd = true
vim.opt.cmdheight = 1
vim.opt.laststatus = 2
vim.opt.expandtab = true
vim.opt.smarttab = true
vim.opt.cindent = true
vim.opt.shell = "zsh"
vim.opt.backup = true
vim.opt.backupdir = { vim.fn.expand('$HOME/.local/share/nvim/backups') }
vim.opt.backupskip = { "/tmp/*", "/private/tmp/*" }
vim.opt.writebackup = true
vim.opt.inccommand = "split"
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.breakindent = true
vim.opt.backspace = "start,eol,indent"
vim.opt.wrap = false
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.scrolloff = 3
vim.opt.sidescrolloff = 5
vim.opt.siso = 3
vim.opt.foldcolumn = "0"
vim.opt.foldlevel = 999
vim.opt.foldlevelstart = 99
vim.opt.foldenable = true
vim.opt.foldmethod = "indent"
vim.opt.wildmenu = true
vim.opt.completeopt = "menu,noinsert,preview"
vim.opt.pumheight = 12
vim.opt.pumwidth = 50
vim.opt.wildmode = "longest,full"
vim.opt.updatetime = 100
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.signcolumn = "no"
vim.opt.cursorline = true
vim.opt.swapfile = false
vim.opt.showtabline = 1
vim.opt.winbar = ""
-- vim.opt.mouse = "nv"
vim.opt.colorcolumn = "80,100"

vim.opt.path:append({ "**" })
vim.opt.wildignore:append({ "*/node_modules/*" })
vim.opt.formatoptions:append({ "r" })
vim.opt.clipboard:append({ "unnamedplus" })
vim.opt.shortmess:append({
  I = false, -- No splash screen
  W = false, -- Don't print "written" when editing
  a = true,  -- Use abbreviations in messages ([RO] intead of [readonly])
  c = true,  -- Do not show ins-completion-menu messages (match 1 of 2)
  F = true,  -- Do not print file name when opening a file
  s = true,  -- Do not show "Search hit BOTTOM" message
})

vim.opt.list = true
vim.opt.listchars = {
  nbsp = "⦸",
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
