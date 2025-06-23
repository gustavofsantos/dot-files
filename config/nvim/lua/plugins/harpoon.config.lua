return {
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
}
