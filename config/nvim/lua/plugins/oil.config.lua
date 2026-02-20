return {
  "stevearc/oil.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  cmd = { "Oil" },
  keys = {
    { "-", "<cmd>Oil<CR>", desc = "File explorer" },
  },
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
