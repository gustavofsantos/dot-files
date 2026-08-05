return {
  "nvim-treesitter/nvim-treesitter",
  dependencies = {
    {
      "nvim-treesitter/nvim-treesitter-context",
      event = "BufReadPre",
      opts = {
        max_lines = 3,    -- How many lines the sticky context can take up
        trim_scope = "outer", -- Collapse context lines if they exceed max_lines
      }
    }
  },
  build = ":TSUpdate",
  branch = vim.fn.has("nvim-0.12") == 1 and "main" or "master",
  lazy = false,
}
