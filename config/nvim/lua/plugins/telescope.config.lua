local utils = require("utils")

return {
  "nvim-telescope/telescope.nvim",
  tag = "0.1.8",
  lazy = true,
  event = "VeryLazy",
  keys = {
    { "<leader>o", "<cmd>Telescope find_files<CR>",                desc = "Find files" },
    { "<leader>b", "<cmd>Telescope buffers<CR>",                   desc = "Find buffer" },
    { "<leader>l", "<cmd>Telescope live_grep<CR>",                 desc = "Live grep" },
    { "<leader>f", "<cmd>Telescope current_buffer_fuzzy_find<CR>", desc = "Buffer fuzzy find" },
    { "<C-p>",     "<cmd>Telescope find_files<CR>",                desc = "Find files" },
    { "<C-f>",     "<cmd>Telescope current_buffer_fuzzy_find<CR>", desc = "Fuzzy find buffer" },
    { "<F3>",      "<cmd>Telescope grep_string<cr>",               desc = "Find Word" },
    {
      "<F3>",
      function()
        local selection = utils.get_current_visual_selection()
        vim.cmd("Telescope grep_string default_text=" .. selection)
      end,
      mode = { "v" },
      desc = "Find selection"
    }

    -- set(v, "<F3>", '"zy:Telescope grep_string default_text=<C-r>z<cr>',
    --   { noremap = true, silent = true, desc = "Find Selected" })
  },
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
}
