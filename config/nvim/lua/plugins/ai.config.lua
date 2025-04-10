local utils = require("utils")

return {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    enabled = utils.is_copilot_enabled,
    config = function()
      require("copilot").setup({
        filetypes = {
          lua = true,
          shell = true,
          sh = true,
          python = true,
          html = true,
          sql = true,
          javascript = true,
          javascriptreact = true,
          typescript = true,
          typescriptreact = true,
          ["*"] = false,
        },
        suggestion = { enabled = false },
        panel = { enabled = false },
        copilot_node_command = utils.is_copilot_enabled() and vim.fn.expand("$HOME") .. "/.nix-profile/bin/node" or nil,
      })
    end,
  },
  {
    "olimorris/codecompanion.nvim",
    config = true,
    enabled = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
  },
  {
    "yetone/avante.nvim",
    enabled = false,
    event = "BufRead",
    version = "*",
    build = "make",
    cmd = { "AvanteAsk", "AvanteChat", "AvanteToggle" },
    opts = {
      provider = "copilot",
      auto_suggestions_provider = nil,
      hints = { enabled = false },
      file_selector = {
        provider = "telescope",
        provider_opts = {},
      },
    },
    dependencies = {
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-telescope/telescope.nvim", -- for file_selector provider telescope
      "nvim-tree/nvim-web-devicons",   -- or echasnovski/mini.icons
      "zbirenbaum/copilot.lua",        -- for providers='copilot'
      {
        "HakonHarnes/img-clip.nvim",
        event = "VeryLazy",
        opts = {
          default = {
            embed_image_as_base64 = false,
            prompt_for_file_name = false,
            drag_and_drop = {
              insert_mode = true,
            },
            -- required for Windows users
            use_absolute_path = true,
          },
        },
      },
      {
        -- Make sure to set this up properly if you have lazy=true
        'MeanderingProgrammer/render-markdown.nvim',
        opts = {
          file_types = { "Avante" },
        },
        ft = { "Avante" },
      },
    },
  },
}
