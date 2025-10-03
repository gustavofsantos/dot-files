return {
  "nvim-telescope/telescope.nvim",
  tag = "0.1.8",
  cmd = "Telescope",
  keys = {
    { "<leader>o", "<cmd>Telescope find_files<CR>",                desc = "Find files" },
    { "<leader>b", "<cmd>Telescope buffers<CR>",                   desc = "Find buffer" },
    { "<leader>e", "<cmd>Telescope oldfiles only_cwd=true<CR>",    desc = "Recent files" },
    { "<leader>f", "<cmd>Telescope current_buffer_fuzzy_find<CR>", desc = "Fuzzy find current buffer" },
    { "<leader>l", "<cmd>Telescope live_grep<CR>",                 desc = "Fuzzy find" },
    { "<leader>h", "<cmd>Telescope help_tags<CR>",                 desc = "Help" },
    { "<F3>",      "<cmd>Telescope grep_string<cr>",               desc = "Find Word" },
    {
      "<F3>",
      function()
        local function get_current_visual_selection()
          local selected_text = ""
          local temp_reg = "z"
          local old_reg_content = vim.fn.getreg(temp_reg)
          local old_reg_type = vim.fn.getregtype(temp_reg)

          vim.cmd('normal! "' .. temp_reg .. 'y')

          selected_text = vim.fn.getreg(temp_reg, true)

          vim.fn.setreg(temp_reg, old_reg_content, old_reg_type)

          return selected_text
        end
        local selection = get_current_visual_selection()
        vim.cmd("Telescope grep_string default_text=" .. selection)
      end,
      mode = "v",
      desc = "Find selection"
    }
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
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local sorters = require("telescope.sorters")
    local action_state = require("telescope.actions.state")

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

    local function terminals()
      local bufs = vim.api.nvim_list_bufs()
      local results = {}
      for _, buf in ipairs(bufs) do
        local name = vim.api.nvim_buf_get_name(buf)
        if name:match('^term://') then
          table.insert(results, { buf = buf, name = name })
        end
      end

      pickers.new({}, {
        prompt_title = "Terminal Buffers",
        finder = finders.new_table {
          results = results,
          entry_maker = function(entry)
            return {
              value = entry.buf,
              display = entry.name,
              ordinal = entry.name,
            }
          end,
        },
        sorter = sorters.get_generic_fuzzy_sorter(),
        attach_mappings = function(prompt_bufnr, map)
          actions.select_default:replace(function()
            actions.close(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            vim.api.nvim_set_current_buf(selection.value)
          end)
          return true
        end,
      }):find()
    end

    vim.keymap.set("n", "<leader>T", terminals, { desc = "Terminal buffers" })
  end,
}
