return {
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
}
