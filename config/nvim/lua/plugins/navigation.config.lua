return {
  {
    "gustavofsantos/bookmark-tool.nvim",
    -- dir = "~/Code/nvim-plugins/bookmark-tool.nvim",
    -- dev = true,
    opts = {},
  },
  { -- stevearc/oil.nvim
    "stevearc/oil.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("oil").setup({
        default_file_explorer = true,
        skip_confirm_for_simple_edits = true,
        columns = {},
        view_options = {
          show_hidden = true
        }
      })
    end,
  },
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.8",
    event = "VeryLazy",
    dependencies = {
      "nvim-telescope/telescope-symbols.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
      {
        "nvim-telescope/telescope-frecency.nvim",
        version = "*",
        config = function()
          require("telescope").load_extension("frecency")
        end
      },
      {
        "prochri/telescope-all-recent.nvim",
        dependencies = { "kkharji/sqlite.lua" },
        opts = {},
      }
    },
    config = function()
      local theme = 'ivy'

      local telescope = require("telescope")
      local actions = require('telescope.actions')

      telescope.setup({
        defaults = {
          dynamic_preview_title = true,
          prompt_position = "top",
          prompt_prefix = " ",
          selection_caret = "→ ",
          sorting_strategy = "ascending",
          theme = theme,
          file_ignore_patterns = {
            "%.git/",
            ".git/",
            "node_modules/",
            -- "coverage/",
            "__pycache__/",
          },
          -- layout_strategy = "bottom_pane",
          layout_config = {
            --     vertical = { width = 0.25 },
            height = 0.4,
            prompt_position = "top",
          },
          borderchars = {
            prompt = { " ", " ", " ", " ", " ", " ", " ", " " },
            results = { " " },
            preview = { " " },
          },
          mappings = {
            i = {
              ["<esc>"] = actions.close,
            },
            n = {
              ["<esc>"] = actions.close,
            },
          }
        },
        pickers = {
          find_files = {
            theme = theme,
            previewer = true,
            hidden = true,
          },
          oldfiles = {
            previewer = true,
            hidden = true,
            theme = theme,
          },
          live_grep = {
            previewer = true,
            theme = theme,
          },
          grep_string = {
            previewer = true,
            theme = theme,
            prompt_title = false,
          },
          git_files = {
            previewer = true,
            theme = theme,
          },
          commands = {
            theme = theme,
          },
          current_buffer_fuzzy_find = {
            previewer = true,
            theme = theme,
          },
          lsp_references = {
            previewer = true,
            theme = theme,
          },
          lsp_document_symbols = {
            previewer = true,
            theme = theme,
          },
          lsp_dynamic_workspace_symbols = {
            previewer = true,
            theme = theme,
          },
          diagnostics = {
            previewer = true,
            theme = theme,
            disable_coordinates = true,
            entry_maker = require("cmd_palette.entry_maker").gen_from_diagnostics(),
          },
          buffers = {
            previewer = true,
            theme = "dropdown",
            mappings = {
              i = {
                ["<c-d>"] = require("telescope.actions").delete_buffer,
              },
            },
          },
        },
        extensions = {
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
          },
          frecency = {
            db_safe_mode = false,
          },
        },
      })
    end,
  },
  { -- ThePrimeagen/harpoon
    "ThePrimeagen/harpoon",
    dependencies = { "nvim-lua/plenary.nvim" },
    branch = "harpoon2",
    event = "VeryLazy",
    enable = false,
    config = function()
      local harpoon = require('harpoon')
      harpoon:setup({})
      harpoon:extend({
        UI_CREATE = function(cx)
          vim.keymap.set("n", "<C-s>", function()
            harpoon.ui:select_menu_item({ vsplit = true })
          end, { buffer = cx.bufnr })

          vim.keymap.set("n", "<C-S-s>", function()
            harpoon.ui:select_menu_item({ split = true })
          end, { buffer = cx.bufnr })

          vim.keymap.set("n", "<C-t>", function()
            harpoon.ui:select_menu_item({ tabedit = true })
          end, { buffer = cx.bufnr })
        end,
      })
    end,
    -- keys = {
    --   { "<leader>1",  function() require('harpoon'):list():select(1) end },
    --   { "<leader>2",  function() require('harpoon'):list():select(2) end },
    --   { "<leader>3",  function() require('harpoon'):list():select(3) end },
    --   { "<leader>4",  function() require('harpoon'):list():select(4) end },
    --   { "<leader>ma", function() require('harpoon'):list():add() end,    desc = "Mark file" },
    --   {
    --     "<leader>ml",
    --     function()
    --       local harpoon = require('harpoon')
    --       return harpoon.ui:toggle_quick_menu(harpoon:list())
    --     end,
    --     desc = "List marked files"
    --   },
    -- }
  },
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
  }
}
