return {
  { "tpope/vim-sleuth" },
  { "tpope/vim-surround" },
  { "justinmk/vim-sneak" },
  {
    "mbbill/undotree",
    cmd = "UndotreeToggle",
    keys = {
      { "<leader>u", "<cmd>UndotreeToggle<cr>", desc = "toggle undo tree" },
    }
  },
  {
    "AndrewRadev/switch.vim",
    keys = {
      { "<leader>ss", "<cmd>Switch<CR>" }
    },
    config = function()
      vim.cmd([[let g:switch_custom_definitions =
          \ [
          \   {
          \     '^\(.*\)TODO\(.*\)$': '\1DOING\2',
          \     '^\(.*\)DOING\(.*\)$': '\1DONE\2',
          \     '^\(.*\)DONE\(.*\)$': '\1TODO\2',
          \     '^\(.*\)\[ \]\(.*\)$': '\1\[/\]\2',
          \     '^\(.*\)\[/\]\(.*\)$': '\1\[x\]\2',
          \     '^\(.*\)\[x\]\(.*\)$': '\1\[ \]\2',
          \     'it': 'fit',
          \     'fit': 'xit',
          \     'xit': 'it',
          \     'true': 'false',
          \     'false': 'true',
          \     'True': 'False',
          \     'False': 'True',
          \   }
          \ ]
      ]])
    end,
  },
  { "echasnovski/mini.move",      version = '*',     event = "BufRead", opts = {} },
  { "echasnovski/mini.bracketed", version = '*',     event = "BufRead", opts = {} },
  { 'echasnovski/mini.ai',        version = '*',     event = "BufRead", opts = {} },
  { "numToStr/Comment.nvim",      event = "BufRead", opts = {} },
  {
    'saghen/blink.cmp',
    dependencies = {
      'rafamadriz/friendly-snippets',
    },
    version = '*',
    opts = {
      sources = {
        default = { 'lsp', 'snippets', 'path', 'buffer' },
      },
      completion = {
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 300,
        },
      },
    }
  },
  {
    "numToStr/Navigator.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      { "<C-h>", "<cmd>NavigatorLeft<cr>" },
      { "<C-l>", "<cmd>NavigatorRight<cr>" },
      { "<C-k>", "<cmd>NavigatorUp<cr>" },
      { "<C-j>", "<cmd>NavigatorDown<cr>" },
    }
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
  },
  {
    "mfussenegger/nvim-dap",
    enabled = false,
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      "mfussenegger/nvim-dap-python",
    },
    ft = { "python" },
    event = "VeryLazy",
    config = function()
      require("dapui").setup({
        controls = {
          element = "repl",
          enabled = true,
          icons = {
            disconnect = "",
            pause = "",
            play = "",
            run_last = "",
            step_back = "",
            step_into = "",
            step_out = "",
            step_over = "",
            terminate = "",
          },
        },
        element_mappings = {},
        expand_lines = true,
        floating = {
          border = "single",
          mappings = {
            close = { "q", "<Esc>" },
          },
        },
        force_buffers = true,
        icons = {
          collapsed = "",
          current_frame = "",
          expanded = "",
        },
        layouts = {
          {
            elements = {
              {
                id = "scopes",
                size = 0.5,
              },
              {
                id = "breakpoints",
                size = 0.25,
              },
              {
                id = "stacks",
                size = 0.25,
              },
            },
            position = "left",
            size = 40,
          },
          {
            elements = {
              {
                id = "repl",
                size = 0.5,
              },
              {
                id = "console",
                size = 0.5,
              },
            },
            position = "bottom",
            size = 10,
          },
        },
        mappings = {
          edit = "e",
          expand = { "<CR>", "<2-LeftMouse>" },
          open = "o",
          remove = "d",
          repl = "r",
          toggle = "t",
        },
        render = {
          indent = 1,
          max_value_lines = 100,
        },
      })
      local dap, dapui = require("dap"), require("dapui")

      vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError", linehl = "", numhl = "" })

      dap.listeners.before.attach.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.launch.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated.dapui_config = function()
        dapui.close()
      end
      dap.listeners.before.event_exited.dapui_config = function()
        dapui.close()
      end

      -- see: https://github.com/mfussenegger/nvim-dap-python?tab=readme-ov-file#debugpy
      require("dap-python").setup("~/.virtualenvs/debugpy/bin/python")

      vim.keymap.set("n", "<leader>cdu", dapui.toggle, { desc = "toggle dap ui" })
      vim.keymap.set("n", "<F5>", dap.continue, { desc = "continue" })
      vim.keymap.set("n", "<F8>", dap.toggle_breakpoint, { desc = "toggle breakpoint" })
      vim.keymap.set("n", "<F10>", dap.step_over, { desc = "step over" })
      vim.keymap.set("n", "<F11>", dap.step_into, { desc = "step into" })
      vim.keymap.set("n", "<F12>", dap.step_out, { desc = "step out" })
      vim.keymap.set("n", "<leader>cdh", function() require("dap.ui.widgets").hover() end, { desc = "hover" })
      vim.keymap.set("n", "<leader>cdp", function() require("dap.ui.widgets").preview() end, { desc = "preview" })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPre", "BufNewFile" },
    build = ":TSUpdate",
    version = false,
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
      "nvim-treesitter/nvim-tree-docs",
      "windwp/nvim-ts-autotag",
    },
    config = function()
      local treesitter = require("nvim-treesitter.configs")
      treesitter.setup({
        auto_install = true,
        highlight = {
          enable = true,
        },
        indent = { enable = true },
        incremental_selection = { enable = false },
        context_commentstring = {
          enable = true,
        },
        autotag = {
          enable = true,
          enable_rename = true,
          enable_close = true,
          enable_close_on_slash = true,
        },
        tree_docs = { enable = false },
      })
    end,
  }
}
