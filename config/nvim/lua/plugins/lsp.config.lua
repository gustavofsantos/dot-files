return {
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
    "b0o/schemastore.nvim",
    "nvim-telescope/telescope.nvim",
  },
  config = function()
    local mason = require("mason")
    local mason_lspconfig = require("mason-lspconfig")

    mason.setup()
    mason_lspconfig.setup({
      ensure_installed = {
        "lua_ls",
        "vtsls",
        "denols",
        "pyright",
        "dockerls",
        "sqlls",
        "docker_compose_language_service",
        -- "eslint",
        "jsonls",
        "yamlls",
        "vimls",
        "bashls",
      },
    })

    mason_lspconfig.setup_handlers({
      function(server_name)
        require("lspconfig")[server_name].setup({})
      end,
      ["lua_ls"] = function()
        require("lspconfig").lua_ls.setup({})
      end,
      ["jsonls"] = function()
        require("lspconfig").jsonls.setup({
          settings = {
            json = {
              schemas = require("schemastore").json.schemas(),
              validate = { enable = true },
            },
          },
        })
      end,
      ["yamlls"] = function()
        require("lspconfig").yamlls.setup({
          settings = {
            yaml = {
              schemaStore = {
                enable = false,
                url = "",
              },
              schemas = require("schemastore").yaml.schemas(),
            },
          },
        })
      end,
      ["pyright"] = function()
        local lspconfig = require("lspconfig")
        lspconfig.pyright.setup({
          settings = {
            python = {
              analysis = {
                typeCheckingMode = "basic",
              },
            },
          },
        })
      end,
      ["vtsls"] = function()
        local lspconfig = require("lspconfig")
        lspconfig.vtsls.setup({
          root_dir = lspconfig.util.root_pattern("package.json"),
          single_file_support = false
        })
      end,
      ["denols"] = function()
        local lspconfig = require("lspconfig")
        lspconfig.denols.setup({
          root_dir = lspconfig.util.root_pattern("deno.json", "deno.jsonc"),
        })
      end,
      -- disable the kotlin language server
      -- lets be wild
      -- ["kotlin_language_server"] = nil
    })

    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
      callback = function(ev)
        vim.keymap.set("n", "gd", '<cmd>Glance definitions<CR>', { buffer = ev.buf, desc = "Definition" })
        vim.keymap.set("n", "gi", '<cmd>Glance implementations<CR>', { buffer = ev.buf, desc = "Implementation" })
        vim.keymap.set("n", "gr", vim.lsp.buf.rename, { buffer = ev.buf, desc = "Rename symbol" })
        vim.keymap.set("n", "gR", '<cmd>Glance references<CR>', { buffer = ev.buf, desc = "References" })
        vim.keymap.set("n", "g.", vim.lsp.buf.code_action, { buffer = ev.buf, desc = "Code actions" })
        vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = ev.buf, desc = "Hover" })
      end,
    })

    -- Diagnostic symbols in the sign column (gutter)
    local signs = { Error = "■", Warn = "■", Hint = '■', Info = '■' }
    for type, _ in pairs(signs) do
      local hl = "DiagnosticSign" .. type
      vim.fn.sign_define(hl, { text = "", texthl = hl, numhl = "" })
    end

    vim.diagnostic.config({
      underline = false,
      virtual_text = false,
      update_in_insert = false,
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = '■',
          [vim.diagnostic.severity.WARN] = '■',
          [vim.diagnostic.severity.HINT] = '■',
          [vim.diagnostic.severity.INFO] = '■',
        }
      },
      float = {
        source = "if_many",
      },
    })
  end,
}
