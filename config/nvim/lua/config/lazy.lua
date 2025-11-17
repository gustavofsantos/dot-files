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
  spec = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "christoomey/vim-tmux-runner",
    "tpope/vim-sleuth",
    "tpope/vim-surround",
    "tpope/vim-repeat",
    "tpope/vim-dotenv",
    "mbbill/undotree",
    { import = "plugins" }
  },
  install = {
    colorscheme = { "alabaster" },
  },
  checker = {
    notify = false,
  },
  change_detection = {
    notify = false,
  }
})
