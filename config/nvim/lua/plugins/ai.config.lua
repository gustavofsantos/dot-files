local is_copilot_enabled = function()
  return os.getenv("IS_COPILOT_ENABLED") == "1"
end

return {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    enabled = is_copilot_enabled,
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
        suggestion = {
          enabled = true,
          auto_trigger = true,
          debounce = 200,
          hide_during_completion = true,
          keymap = {
            accept = "<M-l>",
            accept_word = false,
            accept_line = false,
            next = "<M-]>",
            prev = "<M-[>",
            dismiss = "<C-]>",
          },
        },
        panel = {
          enabled = true,
          auto_refresh = true,
          keymap = {
            jump_prev = "[[",
            jump_next = "]]",
            accept = "<CR>",
            refresh = "gr",
            open = "<C-space>"
          },
        },
        copilot_node_command = is_copilot_enabled() and vim.fn.expand("$HOME") .. "/.nix-profile/bin/node" or nil,
      })
    end,
  },
  {
    "yetone/avante.nvim",
    enabled = is_copilot_enabled,
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
