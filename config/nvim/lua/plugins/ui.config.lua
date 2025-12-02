return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      local wk = require("which-key")
      wk.setup({})

      wk.add({
        { "<leader>q", group = "Query" },
        { "<leader>t", group = "Test" },
        { "<leader>v", group = "Version Control" }
      })
    end,
  },
  {
    'nvim-lualine/lualine.nvim',
    config = function()
      local overseer = require("overseer")
      require('lualine').setup({
        sections = {
          lualine_a = { 'mode' },
          lualine_b = {},
          lualine_c = { { 'filename', path = 1 } },
          lualine_x = {
            {
              "overseer",
              label = "",     -- Prefix for task counts
              colored = true, -- Color the task icons and counts
              symbols = {
                [overseer.STATUS.FAILURE] = "F:",
                [overseer.STATUS.CANCELED] = "C:",
                [overseer.STATUS.SUCCESS] = "S:",
                [overseer.STATUS.RUNNING] = "R:",
              },
              unique = false, -- Unique-ify non-running task count by name
              status = nil,   -- List of task statuses to display
              filter = nil,   -- Function to filter out tasks you don't wish to display
            },
            'lsp_status',
            'diagnostics' },
          lualine_y = { 'progress' },
          lualine_z = { 'location' }
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = { { 'filename', path = 1 } },
          lualine_x = {
            {
              "overseer",
              label = "",     -- Prefix for task counts
              colored = true, -- Color the task icons and counts
              symbols = {
                [overseer.STATUS.FAILURE] = "F:",
                [overseer.STATUS.CANCELED] = "C:",
                [overseer.STATUS.SUCCESS] = "S:",
                [overseer.STATUS.RUNNING] = "R:",
              },
              unique = false, -- Unique-ify non-running task count by name
              status = nil,   -- List of task statuses to display
              filter = nil,   -- Function to filter out tasks you don't wish to display
            },
            'location' },
          lualine_y = {},
          lualine_z = {}
        },
      })
    end
  },
  {
    'stevearc/quicker.nvim',
    event = "FileType qf",
    ---@module "quicker"
    ---@type quicker.SetupOptions
    opts = {
      keys = {
        {
          ">",
          function()
            require("quicker").expand({ before = 2, after = 2, add_to_existing = true })
          end,
          desc = "Expand quickfix context",
        },
        {
          "<",
          function()
            require("quicker").collapse()
          end,
          desc = "Collapse quickfix context",
        },
      },
    },
  },
  {
    "echasnovski/mini.hipatterns",
    event = "BufRead",
    config = function()
      local hipatterns = require("mini.hipatterns")
      hipatterns.setup({
        highlighters = {
          hex_color = hipatterns.gen_highlighter.hex_color(),
        },
      })
    end,
  }
}
