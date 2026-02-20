return {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen" },
    keys = {
      { "<leader>dvc", "<cmd>DiffviewClose<cr>", desc = "Close diff view" }
    },
    opts = {
      view = {
        merge_tool = {
          layout = "diff3_mixed"
        }
      }
    },
  }
