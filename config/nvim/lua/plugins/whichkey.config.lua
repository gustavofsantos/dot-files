return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      local wk = require("which-key")
      wk.setup({})

      wk.add({
        { "<leader>d", group = "Diff" },
        { "<leader>q", group = "Query" },
        { "<leader>t", group = "Test" },
        { "<leader>v", group = "Version Control" }
      })
    end,
  }
