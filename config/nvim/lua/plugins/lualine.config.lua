return {
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
          "branch",
          "searchcount",
        },
        lualine_x = {
          {
            "diagnostics",
            colored = true,
            sources = { "nvim_diagnostic", "nvim_workspace_diagnostic" },
            sections = { 'error', 'warn' },
            symbols = { error = "■ ", warn = "■ ", hint = "■ ", info = "■ " },
          },
          "overseer",
          "location",
          { "filetype", colored = true, icon_only = true },
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
        "overseer",
        "neo-tree",
        "fugitive",
        "toggleterm",
      },
    })
  end,
}
