return {
  "lewis6991/gitsigns.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "sindrets/diffview.nvim",
    "nvim-telescope/telescope.nvim",
  },
  keys = {
    { "]h", "<cmd>Gitsigns next_hunk<cr>", desc = "Next hunk" },
    { "[h", "<cmd>Gitsigns prev_hunk<cr>", desc = "Previous hunk" },
    { "<leader>ghp", "<cmd>Gitsigns preview_hunk<cr>", desc = "Preview hunk"}
  },
  event = "BufRead",
  config = function()
    require("gitsigns").setup({
      signcolumn = true,
      numhl = false,
      linehl = false,
      attach_to_untracked = false,
      current_line_blame = false,
      current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d>",
      signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "▎" },
        topdelete = { text = "▎" },
        changedelete = { text = "▎" },
        untracked = { text = "░" },
      },
      signs_staged = {
        add          = { text = '░' },
        change       = { text = '░' },
        delete       = { text = '░' },
        topdelete    = { text = '░' },
        changedelete = { text = '░' },
        untracked    = { text = '░' },
      },
    })
  end,
}
