return {
  { "tpope/vim-sleuth" },
  { "tpope/vim-surround" },
  { "tpope/vim-repeat" },
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
  },
  {
    "Olical/conjure",
    ft = { "clojure" }, -- etc
    lazy = true,
    init = function()
      -- Set configuration options here
      -- Uncomment this to get verbose logging to help diagnose internal Conjure issues
      -- This is VERY helpful when reporting an issue with the project
      -- vim.g["conjure#debug"] = true
      vim.g["conjure#mapping#doc_word"] = "gk"
    end,
    dependencies = {
      "guns/vim-sexp",
      "tpope/vim-sexp-mappings-for-regular-people",
      {
        "PaterJason/cmp-conjure",
        lazy = true,
        config = function()
          local cmp = require("cmp")
          local config = cmp.get_config()
          table.insert(config.sources, { name = "conjure" })
          return cmp.setup(config)
        end,
      }
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
  },
  {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPre", "BufNewFile" },
    build = ":TSUpdate",
    version = false,
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
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
        textobjects = {
          select = {
            lookahead = true,
            keymaps = {
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@class.outer",
              ["ic"] = { query = "@class.inner", desc = "Select inner part of a class region" },
            },
          },
          lsp_interop = {
            enable = true,
            border = 'none',
            floating_preview_opts = {},
            peek_definition_code = {
              ["<leader>df"] = "@function.outer",
              ["<leader>dF"] = "@class.outer",
            },
          },
        }
      })
    end,
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
    },
  },
  {
    'ldelossa/litee.nvim',
    event = "VeryLazy",
    opts = {
      notify = { enabled = false },
      panel = {
        orientation = "bottom",
        panel_size = 10,
      },
    },
    config = function(_, opts) require('litee.lib').setup(opts) end
  },
  {
    'ldelossa/litee-calltree.nvim',
    dependencies = 'ldelossa/litee.nvim',
    event = "VeryLazy",
    opts = {
      on_open = "panel",
      map_resize_keys = false,
    },
    config = function(_, opts) require('litee.calltree').setup(opts) end
  },
}
