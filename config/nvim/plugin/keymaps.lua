local set = vim.keymap.set
local n = "n"
local i = "i"
local x = "x"
local o = "o"
local v = "v"
local t = "t"

set(n, "Q", "<Nop>")
set(n, "<c-s>", "<cmd>w<cr>")
set(i, "<c-c>", "<Esc>")
set(n, "<c-q>", "<cmd>q<cr>")
set(n, "<Esc>", ":noh<cr><Esc>")
set(t, "<Esc>", "<c-\\><c-n>")
set(n, "<leader><leader>", "<c-^>", { desc = "Switch buffer" })
set(n, "]c", "<cmd>cnext<cr>", { desc = "quickfix next" })
set(n, "[c", "<cmd>cprevious<cr>", { desc = "quickfix previous" })
set(n, "<leader>ws", "<cmd>vsplit<cr>", { desc = "split window", noremap = true })
set(n, "<leader>wS", "<cmd>split<cr>", { desc = "split window down", noremap = true })
set(n, "<leader>Q", "<cmd>qa!<cr>", { desc = "Quit!" })
set(n, "<leader>W", "<cmd>wa!<cr>", { desc = "Save all" })

set(n, "<C-h>", "<cmd>NavigatorLeft<cr>")
set(n, "<C-l>", "<cmd>NavigatorRight<cr>")
set(n, "<C-k>", "<cmd>NavigatorUp<cr>")
set(n, "<C-j>", "<cmd>NavigatorDown<cr>")

set(v, "<leader>b",
  ':<C-U>!git blame <C-R>=expand("%:p") <CR> | sed -n <C-R>=line("\'<") <CR>,<C-R>=line("\'>") <CR>p <CR>')

set(n, "]h", "<cmd>Gitsigns next_hunk<cr>", { noremap = true, desc = "Next hunk" })
set(n, "[h", "<cmd>Gitsigns prev_hunk<cr>", { noremap = true, desc = "Previous hunk" })

set(n, "<leader>u", "<cmd>UndotreeToggle<cr>", { desc = "Undo tree" })

-- Navigation
set(n, "-", "<cmd>Oil<CR>", { noremap = true, desc = "File explorer" })
set(n, "<leader>o", "<cmd>Telescope find_files<CR>", { desc = "Find files" })
set(n, "<leader>b", "<cmd>Telescope buffers<CR>", { desc = "Find buffer", noremap = true })
set(n, "<leader>e", "<cmd>Telescope oldfiles only_cwd=true<CR>", { desc = "Recent files", noremap = true, silent = true })
set(n, "<leader>f", "<cmd>Telescope current_buffer_fuzzy_find<CR>", { desc = "Buffer fuzzy find", noremap = true })
set(n, "<leader>lg", "<cmd>Telescope live_grep<CR>", { desc = "Live grep", noremap = true })
set(n, "<leader>lt", "<cmd>LiveGrepTests<CR>", { desc = "Live grep in test files", noremap = true })
set(n, "<leader>ls", "<cmd>LiveGrepNonTests<CR>", { desc = "Live grep in source files", noremap = true })
set(n, "<leader>h", "<cmd>Telescope help_tags<CR>", { desc = "Help", noremap = true })
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

set({ n, x, o }, "s", function() require("flash").jump() end, { desc = "Flash", noremap = true })
set({ n, x, o }, "S", function() require("flash").treesitter() end, { desc = "Flash Treesitter", noremap = true })

set(n, "<leader>ss", "<cmd>Switch<CR>", { noremap = true, desc = "Switch" })

set('n', '<C-CR>', '<cmd>OverseerRunLast<CR>', { silent = true, desc = "Rerun last Overseer task" })
set('n', '<localleader>ot', '<cmd>OverseerToggle<CR>', { silent = true, desc = "Toggle Overseer" })

-- LSP
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
  callback = function(ev)
    set(n, "K", function() vim.lsp.buf.hover({ max_width = 60 }) end, { buffer = ev.buf, desc = "Hover" })
    set(n, "grd", vim.lsp.buf.definition, { buffer = ev.buf, desc = "Go to definition" })
    set(n, "gf", "<cmd>Format<cr>", { buffer = ev.buf, desc = "Format async" })
    -- local client = vim.lsp.get_client_by_id(ev.data.client_id)
    -- if client then
    --   client.server_capabilities.semanticTokensProvider = nil
    -- end
  end,
})
