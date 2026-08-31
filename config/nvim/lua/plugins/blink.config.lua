return {
  'saghen/blink.cmp',
  dependencies = {
    { 'nvim-mini/mini.icons', version = false },
    "onsails/lspkind.nvim",
  },
  version = '1.*',
  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    -- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
    -- 'super-tab' for mappings similar to vscode (tab to accept)
    -- 'enter' for enter to accept
    -- 'none' for no mappings
    --
    -- All presets have the following mappings:
    -- C-space: Open menu or open docs if already open
    -- C-n/C-p or Up/Down: Select next/previous item
    -- C-e: Hide menu
    -- C-k: Toggle signature help (if signature.enabled = true)
    --
    -- See :h blink-cmp-config-keymap for defining your own keymap
    keymap = { preset = 'default' },

    appearance = {
      -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
      -- Adjusts spacing to ensure icons are aligned
      nerd_font_variant = 'mono'
    },

    -- (Default) Only show the documentation popup when manually triggered
    completion = {
      documentation = { auto_show = false, window = { border = 'solid' } },
      menu = {
        border = 'none',
        draw = {
          components = {
            kind_icon = {
              text = function(ctx)
                if ctx.source_name ~= "Path" then
                  return require("lspkind").symbol_map[ctx.kind] or "" .. ctx.icon_gap
                end

                local is_unknown_type = vim.tbl_contains({ "link", "socket", "fifo", "char", "block", "unknown" },
                  ctx.item.data.type)
                local mini_icon, _ = require("mini.icons").get(
                  is_unknown_type and "os" or ctx.item.data.type,
                  is_unknown_type and "" or ctx.label
                )

                return (mini_icon or ctx.kind_icon) .. ctx.icon_gap
              end,

              highlight = function(ctx)
                if ctx.source_name ~= "Path" then return ctx.kind_hl end

                local is_unknown_type = vim.tbl_contains({ "link", "socket", "fifo", "char", "block", "unknown" },
                  ctx.item.data.type)
                local mini_icon, mini_hl = require("mini.icons").get(
                  is_unknown_type and "os" or ctx.item.data.type,
                  is_unknown_type and "" or ctx.label
                )
                return mini_icon ~= nil and mini_hl or ctx.kind_hl
              end,
            }
          }
        }
      }
    },

    -- Default list of enabled providers defined so that you can extend it
    -- elsewhere in your config, without redefining it, due to `opts_extend`
    sources = {
      default = { 'lsp', 'path', 'snippets', 'buffer' },
    },

    -- (Default) Rust fuzzy matcher for typo resistance and significantly better performance
    -- You may use a lua implementation instead by using `implementation = "lua"` or fallback to the lua implementation,
    -- when the Rust fuzzy matcher is not available, by using `implementation = "prefer_rust"`
    --
    -- See the fuzzy documentation for more information
    fuzzy = { implementation = "prefer_rust_with_warning" }
  },
  opts_extend = { "sources.default" }
}
