return {
  "tpope/vim-fugitive",
  "tpope/vim-rhubarb",
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen" },
    opts = {
      view = {
        merge_tool = {
          layout = "diff3_mixed"
        }
      }
    },
  },
  {
    "lewis6991/gitsigns.nvim",
    keys = {
      { "]h",           "<cmd>Gitsigns next_hunk<cr>",        desc = "Next hunk" },
      { "[h",           "<cmd>Gitsigns prev_hunk<cr>",        desc = "Previous hunk" },
      { "<leader>ghp",  "<cmd>Gitsigns preview_hunk<cr>",     desc = "Preview hunk" },
      { "<leader>ghr",  "<cmd>Gitsigns reset_hunk<cr>",       desc = "Reset hunk" },
      { "<leader>ghtl", "<cmd>Gitsigns toggle_linehl<cr>",    desc = "Toggle line highlight" },
      { "<leader>ghtw", "<cmd>Gitsigns toggle_word_diff<cr>", desc = "Toggle word diff" },
      { "<leader>ghdt", "<cmd>Gitsigns diffthis<cr>",         desc = "Diff this" }
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
}
