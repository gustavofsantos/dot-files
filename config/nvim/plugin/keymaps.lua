local test = require("gustavo.test")
local set = vim.keymap.set
local n = "n"
local i = "i"
local x = "x"
local o = "o"
local v = "v"
local t = "t"

-- set(n, "]h", "<cmd>Gitsigns next_hunk<cr>", { noremap = true, desc = "Next hunk" })
-- set(n, "[h", "<cmd>Gitsigns prev_hunk<cr>", { noremap = true, desc = "Previous hunk" })

-- Navigation
set(n, "<leader>p", function()
  require("personal-plugins.cmd_palette").open()
end, { desc = "Cmd Palette", noremap = true })
set(n, "<F3>", "<cmd>Telescope grep_string<cr>", { desc = "Find Word", noremap = true })
set(v, "<F3>",
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
  {
    desc = "Find selection"
  })

set(n, "<leader>t", "<cmd>TestFile<cr>", { desc = "Test current file", noremap = true, silent = true })
set(n, "<C-CR>", function() test.run_tests(vim.fn.expand('%:p')) end,
  { desc = "Run tests for current file", noremap = true, silent = true })
