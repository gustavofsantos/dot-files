return {
  { "windwp/nvim-autopairs", event = "InsertEnter", opts = { enable_check_bracket_line = false } },
  { "kevinhwang91/nvim-bqf", filetypes = { "qf" } },
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "neovim/nvim-lspconfig",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "onsails/lspkind.nvim",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip"
    },
    config = function()
      local cmp = require("cmp")
      local lspkind = require('lspkind')
      local cmp_mappings = {
        ["<C-d>"] = cmp.mapping.scroll_docs(-4),
        ["<C-u>"] = cmp.mapping.scroll_docs(4),
        ["<C-c>"] = cmp.mapping.close(),
        ["<C-space>"] = cmp.mapping.complete(),
        ["<C-y>"] = cmp.mapping.confirm({ select = true }),
        ["<C-p>"] = cmp.mapping.select_prev_item(),
        ["<C-n>"] = cmp.mapping.select_next_item(),
      }

      lspkind.init({
        symbol_map = {
          Copilot = "",
        },
      })

      cmp.setup({
        completion = {
          completeopt = "menu,menuone,noinsert",
        },
        snippet = {
          expand = function(args)
            require("luasnip").lsp_expand(args.body)
          end,
        },
        formatting = {
          format = lspkind.cmp_format({
            mode = "symbol",
          }),
        },
        window = {
          documentation = cmp.config.window.bordered({
            scrolloff = 2,
            side_padding = 2,
            max_height = 10,
            max_width = 80,
          }),
        },
        mapping = cmp_mappings,
        performance = {
          max_view_entries = 25,
        },
        sources = {
          { name = "nvim_lsp" },
          { name = "luasnip",  keyword_length = 2, max_item_count = 5 },
          { name = "nvim_lua", keyword_length = 2, max_item_count = 4 },
          { name = "path",     keyword_length = 3, max_item_count = 5 },
          { name = "buffer",   keyword_length = 5, max_item_count = 3 },
        },
      })
    end
  },
  {
    "L3MON4D3/LuaSnip",
    version = "v2.*",
  },
  {
    "rebelot/kanagawa.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      local utils = require("utils")
      require("kanagawa").setup({
        dimInactive = false,
        globalStatus = true,
        commentStyle = { italic = true },
        functionStyle = { italic = false },
        keywordStyle = { italic = false },
        statementStyle = { italic = false },
        typeStyle = { italic = true },
        variablebuiltinStyle = { italic = false },
        transparent = utils.is_transparent_background_enabled(),
        background = {
          dark = "wave",
          light = "lotus",
        },
        colors = {
          theme = {
            all = {
              ui = {
                bg_gutter = "none",
              },
            },
          },
        },
        overrides = function(colors)
          -- only override the colors if the background is not light
          if vim.o.background == "light" then
            return {}
          end

          return {
            Constant = { fg = colors.palette.fujiWhite },

            StatusLine = { bg = colors.palette.sumiInk4 },
            StatusLineNC = { bg = colors.palette.sumiInk2 },
            ColorColumn = { bg = colors.palette.sumiInk2 },

            -- CursorLine = { bg = "NONE" },
            -- CursorLineSign = { bg = "#000000" },
            -- CursorLineNr = { bg = "#000000"},

            -- DiagnosticWarn = { link = "LineNr" },
            -- DiagnosticInfo = { link = "LineNr" },
            -- DiagnosticHint = { link = "LineNr" },
            -- DiagnosticSignWarn = { link = "LineNr" },
            -- DiagnosticSignInfo = { link = "LineNr" },
            -- DiagnosticSignHint = { link = "LineNr" },

            TelescopeTitle = { fg = colors.theme.ui.special, bold = true },
            TelescopePromptNormal = { bg = colors.theme.ui.bg_p1 },
            TelescopePromptBorder = { fg = colors.theme.ui.bg_p1, bg = colors.theme.ui.bg_p1 },
            TelescopeResultsNormal = { fg = colors.theme.ui.fg_dim, bg = colors.theme.ui.bg_m1 },
            TelescopeResultsBorder = { fg = colors.theme.ui.bg_m1, bg = colors.theme.ui.bg_m1 },
            TelescopePreviewNormal = { bg = colors.theme.ui.bg_dim },
            TelescopePreviewBorder = { bg = colors.theme.ui.bg_dim, fg = colors.theme.ui.bg_dim },

            Pmenu = { fg = colors.theme.ui.shade0, bg = colors.theme.ui.bg_p1 }, -- add `blend = vim.o.pumblend` to enable transparency
            PmenuSel = { fg = "NONE", bg = colors.theme.ui.bg_p2 },
            PmenuSbar = { bg = colors.theme.ui.bg_m1 },
            PmenuThumb = { bg = colors.theme.ui.bg_p2 },

            ["@type"] = { italic = false, bold = true },
            ["@tag"] = { italic = false },
            ["@tag.delimiter"] = { fg = colors.palette.sumiInk6 },
            ["@tag.attribute"] = { italic = true },
            ["@punctuation.bracket"] = { fg = colors.palette.sumiInk6 },
            ["@conditional.ternary"] = { fg = colors.palette.oniViolet, italic = false },
            ["@string.documentation.python"] = { link = "Comment" },
          }
        end,
      })
    end,
  },
  'maxmx03/solarized.nvim',
  'datsfilipe/vesper.nvim',
  { "numToStr/Comment.nvim",      event = "BufRead", opts = {} },
  {
    "stevearc/conform.nvim",
    config = function()
      vim.g.disable_autoformat = true
      local conform = require("conform")
      conform.setup({
        formatters_by_ft = {
          lua = { "stylua" },
          python = { "isort", "black" },
          javascript = { "deno_fmt", "prettierd", "prettier", "eslint_d", "eslint" },
          typescript = { "deno_fmt", "prettierd", "prettier", "eslint_d", "eslint" },
          javascriptreact = { "prettierd", "prettier", "eslint_d", "eslint" },
          typescriptreact = { "prettierd", "prettier", "eslint_d", "eslint" },
        },
        format_on_save = function(bufnr)
          -- Disable with a global or buffer-local variable
          if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
            return
          end
          return { timeout_ms = 500, lsp_fallback = true }
        end,
      })

      vim.api.nvim_create_user_command("Format", function(args)
        local range = nil
        if args.count ~= -1 then
          local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
          range = {
            start = { args.line1, 0 },
            ["end"] = { args.line2, end_line:len() },
          }
        end
        require("conform").format({ async = true, lsp_format = "fallback", range = range })
      end, { range = true })

      vim.api.nvim_create_user_command("FormatDisable", function(args)
        if args.bang then
          vim.b.disable_autoformat = true
        else
          vim.g.disable_autoformat = true
        end
      end, {
        desc = "Disable autoformat-on-save",
        bang = true,
      })

      vim.api.nvim_create_user_command("FormatEnable", function()
        vim.b.disable_autoformat = false
        vim.g.disable_autoformat = false
      end, {
        desc = "Re-enable autoformat-on-save",
      })

      vim.api.nvim_create_user_command("FormatToggle", function()
        if vim.g.disable_autoformat then
          vim.g.disable_autoformat = false
        else
          vim.g.disable_autoformat = true
        end
      end, {
        desc = "Toggle autoformat-on-save",
      })
    end,
  },
  {
    "Olical/conjure",
    ft = { "clojure" },
    lazy = true,
    init = function()
      vim.g['conjure#extract#tree_sitter#enabled'] = true
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
      },
      {
        "julienvincent/nvim-paredit",
        config = function()
          require("nvim-paredit").setup()
        end
      }
    },
  },
  {
    "tpope/vim-dadbod",
    dependencies = {
      { "kristijanhusak/vim-dadbod-ui",         lazy = true },
      { "kristijanhusak/vim-dadbod-completion", ft = { 'sql', 'mysql', 'plsql' }, lazy = true },
    },
    cmd = {
      'DBUI',
      'DBUIToggle',
      'DBUIAddConnection',
      'DBUIFindBuffer',
    },
    config = function()
      vim.g.db_ui_use_nerd_fonts = 1
      vim.g.db_ui_save_location = '~/Documents/dadbod/'
    end
  },

  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen" },
    opts = {
      view = {
        merge_tool = {
          layout = "diff3_mixed"
        }
      }
    },
  },
  {
    "stevearc/dressing.nvim",
    dependencies = { "nvim-telescope/telescope.nvim" },
    opts = {
      select = {
        telescope = require("telescope.themes").get_cursor(),
      },
    },
  },
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    ---@type Flash.Config
    opts = {},
    keys = {
      { "s", function() require("flash").jump() end,       desc = "Flash",            mode = { "n", "x", "o" }, noremap = true, silent = true },
      { "S", function() require("flash").treesitter() end, desc = "Flash Treesitter", mode = { "n", "x", "o" }, noremap = true, silent = true },
    }
  },
  {
    "tpope/vim-fugitive",
    dependencies = { "tpope/vim-rhubarb" },
    event = "VeryLazy",
  },
  {
    "lewis6991/gitsigns.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim",
      "nvim-telescope/telescope.nvim",
    },
    keys = {
      { "]h", "<cmd>Gitsigns next_hunk<cr>", noremap = true, desc = "Next hunk" },
      { "[h", "<cmd>Gitsigns prev_hunk<cr>", noremap = true, desc = "Previous hunk" }
    },
    event = "BufRead",
    config = function()
      require("gitsigns").setup({
        signcolumn = true,
        numhl = false,
        linehl = false,
        attach_to_untracked = false,
        current_line_blame = false,
        current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d>",
        signs = {
          add = { text = "▎" },
          change = { text = "▎" },
          delete = { text = "▎" },
          topdelete = { text = "▎" },
          changedelete = { text = "▎" },
          untracked = { text = "░" },
        },
        signs_staged = {
          add          = { text = '░' },
          change       = { text = '░' },
          delete       = { text = '░' },
          topdelete    = { text = '░' },
          changedelete = { text = '░' },
          untracked    = { text = '░' },
        },
      })
    end,
  },
  {
    "mfussenegger/nvim-lint",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      local lint = require("lint")
      lint.linters_by_ft = {
        markdown = { "vale" },
        python = { "mypy", "flake8", "ruff" },
        javascript = { "eslint_d" },
        javascriptreact = { "eslint_d" },
        typescript = { "deno", "eslint_d" },
        typescriptreact = { "deno", "eslint_d" },
      }

      vim.api.nvim_create_user_command("Lint", function()
        lint.try_lint()
      end, {
        desc = "Lint current buffer",
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    event = { "BufEnter", "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      {
        "folke/lazydev.nvim",
        ft = "lua",
        opts = {
          library = {
            { path = "${3rd}/luv/library", words = { "vim%.uv" } }
          }
        }
      },
      {
        'dnlhc/glance.nvim',
        cmd = 'Glance',
        opts = {
          hooks = {
            before_open = function(results, open, jump, method)
              if #results == 1 then
                jump(results[1])
              else
                open(results)
              end
            end,
          }
        }
      },
      "hrsh7th/nvim-cmp",
      "b0o/schemastore.nvim",
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      local mason = require("mason")
      local mason_lspconfig = require("mason-lspconfig")
      local capabilities = require("cmp_nvim_lsp").default_capabilities()
      local function toggle_diagnostic_lines()
        local _1_
        if vim.diagnostic.config().virtual_lines then
          _1_ = false
        else
          _1_ = { current_line = true }
        end
        return vim.diagnostic.config({ virtual_lines = _1_ })
      end

      local function toggle_diagnostic_text()
        return vim.diagnostic.config({ virtual_text = not vim.diagnostic.config().virtual_text })
      end

      mason.setup()
      mason_lspconfig.setup({
        automatic_enable = true,
        ensure_installed = {
          "lua_ls",
          "vtsls",
          "pyright",
          "dockerls",
          "sqlls",
          "docker_compose_language_service",
          "vimls",
          "bashls",
        },
      })

      vim.lsp.config("*", { capabilities = capabilities })

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
        callback = function(ev)
          vim.keymap.set("n", "gd", '<cmd>Glance definitions<CR>', { buffer = ev.buf, desc = "Definition" })
          vim.keymap.set("n", "gi", '<cmd>Glance implementations<CR>', { buffer = ev.buf, desc = "Implementation" })
          vim.keymap.set("n", "gr", vim.lsp.buf.rename, { buffer = ev.buf, desc = "Rename symbol" })
          vim.keymap.set("n", "gR", '<cmd>Glance references<CR>', { buffer = ev.buf, desc = "References" })
          vim.keymap.set("n", "g.", vim.lsp.buf.code_action, { buffer = ev.buf, desc = "Code actions" })
          vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = ev.buf, desc = "Hover" })
          vim.keymap.set("n", "gf", "<cmd>Format<cr>", { buffer = ev.buf, desc = "Format async" })
          vim.keymap.set("n", "<leader>so", vim.lsp.buf.outgoing_calls,
            { noremap = true, silent = true, desc = "Symbol outgoing calls" })
          vim.keymap.set("n", "<leader>si", vim.lsp.buf.incoming_calls,
            { noremap = true, silent = true, desc = "Symbol incoming calls" })
          vim.keymap.set("n", "g@", "<cmd>Telescope lsp_document_symbols<cr>",
            { noremap = true, silent = true, desc = "Document symbols" })
          vim.keymap.set("n", "g#", "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>",
            { noremap = true, silent = true, desc = "Workspace symbols" })

          vim.keymap.set("n", "<leader>tdl", toggle_diagnostic_lines, { desc = "Toggle diagnostic virtual lines." })
          vim.keymap.set("n", "<leader>tdt", toggle_diagnostic_text, { desc = "Toggle diagnostic virtual text." })
        end,
      })
    end,
  },

  {
    "nvim-lualine/lualine.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
      "arkav/lualine-lsp-progress"
    },
    enable = false,
    config = function()
      require("lualine").setup({
        options = {
          globalstatus = false,
          section_separators = "",
          component_separators = { left = '', right = '' },
        },
        sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = {
            { "filename", path = 1 },
            "searchcount",
          },
          lualine_x = {
            {
              "diagnostics",
              colored = true,
              sources = { "nvim_diagnostic" },
              sections = { 'error', 'warn' },
              symbols = { error = "■ ", warn = "■ ", hint = "■ ", info = "■ " },
            },
            { "filetype", colored = true, icon_only = true },
            "location",
          },
          lualine_y = { "lsp_status", "lsp_progress" },
          lualine_z = {},
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = {
            { "filename", path = 1 },
          },
          lualine_x = {
            { "filetype", colored = true, icon_only = true },
          },
          lualine_y = {},
          lualine_z = {},
        },
        extensions = {
          "quickfix",
          "oil",
          "lazy",
          "neo-tree",
          "fugitive",
          "toggleterm",
        },
      })
    end,
  },

  { "echasnovski/mini.ai",        version = '*',     event = "BufRead", opts = {} },
  { "echasnovski/mini.bracketed", version = '*',     event = "BufRead", opts = {} },
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
  { "echasnovski/mini.move", version = '*', event = "BufRead", opts = {} },
  {
    "numToStr/Navigator.nvim",
    lazy = true,
    event = "VeryLazy",
    opts = {},
    keys = {
      { "<C-h>", "<cmd>NavigatorLeft<cr>" },
      { "<C-l>", "<cmd>NavigatorRight<cr>" },
      { "<C-k>", "<cmd>NavigatorUp<cr>" },
      { "<C-j>", "<cmd>NavigatorDown<cr>" },
    }
  },
  "tpope/vim-sleuth",
  "tpope/vim-surround",
  "tpope/vim-repeat",
  {
    "stevearc/oil.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("oil").setup({
        default_file_explorer = true,
        skip_confirm_for_simple_edits = true,
        columns = {},
        view_options = {
          show_hidden = true
        }
      })
    end,
  },
  {
    "AndrewRadev/switch.vim",
    cmd = { "Switch" },
    keys = {
      { "<leader>ss", "<cmd>Switch<CR>", noremap = true, silent = true, desc = "Switch" }
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
  {
    "akinsho/toggleterm.nvim",
    dependencies = {},
    version = "*",
    event = "BufEnter",
    config = function()
      require("toggleterm").setup({
        size = function(term)
          if term.direction == "horizontal" then
            return 15
          elseif term.direction == "vertical" then
            return vim.o.columns * 0.5
          end
        end,
        open_mapping = [[<c-t>]],
        insert_mappings = true,
        terminal_mappings = true,
        persist_size = true,
        persist_mode = true,
        shade_terminals = false,
        start_in_insert = true,
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
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "gnn",
            node_incremental = "grn",
            scope_incremental = "grc",
            node_decremental = "grm",
          },
        },
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


      vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
    end,
  },
  {
    "mbbill/undotree",
    lazy = true,
    event = "VeryLazy",
    cmd = "UndotreeToggle",
    keys = {
      { "<leader>ut", "<cmd>UndotreeToggle<cr>", desc = "Undo tree" }
    }
  },
  {
    "vim-test/vim-test",
    enabled = true,
    dependencies = { "christoomey/vim-tmux-runner" },
    cmd = { "TestFile", "TestNearest", "TestSuite", "TestLast" },
    config = function()
      -- if vim.env.TMUX then
      --   vim.cmd([[let test#strategy = "vtr"]])
      -- else
      --   vim.cmd([[let test#strategy = "toggleterm"]])
      -- end
      vim.cmd([[let test#strategy = "toggleterm"]])
      vim.cmd([[let test#javascript#playwright#options = "--headed --retries 0 --workers 1"]])
      vim.cmd([[let test#clojure#runner = "leintest"]])
      vim.cmd([[let test#clojure#leintest#executable = "lein with-profile test midje"]])
      vim.cmd([[let test#clojure#leintest#options = ""]])
    end,
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
    },
  },

  {
    "gustavofsantos/bookmark-tool.nvim",
    event = "VeryLazy",
    opts = {},
  },

  {
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
}
