return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  branch = vim.fn.has("nvim-0.12") == 1 and "main" or "master",
  lazy = false,
}
