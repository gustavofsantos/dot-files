return {
  {
    "tpope/vim-fugitive",
    dependencies = { "tpope/vim-rhubarb" },
    event = "VeryLazy",
  },
  {
    "lewis6991/gitsigns.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim",
      "nvim-telescope/telescope.nvim",
    },
    event = "BufRead",
    keys = {
      { "]h", "<cmd>Gitsigns next_hunk<cr>", desc = "Next hunk" },
      { "[h", "<cmd>Gitsigns prev_hunk<cr>", desc = "Previous hunk" },
    },
    config = function()
      require("gitsigns").setup({
        signcolumn = false,
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
  },
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen" },
    opts = {
      view = {
        merge_tool = {
          layout = "diff3_mixed"
        }
      }
    }
  },
}
