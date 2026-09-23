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
      previewer = false,
      hidden = true,
    },
    oldfiles = {
      previewer = false,
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

  -- Custom previewer for terminal buffers
  local function terminal_previewer()
    local previewers = require("telescope.previewers")

    return previewers.new_buffer_previewer({
      title = "Terminal Preview",
      define_preview = function(self, entry, status)
        local bufnr = entry.value

        -- Check if it's a terminal buffer
        local buftype = vim.api.nvim_buf_get_option(bufnr, "buftype")
        if buftype == "terminal" then
          -- Get terminal buffer content
          local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

          -- Process lines to remove/replace problematic characters
          local processed_lines = {}
          for _, line in ipairs(lines) do
            -- Strip ANSI escape codes (basic implementation)
            line = line:gsub("\27%[[0-9;]*[mGK]", "") -- Remove color codes
            line = line:gsub("\27%[[0-9;]*[Hf]", "") -- Remove cursor movement
            line = line:gsub("\27%[[0-9;]*[A-D]", "") -- Remove cursor positioning
            line = line:gsub("\27%[[0-9]*J", "") -- Remove screen clearing
            line = line:gsub("\27%[[0-9]*K", "") -- Remove line clearing
            -- Replace other control characters with readable equivalents
            line = line:gsub("\r", "↵") -- Carriage return
            line = line:gsub("\t", "    ") -- Tab
            table.insert(processed_lines, line)
          end

          -- Set the processed content in the preview buffer
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, processed_lines)

          -- Set filetype for better syntax highlighting
          vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", "text")
        else
          -- Fallback for non-terminal buffers (shouldn't happen in this picker)
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, { "Not a terminal buffer" })
        end
      end,
    })
  end

  pickers.new({}, {
    prompt_title = "Terminal Buffers",
    theme = theme,
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
    previewer = terminal_previewer(),
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

require("telescope-all-recent").setup({})

vim.keymap.set("n", "<leader>o", "<cmd>Telescope find_files<CR>", { desc = "Find files" })
vim.keymap.set("n", "<leader>b", "<cmd>Telescope buffers<CR>", { desc = "Find buffer" })
vim.keymap.set("n", "<leader>e", "<cmd>Telescope oldfiles only_cwd=true<CR>", { desc = "Recent files" })
vim.keymap.set("n", "<leader>f", "<cmd>Telescope current_buffer_fuzzy_find<CR>", { desc = "Fuzzy find current buffer" })
vim.keymap.set("n", "<leader>l", "<cmd>Telescope live_grep<CR>", { desc = "Fuzzy find project" })
vim.keymap.set("n", "<leader>h", "<cmd>Telescope help_tags<CR>", { desc = "Help" })
vim.keymap.set("n", "<F3>", "<cmd>Telescope grep_string<cr>", { desc = "Find Word" })
vim.keymap.set("v", "<F3>", function()
  local selection = require("utils").get_current_visual_selection()
  vim.cmd("Telescope grep_string default_text=" .. selection)
end, { desc = "Find selection" })
