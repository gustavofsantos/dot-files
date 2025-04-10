return {
  { "tpope/vim-sleuth" },
  { "tpope/vim-surround" },
  { "justinmk/vim-sneak" },
  {
    "mbbill/undotree",
    cmd = "UndotreeToggle",
  },
  {
    "AndrewRadev/switch.vim",
    cmd = { "Switch" },
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
  { "echasnovski/mini.ai",        version = '*',     event = "BufRead", opts = {} },
  { "numToStr/Comment.nvim",      event = "BufRead", opts = {} },
  {
    'saghen/blink.cmp',
    enabled = false,
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
