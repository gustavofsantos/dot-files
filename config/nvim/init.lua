vim.g.mapleader = " "
vim.g.maplocalleader = ","

vim.opt.background = "dark"
vim.cmd.colorscheme("nord")
vim.opt.inccommand = "split"
vim.opt.winwidth = 100
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.number = false
vim.opt.relativenumber = false
vim.opt.hidden = true
vim.opt.encoding = "utf-8"
vim.opt.hidden = true
vim.opt.hlsearch = true
vim.opt.infercase = true
vim.opt.showcmd = true
vim.opt.laststatus = 2
vim.opt.expandtab = true
vim.opt.smarttab = true
vim.opt.cindent = true
vim.opt.backup = true
vim.opt.backupdir = { vim.fn.expand('$HOME/.local/share/nvim/backups') }
vim.opt.backupskip = { "/tmp/*", "/private/tmp/*" }
vim.opt.writebackup = true
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
vim.opt.wildmode = "longest,list"
vim.opt.completeopt = "menu,noinsert,preview"
vim.opt.pumheight = 12
vim.opt.pumwidth = 50
vim.opt.updatetime = 100
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.signcolumn = "yes"
vim.opt.shada = { "'10", "<0", "s10", "h" }
vim.opt.cursorline = true
vim.opt.clipboard = "unnamedplus"
vim.opt.swapfile = false
vim.opt.showtabline = 1
vim.opt.winbar = ""
vim.opt.title = true
vim.opt.titlestring = '%t%( %M%)%( (%{expand("%:~:h")})%)%a (nvim)'
vim.opt.colorcolumn = ""
vim.opt.statusline = "%<%{fnamemodify(expand('%'), ':~:.')} (%{&ft}) %-3(%m%)%=%-19(%3l,%02c%03V%)"

vim.opt.path:append({ "**" })
vim.opt.wildignore:append({ "*/node_modules/*" })
vim.opt.formatoptions:append({ "r" })
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


vim.keymap.set("n", "Q", "<Nop>")
vim.keymap.set("n", "<c-s>", "<cmd>w<cr>")
vim.keymap.set("i", "<c-c>", "<Esc>")
vim.keymap.set("n", "<c-q>", "<cmd>q<cr>")
vim.keymap.set("n", "<Esc>", ":noh<cr><Esc>")
vim.keymap.set("t", "<Esc>", "<c-\\><c-n>")
vim.keymap.set("n", "<leader><leader>", "<c-^>", { desc = "Switch buffer" })
vim.keymap.set("n", "]c", "<cmd>cnext<cr>", { desc = "quickfix next" })
vim.keymap.set("n", "[c", "<cmd>cprevious<cr>", { desc = "quickfix previous" })
vim.keymap.set("n", "<leader>ws", "<cmd>vsplit<cr>", { desc = "split window", noremap = true })
vim.keymap.set("n", "<leader>wS", "<cmd>split<cr>", { desc = "split window down", noremap = true })
vim.keymap.set("n", "<leader>Q", "<cmd>qa!<cr>", { desc = "Quit!" })
vim.keymap.set("n", "<leader>W", "<cmd>wa!<cr>", { desc = "Save all" })
vim.keymap.set('n', 'gK', function()
  local new_config = not vim.diagnostic.config().virtual_lines
  vim.diagnostic.config({ virtual_lines = new_config })
end, { desc = 'Toggle diagnostic virtual_lines' })

vim.keymap.set("v", "<leader>b",
  ':<C-U>!git blame <C-R>=expand("%:p") <CR> | sed -n <C-R>=line("\'<") <CR>,<C-R>=line("\'>") <CR>p <CR>')

vim.keymap.set("n", "<leader>tf", "<cmd>RunTests<CR>", { desc = "Test current file", noremap = true, silent = true })
vim.keymap.set("n", "<leader>tv", "<cmd>TestVisit<CR>", { desc = "Visit last test", noremap = true, silent = true })
vim.keymap.set("n", "<leader>tl", "<cmd>TestLast<CR>", { desc = "Test last file", noremap = true, silent = true })

-- Diagnostic symbols in the sign column (gutter)
local signs = { Error = "■", Warn = "■", Hint = '■', Info = '■' }
for type, _ in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = "", texthl = hl, numhl = "" })
end

-- -- undercurl
-- vim.cmd([[let &t_Cs = "\e[4:3m"]])
-- vim.cmd([[let &t_Ce = "\e[4:0m"]])
-- vim.cmd([[let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"]])
-- vim.cmd([[let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"]])

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  { import = "plugins" },
}, {
  install = {
    colorscheme = { "nord" },
  },
  checker = {
    notify = false,
  },
  change_detection = {
    notify = false,
  },
  dev = {
    path = "~/Code/nvim-plugins"
  }
})
